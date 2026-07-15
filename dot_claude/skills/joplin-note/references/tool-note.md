# Tool Note Workflow

Use this workflow when the user wants to create a note documenting a specific tool (CLI, library, SaaS, desktop app, etc.).

---

## Workflow

### 1. Identify the tool name
Extract the tool name from the user's request (e.g. "ripgrep", "k9s", "Obsidian"). This becomes the folder name and is used in the note title.

### 2. Verify the "tooling" notebook exists
Call `mcp__joplin__list_folders` and find the folder named `tooling` (case-insensitive match).

**If "tooling" does not exist: STOP.** Tell the user:
> "I can't find a notebook named 'tooling' in Joplin. Please create it first, then ask me again."

Do not fall back to a different notebook.

### 3. Create a sub-folder for the tool
Call `mcp__joplin__create_folder` with:
- `title`: the tool name (e.g. `ripgrep`)
- `parent_id`: the ID of the "tooling" folder

### 4. Research the tool

**Try context7 first** — call `mcp__context7__resolve-library-id` with the tool name. If it resolves, use `mcp__context7__query-docs` to gather all of the following. If it doesn't resolve, fall back to web research.

Gather:
- **Official website** (if any)
- **GitHub repository** (if any)
- **One additional link** (docs, package registry) — only if clearly more useful than the above two
- **A 2–3 sentence description** of what the tool does
- **Cheat sheet material** — see step 7 for what to collect
- **Community sentiment** — what the community broadly thinks of the tool, its pros, its cons, and observable adoption trends

Cap links at 3. Do not add links you are not confident exist.

### 5. Ask the user "Why this tool?"
If the user has not already explained why they care about this tool, ask:
> "Why does this tool matter to you? (What problem does it solve for you, or what drew you to it?)"

Wait for the answer before creating the notes.

### 6. Create the README note
Call `mcp__joplin__create_note` with:
- `title`: `README_<tool-name>` (e.g. `README_ripgrep`)
- `parent_id`: the ID of the new tool sub-folder (step 3)
- `body`: the template below, filled in

```markdown
# Main tool links
[link 1]
[link 2]
[link 3 — omit if only 2 links found]

# In few words...
[2–3 sentences describing what the tool does]

# Why this tool?
[User's own words from step 5]

# Community sentiment
[What the community broadly thinks of the tool — 2–3 sentences]

# Pros
- [pro 1]
- [pro 2]

# Cons
- [con 1]
- [con 2]

# Future adoption (my take)
[Your honest assessment of where this tool is heading — adoption trajectory, competitive pressure, ecosystem momentum]
```

### 7. Create the cheat sheet note
Call `mcp__joplin__create_note` with:
- `title`: `cheat_sheet_<tool-name>` (e.g. `cheat_sheet_ripgrep`)
- `parent_id`: the ID of the new tool sub-folder (step 3)
- `body`: developer-oriented markdown with **real, researched content** — no invented commands or flags

Shape the content to the tool type:

**CLI / desktop app:**
```markdown
# Install
[install command(s) for common platforms]

# Common commands
[real commands with short descriptions]

# Key flags / options
[flags worth knowing, with what they do]

# Tips & gotchas
[non-obvious behaviour, common mistakes, useful patterns]
```

**Library / SDK:**
```markdown
# Install
[package manager install command]

# Import / setup
[minimal setup snippet]

# Common usage
[real API calls or patterns developers reach for most]

# Key options
[important parameters or config worth knowing]

# Tips & gotchas
[non-obvious behaviour, common mistakes, useful patterns]
```

Only include commands and APIs you are confident are real. When in doubt, omit rather than invent.

### 8. Apply tags
For **both notes**, pick 2–4 tags from the taxonomy (`references/taxonomy.md`). Always include `reference`. Add one domain tag that fits the tool (e.g. `development`, `infrastructure`, `ai`, `automation`). Apply them with `mcp__joplin__tag_note`. Add the LLM provenance tag to both (both are newly created notes).

### 9. Confirm to the user
Report: folder created, both note titles, tags applied.
