---
name: chezmoi
description: >
  Use whenever Ismael mentions creating, editing, or managing a dotfile or configuration
  file — including shell configs (.bashrc, .zshrc, .profile), editor configs (.vimrc,
  init.lua), git config (.gitconfig), and any file in ~/ that configures a tool.
  Also triggers on phrases like "update my dotfiles", "add this to chezmoi", "manage
  this config", "edit my shell config", or any request that would otherwise result in
  directly editing a file under ~/. Do not wait for the word "chezmoi" — if the file
  is a dotfile or home-directory config, this skill applies.
---

# chezmoi Dotfile Orchestration

The home directory (`~/`) is rendered output, not an editing surface.
**Never modify dotfiles directly in `~/`** — always go through chezmoi's source directory.

## Step 0: Is the file already managed?

```bash
chezmoi managed            # list all managed files
chezmoi status ~/.file     # A = added, M = modified, D = deleted (from chezmoi's view)
```

If the file isn't managed yet, start with `chezmoi add`. If it is, use `chezmoi edit`.

---

## Entry point A — New dotfile (not yet managed)

```bash
# Plain file — same content on every machine
chezmoi add ~/.file

# Template — content varies by machine, OS, or user
chezmoi add --template ~/.file
```

Unsure which to pick? See the **Decision: plain vs template** section below, or ask Ismael with AskUserQuestion.

---

## Entry point B — Existing managed dotfile

```bash
chezmoi edit ~/.file              # opens source file in $EDITOR
chezmoi edit --apply ~/.file      # edit and apply to ~/ immediately
```

**Do not** `vim ~/.file && chezmoi add ~/.file` — editing in `~/` then re-adding risks
overwriting chezmoi's source with stale content and loses template attributes.

---

## Decision: plain file vs template vs sub-template

| When the file… | Use |
|---|---|
| Is identical on every machine | Plain file |
| Varies by OS, hostname, or user-specific data | Template (`.tmpl` suffix) |
| Contains a block shared across several dotfiles | Sub-template in `.chezmoitemplates/` |

**When unsure, use AskUserQuestion**: "Does this file need to differ between your machines or OSes?"

### Promoting a plain file to a template

```bash
chezmoi chattr +template ~/.file
```

This renames the source file from `dot_file` → `dot_file.tmpl` and enables template rendering.

### Sub-templates (shared fragments)

If the same block of config (e.g., common shell aliases) appears in both `.bashrc` and `.zshrc`,
extract it to `.chezmoitemplates/` and include it from both files.

See `references/templates.md` for full syntax and `references/patterns.md` for sub-template
patterns and source directory naming conventions.

---

## Validate before applying

```bash
chezmoi cat ~/.file                          # print the target content of any managed file
chezmoi diff                                 # preview what apply would change
chezmoi execute-template '{{ .chezmoi.os }}' # test an inline template fragment
```

`chezmoi cat` shows what chezmoi would write to `~/` for any managed file — plain or
template. Use it after every edit to confirm the output is what you expect.

---

## Commit the change

After validating, commit the modified source file(s) to the chezmoi git repo.
Use `chezmoi git` — it proxies git commands directly into the source directory
without requiring a `cd`.

```bash
# See what changed in the source directory
chezmoi git status

# Stage the specific file(s) — use the source-directory name, not the home path
chezmoi git add -- dot_file           # plain file
chezmoi git add -- dot_file.tmpl      # template
chezmoi git add -- .chezmoitemplates/fragment.tmpl   # sub-template

# Commit with a meaningful message
chezmoi git commit -- -m "feat: add .file"
chezmoi git commit -- -m "feat: manage .gitconfig as template"
chezmoi git commit -- -m "refactor: extract shared aliases to .chezmoitemplates"
```

The source filename uses chezmoi's encoding (`dot_` prefix, `.tmpl` suffix, etc.).
If you're unsure of the exact source name, run `chezmoi source-path ~/.file` first.

Pushing to the remote is not part of this skill's scope — that's handled separately.

---

## Template data quick reference

```bash
chezmoi data    # shows every variable available in templates (JSON)
```

| Variable | Meaning |
|---|---|
| `.chezmoi.os` | `linux`, `darwin`, `windows` |
| `.chezmoi.hostname` | short hostname |
| `.chezmoi.username` | current user |
| `.chezmoi.homeDir` | home directory path |

Custom variables live in `~/.chezmoidata.json` (or `.toml` / `.yaml`).
They're deterministic — you define them, and templates depend on them.

---

## When to ask Ismael (use AskUserQuestion)

- Whether the file needs to vary by machine/OS → determines plain vs template
- Whether a repeated config block belongs in `.chezmoitemplates/` → reduces duplication
- Whether to add new keys to `~/.chezmoidata.json` vs inline values in the template
- If `chezmoi managed` shows an unexpected state for the target file

---

## Reference files

| File | Contents |
|---|---|
| `references/templates.md` | Go template syntax, conditionals, loops, sprig functions, `.chezmoitemplates/` usage |
| `references/patterns.md` | Source directory naming conventions, common patterns, examples |
