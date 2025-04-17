# Roadmap

## WIP 

✅ `gacli.zsh`:
    - `main` :
        - `_gacli_check_system` → Check `OS` and enable `emojis` if possible
        - `_gacli_check_files` → Check `folders` and `files` intergity
        - Source core `scripts`
        - `update_check` → `modules_init` + `_update_merge` + [if `tmp` ≠ `installed` || `today` > `next_update`]→(`brew_bundle` + `update_save`) 
        - `modules_load` → source `modules` entry point
        - `gacli_dispatch` → call various `functions` depending on given `args`

✅ `brew.zsh` :
    - `_brew_install`
    - `brew_bundle <Brewfile>` (performed only if at least one `formula` or `cask` from given `<Brewfile>` is not `active`)
    - `brew_is_f_active <formula>`
    - `brew_is_c_active <cask>`

✅ `modules.zsh` :
    - `modules_init`:
        - `_modules_download` → Download missing `modules` from `github`
        - `_modules_merge` → Merge dependencies in `modules.tools.yaml` (with cycling mangement)
    - `modules_load` → source each module

✅ `update.zsh` :
    - `update_auto` :
        - `modules_init` → Download missing `modules` and merge dependencies into `modules.tools.yaml`
        - `_update_merge` → Merge dependencies from `core.tools.yaml` and `modules.tools.yaml` into `tmp.tools.yaml` and `tmp.Brewfile`
        - `_update_is_due`:
            - if `today` >= `next_update` → `true`
            - if `installed.tools.yaml` doesn't contain all `tmp.tools.yaml` items
        - if `_update_is_due` → `update_run`
        - else → delete `tmp.tools.yaml` and `tmp.Brewfile`
    - `update_run` :
        - `_update_merge` → Merge dependencies from `core.tools.yaml` and `modules.tools.yaml` into `tmp.tools.yaml` and `tmp.Brewfile`
        - `brew_bundle $tmp.Brewfile` → Updates formulae and casks
        - `_update_save` → check each `tmp.tools.yaml` tool status and add only active ones to `installed.tools.yaml`
        → delete `tmp.tools.yaml` and `tmp.Brewfile`

✅ Final review pass on `gacli.zsh`

✅ Update `codebase.txt` and all `GPT project GACLI` files

6. Update all files `description`

7. Passer tous les commentaires de fonction au format requis (`"# PRIVATE - ..."` / `"# PUBLIC - ..."`)

8. Final review of `install.zsh`

9. 🙌

---

1. rewrite all possible `if ... then ...` → `... 2> /dev/null || {...}` (mute called function error messages if calling function can handle error)

---

## Test local - Install
1. 🚧 Test: Tester l'installation
2. 🚧 Test: Tester la mise à jour automatique
=> 👌 test(install): Installer validated local test

---

## Test local - Add tool
1. 🚧 Test: Tester l'ajout d'une `formula` dans `tools.yaml`
2. 🚧 Test: Tester l'ajout d'un `cask` dans `tools.yaml`
3. 🚧 Test: Tester l'ajout d'un `module` dans `tools.yaml`
4. 🚧 Test: Tester l'ajout d'un `module` dans `gacli/modules/`
=> 👌 test(tools): Tools system validated local test

---

## Test Docker - Install
1. 🚧 Setup: Installer Container Linux minimal avec `Docker`
2. 🚧 Test: Tester l'installation
3. 🚧 Test: Tester la mise à jour automatique
=> 👌 fix(install): Installer validated Linux Docker test

---

## Test Docker - Add tool
1. 🚧 Test: Tester l'ajout d'une `formula` dans `tools.yaml`
2. 🚧 Test: Tester l'ajout d'un `cask` dans `tools.yaml`
3. 🚧 Test: Tester l'ajout d'un `module` dans `tools.yaml`
4. 🚧 Test: Tester l'ajout d'un `module` dans `gacli/modules/`
=> 👌 test(tools): Tools system validated Linux Docker test

---

## Version 1.1.0
🎁 feat(modules, install): Enable modules recursive auto_install and update installer [🔖 v1.1.0]

---

## Version 1.2.0
1. 🚧 Feat: `gacli add formula <formula>`, `gacli rm module <formula>`, `gacli list formulae`
2. 🚧 Feat: `gacli add cask <cask>`, `gacli rm cask <cask>`, `gacli list casks`
3. 🚧 Feat: `gacli add module <module>`, `gacli rm module <module>`, `gacli list modules`
=> 🎁 feat(modules): Enable commands for managing formulae, casks and modules [🔖 v1.2.0]

---

## Version 1.3.0
1. 🚧 Feat: auto-update to latest `GACLI` version
2. 🚧 Feat: auto-update to latest `modules` version
=> 🎁 feat(update): Add auto-update system for GACLI and modules

---

## Version 1.3.1
1. 🚧 Update `README.md` (+ check sur github.com branche dev)
2. 🚧 Release `gacli v1.1.0` (first public `release`)
=> 🚀 TODO: release commit message ??

---

## Module compillm 0.1.0
1. ⚠️ Fix: module `gacli_compillm`
=> 🚀 TODO: release commit message ??
(🕘 LATER => `compillm` -> `folder2md` with `pandoc`)

---

## Module git_helper 0.1.0
1. 🧩 Feat: module `git_helper` (branch name + status color)

