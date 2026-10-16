# PowerShell Style

## Applies to

`.ps1` scripts, `.psm1` modules, and `.psd1` manifests, including profile
scripts. Files that *embed* PowerShell (CI YAML blocks, `.csproj` build steps)
follow these rules for the PowerShell they contain.

## Source of truth

`.editorconfig`, `PSScriptAnalyzerSettings.psd1`, then this file.
PSScriptAnalyzer owns diagnostics: run it, fix the finding, or suppress it
narrowly with a reason.

The defaults below apply only where the project configures nothing.

## Formatting

- 4 spaces per indent level, never tabs. Line endings per the project's
  `.editorconfig` (LF when it says so, CRLF otherwise), one final newline, no
  trailing whitespace.
- Keep lines under 100 columns. Break a pipeline after the `|`, indenting the
  continuation; break a long parameter list one parameter per line once there
  are more than two parameters or any splatting.
- `[CmdletBinding()]` and `param()` come immediately after the comment-based
  help, and the opening brace of a construct stays on the statement's line:
  `if ($x) {`, with `}` on its own line.
- One statement per line; no `;` chaining except for a deliberate
  `if (...) { ... } else { ... }` alias-free one-liner in a pipeline.
- Binary operators at the end of the continued line, operands indented.
- Let the formatter or the editor config own whitespace; never align
  assignments into columns by hand.

## Naming

| Element | Style |
| --- | --- |
| function / cmdlet | `Verb-Noun`, approved verb, singular noun |
| parameter | `PascalCase` |
| script- or module-scope variable | `PascalCase` |
| loop / temporary local | `camelCase` |
| constant | `PascalCase` with `Set-Variable -Option ReadOnly` or `New-Variable` |
| class / enum | `PascalCase` |
| private helper | unexported, `_`-free; the module boundary is what makes it private |

- Only approved verbs (`Get-Verb`); inventing `Fetch-Item` breaks discovery and
  autocompletion.
- Singular nouns: `Get-Item`, never `Get-Items`.
- A function that changes state uses the matching verb (`Set-`, `New-`,
  `Remove-`), and a function that only reads never has a side effect.
- Private module functions are excluded from `FunctionsToExport` (or
  `Export-ModuleMember`) rather than named with a prefix.

## Structure and imports

- Script layout, in order: `using` statements, `#Requires` lines, comment-based
  help, `[CmdletBinding()]` + `param()`, strict mode and error preference,
  constants, functions, then the executable body.
- `using namespace` / `using module` come first — they must precede every other
  statement to take effect.
- `#Requires -Version 7.0` (or the pinned version) and
  `#Requires -Modules @{ ModuleName = "..."; ModuleVersion = "..." }` for hard
  dependencies, so a missing requirement fails with a clear message instead of
  an obscure one later.
- `Import-Module` only for what the session does not auto-load, and never with
  `-Force` in production code; a module import is a dependency declaration, not
  a reload button.
- Dot-sourcing (`. ./helper.ps1`) is for interactive helpers and tests, not a
  substitute for a module.
- One public function per file when the project ships a module folder layout;
  the manifest's `FunctionsToExport` is the contract and stays in step with the
  files.

## Types and annotations

- Type-constrain every parameter (`[string]`, `[int]`, `[hashtable]`,
  `[datetime]`) so the binder converts and rejects instead of the body
  discovering the type at run time.
- Validate through attributes, not body checks: `[ValidateNotNullOrEmpty()]`,
  `[ValidateSet('a','b')]`, `[ValidateRange(1, 10)]`,
  `[ValidatePattern('^[a-z]+$')]`.
- `[Parameter(Mandatory)]` for required input; `[Parameter(ValueFromPipeline)]`
  plus a `process` block for pipeline input.
- `[OutputType([string])]` (or the object type) on every public function, and
  `[CmdletBinding(SupportsShouldProcess)]` on anything destructive.
- Structured output is `[pscustomobject]@{ ... }`; use `[ordered]@{}` when the
  field order matters for display.
- `Set-StrictMode -Version Latest` in scripts and modules so an undefined
  variable or a missing property is an error instead of `$null`.
- Avoid `[ref]` and `[object]` parameters; use a `class` or a typed
  `[pscustomobject]` when several values belong together.

## Comments and documentation

- Every public function carries comment-based help: `.SYNOPSIS` (one imperative
  line), `.DESCRIPTION`, `.PARAMETER <name>` for each parameter, `.INPUTS`,
  `.OUTPUTS`, `.EXAMPLE` (a runnable command), and `.NOTES` where a caveat
  belongs.
- Keep `.PARAMETER` blocks in the same order as the parameters themselves.
- Scripts document the required version, required modules, environment
  variables read, and exit codes in a header block.
- Plain comments explain why, above the code; a comment restating the cmdlet
  below is noise.
- Task tags `TODO(name):`, `NOTE:`, `FIXME:`; a `TODO` names an owner.
- No commented-out code.
- State the elevation requirement (or its absence) explicitly when a script
  touches machine-wide state.

## Error handling

- `$ErrorActionPreference = 'Stop'` at the top of scripts and modules; add
  `-ErrorAction Stop` for a cmdlet whose failure must abort the pipeline even
  when the preference is overridden.
- `try { } catch { }` around what can throw, and never an empty `catch`: either
  rethrow (`throw`), add context and rethrow (`throw "Import failed: $_"`), or
  handle it and record it.
- Prefer terminating errors (`throw`) in scripts and modules, so a caller's
  `try`/`catch` works; use `Write-Error` when the caller should decide whether
  to continue.
- `-ErrorAction SilentlyContinue` and `-ErrorVariable` only with a stated
  reason and an immediate check of the collected errors.
- Destructive operations implement `-WhatIf` and `-Confirm`: declare
  `[CmdletBinding(SupportsShouldProcess)]` and gate the action behind
  `if ($PSCmdlet.ShouldProcess($target, 'Remove')) { ... }`.
- Scripts return meaningful exit codes (`exit 1`, `exit 2`) and document them;
  a script that only writes to the error stream gives the caller nothing to
  branch on.
- Clean up in `finally` (or the `clean` block of an advanced function) so a
  failure does not leave a temp file, a lock, or a modified preference behind.

## Idioms and anti-patterns

Prefer:

- Full cmdlet and parameter names in scripts (`Where-Object`, `Get-ChildItem
  -Path`); aliases (`?`, `%`, `gci`) are for the interactive prompt, not for
  saved code.
- `-LiteralPath` when the path comes from data — `[` and `]` in a name are
  wildcard characters to `-Path`.
- `-File`, `-Directory`, `-Filter` on `Get-ChildItem`; `-Filter` is applied by
  the provider and is much faster than filtering afterwards.
- Objects down the pipeline, with formatting left to the end: output
  `[pscustomobject]`s or typed objects, and let the caller `Format-Table`.
- `Write-Output` (or a bare expression) for data and `Write-Verbose` /
  `Write-Information` for progress; `Write-Host` only for genuine UI.
- Splatting for long or conditional argument lists:
  `$params = @{ Path = $p; Recurse = $true }; Get-ChildItem @params`.
- Single-quoted strings for literals and double quotes only for interpolation;
  here-strings (`@' ... '@`, `@" ... "@`) for multi-line text, with the closing
  delimiter at column zero.
- `$null -eq $x` (constant on the left), so an array on the right is not
  filtered by comparison.
- `Join-Path`, `Split-Path`, and `[System.IO.Path]::Combine` for paths;
  `Test-Path -PathType Leaf` before reading a file.
- `Get-CimInstance` over the deprecated `Get-WmiObject`.

Avoid:

- `Invoke-Expression` and commands assembled from strings.
- `$args` parsing by hand; declare `param()` and let the binder do it.
- `Format-*` and `Out-String` inside a script: they consume the objects and
  break the pipeline for every downstream consumer.
- `Add-Content` / `Set-Content` without `-Encoding` when the file's encoding
  matters (`utf8NoBOM` explicitly).
- Catching everything with an empty `catch`, or setting
  `$ErrorActionPreference = 'SilentlyContinue'` globally.
- Functions with `Write-Host` output and no return value used as if they were
  pure.
- Comparing dates and numbers as strings; convert first.
- `Start-Sleep` as synchronization; wait for the actual condition.
- Writing to `$PROFILE` or another user-scope path from a script without saying
  so and confirming.

## Tests

- Pester 5, `*.Tests.ps1` files next to the module or under `tests/`;
  `Describe` / `Context` / `It` names state the behavior and the expected
  result.
- `BeforeAll` for setup, `Mock` for external calls, and never a test that hits
  the network, the registry, or the user's real profile directory — redirect
  to a temporary directory created by the test.
- Assert on objects (`Should -Be`, `Should -HaveCount`, `Should -Throw`), not
  on formatted text, and assert the exit code separately from the output when
  testing a script.
- Test the failure path, not just the happy one: a mandatory parameter missing,
  a file absent, a cmdlet that throws.
- `Invoke-Pester -Output Detailed` while iterating; the full run before
  declaring work done.

## Tooling

- `Invoke-ScriptAnalyzer -Path . -Recurse` with the project's settings file;
  fix findings, or suppress a single rule with
  `[Diagnostics.CodeAnalysis.SuppressMessageAttribute()]` and a reason.
- `pwsh -NoProfile -File script.ps1` proves the script parses, binds, and
  starts; `Set-PSDebug -Trace 1` or `-Verbose` while debugging.
- Target PowerShell 7+ unless the project pins Windows PowerShell 5.1 — the two
  differ on `&&` and `||`, the ternary and null-coalescing operators,
  `-Encoding` defaults, and `Get-CimInstance` availability; never use 7-only
  syntax in a 5.1-targeted script.
- Cross-platform scripts avoid Windows-only cmdlets, backslash-separated path
  literals, and case-insensitive path assumptions.

## Examples

Follows the rules — declared contract, validation by attribute, help that
answers a caller's question, and output as data:

```powershell
function Get-ProfilePath {
    <#
    .SYNOPSIS
    Resolve a profile file path for the current host.

    .PARAMETER Name
    Profile file name, for example Microsoft.PowerShell_profile.ps1.

    .OUTPUTS
    System.String

    .EXAMPLE
    Get-ProfilePath -Name Microsoft.PowerShell_profile.ps1
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $directory = Split-Path -Parent $PROFILE.CurrentUserAllHosts
    return Join-Path -Path $directory -ChildPath $Name
}
```

Breaks the rules — unapproved verb, no contract, an alias, a suppressed error,
and UI output where data was promised:

```powershell
function getpath($n) {
  $p = "$env:USERPROFILE\Documents\$n"
  Get-ChildItem $p -ErrorAction SilentlyContinue | ? { $_.Name }
  Write-Host "path: $p"
}
```

Why it is wrong: `getpath` is not a `Verb-Noun` name; `$n` has no type or
validation, so a typo surfaces deep inside; `-Path` treats the value as a
wildcard pattern; the alias `?` is unreadable in saved code;
`-ErrorAction SilentlyContinue` hides a missing directory; `Write-Host` writes
text that no caller can use, and the function returns nothing at all.
