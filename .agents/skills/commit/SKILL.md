---
name: commit
description: Stage, generate a Conventional Commits message, and commit, writing the changelog and architecture entries from the staged diff in the same pass. Use when the user asks to commit changes, stage and commit, create a commit, update or sync docs alongside a commit, or prepare a release; release mode (/commit v{version}) promotes the changelog, bumps the version, and tags the release
---

# Commit Changes

Two modes:

- **Commit mode (Steps 1–7, the default)** — stage, write the `docs/CHANGELOG.md` and `docs/ARCHITECTURE.md` entries the staged diff requires (plus `README.md` when it has gone stale), confirm the message with the user, and make one commit. Nearly every invocation stops here.
- **Release mode (Step 8, opt-in)** — triggered by `/commit v{version}`, where the user supplies the version: promote the accumulated `Unreleased` entries to that version, bump the version file (`pyproject.toml` in a Python project), commit the release, and tag it.

If the message is `/commit v{version}`, run the **whole** workflow — Steps 1–7 as a normal commit, then Step 8 as the release commit, so the invocation yields two commits and a tag: the work itself, then `chore(release): prepare v{version}` tagged `v{version}`. A bare `/commit` (no version) is commit mode and stops after Step 7. Anything else ("commit this", "update the docs") is commit mode as well.

## Workflow

### Step 1: Stage All Changes

```bash
git add .
```

### Step 2: Inspect Staged Changes

Understand what was modified before writing the commit message:

```bash
git diff --cached --stat
git diff --cached
```

Pay attention to:
- **Scope**: which modules/packages are affected
- **Nature**: new feature, bug fix, refactor, docs, test, style, etc.
- **Impact**: breaking change, deprecation, new API, internal-only

If the staging area is empty — nothing was modified, or everything was already committed — say so and stop; there is nothing to commit.

### Step 3: Write the Docs This Commit Requires

This step is the only place `docs/CHANGELOG.md` and `docs/ARCHITECTURE.md` are written: they are prepared **with the commit, never while the change itself is being made**. Entries already sitting in the staged diff are raw material — keep what the diff supports and finish what it is missing; when an entry is not supported by the diff, flag it and ask the user before removing it.

`docs/CHANGELOG.md`, `docs/ARCHITECTURE.md`, and `README.md` are **not** touched on every commit. Decide from the staged diff in Step 2 whether the change is user-visible or structural: when it is neither, the correct action is to change none of these files and go straight to the commit message.

| Change in the staged diff | CHANGELOG | ARCHITECTURE | README |
|---|---|---|---|
| New feature, new CLI flag, new public API | entry under `Added` | if it adds a module, subsystem, or entry point | if the documented surface changed |
| Fix, behavior change, deprecation, removal | entry under `Fixed` / `Changed` / `Removed` | no | if the documented surface changed |
| Installation, supported Python, dependencies, quickstart, examples | entry under `Changed` | no | keep it accurate |
| Repository layout, startup/entry flow, plugin or module set, setup scripts | entry under `Changed` when user-visible | targeted edit to the section that went stale | if the documented surface changed |
| Internal refactor with identical behavior | no | no | no |
| Type annotations, formatting, lint, CI, tooling config | no | no | no |
| Tests only | no | no | no |
| Docs only | no — a changelog entry about documentation is noise | only for the structure being documented | only if the README itself is wrong |

**CHANGELOG** — a file at `docs/CHANGELOG.md`, else the root `CHANGELOG.md`. If it exists, append to the entries already under the top `Unreleased` heading, under the `Added` / `Changed` / `Fixed` / `Removed` / `Security` heading that fits, in the file's existing style. Never start a new version section and never duplicate an entry for a change already listed there. An entry describes the state a reader will get, not the order the work happened in: when the diff reworks something that is itself still only an `Unreleased` addition, extend that `Added` entry instead of filing a `Changed` one for a state no release ever had.

**README** — update only when the change makes a documented statement inaccurate: the described commands/flags, install steps, feature list, project structure, or example paths. A new internal module or a refactor is not a README change.

**ARCHITECTURE** — a file at `docs/ARCHITECTURE.md`, else the root `ARCHITECTURE.md`; a repository that keeps none skips it. Update only the sections the commit made stale — repository layout, startup or entry flow, the plugin/module set, the setup scripts, or how a subsystem is wired — as a targeted edit, never a rewrite. It records structure and design decisions, so a behavior fix that leaves the structure alone needs no edit.

When it is genuinely unclear whether the change is user-visible or structural, ask the user instead of guessing. When in doubt between an entry and no entry, the entry is the safer choice — but never invent a user-facing change that the diff does not contain.

If any of these files was edited, it gets staged by name in Step 6, so the doc changes land in the same commit — then continue with the message.

### Step 4: Generate Commit Message

Format: [Conventional Commits](https://www.conventionalcommits.org/) — `type(scope): description`

**Types:**

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, semicolons (no code change) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks, dependency updates, tool config |
| `ci` | CI/CD pipeline changes |
| `build` | Build system or external dependencies |

**Scope:** optional module/area name derived from the files modified. Pick the most specific relevant scope. Omit for repo-wide changes.

**Subject line rules:**
- Use imperative mood ("add feature" not "added feature" or "adds feature")
- Lowercase first word after scope
- No period at the end
- Max 72 characters for the full `type(scope): description`

**Examples:**

```
feat(auth): add JWT token refresh endpoint
fix(db): prevent connection leak on timeout
docs(readme): add installation instructions
refactor(api): extract pagination helper
chore(deps): bump httpx to 0.28
test(core): add edge case coverage for parser
```

### Step 5: Determine if Body is Needed

Include a body paragraph when:
- The change has non-obvious reasoning ("why" not "what")
- Multiple interacting parts need context
- It fixes a subtle bug worth explaining
- It introduces a deprecation or migration note

**Body format — HARD RULE (ONE LINE ONLY):** Every paragraph — including EVERY bullet point in an enumeration — must stay on ONE single line. Never wrap a paragraph or bullet across multiple lines, no matter how long it is. There is NO length exception. If a bullet is too long to fit on one line, shorten its wording instead of wrapping it. Separate paragraphs with an empty line.

Correct — each bullet stays on ONE line, even when long:

```
type(scope): description

- Bullet point one that keeps going even when the sentence is quite long and detailed
- Bullet point two that also keeps going on the same single line no matter the length
```

WRONG — never wrap a paragraph or bullet across multiple lines:

```
type(scope): description

- Bullet point one that is wrapped onto
  a second continuation line, which is wrong
- Bullet point two that is also
  wrapped across multiple lines
```

For breaking changes, append `!` after the type and add `BREAKING CHANGE:` footer:

```
feat(api)!: redesign error response format

BREAKING CHANGE: Error responses now use `{error: {code, message}}` instead of flat `{code, message}`.
```

### Step 6: Stage the Doc Edits, Then Confirm With the User

Stage the files this skill just wrote — by name, only the ones Step 3 actually edited — so documentation written after Step 1 is included, and show the staged summary:

```bash
git add docs/CHANGELOG.md README.md   # the files Step 3 edited, at the paths that exist
git diff --cached --stat
```

Never `git add .` here: staging names the files this skill touched (`docs/CHANGELOG.md` or the root `CHANGELOG.md`, `docs/ARCHITECTURE.md` or the root `ARCHITECTURE.md`, `README.md`), and a file Step 3 did not edit is not staged "just in case". Targeted staging is what keeps unrelated or sensitive working-tree changes out of the commit.

Staging immediately before every commit in this skill is mandatory, not optional cleanup: `git add .` at Step 1 for the user's work, then this targeted staging here and before the release commit in Step 8.

**Then stop and ask the user before committing — this gate applies to every commit in this skill, including the release commit.** Present (1) the complete commit message, subject and body exactly as it will be committed, and (2) the staged file summary, then ask for confirmation, using an interactive question tool when one is available. Wait for explicit approval:

- Approved → continue to Step 7.
- Changes requested (message, scope, file selection) → apply them, present the revised message, and ask again.
- In release mode, confirm both planned messages and the tag at once (the work commit, then `chore(release): prepare v{version}` tagged `v{version}`).

Never commit on assumption, and never reuse an approval given for an earlier message after the message has changed.

### Step 7: Commit

Only after the user approved the message in Step 6:

```bash
git commit -m "type(scope): description

Body with additional context and a bullet list of key changes."
```

Or pipe the message in with a quoted heredoc, which survives quotes and apostrophes in the text:

```bash
git commit -F - <<'EOF'
type(scope): description

Body text here.
EOF
```

Co-authored-by trailer is added automatically by the tool; do not include it in the message.

### Step 8: Release Mode — `/commit v{version}`

**Trigger:** the user writes `/commit v{version}` (for example `/commit v0.3.0`), optionally with extra instructions. Accept the version with or without the `v` prefix and tag with `v` either way; when what follows the command is not a plausible version (`v2`, `v1.2.3.4`, free text), ask the user to state the exact version before doing anything. The version in the command is authoritative — it is the version to prepare, not a suggestion to re-derive.

Steps 1–7 still run first and land as their own normal commit; Step 8 then adds the release commit and the version tag on top. So one `/commit v{version}` invocation produces two commits and a tag: the work (with any `Unreleased` entries it warranted), then `chore(release): prepare v{version}` tagged `v{version}`. If Steps 1–7 find nothing to commit, say so and go straight to the release commit. Keep release mode opt-in: without the version-carrying command, stop at Step 7 and never bump a version, tag, or push on your own. The same targeted staging rule applies before this commit too — the release edits and the version bump are staged by name, never with `git add .`.

Release mode works from **commit history since the last tag**, not just from the staged diff: it additionally checks whether the documentation matches what the history actually changed.

1. **Find the last tag and the range.**

   ```bash
   git describe --tags --abbrev=0
   git log --oneline <tag>..HEAD
   ```

   With no tags yet, use the first commit and read the whole history: `git rev-list --max-parents=0 HEAD`.

2. **Inspect each commit's diff** — `git diff <commit>^..<commit> --stat`. Look for new features, API changes, removed functionality, configuration and dependency changes, and anything user-visible that has no changelog entry yet.

3. **Confirm the requested version fits the range.** The user picks the version; your job is a sanity check, not a re-derivation.

   | Commits since the last tag | Usual bump |
   |---|---|
   | any `feat!:` or `BREAKING CHANGE` | major (1.x.x → 2.0.0) |
   | any `feat:` | minor (x.1.0 → x.2.0) |
   | only `fix`/`chore`/`docs`/`test`/`style`/`refactor`/`perf` | patch (x.1.0 → x.1.1) |

   Before 1.0.0 the convention shifts one level down: a breaking change bumps minor (0.3.x → 0.4.0) and everything else bumps patch.

   If the requested version contradicts the range (a patch bump over new features, a major bump with no breaking change), flag the mismatch and ask before proceeding — do not silently "correct" it. If it matches, continue without discussion.

4. **Promote the changelog.** Every `Unreleased` entry counts, including any added moments earlier in Step 3 of this same invocation — a fresh entry from this run is part of the release, not something to drop. Rename the top `Unreleased` heading to the version and today's date in the file's existing version-heading format (for example `## [{version}] - YYYY-MM-DD`), start a fresh empty `## [Unreleased]` above it, and append the link reference at the bottom in the order the file already uses:

   ```markdown
   [{version}]: https://<host>/<owner>/<repo>/compare/v<prev>...v{version}
   ```

   Groups (`Added`/`Changed`/`Fixed`/`Removed`/`Security`) keep the entries they already have — move them, never rewrite or drop them. Add entries for user-visible changes the history shows but `Unreleased` does not — and only those. If the `Unreleased` section is missing or empty, there is nothing to release: tell the user instead of inventing a version.

5. **Bump the version** to `{version}` in the project's version file — `project.version` in `pyproject.toml` for a Python project, the `version` field in `package.json`, `Cargo.toml`, and so on — and update the project description there if the project scope changed. When the project uses uv, refresh the lockfile (`uv lock`) so `uv.lock` carries the new version too.

6. **README / AGENTS / ARCHITECTURE**: update commands, flags, configuration tables, project-structure trees, feature lists, and architecture sections that the range made stale. Prefer targeted edits over rewriting whole files, and never remove documentation unrelated to these commits.

7. **Stage the release edits, confirm, then commit the release** — `git add` the files this step touched, by name: the changelog, `README.md`, `ARCHITECTURE.md`, and the version file with its lockfile (`pyproject.toml` and `uv.lock` in a Python/uv project) — only the ones actually edited. Get the user's approval for the release message and tag per the Step 6 gate (unless it was already confirmed there), then `git commit -m "chore(release): prepare v{version}"` so the changelog promotion, version bump, and doc sync all land in it — then show the summary:

   ```
   ## Documentation Updated

   **Version:** 1.2.0 → 1.3.0 (minor — 3 new features)

   **Files modified:**
   - docs/CHANGELOG.md — added the v1.3.0 section
   - README.md — added the new CLI flag
   - pyproject.toml — bumped version to 1.3.0

   **Tag:** v1.3.0 (on the release commit, style matching the repository's existing tags)

   **Commits included (since v1.2.0):**
   - feat(cli): add export command
   - fix(db): handle connection timeout
   ```

8. **Tag the release** — right after the release commit lands, tag it, matching the tag style the repository already uses: `git for-each-ref refs/tags --format '%(objecttype)'` prints `tag` for annotated tags and `commit` for lightweight ones. Use an annotated tag when that is what the history shows, or when there are no prior tags to match:

   ```bash
   git tag -a "v{version}" -m "v{version}"   # annotated
   git tag "v{version}"                      # lightweight
   ```

   The changelog compare links point at `v{version}`, so they stay dead until the tag exists — tagging is part of the release, not an optional extra. Pushing the tag (`git push origin "v{version}"` — note that `--follow-tags` only pushes annotated tags, not lightweight ones), pushing the branch, or creating a GitHub release still needs an explicit request.

## Do NOT

- Commit before the user confirms the message — the Step 6 gate is mandatory for every commit, including the release commit; approval is not implied by the `/commit` invocation itself
- Commit without staging first — `git add .` at Step 1 for the user's work, then a targeted `git add` of the files this skill edited before each later commit, or documentation and version edits would be silently left behind
- Run `git add .` at Step 6 or Step 8 — later staging names the files this skill just wrote (changelog, architecture doc, README, `pyproject.toml`, `uv.lock`), never the whole tree, so unrelated or sensitive working-tree changes stay out of the commit
- Write the changelog or the architecture doc while making a change — Step 3 is where both are written, so the entries land in the commit they describe
- Edit `docs/CHANGELOG.md`, `docs/ARCHITECTURE.md`, or `README.md` when the staged diff requires none of them, and never create one of these files just to fill it in
- Open a new version section in the changelog, or duplicate an entry already under `Unreleased`
- Enter release mode, bump a version, or tag unless the user asked for it — pushing the tag or the branch, or creating a GitHub release, always needs its own explicit request
- Swap out the version the user typed in `/commit v{version}` for one you derived yourself — flag a mismatch and ask instead
- Remove or rewrite existing documentation not related to the new commits
- Wrap any commit-message paragraph or bullet point across multiple lines (HARD RULE — one line each, no length exception)
- Force-push or amend without explicit instruction
- Use `--no-verify` unless explicitly asked
- Commit sensitive files (`.env`, credentials, keys)
