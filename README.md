# aws-terraform-platform

Terraform for a small AWS platform, deployed from GitHub Actions **without any stored AWS keys**.
GitHub issues a short-lived OIDC token, AWS exchanges it for a role session, and the role that can
change infrastructure can only be reached from a manually approved GitHub environment.

```
 Pull request                                  Manual run (workflow_dispatch, main only)
      |                                                    |
      v                                                    v
 fmt / validate / tflint / trivy                  environment "dev"  (required reviewer)
      |                                                    |
      v   OIDC                                             v   OIDC
 role: <project>-github-plan  (read-only + state)   role: <project>-github-apply (scoped)
      |                                                    |
      +---------------------- terraform ------------------+
                                  |
                  S3 state (versioned, encrypted, native locking)
                                  |
                 VPC  ->  ALB  ->  ECS Fargate service  ->  CloudWatch Logs
```

## What is in here

| Path | What it does |
|---|---|
| `bootstrap/` | One-time stack: S3 state bucket, GitHub OIDC provider, plan role, apply role. Uses local state. |
| `modules/vpc/` | VPC, 2 public + 2 private subnets, internet gateway, optional single NAT gateway, S3 gateway endpoint, locked-down default security group. |
| `modules/lambda-service/` | Python Lambda (arm64, 128 MB) behind a public HTTPS function URL, own log group, least-privilege execution role. Serves a small page plus `/health` and `/info`. This is the default, free-tier friendly demo. |
| `modules/ecs-service/` | ECS cluster (Container Insights), Fargate task + service with deployment circuit breaker, ALB, security groups (internet -> ALB -> tasks only), log group, separate execution and task roles. Optional HTTPS with an ACM certificate. |
| `envs/dev/` | Composes the modules. The Lambda demo is on by default (`enable_lambda`); the ALB + Fargate nginx demo is created only when `enable_app = true`. Optional cost-alert budget. |
| `.github/workflows/terraform-ci.yml` | On pull requests: `fmt -check`, `validate`, TFLint, Trivy config scan, then `plan` posted as a PR comment. |
| `.github/workflows/terraform-apply.yml` | Manual `apply` or `destroy`, only from `main`, only through the approval-gated `dev` environment. |

## Design decisions

- **OIDC instead of access keys.** Trust policies pin the token `sub` claim: the plan role accepts only
  `repo:<owner>/<repo>:pull_request`; the apply role accepts only `repo:<owner>/<repo>:environment:dev`.
- **Two roles, two blast radii.** Pull requests get read-only access plus the state lock. Changing
  infrastructure needs the protected environment and a human approval.
- **Native S3 state locking** (`use_lockfile`, Terraform 1.10+), so there is no DynamoDB table to manage.
- **Cost-aware defaults.** No NAT gateway by default: tasks run in public subnets with a public IP, but their
  security group accepts traffic from the load balancer only. Set `enable_nat_gateway = true` to run them in
  private subnets instead.
- **Apply role is scoped, not admin.** IAM actions are limited to roles named `<project>-*`, and `PassRole` only
  to `ecs-tasks.amazonaws.com`. Service actions (`ec2:*`, `ecs:*` and so on) are still broad by action; see
  "Known limitations".

## Status: read this first

- Checked locally with Terraform 1.16.5 and AWS provider 6.x: `terraform fmt -check` is clean and
  `terraform init -backend=false && terraform validate` succeeds in `bootstrap`, `envs/dev` and all three modules.
- Bootstrap applied to a real AWS account (state bucket, GitHub OIDC provider, plan and apply roles). The dev stack
  (Lambda demo) has not been applied yet, and the first CI run is still to come.
  Do not describe the demo as running anywhere until the apply workflow has run and the output URL works.
- Provider is pinned to `>= 6.0, < 7.0` (the `data.aws_region` `region` attribute needs provider 6).

## Setup

Prerequisites: an AWS account, AWS CLI credentials with admin rights **for the one-time bootstrap only**,
Terraform >= 1.10, and a GitHub repository for this code.

1. **Bootstrap** (local state, run once):
   ```bash
   cd bootstrap
   cp example.tfvars terraform.tfvars   # edit github_org / github_repo
   terraform init
   terraform apply
   ```
   Keep `bootstrap/terraform.tfstate` safe; it is git-ignored on purpose.

2. **Configure GitHub** (Settings -> Secrets and variables -> Actions -> *Variables*, not secrets):
   `AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN` and `TF_STATE_BUCKET` from the bootstrap outputs.
   Then create an environment named `dev` (Settings -> Environments) and add yourself as a required reviewer.

3. **Open a pull request.** CI runs the checks and posts the plan.

4. **Deploy:** merge to `main`, then Actions -> `terraform-apply` -> Run workflow -> `apply`, and approve it.
   The URL is in the job output (`web_url`; `app_url` only when `enable_app` is on).

5. **Tear down** when you are done: run the same workflow with `destroy`.

Local run without GitHub, once the bootstrap exists:
```bash
cd envs/dev
terraform init -backend-config="bucket=<state_bucket>"
terraform plan
```

## Cost

**With the defaults, this stack should cost nothing.** The S3 state bucket (a few KB), IAM roles, OIDC provider, VPC
networking and the Lambda demo are free at this scale: AWS Lambda includes 1 million requests and 400,000 GB-seconds
per month on its always-free tier. The only billable resources are the Application Load Balancer and the Fargate task,
and they sit behind a switch:

| `enable_lambda` | `enable_app` | `enable_nat_gateway` | Creates | Cost |
|---|---|---|---|---|
| `true` (default) | `false` (default) | `false` (default) | VPC, Lambda + public URL | free at demo traffic |
| any | `true` | `false` | + ALB, Fargate task, log group | ALB roughly €15-20 per month while it exists, Fargate task a few cents per hour |
| any | any | `true` | + NAT gateway | roughly €30 per month more; leave off |

The Lambda URL is public by design. Normal portfolio traffic stays far inside the free allowance, but anyone with the
link can call it. If you are worried about abuse, set `lambda_reserved_concurrency` (not possible on brand-new accounts
that still have the default low concurrency quota), set `budget_email`, or run `destroy` when you are not showing it.

Rough eu-central-1 figures, check the AWS pricing pages for current numbers. To demo the Fargate version for under an
hour and pay cents: set `enable_app = true`, apply, take a screenshot or two, then apply with
`enable_app = false` or run the workflow with `destroy`.

Safety net: set `budget_email` and the stack creates an AWS Budget that emails you at 80% of actual spend and at
100% of forecast (default limit is 1 USD per month; the first two budgets per account are free). A budget alerts,
it does not stop spending, so still destroy what you do not need. Also set `allowed_ingress_cidr` to your own IP
while testing.

## Known limitations

- Demo traffic is plain HTTP unless you pass an ACM `certificate_arn` (then HTTP redirects to HTTPS).
- The apply role is limited by service and by IAM role-name prefix, but not by individual resource. After a first
  successful apply, generate a tighter policy with IAM Access Analyzer.
- Trivy runs report-only in CI. Review the first findings (expect public load balancer, HTTP listener, wildcard
  egress on 443, no customer-managed KMS keys), record accepted ones in a `.trivyignore` with reasons, then set
  `exit-code: "1"`.
- One environment (`dev`). Adding `staging`/`prod` means copying `envs/dev`, giving each its own state key and
  GitHub environment, and widening the apply role trust policy.
- No autoscaling, WAF, custom domain or CI image build; the service runs a stock nginx image.

## Next steps worth doing

- Add Terratest or `terraform test` for the `vpc` module.
- Add Infracost to the pull request workflow.
- Build and push a real application image to ECR and deploy it through this pipeline.