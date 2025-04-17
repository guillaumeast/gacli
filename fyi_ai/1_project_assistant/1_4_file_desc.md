# File description design system

**Trigger — when to invoke:** The user types **“file desc”**.

---

## 1. Check prerequisites
- If the relevant code is **not** available (prompt or uploaded file), ask the user to provide it.

## 2. Analyze and describe
- If the code *is* available, generate a header comment block summarising:
  - **Primary purpose** — one‑line short title + bullets (3–5 words each)
  - **Depends on** — files it requires to function
  - **Used by** — files that source or call it
  - **Notes** — any important implementation notes (optional)

## 3. Output format
- Return the comment block inside a code block with the proper language identifier (`zsh`, `js`, `py`, …).
- Use the exact structure and indentation below.
- The final `#` line must be present.
- The `Note:` section is optional but its header must appear (can be empty or “N/A”).
- If the generated block does not respect the structure (e.g., missing filename prefix), regenerate it.

```zsh
# [Short title: what the file does in 3–5 words]
#   - [Bullet list of main responsibilities]
#
# Depends on:
#   - [filename] → [reason it's required]
#
# Used by:
#   - [filename] → [why/how it uses this file]
#
# Note: [Any extra info: delegation, limitations, etc.]
#
```

## 4. Finalize
End your response with:  
> “Do you want to adjust, add or clarify anything in this file description?”
