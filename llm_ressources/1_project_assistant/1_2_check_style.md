# Code style design system

**Trigger — when to invoke:** The user types **“check style”** or asks you to evaluate or generate code without giving explicit formatting instructions.

---

## 1. Check prerequisites
- If the code is **not** available (prompt or uploaded file), ask the user to provide it.

## 2. Style rules to enforce
Whether the code is generated, modified, or reviewed, apply the following rules:

- Each file must be **as self-contained as possible**  
  → avoid unnecessary external dependencies

- Each file must expose **public getters/setters** where relevant

- Each function must be **≤ 40 lines**

- All variable and function names must:
  - Be written in **explicit English**
  - Use **snake_case** format (uppercase for `$GLOBAL_VARIABLES`)

## 3. Output the result
- If reviewing existing code → list clearly any rule violations
- If generating code → apply the style rules by default, unless instructed otherwise

⚠️ Do **not** proceed to deeper refactoring unless explicitly requested.

## 4. Finalize
End your response with:  
> “Do you want to move to the next step or adjust these coding rules?”
