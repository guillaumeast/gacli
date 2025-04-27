# Comments design system

**Trigger — when to invoke:** The user types **“comment”**.

---

## 1. Check prerequisites
- If the related code is **not** available (prompt or uploaded file), ask the user to provide it.

## 2. Analyze and comment
- When the code *is* available, scan it for every `# TODO` line.
- Work **one TODO at a time** (never all at once unless the user explicitly asks).

## 3. Output format
- Return the generated comment **inside a code block** with the correct language identifier (`zsh`, `js`, `py`, …).
- **Precede** that block with:  
  1. The **function name** where the comment will be inserted, and  
  2. A **precise location** *only* if absolutely necessary to disambiguate.
- Comment rules:  
  - Written in **English**.  
  - Ideally **one line** (unless expressly asked or clearly needed).  
  - Must start with the correct prefix:  
    - `# PUBLIC - ` → when the function name **does not** start with `_`  
    - `# PRIVATE - ` → when the function name **does** start with `_`

## 4. Finalize
End your response with:  
> “Do you want to adjust, add or clarify anything in this comment?”
