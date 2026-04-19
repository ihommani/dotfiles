---
name: joplin-note
description: "Use this skill whenever the user wants to save, write, capture, or record something in Joplin — including creating new notes, updating existing ones, or cleaning up tags on a note. Trigger on phrases like 'save this to Joplin', 'create a note about', 'add this to my notes', 'update my Joplin note on', 'jot this down', 'remember this in Joplin'. Also use when the user asks to tag or re-tag a Joplin note."
---

# Joplin Note Skill

Helps create and update notes in Joplin with consistent, queryable tagging.

The goal of tags is to let you find the right notes later from a plain-English description. Tags should be broad categories — useful for filtering, not for describing specifics. Think "container" not "docker", "cooking" not "mashed potatoes", "trip" not "trip to Spain".

---

## Tag Taxonomy

Read `references/taxonomy.md` for the full tag list, selection rules, and examples. That file is intentionally separate so you can edit it without touching the skill logic.

---

## LLM tag

For **new notes only**, always add an LLM provenance tag in the format:

```
llm:<vendor>/<model>
```

Determine which model you are from your system context and format accordingly:

| Model ID in system prompt | Tag |
|---|---|
| claude-sonnet-4-6 | `llm:anthropic/sonnet-4.6` |
| claude-opus-4-6 | `llm:anthropic/opus-4.6` |
| claude-haiku-4-5* | `llm:anthropic/haiku-4.5` |

Do **not** add this tag when updating an existing note — the note wasn't created by you.

---

## Workflow

### Creating a new note

1. **Determine the notebook** — use the user's specified notebook, or default to `"To Sort"`.
2. **Propose tags** — based on the note content, pick 2–5 tags from the taxonomy above. Proceed without asking unless the content is genuinely ambiguous (e.g., the same note could reasonably belong to two very different categories).
3. **Create the note** with `mcp__joplin__create_note` (pass `parent_id` for the notebook).
4. **Apply tags**:
   - List existing tags with `mcp__joplin__list_tags` to avoid duplicates.
   - For any tag that doesn't exist yet, create it with `mcp__joplin__create_tag`.
   - Attach each tag to the note with `mcp__joplin__tag_note`.
   - Include the LLM tag (see above).
5. Confirm to the user: note title, notebook, and the tags applied.

### Updating an existing note

1. **Find the note** — use `mcp__joplin__search` or the note ID if provided.
2. **Review existing tags** — fetch the note, check its current tags.
   - **Never touch** tags that start with `fabric-model` or `generated-with-fabric` — leave them exactly as-is. These are technical provenance tags from the Fabric framework that must be preserved.
   - **Never remove or modify** the `to_read` tag — it is a personal workflow marker that must be preserved as-is.
   - **Never remove or modify** the `favorite` tag — it is a personal curation marker.
   - **Never remove or modify** tags that start with `note:` (e.g. `note:10/10`) — these are personal annotation tags.
   - Replace over-specific tags with the appropriate taxonomy equivalent (e.g., `docker` → `container`, `museum` → `outing`).
   - Remove tags that have no equivalent in the taxonomy and add a better one if the content warrants it.
   - Do **not** add the LLM provenance tag.
3. **Update the note content** with `mcp__joplin__update_note`.
4. **Reconcile tags**: remove stale tags and add new ones as needed.
5. Confirm to the user: what changed in content, and for tags explicitly list what was swapped (e.g., `docker` → `container`, removed: `museum`, added: `outing`).

---

## Finding the right folder

Use `mcp__joplin__list_folders` to find the folder ID by name. Match case-insensitively. If the requested notebook doesn't exist, tell the user rather than silently falling back.

**Never infer tags from the notebook name.** Tags are derived solely from the note's content and, when present, the notebook's README (see below).

## Notebook README

After resolving the target notebook, search for a note titled exactly `README_<notebook-name>` inside it (e.g. `README_a_la_french`). If found, read its content before selecting tags — it reliably describes the notebook's purpose and typical content, and should inform your choices. If absent, proceed on note content alone. Never block or ask the user about it.

