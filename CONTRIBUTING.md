# CONTRIBUTING

This document provides all the information you would need to contribute to this repository.
If you have any questions, please feel free to contact the repository owner. Details provided in the footer.

---

## TABLE OF CONTENTS

- [CONTRIBUTING](#contributing)
  - [TABLE OF CONTENTS](#table-of-contents)
  - [Branching Workflow](#branching-workflow)
    - [Permanent branches](#permanent-branches)
    - [Supporting branches](#supporting-branches)
    - [Naming conventions](#naming-conventions)
    - [Workflow](#workflow)
      - [Starting a feature](#starting-a-feature)
      - [Starting a release](#starting-a-release)
      - [Starting a hotfix](#starting-a-hotfix)
    - [Pull requests](#pull-requests)
    - [Closing issues](#closing-issues)
  - [Commit message requirements](#commit-message-requirements)
  - [Continuous integration checks](#continuous-integration-checks)
  - [Code comment style](#code-comment-style)
  - [CONTACT INFORMATION](#contact-information)
  - [COPYRIGHT](#copyright)

---

## Branching Workflow

This repository follows a Gitflow-style workflow, with one deliberate
deviation from strict Gitflow: **feature branches are squash-merged into
`develop`**, rather than merged with a merge commit. Release and hotfix
branches still merge normally (a real merge commit), so `master`'s history
and version tags stay intact.

It defines two permanent branches and several types of short-lived
supporting branches, each with a specific purpose and merge direction.

---

### Permanent branches

| Branch    | Purpose                                                                                       |
|-----------|-----------------------------------------------------------------------------------------------|
| `master`  | Production-ready code only. Every commit on `master` is a release.                            |
| `develop` | Integration branch. Reflects the latest delivered development changes for the next release.   |

Nobody commits directly to `master` or `develop`. All changes arrive via
pull requests from supporting branches.

---

### Supporting branches

| Branch | From      | Merges into          | Merge type    | Naming             | Purpose                         |
|--------|-----------|----------------------|---------------|--------------------|---------------------------------|
| Feature| `develop` | `develop`            | Squash merge  | `feature/<name>`   | New or in-progress functionality|
| Release| `develop` | `master`, `develop`  | Merge commit  | `release/<version>`| Stabilise and prepare a release |
| Hotfix | `master`  | `master`, `develop`  | Merge commit  | `hotfix/<version>` | Urgent production fixes         |

Squashing a feature branch collapses all of its commits into a single new
commit on `develop`. That commit has no merge-parent link back to
`feature/<name>`, so the branch's individual commits do not appear in
`develop`'s history — only the squashed result does.

```mermaid
%%{init: { 'gitGraph': { 'mainBranchName': 'master' }}}%%
gitGraph
   commit id: "init"
   branch develop
   checkout develop
   commit id: "setup"
   branch feature/core
   checkout feature/core
   commit id: "work"
   checkout develop
   commit id: "core (squashed)"
   branch release/v1.0.0
   checkout release/v1.0.0
   commit id: "stabilise"
   checkout master
   merge release/v1.0.0 tag: "v1.0.0"
   checkout develop
   merge release/v1.0.0
   checkout master
   branch hotfix/v1.0.1
   checkout hotfix/v1.0.1
   commit id: "fix"
   checkout master
   merge hotfix/v1.0.1 tag: "v1.0.1"
   checkout develop
   merge hotfix/v1.0.1
```

---

### Naming conventions

- Feature branches: `feature/<short-description>` (e.g. `feature/login-page`)
- Release branches: `release/<version>` (e.g. `release/v1.1.0`)
- Hotfix branches: `hotfix/<version>` (e.g. `hotfix/v1.0.1`)

Versions follow [Semantic Versioning](https://semver.org/) (`vMAJOR.MINOR.PATCH`).

---

### Workflow

#### Starting a feature

```text
git checkout develop
git pull origin develop
git checkout -b feature/<short-description>
```

Push the branch and open a pull request into `develop` when ready.
**Squash merge** the pull request — GitHub's "Squash and merge" option, or
the CLI equivalent — so the feature lands on `develop` as one commit.
Delete the feature branch once merged.

#### Starting a release

When `develop` has enough features for a release:

```text
git checkout develop
git pull origin develop
git checkout -b release/<version>
```

Only bug fixes, documentation, and release-related chores (version bumps,
changelog) belong on a release branch — no new features.

When the release branch is stable:

1. Open a pull request from `release/<version>` into `master`. Merging tags
   the resulting commit as `<version>`.
2. `sync-master-to-develop.yaml` automatically opens a pull request
   bringing that merge into `develop` — review and merge it (a regular
   merge commit, not squash) so the fixes made during stabilisation
   aren't lost.
3. Delete the release branch.

#### Starting a hotfix

For an urgent fix to production:

```text
git checkout master
git pull origin master
git checkout -b hotfix/<version>
```

When the fix is ready:

1. Open a pull request from `hotfix/<version>` into `master`. Merging tags
   the resulting commit as `<version>`.
2. `sync-master-to-develop.yaml` automatically opens a pull request
   bringing that merge into `develop` — review and merge it (a regular
   merge commit, not squash) so the fix is included in future releases.
   ⚠️ **Caution:** this automation only syncs into `develop`. If a
   `release/*` branch is active at the same time, merge the fix into that
   branch by hand too — the sync does not cover it.
3. Delete the hotfix branch.

---

### Pull requests

- All merges into `master` or `develop` happen via pull request — no direct
  pushes.
- A pull request into `master` must come from a `release/*` or `hotfix/*`
  branch. Enforced by the `Branch Policy Check` required status check —
  see [Continuous integration checks](#continuous-integration-checks).
- `feature/*` → `develop` pull requests must be **squash merged**.
- `release/*` and `hotfix/*` pull requests must use a regular **merge
  commit** (not squash, not rebase) — this keeps `master`'s history and
  tags accurate and preserves the full set of stabilisation commits when
  merging back into `develop`.
- Keep feature branches short-lived and up to date with `develop` to avoid
  large, conflict-prone merges.

---

### Closing issues

⚠️ **Caution:** merging into `develop` does **not** auto-close referenced issues, even
with GitHub's usual `Closes #123`-style keywords. GitHub only evaluates
those keywords when a pull request merges into the repository's
**default branch** (`master`) — not `develop`.

Issues are therefore **closed manually** when merging a `feature/*` pull
request, rather than automated. This is a deliberate choice, not a
limitation being worked around: closing issues by hand at merge time
means actually reviewing what a merge resolves, rather than trusting a
keyword match.

Reference the issues a pull request addresses in its description (e.g.
`References #123`) so there's a checklist to close against at merge
time, even though this reference will not trigger an automatic close.

---

## Commit message requirements

All commit messages, and `feature/*` → `develop` pull request titles and
descriptions (squashing turns the PR title + body into the actual commit
message — see [Supporting branches](#supporting-branches)), must follow
[Conventional Commits](https://www.conventionalcommits.org/) as
configured in `.config/commitlint.config.mjs`, with a custom plugin at
`.config/signed-off-by-regex.js`.

Beyond the standard Conventional Commits format, this project requires:

- A **scope** from a fixed list: `core`, `api`, `ui`, `auth`, `db`, `deps`,
  `tests`, `config`, `security`, `rebase`.
- A **subject in the imperative mood** — "add", "update", "fix", not
  "added", "updated", "fixed". Read it as completing "This commit will
  ...".
- A **body** of at least 10 characters, in sentence case.
- A **`Signed-off-by: Name <email@example.com>`** line — a
  [Developer Certificate of Origin](https://developercertificate.org/)-style
  sign-off, not a cryptographically signed commit.

⚠️ **Not yet enforced by commitlint:** the imperative-mood rule above is
currently a convention only — `.config/commitlint.config.mjs` has no rule
checking it (commitlint has no built-in imperative-mood check), so
"added"/"updated" subjects will still pass CI today. See the TODO in that
file for tightening this.

Example:

```text
feat(core): add player movement

Adds basic WASD movement to the player controller.

Signed-off-by: Jane Doe <jane@example.com>
```

---

## Continuous integration checks

Pushing to a `feature/*` branch, and opening a pull request into `develop`
or `master`, each trigger automated checks:

| Check                    | Runs on                                  | What it checks                                |
|--------------------------|------------------------------------------|-----------------------------------------------|
| `preview / commitlint`   | Push to `feature/*`                      | Latest commit message; see [requirements][cm] |
| `preview / markdownlint` | Push to `feature/*`                      | Every Markdown file in the repository         |
| `lint-pr-message`        | `feature/*` → `develop` pull requests    | PR title and body become the squash commit    |
| `check-source-branch`    | Pull requests into `master` or `develop` | PR source branch matches the allowed pairings |

[cm]: #commit-message-requirements

`preview / commitlint` and `preview / markdownlint` also register a
`preview` GitHub Deployment for the commit.

🚨 **Warning:** do **not** add a "Require deployments to succeed: preview"
branch protection rule on `develop` — this was tried and it breaks
GitHub's auto-merge feature outright ("Failed enabling auto-merge for
pull request"), even when every check is genuinely passing. It's also
redundant: the jobs that create the `preview` deployment are the same
jobs already enforced as required status checks above, so the rule adds
no protection that isn't already there. Require the status checks
themselves, not the deployment.

`preview / commitlint` and `preview / markdownlint` also register a
`preview` GitHub Deployment for the commit, so a "Require deployments to
succeed: preview" branch protection rule has something to check against.

---

## Code comment style

In source-code comments (`.mjs`, `.js`, `.sh`, `.yaml`, etc.), prefer
backticks (`` ` ``) over single quotes (`'`) when quoting an identifier,
value, file path, or branch name — e.g. `` `feature/*` `` rather than
`'feature/*'`. This matches how this document quotes identifiers and
keeps quoting consistent between prose and code.

---

## CONTACT INFORMATION

Author: Daniel Mallett (Monkey Knuckles)

If you have any problems with the repository or have any suggestions please contact us at <info@ninjamonkeygames.com>.

You may also contact us via our [website](https://ninjamonkeygames.com).

Any bugs should be raised as an [issue](https://github.com/NinjaMonkeyGames/grid-utility-professional/issues) on
GitHub.

---

## COPYRIGHT

*NinjaMonkeyGames™ Copyright © 2026 All rights reserved.*
