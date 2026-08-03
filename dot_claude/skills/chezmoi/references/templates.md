# chezmoi Templating Reference

chezmoi uses Go's `text/template` syntax, extended with [sprig](http://masterminds.github.io/sprig/) functions.
Template files have a `.tmpl` suffix in the source directory.

---

## Syntax basics

Template actions are wrapped in `{{ }}`. Everything outside them is literal text.

```
# My editor config
export EDITOR={{ .chezmoi.os | quote }}
```

### Whitespace trimming

Use `{{-` and `-}}` to eat whitespace/newlines on either side of an action:

```
HOSTNAME={{- .chezmoi.hostname }}
# renders as: HOSTNAME=mymachine  (no leading space)
```

---

## Conditionals

```
{{ if eq .chezmoi.os "linux" }}
# Linux-only config
{{ else if eq .chezmoi.os "darwin" }}
# macOS-only config
{{ else }}
# Everything else
{{ end }}
```

Compound conditions:

```
{{ if (and (eq .chezmoi.os "linux") (ne .chezmoi.hostname "work-laptop")) }}
# Linux, but not on work-laptop
{{ end }}
```

Operators: `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `not`, `and`, `or`

---

## Variables from `chezmoi data`

Run `chezmoi data` to see the full JSON of available variables. Key built-ins:

| Variable | Example value |
|---|---|
| `.chezmoi.os` | `linux`, `darwin`, `windows` |
| `.chezmoi.arch` | `amd64`, `arm64` |
| `.chezmoi.hostname` | `my-laptop` |
| `.chezmoi.username` | `ismael` |
| `.chezmoi.homeDir` | `/home/ismael` |
| `.chezmoi.kernel.osrelease` | `6.1.0-arch1` (Linux only) |

### Custom variables

A data file placed in `~/` is **silently ignored** by chezmoi. There are two valid
locations, and the choice depends on whether the value is the same on every machine.

#### Same value everywhere → `.chezmoidata.toml` in the source directory

```toml
# File: $(chezmoi source-path)/.chezmoidata.toml   ← leading dot required
editor = "nvim"
```

This file is committed to the repo, so every machine sees the same value.

#### Value differs per machine → `.chezmoi.toml.tmpl` in the source directory

This template generates each machine's local `~/.config/chezmoi/chezmoi.toml`, which is
**not** committed. `promptStringOnce` asks the question on first `chezmoi init` and never
asks again:

```gotemplate
{{- $machineProfile := promptStringOnce . "machine_profile" "Machine profile (e.g. personal, gcp-workstation)" "personal" -}}
[data]
  machine_profile = {{ $machineProfile | quote }}
```

Set a profile non-interactively:

```bash
chezmoi init --promptString machine_profile=gcp-workstation
```

#### Access in templates

Both locations expose the value at the top level of the data context:

```
git config --global user.email {{ .email | quote }}
{{ if eq .machine_profile "personal" }}
# personal-machine-only section
{{ end }}
```

Before adding a custom variable, run `chezmoi data` — a built-in like
`.chezmoi.osRelease.id` often already carries the distinction you need.

---

## Testing templates

```bash
# Preview the rendered output of a managed file (plain or template)
chezmoi cat ~/.file

# Test an inline expression
chezmoi execute-template '{{ .chezmoi.os }}'

# Pipe a template file to execute-template
chezmoi execute-template < ~/.local/share/chezmoi/dot_file.tmpl
```

---

## `.chezmoitemplates/` — Reusable fragments

Files in `~/.local/share/chezmoi/.chezmoitemplates/` are parsed as named templates.
They are not rendered to the home directory themselves — they exist only to be included.

### Defining a fragment

`.local/share/chezmoi/.chezmoitemplates/common_aliases.tmpl`:

```
alias ll='ls -lah'
alias gs='git status'
{{ if eq .chezmoi.os "linux" }}
alias open='xdg-open'
{{ end }}
```

### Including a fragment in a dotfile

`dot_bashrc.tmpl` and `dot_zshrc.tmpl` can both include it:

```
# --- common aliases ---
{{ template "common_aliases.tmpl" . }}
# --- end common aliases ---
```

The trailing `. ` passes the current data context so the fragment can access `.chezmoi.*`
and your custom variables. Without it, the fragment sees no data.

### Passing explicit arguments

For parameterized fragments (e.g., font size that differs per profile):

`.chezmoitemplates/alacritty_font.tmpl`:
```
font:
  size: {{ .size }}
  family: {{ .family }}
```

Calling with a dict:

```
{{ template "alacritty_font.tmpl" (dict "size" 14 "family" "JetBrains Mono") }}
```

---

## Common sprig functions

| Function | Example |
|---|---|
| `quote` | `{{ .email \| quote }}` → `"me@host.org"` |
| `upper` / `lower` | `{{ .chezmoi.hostname \| upper }}` |
| `contains` | `{{ if contains "work" .chezmoi.hostname }}` |
| `hasPrefix` | `{{ if hasPrefix "ws-" .chezmoi.hostname }}` |
| `default` | `{{ .editor \| default "vim" }}` |
| `ternary` | `{{ ternary "nvim" "vim" .work }}` |
| `trimSpace` | `{{ .someValue \| trimSpace }}` |

Full sprig reference: http://masterminds.github.io/sprig/
