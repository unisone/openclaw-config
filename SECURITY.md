# Security

This repo contains config and automation scripts that are designed to be copied into a real OpenClaw workspace.

## Reporting a vulnerability

If you find a security issue (e.g., something that could cause secret leakage, unsafe file permissions, or remote execution surprises), please open a GitHub issue with:

- the file path
- what the risk is
- how to reproduce
- a suggested fix (if you have one)

If the report includes sensitive details, contact the maintainer privately first.

## Safety rules for contributors

- Never commit secrets (keys, tokens, cookies, auth headers)
- Avoid embedding personal identifiers in templates
- Scripts should fail safely (don’t `rm -rf`, don’t upload data)

## Safety rules for users

- Review any file before copying into your workspace
- Treat `config/*.json5` as examples — merge carefully
- Don’t run scripts you don’t understand on machines that hold credentials
