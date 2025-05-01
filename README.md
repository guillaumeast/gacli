# 🚀 GACLI

[![macOS](https://img.shields.io/badge/OS-macOS-darkgreen)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/OS-Linux-darkgreen)](https://kernel.org/)
[![Shell: zsh](https://img.shields.io/badge/shell-zsh-darkblue)](https://www.zsh.org/)
[![Status: Beta](https://img.shields.io/badge/status-beta-red)](#🏗️Roadmap)
[![License: MIT](https://img.shields.io/badge/license-MIT-white)](./LICENSE.txt)

'***Modular cross-platform CLI** to bootstrap and manage your development environment.*'

---

## ✨ Highlights

- **Cross-platform** – tested on `macOS` + main `Linux` package managers
- **One-command bootstrap** – even on a bare `container`
- **Zero external deps** – `curl` ***OR*** `wget` ***OR*** `POSIX sh` only
- **Modular by design** – drop folders in `$HOME/.gacli/modules/` or run `gacli install <module>`
- **Built-in CLI** – `gacli commands` and `custom modules commands` available
- **Instant status dashboard** – displays each `tool` status at shell startup
- **Test-ready** – `zunit` & `bats-core` scaffolding

---

## 🚀 Installation

Paste that in a `macOS` Terminal or `Linux` shell prompt:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/guillaumeast/gacli/master/installer/install.sh)"
```

<details>
  <summary>Other install methods</summary>

  - If you have `wget` :
  
  ```sh
  sh -c "$(wget -qO- https://raw.githubusercontent.com/guillaumeast/gacli/master/installer/install.sh)"
  ```
  
  - Else, grab `installer/install.sh` from the repo and run :
  
  ```sh
  sh /path/to/install.sh
  ```
  
</details>

<details>
  <summary>Options</summary>

  - --force → overwrite an existing installation
  
  ```sh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/guillaumeast/gacli/master/installer/install.sh)" -- --force
  ```
  
  💡 Pass options after `--` so they aren’t interpreted by `curl` / `wget`.
    
</details>

<details>
  <summary> Supported platforms & package managers</summary>

- `GACLI` installs `Homebrew` **plus** your declared `tools` on the following systems:
  
[![macOS](https://img.shields.io/badge/OS-macOS-darkgreen)](https://www.apple.com/macos/)

[![Docker: ubuntu](https://img.shields.io/badge/Linux-ubuntu-blue)](https://hub.docker.com/_/ubuntu)
[![Docker: debian](https://img.shields.io/badge/Linux-debian-blue)](https://hub.docker.com/_/debian)
[![Docker: mageia](https://img.shields.io/badge/Linux-mageia-blue)](https://hub.docker.com/_/mageia)
[![Docker: fedora](https://img.shields.io/badge/Linux-fedora-blue)](https://hub.docker.com/_/fedora)
[![Docker: archlinux](https://img.shields.io/badge/Linux-archlinux-blue)](https://hub.docker.com/_/archlinux)
[![Docker: opensuse/leap](https://img.shields.io/badge/Linux-opensuse%2Fleap-blue)](https://hub.docker.com/r/opensuse/leap)
[![Docker: gentoo/stage3](https://img.shields.io/badge/Linux-gentoo%2Fstage3-blue)](https://hub.docker.com/r/gentoo/stage3)

[![Pkg: apt](https://img.shields.io/badge/Pkg-apt-purple)](https://wiki.debian.org/apt)
[![Pkg: urpmi](https://img.shields.io/badge/Pkg-urpmi-purple)](https://wiki.mageia.org/en/URPMI)
[![Pkg: dnf](https://img.shields.io/badge/Pkg-dnf-purple)](https://dnf.readthedocs.io/en/latest/)
[![Pkg: pacman](https://img.shields.io/badge/Pkg-pacman-purple)](https://wiki.archlinux.org/title/Pacman)
[![Pkg: zypper](https://img.shields.io/badge/Pkg-zypper-purple)](https://en.opensuse.org/SDB:Zypper_manual)
[![Pkg: emerge](https://img.shields.io/badge/Pkg-emerge-purple)](https://wiki.gentoo.org/wiki/Portage)
[![Pkg: slackpkg](https://img.shields.io/badge/Pkg-slackpkg-purple)](https://docs.slackware.com/slackpkg)
  
  > 🧠 `Install.sh` detects the `package manager` and pulls `curl`, `bash`, `zsh`, `coreutils` and `jq` before `Homebrew` and the rest.  
  
  > 🤞 If your `distro` is not listed but ships one of the `package managers` above, chances are it will work — `PR`s welcome!
</details>

---

## 🏃 Getting started

`GACLI` automatically launch on each `zsh` startup but you can also launch it manually from any `shell`:

| Command | Description | Details |
|---------|-------------|---------|
| `gacli` | Launch | Prints status of each `tool` and `command` |
| `gacli help` | Get help | Prints available `tools` and `commands` |
| `gacli config` | Configure `GACLI` | Triggers interactive `configuration` wizard |
| `gacli install <list/file>` | Install `tools` | Installs one or more `tools` from given `list` or `file` |
| `gacli rm <list/file>` | Uninstall `tools` | Uninstalls one or more `tools` from given `list` or `file` |
| `gacli list <type>` | Print installed `tools` | Displays all `tools` installed if no `type` specified |
| `gacli update` | Update `tools` | Merges and updates all `tools` |
| `gacli <command> [args …]` | Run `module` commands | Every `module` can expose its own `CLI` |

> 💡 Run `gacli uninstall` anytime to cleanly remove `GACLI` files, wrapper and `.zshrc` entries, but keep `Homebrew` & tools.

---

## 🛠️ Tools

| Tool type | Source |
|-----------|--------|
| `formula` | [Homebrew Formulae](https://formulae.brew.sh/formula/) |
| `cask` | [Homebrew Casks](https://formulae.brew.sh/cask/) |
| `module` | **[Gacli-Hub](https://github.com/guillaumeast/gacli-hub)** |

<details>
  <summary>Descriptors</summary>

| Descriptor | Source | Tools name |
|--------|------|--------------|
| `data/tools/core.tools.json` | Core `GACLI` dependencies | `core tools`
| `modules/*/tools.json` | Individual `module` dependecies (optional) | `module tools`
| `data/tools/modules.tools.json` | Merged `modules` dependecies (optional) | `modules tools`
| `data/tools/user.tools.json` | `user` tools (optional) | `user tools`
</details>

<details>
  <summary>Descriptors schema</summary>

```json
{
  "formulae": ["formula_1", "formula_2"],
  "casks": ["cask_1", "cask_2"],
  "modules": ["module_1", "module_2"]
}
```
</details>

### Add or remove tools

```sh
gacli install "${tool_names[@]}"
gacli rm "${tool_names[@]}"
```

> Or add/remove **local** `modules folders` in `$HOME/.gacli/modules/` and run `gacli update`
> 
> Or add/remove **[gacli-hub](https://github.com/guillaumeast/gacli-hub)** `module names` in `$HOME/.gacli/data/tools/user.tools.json` and run `gacli update`

---

## 🧩 Modules

<details>
  <summary>What is a module?</summary>

A **`module`** is a self‑contained folder that can:

* declare its own `formulae`, `casks` and dependent `modules` inside **`tools.json`**
* expose `CLI commands` through a `get_commands` function in **`main.zsh`**
* bundle any helper `scripts`, `assets` or `docs` it needs

If the folder lives in **`src/modules/`** it is considered *`local`*; otherwise `GACLI` can download it on‑the‑fly from the **[gacli-hub](https://github.com/guillaumeast/gacli-hub)**.
</details>

<details>
  <summary>Lifecycle</summary>

1. **Discovery** – `modules_init` collects: sub‑folders of `src/modules/` **+** the `modules` array in `user.tools.json`
2. **Download / update** – missing modules are fetched from `gacli‑hub`, extracted into `src/modules/`
3. **Dependency merge** – each module’s `tools.json` is merged into `modules.tools.json`
4. **Load & register** – `modules_load` sources `<module>/main.zsh`, calls `get_commands` and registers them
</details>

<details>
  <summary>Expose commands</summary>

1. In your `module` entry point (`my_name/main.zsh`):
```zsh
my_hello() {
  printStyled highlight "Hello from my_module!"
}

get_commands() {
  echo "hello=my_hello"
}
```

2. In your terminal:

```sh
gacli hello
# Output: Hello from my_module!
```
</details>

<details>
  <summary>Install a module</summary>

- Install a `remote module`
```sh
gacli install "module_name"
```

- Install a `local module`
```sh
gacli install "module_path"
```

`GACLI` downloads **`module`**, installs its deps and its `commands` become available instantly.
</details>

<details>
  <summary>Uninstall a module</summary>

```sh
gacli rm "module_name"
```
</details>

<details>
  <summary>Nested modules</summary>

A `module` can require others in its **`tools.json`**:

```json
{
  "modules": ["nested_module_1", "nested_module_2"]
}
```

`GACLI` resolves these recursively, downloading each only once.
</details>

<details>
  <summary>Create your own module</summary>

```bash
modules/
└── my_module/
    ├── main.zsh
    ├── tools.json
    └── ...
```

1. Create the folder & files  
2. `gacli update` – merges dependencies  
3. Reload shell & test commands
4. When ready, publish to `GitHub` and open a PR on **[gacli-hub](https://github.com/guillaumeast/gacli-hub)** to share it!
</details>

> 💡 More details at: **[gacli-hub](https://github.com/guillaumeast/gacli-hub)**

---

## ♻️ Update & auto‑update

| Command | Description |
|---------|-------------|
| `gacli config` | Edit auto‑update frequency interactively |
| *(startup)* | Auto‑update if `next_update` reached or deps missing |
| `gacli update` | Run an update immediately |

> 💡 You can disable auto-update by setting frequency to `0`.

<details>
  <summary>Manual update</summary>

  Trigger a full merge → install → cleanup cycle at any time:

  ```sh
  gacli update
  ```

  Under the hood:

  1. `update_merge_into` concatenates **core + user + modules** `JSON descriptors` into `src/.tmp/Brewfile`
  2. `brew_bundle` installs missing `formulae`/`casks`, upgrades outdated ones, then runs `brew cleanup`
  3. Config file `update.config.json` is refreshed (`last_update`, `next_update`)
</details>

<details>
  <summary>Auto‑update scheduler</summary>

  During start‑up `update_init` checks:

  * `auto_update`   → enabled / disabled  
  * `next_update`   → UNIX timestamp of the next run  
  * **OR** missing dependencies

  If the date is reached **or** deps are missing, the manual update routine is executed automatically.
</details>

<details>
  <summary>Configuration</summary>

  The configuration wizard is automatically triggered on first launch.

  You can edit config at any time by running:

  ```sh
  gacli config
  ```

  You will be asked:

  > `How many days between each auto‑update? (OFF = 0)`

  * `0` → disables auto‑update  
  * any integer *n* → scheduler will run every *n* days

  The values are saved in `data/config/update.config.json`:

  ```json
  {
    "initialized": "true",
    "auto_update": "true",
    "last_update": "1713504000",
    "freq_days": "7",
    "next_update": "1714108800"
  }
  ```
</details>

---

## 🧠 How it works

<details>
  <summary>1. Config step</summary>
  
  – On first run or on `gacli config`, asks for an *auto‑update frequency* and stores it in `data/config/update.config.json`.
</details>

<details>
  <summary>2. Modules discovery</summary>
  
  – `modules_init` scans `modules/` **and** `data/tools/user.tools.json`.
</details>


<details>
  <summary> 3. Modules download</summary>
  
  - Clones any missing `module` from `GitHub`, then merges their `tools.json` into `data/tools/modules.tools.json`.
</details>
  
<details>
  <summary> 4. Dependencies merge</summary>
  
  – Core, user & modules `tools.json` files are concatenated **deduplicated** into `.tmp/Brewfile`.  
</details>

<details>
  <summary> 5. Update check</summary>
  
  – `update_init` compares the current date with `next_update` **and** checks for missing `formulae`/`casks`
</details>

<details>
  <summary> 6. Smart update</summary>
  
  - If needed, `brew_bundle` installs/upgrades everything and cleans old versions.  
</details>

<details>
  <summary> 7. Dynamic CLI</summary>
  
  – `modules_load` sources each module’s `main.zsh`, reads `get_commands`, and appends them to the dispatcher.  
</details>

<details>
  <summary> 8. Runtime</summary>
  
  – Without args, `GACLI` prints a coloured status dashboard; with a command, it routes to the matching function (core or `module`).
</details>

<details>
  <summary>👁️ Better have a look?</summary>

  ```mermaid
  flowchart TD
      A[Start shell] --> B(Execute <code>gacli</code>)
      B --> C[Integrity checks & helper load]
      C --> D[<code>modules_init</code>: download/merge modules]
      D --> E[<code>update_init</code>: merge tools files]
      E --> F{Auto‑update due?<br>Missing deps?}
      F -- Yes --> G[<code>brew_bundle</code>: install / upgrade / cleanup]
      F -- No --> H[Skip]
      G --> I[<code>modules_load</code>: source modules & commands]
      H --> I
      I --> J[Dashboard + command dispatch]
  ```
</details>

---

## 🗂️ Repository structure

```bash
gacli/
├── installer/
│   ├── Brewfile                    # GACLI dependencies descriptor
│   └── install.sh                  # <----- 1. ONE-LINER AUTO-INSTALLER
├── src/
│   ├── main.zsh                    # <----- 2. GACLI ENTRY POINT (dispatcher)
│   ├── data/                       # static JSON descriptors
│   ├── helpers/                    # stateless utilities
│   ├── logic/                      # <----- 3. ORCHESTRATION LAYER (modules / update / uninstall)
│   ├── modules/                    # <----- 4. USER & DOWNLOADED MODULES
│   │   └── ...                     # (each folder = 1 module)
│   └── .tmp/                       # runtime‑generated files (merged Brewfile, etc.)
└── test/                           # bats-core test scripts
    ├── unit/                       # zunit tests
    ├── _output_/                   # zunit TAP reports
    ├── _support_/                  # zunit bootstrap
    └── fixture/                    # tests fixtures
```

> 💡 Only `src` folder is installed by `ìnstall.sh`, other dirs are only required for dev purposes

> 💡 `GACLI` automatically creates `src/.tmp/` and fills it at runtime; you can safely add it to your `.gitignore`.

### Module anatomy

```bash
my_module/
├── main.zsh        # <----- 5. MODULE ENTRY POINT (may implement get_commands)
├── tools.json      # formulae / casks / nested modules
└── …               # optional helpers, docs, etc.
```

---

## 🧪 Testing & CI

### Tested environments

[![Local: macOS](https://img.shields.io/badge/Local-macOS-darkgreen)](https://www.apple.com/macos/)

[![Docker: ubuntu](https://img.shields.io/badge/Docker-ubuntu-blue)](https://hub.docker.com/_/ubuntu)
[![Docker: debian](https://img.shields.io/badge/Docker-debian-blue)](https://hub.docker.com/_/debian)
[![Docker: mageia](https://img.shields.io/badge/Docker-mageia-blue)](https://hub.docker.com/_/mageia)
[![Docker: fedora](https://img.shields.io/badge/Docker-fedora-blue)](https://hub.docker.com/_/fedora)
[![Docker: archlinux](https://img.shields.io/badge/Docker-archlinux-blue)](https://hub.docker.com/_/archlinux)
[![Docker: opensuse/leap](https://img.shields.io/badge/Docker-opensuse%2Fleap-blue)](https://hub.docker.com/r/opensuse/leap)
[![Docker: gentoo/stage3](https://img.shields.io/badge/Docker-gentoo%2Fstage3-blue)](https://hub.docker.com/r/gentoo/stage3)

[![Pkg: apt](https://img.shields.io/badge/Pkg-apt-purple)](https://wiki.debian.org/apt)
[![Pkg: urpmi](https://img.shields.io/badge/Pkg-urpmi-purple)](https://wiki.mageia.org/en/URPMI)
[![Pkg: dnf](https://img.shields.io/badge/Pkg-dnf-purple)](https://dnf.readthedocs.io/en/latest/)
[![Pkg: pacman](https://img.shields.io/badge/Pkg-pacman-purple)](https://wiki.archlinux.org/title/Pacman)
[![Pkg: zypper](https://img.shields.io/badge/Pkg-zypper-purple)](https://en.opensuse.org/SDB:Zypper_manual)
[![Pkg: emerge](https://img.shields.io/badge/Pkg-emerge-purple)](https://wiki.gentoo.org/wiki/Portage)
[![Pkg: slackpkg](https://img.shields.io/badge/Pkg-slackpkg-purple)](https://docs.slackware.com/slackpkg)

> Each supported `platform` and `package manager` is fully tested

### Test suites

| Layer | Framework | Status |Location |
|-------|-----------|--------|---------|
| **`zsh` scripts** | **`zunit`** | ✅ Implemented | `tests/unit/*.zunit` |
| **`sh` POSIX scripts** | **`bats‑core`** | 🚧 WIP | `tests/*.bats` |

<details>
  <summary>Test scripts and fixtures</summary>

| Framework | Description |Location |
|-----------|-------------|---------|
| **`zunit`** | config file | `.zunit.yaml` |
| **`zunit`** | setup script | `tests/_support/bootstrap` |
| **`zunit`** | TAP reports | `tests/_output` |
| **`zunit`** | Various fixtures | `tests/fixture` |
</details>

### Run local tests

```sh
zunit
```

### Run Docker tests

```sh
# 🚧 Work in progress...
```

### CI Pipeline (`GitHub Actions`)

```sh
# 🚧 Work in progress...
```

---

## 🏗️ Roadmap

| Version | Status | Description |
|---------|--------|-------------|
| 0.7.0 | 🟠 deployed → `dev` branch | 🎁 feat(all): Initial untest version |
| 0.7.1 | 🟠 deployed → `dev` branch | 🧪 test(zsh): Implement `Zunit` tests |
| 0.7.2 | 🚧 WIP → `dev` branch | 🧪 test(sh): Implement `bats_core` tests |
| 0.7.3 | 🔴 TODO | ⚙️ ci(all): Add `GitHub Actions` CI pipeline |
| 0.8.0 | 🔴 TODO | 🎁 feat(modules): Add commands `gacli <install-list-rm> <tools>` |
| 0.9.0 | 🔴 TODO | 📦 build(modules): `Modules` version management |
| 1.0.0 | 🔴 TODO | 🚀 First public `release` |

---

## 🎓 Why GACLI exists

This project started as a **learning sandbox** to understand:

- 📦 internals of **`package management systems`**
- ⚡️ building a **`one-liner installer`** in pure `POSIX` `sh`  
- 🧩 building a **`modular CLI`** in pure `zsh`  
- 👹 building **`cross‑platform` `shell automations`** (`macOS` + many `Linux` distros)  
- ♻️ writing **`self‑updating scripts`** with minimal `dependencies`
- 🧪 writing **`unit tests`** with `zunit` and `bats-core`
- 🐳 using **`containers`** with `Docker`
- ⚙️ setting up a **`CI pipeline`** with `GitHub Actions`

🫵 Feel free to `fork`, `tweak` or `cherry‑pick` parts for your own setup!

---

## 🙏 Contributing

1. `Fork` → `branch` → `code`  
2. Ensure `zunit` & `bats` suites pass locally  
3. `Commit` using conventional prefixed messages (`feat(): ...`, `fix(): ...`, …)  
4. Open a `PR` → `CI` must be green 💚

---

## License

MIT – see [LICENSE](./LICENSE)

Made with ❤️ and way too much `if !` statements by [@guillaumeast](https://github.com/guillaumeast)
