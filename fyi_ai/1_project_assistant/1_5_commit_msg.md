# Commit messages design system

**Trigger — when to invoke:** The user types **“commit msg”**.

---

## 1. Check prerequisites
- If you lack enough context to generate the commit message (e.g., if you don't know which code has been modified since the last commit), ask the user to list the main changes to include.

## 2. Generate the message
- If you have enough context, generate a commit message inside a code block.
- End your response by asking the user if they want to add, modify, or remove anything in the commit message.

## 3. Commit format
- Commit messages must be written in **English**.
- Must fit on **one simple line**, max **50 characters**, and **no period** at the end.

### Allowed types and scopes

#### No impact
- ⏪ `revert(scope)`   → Reverting a commit
- 📝 `docs(scope)`     → Documentation changes
- 🎨 `style(scope)`    → Format/indentation changes only
- 🔧 `chore(scope)`    → Task with no direct code impact (e.g., deps update)

#### Building
- ⚙️ `ci(scope)`       → Continuous integration changes (workflows, pipelines, etc.)
- 📦 `build(scope)`    → Build system changes (Makefile, bundler, etc.)
- ⛓️ `deps(scope)`     → Dependency update (add, remove, version)

#### Stabilizing
- 🚧 `wip(scope)`      → Work in progress random snapshot, "just in case"
- 🧪 `test(scope)`     → Adding/modifying tests (unit, end-to-end, etc.)
- 🐛 `fix(scope)`      → Bug fix or unexpected behavior correction
- 🏗️ `refacto(scope)`  → Code rewrite without behavior change (structure, naming…)

#### Adding value
- ⚡️ `perf(scope)`     → Performance improvement (optimization, caching…)
- ✨ `polish(scope)`   → Minor visual or functional improvement (UX, labels, animations…)
- 🎁 `feat(scope)`     → New feature or behavior added
- 🚀 `release(scope)`  → Version release (tag, changelog, deployment…)

## 4. Finalize
End your response with:  
> “Do you want to add, modify, or remove anything in this commit message?”

