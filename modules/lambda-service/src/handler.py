"""Tiny demo handler served through a Lambda function URL.

It only reports facts the runtime already knows (function name, region,
runtime, memory). Nothing here claims more than the deployment can prove.
"""

import html
import json
import os


def handler(event, context):
    info = {
        "service": os.environ.get("SERVICE_NAME", "unknown"),
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
        "function": context.function_name,
        "region": os.environ.get("AWS_REGION", "unknown"),
        "runtime": os.environ.get("AWS_EXECUTION_ENV", "unknown"),
        "memory_mb": context.memory_limit_in_mb,
        "request_id": context.aws_request_id,
    }

    path = (event.get("rawPath") or "/") if isinstance(event, dict) else "/"

    if path == "/health":
        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"status": "ok"}),
        }

    if path == "/info":
        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps(info, indent=2),
        }

    rows = "".join(
        f"<tr><th>{html.escape(k)}</th><td>{html.escape(str(v))}</td></tr>"
        for k, v in info.items()
    )
    page = (
        "<!doctype html><html lang='en'><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        "<title>aws-terraform-platform</title>"
        "<style>body{font:16px/1.5 system-ui,sans-serif;max-width:40rem;margin:3rem auto;padding:0 1rem}"
        "th{text-align:left;padding-right:1.5rem;color:#555}table{border-collapse:collapse}"
        "td,th{padding:.25rem 0}</style></head><body>"
        "<h1>aws-terraform-platform</h1>"
        "<p>This page is served by an AWS Lambda function that was deployed with Terraform "
        "from GitHub Actions using OIDC (no stored AWS keys).</p>"
        f"<table>{rows}</table>"
        "<p>Also available: <a href='/health'>/health</a>, <a href='/info'>/info</a>.</p>"
        "</body></html>"
    )
    return {
        "statusCode": 200,
        "headers": {"content-type": "text/html; charset=utf-8"},
        "body": page,
    }