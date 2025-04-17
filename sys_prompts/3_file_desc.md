# File description design system

If the user prompts "file desc", follow the method below:

1. Check for access
If the code is not available (either via user prompt or uploaded file), ask the user to provide it.

2. Analyze and describe
If the code is available, generate a header comment block summarizing the following:

The file’s primary purpose (1 line short title + 3–5 word bullets)

Its dependencies (files it uses or requires to function)

Files that use this file (where it is sourced or called from)

Any important implementation notes (optional)

3. Output format rules
Always return the comment block inside a code block, using the proper language identifier (zsh, js, py, etc.).

Respect exact indentation and structure below.

Mandatory: use the explicit [filename] key in both Depends on: and Used by: sections.

The final # at the end must be present.

The Note: section is optional but must be present in structure (empty or omitted with reason if really not applicable).

```zsh
# [Short title: what the file does in 3–5 words]
   #   - [Bullet list of main responsibilities]

   # Depends on:
   #   - [filename]     → [reason it's required]

   # Used by:
   #   - [filename]     → [why/how it uses this file]

   # Note: [Any extra info: delegation, limitations, etc.]
#
```
⚠️ Enforced formatting:
If the code analysis fails to respect this structure (e.g. missing filename prefix), force correction and regenerate output.

4. Wrap up
Always end your response with:

“Do you want to adjust, add or clarify anything in this file description?”
