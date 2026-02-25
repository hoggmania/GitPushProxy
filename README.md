# Stateless Gitleaks GitProxy Service

This repository builds a custom service based on [finos/git-proxy](https://github.com/finos/git-proxy) that runs **Gitleaks only**.

## What this service does

- Uses upstream `finos/git-proxy` source (pinned commit in `Dockerfile`).
- Applies `patches/git-proxy-stateless-gitleaks.patch` during image build.
- Keeps only these push processors:
  - `parsePush`
  - `pullRemote`
  - `writePack`
  - `gitleaks`
- Removes stateful behavior:
  - no approval flow
  - no audit persistence
  - no repo/user bootstrap state
- Removes built-in checks unrelated to Gitleaks.

## Run

```bash
docker compose up --build
```

Service endpoint: `http://localhost:8000`

## Git remote example

```bash
git remote add proxy http://localhost:8000/github.com/OWNER/REPO.git
git push proxy HEAD
```

## Configuration

Edit `config/proxy.config.json`.

- `api.gitleaks.enabled` should remain `true`.
- Optionally add `api.gitleaks.configPath` and mount that file in your deployment.
- Replace `cookieSecret` for production use.
