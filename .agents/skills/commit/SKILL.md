---
name: commit
description: Commit the working tree as one or more atomic commits, with the changelog and architecture entries each commit requires — the whole workflow runs in a single subagent, steered by the user's stated intent and commit count. Use when the user asks to commit changes, stage and commit, create a commit, update or sync docs alongside a commit, or prepare a release; release mode (/commit v{version}) promotes the changelog, bumps the version, and tags the release
---

# Commit Changes

Two modes:

- **Commit mode (the default)** — one subagent inspects the working tree, splits the changes into atomic commits, and then per commit writes the `docs/CHANGELOG.md` and `docs/ARCHITECTURE.md` entries it requires (plus `README.md` when it has gone stale), stages and commits. Nearly every invocation stops here.
- **Release mode (opt-in)** — triggered by `/commit v{version}`, where the user supplies the version: after the work commits, promote the accumulated `Unreleased` entries to that version, bump the version file (`pyproject.toml` in a Python project), commit the release, and tag it. The release pass runs inside the same subagent.

If the message is `/commit v{version}`, the invocation yields the work commits, then `chore(release): prepare v{version}` tagged `v{version}`. A bare `/commit` (no version) is commit mode. Anything else ("commit this", "update the docs") is commit mode as well.

## Roles

**The main agent orchestrates and never touches the repository.** It:

1. Parses the invocation for the user's **intent** and the requested **commit count** (see below).
2. Spawns **one subagent** with the working directory, the user's intent verbatim, the commit count when given, and this workflow.
3. Reports the subagent's result — the commits created, their messages and file summaries — to the user.

The main agent never inspects diffs to plan commits, never edits files, never stages and never commits. Everything after the spawn happens inside the subagent.

**The subagent runs the whole workflow** (Steps 1–3, plus Step 4 for a release): inspect, plan, then per commit write docs, stage, message and commit. It works autonomously — it does not stop to ask the user — and escalates back only in the one case described under Step 2.

## User Intent and Commit Count

The user decides both **before** invoking: what the commits should say and how many atomic commits to create. A `/commit` invocation may therefore carry an intent (`commit this`, `/commit only the shell files`, `/commit split the nvim changes from the docs`) and a count (`/commit as 2 commits`).

- Stated intent and count are **authoritative**: the subagent shapes the split, the file selection and the messages around them.
- When the invocation carries **neither**, the subagent decides the split and the messages on its own, from the changes themselves.
- The main agent passes the intent to the subagent verbatim; it does not interpret, extend or trim it.

## The Subagent's Workflow

### Step 1: Inspect the Working Tree

Look at everything that could be committed — the staging area, the unstaged changes and the untracked files — and read the actual changes, not a summary:

```bash
git status --porcelain
git diff --cached
git diff
```

Untracked files that belong to the change are read with the file tools. A `--stat` view may accompany the diffs for orientation, but it never replaces them: the commit plan is built from the concrete changes, line by line.

Pay attention to:
- **Scope**: which modules/packages are affected
- **Nature**: new feature, bug fix, refactor, docs, test, style, etc.
- **Impact**: breaking change, deprecation, new API, internal-only
- **Boundaries**: which changes belong together and which are independent

If there is nothing to commit — no staged, unstaged or untracked change — report that and stop.

### Step 2: Plan the Atomic Commits

Group the changes into **atomic commits**: one logical change per commit, sized so that reverting it neither breaks the tree nor takes unrelated work with it. There may be exactly one. When the user stated a count, the plan has exactly that many commits; when the user stated an intent, the split and the file selection follow it.

**Escalation — the only interruption.** The subagent decides everything itself except when the stated count or intent is irreconcilable with the actual changes — the user asked for three commits but the tree holds one small fix, or the intent describes changes the diff does not contain. In that case the subagent does not guess: it returns the conflict (what was asked versus what the tree shows) to the main agent, which asks the user and spawns the subagent again with the answer. Ordinary judgment calls — how to group, which type, what the body says — never escalate.

### Step 3: Commit Each Part — Docs, Staging, Message, Commit

Work through the planned commits in plan order. For each one: **write the docs this commit requires, `git add` its files by name, write the message, `git commit` — then loop to the next.** The docs are written immediately before their own commit, so they land in the commit they describe and never leak into an earlier one.

#### 3.1 Write the docs this commit requires

`docs/CHANGELOG.md`, `docs/ARCHITECTURE.md`, and `README.md` are **not** touched on every commit. Decide from this commit's diff (from Step 1) whether the change is user-visible or structural: when it is neither, the correct action is to change none of these files and go straight to staging.

| Change in the commit | CHANGELOG | ARCHITECTURE | README |
|---|---|---|---|
| New feature, new CLI flag, new public API | entry under `Added` | if it adds a module, subsystem, or entry point | if the documented surface changed |
| Fix, behavior change, deprecation, removal | entry under `Fixed` / `Changed` / `Removed` | no | if the documented surface changed |
| Installation, supported Python, dependencies, quickstart, examples | entry under `Changed` | no | keep it accurate |
| Repository layout, startup/entry flow, plugin or module set, setup scripts | entry under `Changed` when user-visible | targeted edit to the section that went stale | if the documented surface changed |
| Internal refactor with identical behavior | no | no | no |
| Type annotations, formatting, lint, CI, tooling config | no | no | no |
| Tests only | no | no | no |
| Docs only | no — a changelog entry about documentation is noise | only for the structure being documented | only if the README itself is wrong |

**CHANGELOG** — a file at `docs/CHANGELOG.md`, else the root `CHANGELOG.md`. If it exists, append to the entries already under the top `Unreleased` heading, under the `Added` / `Changed` / `Fixed` / `Removed` / `Security` heading that fits, in the file's existing style. **The changelog is append-only: entries are added and never deleted, rewritten or moved** — an existing entry that looks unsupported by the diff is left in place and mentioned in the report; removal is the user's call, never this skill's. Never start a new version section and never duplicate an entry for a change already listed there. An entry describes the state a reader will get, not the order the work happened in: when the diff reworks something that is itself still only an `Unreleased` addition, extend that `Added` entry instead of filing a `Changed` one for a state no release ever had.

**README** — update only when the change makes a documented statement inaccurate: the described commands/flags, install steps, feature list, project structure, or example paths. A new internal module or a refactor is not a README change.

**ARCHITECTURE** — a file at `docs/ARCHITECTURE.md`, else the root `ARCHITECTURE.md`; a repository that keeps none skips it. Update only the sections the commit made stale — repository layout, startup or entry flow, the plugin/module set, the setup scripts, or how a subsystem is wired — as a targeted edit, never a rewrite. It records structure and design decisions, so a behavior fix that leaves the structure alone needs no edit.

When in doubt between an entry and no entry, the entry is the safer choice — but never invent a user-facing change that the diff does not contain.

#### 3.2 Stage by name

Stage exactly this commit's files — the changes from the working tree plus the doc edits 3.1 just wrote — naming every path:

```bash
git add path/to/file another/file a/directory/
git diff --cached --stat
```

`git add .`, `git add -A` and `git add -u` are forbidden: staging names the files and directories, so unrelated or sensitive working-tree changes stay out of the commit. A file the plan did not assign to this commit is not staged "just in case".

#### 3.3 Write the message

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

#### 3.4 Commit

```bash
git commit -F - <<'EOF'
type(scope): description

Body text here.
EOF
```

The quoted heredoc survives quotes and apostrophes in the text. Co-authored-by trailer is added automatically by the tool; do not include it in the message.

### Step 4: Release Mode — `/commit v{version}`

**Trigger:** the user writes `/commit v{version}` (for example `/commit v0.3.0`), optionally with extra instructions. Accept the version with or without the `v` prefix and tag with `v` either way; when what follows the command is not a plausible version (`v2`, `v1.2.3.4`, free text), the subagent returns to the main agent, which asks the user to state the exact version. The version in the command is authoritative — it is the version to prepare, not a suggestion to re-derive.

Steps 1–3 still run first and land as their own normal commits; Step 4 then adds the release commit and the version tag on top, all inside the same subagent. If Steps 1–3 find nothing to commit, say so and go straight to the release commit. Keep release mode opt-in: without the version-carrying command, stop at Step 3 and never bump a version, tag, or push on your own. The same rules apply to the release commit: staging names the files.

Release mode works from **commit history since the last tag**, not just from the current working tree: it additionally checks whether the documentation matches what the history actually changed.

1. **Find the last tag and the range.**

   ```bash
   git describe --tags --abbrev=0
   git log --oneline <tag>..HEAD
   ```

   With no tags yet, use the first commit and read the whole history: `git rev-list --max-parents=0 HEAD`.

2. **Inspect each commit's diff** — `git diff <commit>^..<commit> --stat`. Look for new features, API changes, removed functionality, configuration and dependency changes, and anything user-visible that has no changelog entry yet.

3. **Confirm the requested version fits the range.** The user picks the version; the subagent's job is a sanity check, not a re-derivation.

   | Commits since the last tag | Usual bump |
   |---|---|
   | any `feat!:` or `BREAKING CHANGE` | major (1.x.x → 2.0.0) |
   | any `feat:` | minor (x.1.0 → x.2.0) |
   | only `fix`/`chore`/`docs`/`test`/`style`/`refactor`/`perf` | patch (x.1.0 → x.1.1) |

   Before 1.0.0 the convention shifts one level down: a breaking change bumps minor (0.3.x → 0.4.0) and everything else bumps patch.

   If the requested version contradicts the range (a patch bump over new features, a major bump with no breaking change), the subagent flags the mismatch and returns to the main agent, which asks the user before proceeding — do not silently "correct" it. If it matches, continue without discussion.

4. **Promote the changelog.** Every `Unreleased` entry counts, including any added moments earlier in Step 3 of this same invocation — a fresh entry from this run is part of the release, not something to drop. Rename the top `Unreleased` heading to the version and today's date in the file's existing version-heading format (for example `## [{version}] - YYYY-MM-DD`), start a fresh empty `## [Unreleased]` above it, and append the link reference at the bottom in the order the file already uses:

   ```markdown
   [{version}]: https://<host>/<owner>/<repo>/compare/v<prev>...v{version}
   ```

   Groups (`Added`/`Changed`/`Fixed`/`Removed`/`Security`) keep the entries they already have — move them, never rewrite or drop them. Add entries for user-visible changes the history shows but `Unreleased` does not — and only those. If the `Unreleased` section is missing or empty, there is nothing to release: say so instead of inventing a version.

5. **Bump the version** to `{version}` in the project's version file — `project.version` in `pyproject.toml` for a Python project, the `version` field in `package.json`, `Cargo.toml`, and so on — and update the project description there if the project scope changed. When the project uses uv, refresh the lockfile (`uv lock`) so `uv.lock` carries the new version too.

6. **README / AGENTS / ARCHITECTURE**: update commands, flags, configuration tables, project-structure trees, feature lists, and architecture sections that the range made stale. Prefer targeted edits over rewriting whole files, and never remove documentation unrelated to these commits.

7. **Stage the release edits, then commit the release** — `git add` the files this step touched, by name: the changelog, `README.md`, `ARCHITECTURE.md`, and the version file with its lockfile (`pyproject.toml` and `uv.lock` in a Python/uv project) — only the ones actually edited. Commit with `chore(release): prepare v{version}` so the changelog promotion, version bump, and doc sync all land in it.

8. **Tag the release** — right after the release commit lands, tag it, matching the tag style the repository already uses: `git for-each-ref refs/tags --format '%(objecttype)'` prints `tag` for annotated tags and `commit` for lightweight ones. Use an annotated tag when that is what the history shows, or when there are no prior tags to match:

   ```bash
   git tag -a "v{version}" -m "v{version}"   # annotated
   git tag "v{version}"                      # lightweight
   ```

   The changelog compare links point at `v{version}`, so they stay dead until the tag exists — tagging is part of the release, not an optional extra. Pushing the tag (`git push origin "v{version}"` — note that `--follow-tags` only pushes annotated tags, not lightweight ones), pushing the branch, or creating a GitHub release still needs an explicit request.

## The Subagent's Report

The subagent ends with the result the main agent relays to the user:

```
## Commits Created

- e462076 feat: point the vim shortcut at a plugin-free nvim (4 files, +13/-3)
- 68823d9 docs: sync readme and architecture with the current configuration (2 files, +83/-46)

**Left in the working tree:** nothing / <paths and why>
**Flagged:** <existing changelog entries that look unsupported, intent the diff did not cover, etc.>
```

## Do NOT

- Run any part of the workflow in the main agent — it only parses the intent, spawns the subagent and relays the report; it never edits, stages or commits
- Escalate ordinary judgment calls to the user — the subagent decides the split, the types and the messages itself; only an irreconcilable conflict between the stated intent/count and the actual changes goes back
- Run `git add .`, `git add -A` or `git add -u` — every `git add` names the files or directories to stage, so unrelated or sensitive working-tree changes stay out of the commit
- Delete, rewrite or move existing changelog entries — `docs/CHANGELOG.md` is append-only for this skill; flag a suspicious entry in the report and leave it in place
- Write the changelog or the architecture doc while making a change — they are written in Step 3, immediately before the commit they describe
- Edit `docs/CHANGELOG.md`, `docs/ARCHITECTURE.md`, or `README.md` when the commit requires none of them, and never create one of these files just to fill it in
- Open a new version section in the changelog, or duplicate an entry already under `Unreleased`
- Enter release mode, bump a version, or tag unless the user asked for it — pushing the tag or the branch, or creating a GitHub release, always needs its own explicit request
- Swap out the version the user typed in `/commit v{version}` for one you derived yourself — flag a mismatch and escalate instead
- Remove or rewrite existing documentation not related to the new commits
- Wrap any commit-message paragraph or bullet point across multiple lines (HARD RULE — one line each, no length exception)
- Force-push or amend without explicit instruction
- Use `--no-verify` unless explicitly asked
- Commit sensitive files (`.env`, credentials, keys)
