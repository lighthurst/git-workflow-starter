# Git Workflow Starter

Drop-in git workflow tooling for any project. Choose your approach:

| Approach        | Best For                        | Commit Validation | Hooks            | Releases         |
| --------------- | ------------------------------- | ----------------- | ---------------- | ---------------- |
| **Husky**       | JS/TS projects                  | commitlint (npm)  | npm-based        | semantic-release |
| **Pre-commit**  | Terraform, Go, Python, polyglot | commitlint (npm)  | Python framework | semantic-release |
| **Rust-native** | Rust projects                   | committed (Rust)  | cargo-husky      | release-plz      |

**Requirements:**

- Husky / Pre-commit: Node 22+ (pinned via `.nvmrc`)
- Rust-native: Rust toolchain only (no Node/Python)

## Quick Start

```bash
# Interactive setup - copies files to your project
./setup.sh /path/to/your/project

# Or run from your project directory
/path/to/git-workflow-starter/setup.sh .
```

The script will ask you to choose:

1. Hook framework (Husky, Pre-commit, or Rust-native)
2. Project type (for pre-commit: Terraform, JS, Python, Go, or generic)

## Manual Setup

### Option A: Husky (Node.js)

```bash
cp husky/package.json /your/project/
cp -r husky/.husky /your/project/
cp shared/commitlint.config.js /your/project/
cp shared/.releaserc.json /your/project/
cp shared/.nvmrc /your/project/
cp -r shared/.github /your/project/

cd /your/project
npm install
```

### Option B: Pre-commit (Python)

```bash
cp pre-commit/package.json /your/project/
cp pre-commit/.pre-commit-config.yaml /your/project/
cp shared/commitlint.config.js /your/project/
cp shared/.releaserc.json /your/project/
cp shared/.nvmrc /your/project/
cp -r shared/.github /your/project/

cd /your/project
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
npm install  # for commitlint + semantic-release
```

Then edit `.pre-commit-config.yaml` to uncomment hooks for your stack.

**Important:** Commit `package-lock.json` - do NOT add it to `.gitignore`. CI requires it for `npm ci`.

### Option C: Rust-native

```bash
cp rust-native/.github/workflows/ci.yml /your/project/.github/workflows/
cp rust-native/release-plz.toml /your/project/
cp rust-native/committed.toml /your/project/
cp rust-native/.gitignore /your/project/
cp rust-native/Cargo.toml.template /your/project/
cp -r rust-native/.cargo-husky /your/project/
cp shared/.github/dependabot.yml /your/project/.github/
cp shared/.github/pull_request_template.md /your/project/.github/

cd /your/project
# Review Cargo.toml.template and merge into your Cargo.toml
chmod +x .cargo-husky/hooks/*  # ensure hooks are executable
cargo install committed  # for local commit validation
cargo test  # installs git hooks via cargo-husky
```

Edit `dependabot.yml` to use `package-ecosystem: "cargo"` instead of npm.

## Folder Structure

```
git-workflow-starter/
├── setup.sh                 # Interactive setup script
├── shared/                  # Used by husky and pre-commit
│   ├── .nvmrc               # Node version (22)
│   ├── commitlint.config.js # Commit message rules
│   ├── .releaserc.json      # Semantic-release config
│   └── .github/
│       ├── workflows/
│       │   └── ci.yml       # CI pipeline (uses GitHub App)
│       ├── dependabot.yml   # Automated dependency updates
│       └── pull_request_template.md
├── husky/                   # Husky-based approach
│   ├── package.json         # Full npm tooling (8 deps)
│   └── .husky/
│       ├── commit-msg
│       └── pre-commit
├── pre-commit/              # Pre-commit framework approach
│   ├── package.json         # 5 deps (commitlint + releases)
│   └── .pre-commit-config.yaml
├── rust-native/             # Rust-native approach (no Node/Python)
│   ├── Cargo.toml.template  # cargo-husky config
│   ├── .cargo-husky/
│   │   └── hooks/
│   │       ├── pre-commit   # cargo fmt + clippy
│   │       └── commit-msg   # committed validation
│   ├── committed.toml       # Conventional commit rules
│   ├── release-plz.toml     # release-plz config
│   ├── .gitignore           # Rust-specific ignores
│   └── .github/
│       └── workflows/
│           └── ci.yml       # Rust CI + release-plz
└── examples/                # CI snippets to copy from
    └── ci-python.yml
```

## Commit Format

All approaches enforce conventional commits:

```
type(scope): description

feat: add user authentication
fix(api): handle null response
docs: update README
refactor!: change auth flow    # Breaking change
```

**Types:** feat, fix, docs, style, refactor, perf, test, chore, revert, ci, build

**Scopes:** api, auth, config, core, db, deps, infra, ui (or add your own)

## Automatic Releases

Push to `main` triggers automated releases (semantic-release or release-plz):

| Commit Type                    | Version Bump | Example       |
| ------------------------------ | ------------ | ------------- |
| `fix:`                         | Patch        | 1.0.0 → 1.0.1 |
| `feat:`                        | Minor        | 1.0.0 → 1.1.0 |
| `feat!:` or `BREAKING CHANGE:` | Major        | 1.0.0 → 2.0.0 |

Creates GitHub release + updates CHANGELOG.md automatically.

**Note:** Rust-native uses release-plz instead of semantic-release. Same version bump logic, but updates `Cargo.toml` instead of `package.json`.

## GitHub App Setup (Required for Protected Branches)

If your `main` branch requires PRs (branch protection), the release tools (semantic-release or release-plz) need a GitHub App to bypass protection for automated releases.

### One-time setup (do this once per GitHub account)

1. **Create the GitHub App**

   - Go to GitHub → Settings → Developer settings → GitHub Apps → New GitHub App
   - **Name:** `Release Bot` (or any name)
   - **Homepage URL:** `https://github.com/yourusername`
   - **Webhooks:** Uncheck "Active" (not needed)
   - **Permissions:**
     - Repository permissions:
       - Contents: **Read and write**
       - Issues: **Read and write**
       - Pull requests: **Read and write**
       - Metadata: **Read-only** (auto-selected)
   - Click "Create GitHub App"

2. **Generate a private key**

   - On the app page, scroll to "Private keys"
   - Click "Generate a private key"
   - Save the `.pem` file

3. **Note the App ID**

   - On the app page, copy the "App ID" number

4. **Install the app on your repos**
   - Go to "Install App" in the left sidebar
   - Choose "All repositories" or select specific repos
   - Click "Install"

### Per-repo setup

Add these secrets to each repo (Settings → Secrets and variables → Actions):

| Secret Name               | Value                       |
| ------------------------- | --------------------------- |
| `RELEASE_APP_ID`          | The App ID number           |
| `RELEASE_APP_PRIVATE_KEY` | Contents of the `.pem` file |

**Tip:** Use organization-level secrets to avoid repeating this per repo.

### Add app to branch protection bypass

1. Go to repo Settings → Rules → Rulesets (or Branch protection rules)
2. Edit your `main` branch rule
3. Under "Bypass list", add your GitHub App
4. Save

Now the release tool can push version commits and tags to `main`.

---

## Customization

### Commitlint rules

Edit `commitlint.config.js`:

- Add/remove allowed scopes in `scope-enum`
- Adjust `header-max-length` (default: 100)
- Modify allowed commit types in `type-enum`

### Pre-commit hooks

Edit `.pre-commit-config.yaml`:

- Uncomment hooks for your language/framework
- Add custom hooks as needed
- See [pre-commit.com](https://pre-commit.com/hooks.html) for available hooks

**Included hooks by language:**
| Language | Hooks |
|----------|-------|
| Python | ruff (lint + format), mypy (types) |
| JavaScript | eslint, prettier |
| Terraform | fmt, validate, tflint, docs |
| Go | fmt, vet, build |
| Shell | shellcheck |

### Rust-native config

**Commit validation** - Edit `committed.toml`:

- Add/remove allowed types in `types`
- Add allowed scopes in `scopes` (or leave empty for any)
- Adjust `max_length` for subject line

**Release automation** - Edit `release-plz.toml`:

- Customize changelog format in `[changelog]`
- Configure per-package settings for workspaces
- Enable/disable crates.io publishing

**Git hooks** - Edit `.cargo-husky/hooks/`:

- `pre-commit`: runs before commit (cargo fmt, clippy)
- `commit-msg`: validates commit message (committed)

### CI Pipeline

Edit `.github/workflows/ci.yml`:

- Replace placeholder steps with your actual validation
- Add environment variables/secrets as needed

### Dependabot

Edit `.github/dependabot.yml`:

- Adjust `schedule.interval` (daily, weekly, monthly)
- Add ecosystems for your stack (pip, docker, terraform, etc.)
- Configure `ignore` rules to skip certain packages
