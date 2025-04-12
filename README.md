# 🚀 GACLI

✌️ *Managing and bootstrapping your dev environment has never been so easy* ⚡

✨ `GACLI` is a **modular CLI** designed to **automate setup, updates and tooling** for both `macOS` and `Linux`.

---

## 🧰 Features

- Installs `Homebrew` if not available
- Installs all `formulae` and `casks` listed in the `Brewfile`
- Initializes a configuration with an **auto-update** frequency
- Updates everything with a **single command**
- Modular structure with optional **command-based extensions**
- Supports nested modules and per-module dependencies
- Shows **tools status** on launch
- 100% compatible with `macOS` and `Linux`

---

## 🎓 Educational Purpose

This project was designed to **learn how to build modular tools from scratch**, without relying on external boilerplates or frameworks.

Its goal is to help understand low-level mechanics behind tools like `Homebrew`, `Oh My Zsh`, `asdf`, or CLI wrappers — how they work, how they can be replaced, and how to design cross-platform automation from scratch.

**This project is not meant to be universally useful.**  
It’s a learning sandbox and a productivity tool for my own setup — but feel free to fork, reuse or contribute if you find it useful!

---

## 🚀 Installation

GACLI requires your default shell to be `zsh`:
  - macOS: preinstalled (if default shell is different, run `chsh -s /bin/zsh`)
  - Linux: `sudo apt install zsh`

### Quick command

```bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/guillaumeast/gacli/refs/heads/master/modules/.install/install.zsh)"
```

This command:

1. Checks and installs required dependencies automatically
2. Clones the repository into `~/.gacli`
3. Creates a symbolic link in `~/.local/bin`
4. Adds `~/.local/bin` to your `PATH` if necessary

<details>
<summary>📦 Dependencies (auto-installed)</summary>

- `git`
- `curl`
- `Homebrew`
- `coreutils`
- `jq`

</details>

### Available options

Use `--force` option to overwrite an existing installation

**Example**:

```bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/guillaumeast/gacli/refs/heads/master/modules/.install/install.zsh)" -- --force
```

> ⚠️ Options must be passed **after `--`**, otherwise they will be interpreted by `curl` instead of the script.


---

## 🧠 How it works

1. Asks for update frequency and stores it in the `config` file
2. Installs `Homebrew` if missing
3. Installs `formulae` and `casks` from the `Brewfile`
4. Loads core `modules` from `gacli/modules/.core/`
5. Loads launcher `modules` from `gacli/modules/.launcher/`
6. Loads user `modules` from `gacli/modules/user_modules/`
7. If found, loads declared `nested modules` from `modules.json`
8. Performs `auto-update` if needed
9. Shows a `status summary` at terminal startup

---

## 🗂️ Project Structure

```bash
gacli
├── README.md
├── gacli.zsh           # GACLI entry point
├── Brewfile            # Declares custom formulae and casks
├── modules.json        # Declares custom modules
└── modules/
    ├── module_manager.zsh  # Parse and orchestrate all modules
    ├── .install/           # GACLI auto-installer
    ├── .core/              # GACLI core modules (cross-platform compatibility)
    ├── .launcher           # Lifecycle logic (config, update, uninstall)
    ├── .tmp                # Runtime generated files (config, merged Brewfile, module index)
    └── user_modules        # User custom modules (optional)
        ├── module_example
        │   ├── main.zsh      # ← module's entry point
        │   ├── Brewfile      # ← required formulae and casks declared here
        │   ├── modules.json  # ← nested modules declared here
        │   └── ...
        └── ...
```

---

## 📦 Brewfile

You can declare custom dependencies in `gacli/Brewfile` and/or in your own `<custom_module>/Brewfile`:

```bash
brew "pyenv"
cask "ollama"
```

Apply changes by restarting your terminal or running:
```bash
gacli update
```

🪄 `GACLI` automatically merges and deduplicates all `Brewfiles` and `modules.json` files into `gacli/modules/.tmp/`.

---

## 🧩 Modules

`GACLI` is fully modular:
- Each `module` lives in its own folder in `user_modules/`
- Each `module` can expose any number of `commands` via a `get_commands()` function
- Each `module` can declare any number of `formulae`, `casks` in his `Brewfile`
- Each `module` can declare any number of `nested modules` in his `modules.json`

You can add new `modules` by:
1. Creating a `.zsh` file in `modules/user_modules/<your_module>/`
2. [OPTIONAL] Declaring `formulae` and `casks` dependencies in `<your_module>/Brewfile` as:
```bash
brew "<formula>"
cask "<cask>"
```
3. [OPTIONAL] Declaring `modules` dependencies in `<your_module>/modules.json` as:
```json
{
  "modules": [
    {
      "name": "<module_name>",
      "repo": "https://github.com/<user>/<module_repo>",
      "enabled": true
    }
  ]
}
```
4. [OPTIONAL] Exposing `commands` via a `get_commands` function as:
```zsh
get_commands() {
  echo "command_name=function_name"
}
```

🪄 `GACLI` automatically merges and deduplicates all `Brewfiles` and `modules.json` files into `gacli/modules/.tmp/`.

---

## 🔄 Update

```zsh
gacli update
```

✅ Merges all `Brewfiles` and `modules.json` files
✅ Installs & updates all tools
✅ Cleans up old versions

---

## 🧹 Uninstall

```zsh
gacli uninstall
```

✅ Delete all `GACLI` files
✅ Delete the `wrapper` and `symlink link`
✅ Delete entries from `.zshrc`
✅ Clean config

👉 It will **NOT**:
🚫 Uninstall `Homebrew`
🚫 Uninstall any `formula` or `cask`

Feel free to remove those manually if you want to fully clean your environment.

---

## 📄 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
See the [LICENSE](./LICENSE) file for details.

---

Made with ❤️ by [guillaumeast](https://github.com/guillaumeast)

