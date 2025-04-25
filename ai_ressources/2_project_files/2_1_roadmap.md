# GACLI ROADMAP / TODO LIST

##  Version 1.1.0 → Final check before tests
1. Vérifier la codebase globalement (structure, logique, problèmes bloquants...)
2. Vérifier la codebase par étapes (fichier par fichier) et sous-étapes (fonction par fonction au sein de chaque fichier) :
    - Chaque fonction doit respecter `Code style design system`
    - Chaque fonction doit respecter `Comments design system`
    - Chaque fichier doit respecter `File description design system`
→ Commit msg ready for final E2E tests

---

##  Version 1.1.0 → Final E2E tests
(test if auto install in one command works → install complete + gacli runs correctly)
1. 🚧 `Local`
2. 🚧 `VM macOS`
3. 🚧 `Docker Linux` → package manager = `apt`
4. 🚧 `Docker Linux` → package manager = `dnf`
5. 🚧 `Docker Linux` → package manager = `pacman`
6. 🚧 `Docker Linux` → package manager = `yum`
→ commit msgall tests passed → rc

---

## Version 1.1.1 → Add tests and CI/CD
1. Create `test env` (`Docker` ?)
1. Create `unit tests`
2. Create `regression tests`
3. Create `CI/CD` pipeline with `Github Actions`
→ Commit msg

---

## Version 1.2.0 → Tools management (formulae, casks and modules)
(`gacli add <name>` → auto check if it's a `formula`, `cask` or `module` → choose [1] / [2] / [3] if conflict)
1. 🚧 Ajouter/retirer une `formula` via `tools.yaml`
2. 🚧 Ajouter/retirer un `cask` via `tools.yaml`
3. 🚧 Ajouter/retirer un `module` via `tools.yaml`
4. 🚧 Ajouter/retirer un `module` via `gacli/modules/`
5. 🚧 Ajouter/retirer une `formula` via `gacli add` / `gacli rm`
6. 🚧 Ajouter/retirer un `caks` via `gacli add` / `gacli rm`
7. 🚧 Ajouter/retirer un `module` via `gacli add` / `gacli rm`
→ commit msg

---

## Version 1.2.0
1. 🚧 Feat: `gacli add formula <formula>`, `gacli rm module <formula>`, `gacli list formulae`
2. 🚧 Feat: `gacli add cask <cask>`, `gacli rm cask <cask>`, `gacli list casks`
3. 🚧 Feat: `gacli add module <module>`, `gacli rm module <module>`, `gacli list modules`
→ commit msg 🎁 feat(modules): Enable commands for managing formulae, casks and modules [🔖 v1.2.0]

---

## Version 1.3.0
1. 🚧 Feat: auto-update to latest `GACLI` version
2. 🚧 Feat: auto-update to latest `modules` version
→ commit msg 🎁 feat(update): Add auto-update system for GACLI and modules

---

## Version 1.3.1 → FIRST RELEASE
1. 🚧 Update `README.md` (+ check sur github.com branche dev)
2. 🚧 Release `gacli v1.3.1` (first public `stable` `release`)
→ Commit msg
→ Release

---

# MODULES ROADMAP / TODO LIST

---

## Module compillm 0.1.0
1. ⚠️ Fix: module `gacli_compillm`
=> 🚀 TODO: release commit message ??
(🕘 LATER => `compillm` -> `folder2md` with `pandoc`)

---

## Module git_helper 0.1.0
1. 🧩 Feat: module `git_helper` (branch name + status color)

