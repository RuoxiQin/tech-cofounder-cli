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
tc apps create "My App" --json
tc apps get my-app --json
tc apps create my-app --fix --json
tc deploy my-app "$(git rev-parse HEAD)" --json
```

`tc apps create` dispatches backend Cloud Run provisioning and automatically waits
up to thirty minutes for the app to reach `ready` status. `--fix` rechecks all provisioning
steps, including previously succeeded operations. Deployment uses the exact pushed commit
and waits up to twenty minutes. Successful runs populate the app's serving URL. `tc apps delete`
retires cloud resources and removes the source repository; local files are preserved.

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
