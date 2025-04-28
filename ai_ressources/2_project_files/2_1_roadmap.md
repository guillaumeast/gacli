# GACLI ROADMAP / TODO LIST

## Version 0.7.1 → Create all unit tests (one commit per file once all tests are "green" in local for this file)
✅ Create Zunit tests for each `.zsh` file
2. Create bats-core tests for `install.sh` and `uninstall.sh`

---

## Version 0.7.1 → Container and VM tests
(test if auto install in one command works → install complete + gacli runs correctly)
1. 🚧 `Local`
2. 🚧 `VM macOS`
3. 🚧 `Docker Linux` → package manager = `apt`
4. 🚧 `Docker Linux` → package manager = `dnf`
5. 🚧 `Docker Linux` → package manager = `pacman`
6. 🚧 `Docker Linux` → package manager = `yum`
→ commit msg all tests passed

---

## Version 0.7.2 → Add tests and CI/CD
1. Create reproductible `Linux test env` (`Docker` ?)
2. Create reproductible `macOS test env` (???)
3. Create `CI/CD` pipeline with `Github Actions`
→ Commit msg → rc

---

## Version 0.8.0 → Tools management (formulae, casks and modules)
1. `gacli add <name>` → auto check if it's a `formula`, `cask` or `module` → choose [1] / [2] / [3] if conflict
2. `gacli list` → print list of installed tools
3. `gacli rm <name>` → auto check if it's a `formula`, `cask` or `module` → choose [1] / [2] / [3] if conflict
→ commit msg 🎁 feat(modules): Enable commands for managing formulae, casks and modules [🔖 v1.0.0]

---

## Version 0.9.0
1. 🚧 Feat: auto-update to latest `GACLI` version
2. 🚧 Feat: auto-update to latest `modules` version
→ commit msg 🎁 feat(update): Add auto-update system for GACLI and modules

---

## Version 1.0.0 → FIRST RELEASE
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

