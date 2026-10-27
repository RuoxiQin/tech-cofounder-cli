# tech-cofounder-cli

Public binary distribution repository for `tc` — the command-line client for the [tech-cofounder](https://github.com/RuoxiQin/tech-cofounder-skills) platform.

This repository hosts standalone macOS native builds compiled with Nuitka, version manifests, and SHA-256 checksums. Standalone releases bundle their required runtime and dependencies without requiring a host Python or virtual environment.

---

## Quick Install (macOS)

Install the latest version into `~/.local/share/tech-cofounder/` and link the binary to `~/.local/bin/tc`:

```bash
curl -fsSL https://raw.githubusercontent.com/RuoxiQin/tech-cofounder-cli/main/install.sh | bash
```

### Install Specific Version

```bash
curl -fsSL https://raw.githubusercontent.com/RuoxiQin/tech-cofounder-cli/main/install.sh | VERSION=v0.1.1 bash
```

---

## Verify Installation

Ensure `~/.local/bin` is in your `$PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Verify the CLI:

```bash
tc --help
```

---

## App Provisioning and Deployment

```bash
tc apps create my-app --name "My App" --json
tc apps get my-app --json
tc apps create my-app --fix --json
tc deploy my-app "$(git rev-parse HEAD)" --json
tc deploys get my-app <deploy_id> --json
```

`tc apps create` dispatches backend Cloud Run provisioning and automatically waits
up to thirty minutes for the app to reach `ready` status. `--fix` resumes incomplete
provisioning steps; `--hard-fix` rechecks all steps, including completed operations. Deployment uses the exact pushed commit.
`tc deploy` returns as soon as the deploy is accepted; check it with `tc deploys get`
until its status is `succeeded` or `failed`. Successful runs populate the app's serving URL. `tc apps delete`
retires cloud resources and removes the source repository; local files are preserved.

CLI v0.1.16 no longer waits for deploys or validations. `tc deploy` and `tc validate`
print the accepted run, including its ID, and exit. `tc deploys get <app_id>
<deploy_id>` and `tc validations get <app_id> <validation_id>` read its status once:
a pending or running run exits 0, and a finished run exits with the codes
`tc deploy` and `tc validate` use for success or failure. Check every minute or so
until the run finishes; a deploy can take 20 minutes or more.

CLI v0.1.15 waits up to sixty-five minutes for `tc deploy` and `tc validate`, longer
than the platform's one-hour worker limit, so a long deploy (for example one that
builds Firestore indexes) is reported as finished rather than timed out. Run it in the
background if your agent's shell stops commands sooner.

CLI v0.1.14 adds resource details to the readable `tc apps get <app_id>` output:
GCP project ID, region, Cloud Run service, image repository, and numeric GitHub
repository ID. The project ID is shown as soon as it is assigned; regional
resource details appear after provisioning. `--json` already exposes these fields.

The CLI requires a root `tech_cofounder_configs.json` for local Terraform validation.
CLI v0.1.13 adds optional supporting files used by Terraform's `file()` function:

```json
{
  "schema_version": 1,
  "terraform": {
    "directory": "infra/terraform",
    "supporting_files": ["firestore.rules"]
  },
  "web_app": {
    "dockerfile": "web_app/Dockerfile",
    "build_context": "web_app"
  }
}
```

Keep the bundled backend/frontend under `web_app/` and deploy it as one Cloud Run
service. Paths are relative to the repository root; use `"."` for a repository-root
build context. Run `tc validate my-app --dir . --json` at the repository root before
pushing and deploying. Deployment reads this manifest from the exact pushed commit.

`supporting_files` is optional and defaults to an empty list. List only UTF-8 files
stored directly beside the Terraform configuration (for example,
`infra/terraform/firestore.rules`). Use unique simple filenames, not nested paths
or symlinks; `.tf`/`.tf.json` files are discovered automatically. Terraform control,
variable, state, and binary files are unsupported companions. Keep secrets out.
Local validation packages the declared files; deployment retrieves them from the
exact pushed commit. Optional root `firebase.json` is for Firebase tools, not tc.

## Repository Structure

```
.
├── .gitignore             # Ignores large binary archives
├── install.sh             # Zero-dependency installer script (downloads from GitHub Releases)
├── README.md              # Documentation
└── releases/
    ├── manifest.json      # Machine-readable release catalog
    └── v0.1.1/
        └── SHA256SUMS     # Checksums for v0.1.1 release
```

Binary `.tar.gz` packages are attached directly to each [GitHub Release](https://github.com/RuoxiQin/tech-cofounder-cli/releases).

---

## Supported Architectures

- **macOS Apple Silicon (`darwin-arm64`)**: M1, M2, M3, M4 Macs
- **macOS Intel (`darwin-amd64`)**: Intel x86_64 Macs
