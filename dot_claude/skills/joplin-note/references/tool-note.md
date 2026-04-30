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
Before writing the note, gather:
- **Official website** (if any)
- **GitHub repository** (if any)
- **One additional link** (docs, package registry) — only if clearly more useful than the above two
- **A 2–3 sentence description** of what the tool does

Cap links at 3. Do not add links you are not confident exist.

### 5. Ask the user "Why this tool?"
If the user has not already explained why they care about this tool, ask:
> "Why does this tool matter to you? (What problem does it solve for you, or what drew you to it?)"

Wait for the answer before creating the note.

### 6. Create the note
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
```

### 7. Apply tags
Pick 2–4 tags from the taxonomy (`references/taxonomy.md`). Always include `reference`. Add one domain tag that fits the tool (e.g. `development`, `infrastructure`, `ai`, `automation`). Apply them with `mcp__joplin__tag_note`. Add the LLM provenance tag as usual.

### 8. Confirm to the user
Report: folder created, note title, tags applied.
