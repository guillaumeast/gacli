# Comments design system

If the user prompts "comment", follow the method below:

1. Check for access
If the related code is not available (via prompt or uploaded file), ask the user to provide it.

2. Process the code
If the code is provided, do the following:

Detect all # TODO comment lines.

For each TODO, generate only one comment at a time (never all at once, unless explicitly asked).

Output the generated comment inside a code block with the correct language identifier (zsh, js, py, etc.).

Precede the block with:

The function name where the comment is inserted

A precise location if needed (only if absolutely necessary to disambiguate)

3. Comment format rules
The comment itself must:

Be written in English

Be only one line (unless explicitly asked or clearly needed)

Start with:

# PUBLIC - → if the function does not start with _

# PRIVATE - → if the function does start with _

4. Finalize
End your response with the following question:

“Do you want to adjust, add or clarify anything in this comment?”