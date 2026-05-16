# Maintenance

This repository uses GitHub Actions for testing, documentation, dependency
upgrades, and release tagging. Workflow files live in `.github/workflows/`.

**Registration status:** registered in the Julia General registry.

## Workflows

| File | Trigger | Purpose |
|---|---|---|
| `Tests.yml` | manual (workflow_dispatch) | Runs the test suite on Ubuntu + Windows, against Julia 1.10 and 1.12. |
| `Documentation.yml` | push to `main` | Builds Documenter docs and deploys them to the `gh-pages` branch. |
| `CompatHelper.yml` | daily cron + manual | Opens a PR whenever a dependency releases a newer major/minor; the PR widens the matching `[compat]` entry in `Project.toml` (and `docs/Project.toml`). |
| `TagBot.yml` | `JuliaTagBot` comment + manual | After a new version is merged into General, creates the `vX.Y.Z` Git tag and a GitHub Release. |

## Why CompatHelper

Julia's General registry requires a `[compat]` entry for every dependency,
and the `"0.12"` syntax is caret-style — it means `>= 0.12.0, < 0.13` and
actively excludes 0.13 when it ships. Without intervention, the package
becomes uninstallable next to anything that has moved on.

CompatHelper handles that intervention automatically: every day it checks
the registry, and if a dep has a new line, it opens a PR like
`ColorTypes = "0.12"` → `"0.12, 0.13"`. You review, test, merge, release.

## Release flow

1. **CompatHelper PR appears**, e.g. widening `ColorTypes` to allow 0.13.
2. **Run Tests.yml against the branch** (Actions → Test → Run workflow →
   select the branch). `Tests.yml` is gated on `workflow_dispatch` only;
   if you'd rather have CompatHelper PRs test automatically, change its
   trigger to `pull_request`.
3. **Merge** the PR if tests are green.
4. **Bump `version =`** in `Project.toml` (usually a patch bump), commit,
   push.
5. **Comment `@JuliaRegistrator register`** on the version-bump commit.
   Julia's Registrator bot opens a PR against General.
6. Once the General PR is merged, `JuliaTagBot` posts back here, which
   triggers `TagBot.yml`. The Git tag and GitHub Release appear
   automatically.

## Required secrets

All workflows share one secret: `DOCUMENTER_KEY`, an SSH deploy key with
write access to this repo. Generate it locally once:

```julia
using DocumenterTools
DocumenterTools.genkeys()
```

Then on GitHub:

- **Settings → Deploy keys** — paste the public key, tick *Allow write
  access*.
- **Settings → Secrets and variables → Actions** — paste the private
  key as `DOCUMENTER_KEY`.

The same key is reused by `Documentation.yml`, `CompatHelper.yml`, and
`TagBot.yml`.
