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
curl -fsSL https://raw.githubusercontent.com/RuoxiQin/tech-cofounder-cli/main/install.sh | VERSION=v0.1.0 bash
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

## Repository Structure

```
.
├── install.sh             # Zero-dependency installer script
├── README.md              # Documentation
└── releases/
    ├── manifest.json      # Machine-readable release catalog
    └── v0.1.0/            # Versioned release assets
        ├── tc-v0.1.0-darwin-arm64.tar.gz
        ├── tc-v0.1.0-darwin-amd64.tar.gz
        └── SHA256SUMS
```

---

## Supported Architectures

- **macOS Apple Silicon (`darwin-arm64`)**: M1, M2, M3, M4 Macs
- **macOS Intel (`darwin-amd64`)**: Intel x86_64 Macs
