# chezmoi Patterns & Naming Conventions

---

## Source directory naming conventions

The source directory lives at `~/.local/share/chezmoi/`. chezmoi encodes file metadata
in the filename using prefixes and suffixes — it never stores actual dotfile names with
leading dots or special permissions directly.

| Source name | Target name / effect |
|---|---|
| `dot_bashrc` | `~/.bashrc` |
| `dot_config/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `dot_bashrc.tmpl` | `~/.bashrc` (rendered as template) |
| `private_dot_netrc` | `~/.netrc` with mode `0600` |
| `executable_dot_script.sh` | `~/.script.sh` with mode `0755` |
| `symlink_dot_vim` | `~/.vim` as a symlink |
| `empty_dot_hushlogin` | `~/.hushlogin` as an empty file |

Prefixes can be combined: `private_executable_dot_script.sh` → `~/.script.sh`, mode `0700`.

Subdirectories follow the same rules: `dot_config/` → `~/.config/`.

---

## When to use a template

**Use a plain file when** the content is identical across all machines and accounts.

**Use a template when** any of the following are true:
- Content differs between Linux and macOS (paths, package managers, syscalls)
- Content differs between work and personal machines (email, proxy, VPN)
- Content references a hostname-specific value
- Content references a variable you'll want to override per machine via `~/.chezmoidata.json`

**Do not over-template.** A file that is currently the same everywhere should start as a
plain file. You can always promote it later with `chezmoi chattr +template ~/.file`.

---

## When to use `.chezmoitemplates/`

Extract a block to `.chezmoitemplates/` when:
- The **same block** would appear in two or more dotfiles (e.g., aliases in `.bashrc` and `.zshrc`)
- A block is long enough that duplicating it would make maintenance painful
- A parameterized fragment (font, theme, color scheme) is reused with different values

Do **not** create a sub-template for a block that only appears in one file. Inline it.

---

## Pattern: OS-specific config blocks

The most common pattern. Wrap OS-specific sections inside a conditional:

`dot_zshrc.tmpl`:
```
# common config
export EDITOR=nvim

{{ if eq .chezmoi.os "darwin" }}
export BROWSER=open
eval "$(/opt/homebrew/bin/brew shellenv)"
{{ else if eq .chezmoi.os "linux" }}
export BROWSER=xdg-open
{{ end }}
```

---

## Pattern: Machine role via `~/.chezmoidata.json`

Define a `work` boolean (or similar role key) and branch on it:

`~/.chezmoidata.json`:
```json
{
  "work": true,
  "email": "ismael@company.com"
}
```

`dot_gitconfig.tmpl`:
```
[user]
    name = Ismael
    email = {{ .email }}
{{ if .work }}
[http]
    proxy = http://proxy.corp:3128
{{ end }}
```

On a personal machine, set `"work": false` and `"email": "ismael@personal.com"`.

---

## Pattern: Shared aliases via `.chezmoitemplates/`

`.chezmoitemplates/shell_aliases.tmpl`:
```
alias ll='ls -lah'
alias ..='cd ..'
alias gs='git status'
alias gd='git diff'
{{ if eq .chezmoi.os "linux" }}
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
{{ end }}
```

`dot_bashrc.tmpl`:
```
# Aliases
{{ template "shell_aliases.tmpl" . }}
```

`dot_zshrc.tmpl`:
```
# Aliases
{{ template "shell_aliases.tmpl" . }}
```

---

## Pattern: `.chezmoiignore` for machine-specific files

Some files should only exist on certain machines. Use `.chezmoiignore` with a template:

`.chezmoiignore`:
```
# Ignore work-only configs on personal machines
{{ if not .work }}
dot_config/work-tool
{{ end }}
```

---

## Pattern: Checking the source state before editing

Before modifying any managed file, orient yourself:

```bash
chezmoi managed                           # full list of managed targets
chezmoi status                            # pending changes
chezmoi cat ~/.file                       # what chezmoi would write right now
chezmoi diff                              # diff between source state and ~/
chezmoi cd                                # open a shell in the source directory
```

The source directory layout:

```
~/.local/share/chezmoi/
├── .chezmoitemplates/
│   └── shell_aliases.tmpl
├── dot_bashrc.tmpl
├── dot_zshrc.tmpl
├── dot_gitconfig.tmpl
└── dot_config/
    └── nvim/
        └── init.lua
```
