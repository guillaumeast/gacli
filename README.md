# 🚀 GACLI

✌️ *Managing and bootstrapping your dev environment has never been so easy* ⚡

✨ `GACLI` is a **modular CLI** designed to **automate setup, updates and tooling**.

---

## 🧰 Features

- Installs `Homebrew` if not available
- Installs all `formulae` and `casks` listed in the `Brewfile`
- Initializes a configuration with an **auto-update** frequency
- Updates everything with a **single command**
- Modular structure with optional **command-based extensions**
- Shows **tools status** on launch
- 100% compatible with `macOS` and `Linux`

---

## ⚙️ Installation

```bash
git clone https://github.com/guillaumeast/gacli.git
cd gacli
zsh gacli.zsh
```

💡 `Homebrew` and `coreutils` are auto-installed if missing.

---

## 🧠 How it works

1. Asks for update frequency and stores it in the `config` file
2. Installs `Homebrew` if missing
3. Installs `formulae` and `casks` from the `Brewfile`
4. Loads core `modules`
5. Loads user `modules` from `gacli/modules/tools/`
6. Performs `auto-update` if needed
7. Shows a `status summary` at terminal startup

---

## 🗂️ Project Structure

```bash
gacli/
├── Brewfile             # List of formulae and casks to install
├── config               # Auto-generated config with update frequency
├── gacli.zsh            # Main launcher script
├── modules              # All logic and features organized by scope
│   ├── module_manager.zsh      # Loads and dispatches modules
│   ├── .core                   # Required modules (style, brew, date)
│   ├── .install                # Lifecycle modules (install, update, uninstall)
│   └── tools                   # Optional user modules (1 folder = 1 module)
```

---

## 🧩 Modules

`GACLI` is fully modular: each optional command is defined in a separate module.

You can add new modules by:
1. Creating a `.zsh` file in `modules/tools/<your_module>/`
2. Exposing commands via a `get_commands` function as:
```zsh
get_commands() {
  echo "command_name=function_name"
}
```

<details>
<summary>Example</summary>

Example implementation of `gacli hello` command:
```zsh
get_commands() {
  echo "hello=hello_world"
}

hello_world() {
  printStyled info "Hello, world!"
}
```

</details>

---

## 📦 Brewfile

Edit `Brewfile` to add or remove tools.

```bash
# Add a formula
brew "formula_name"

# Add a cask
cask "cask_name"
```

⚠️ **DO NOT** remove `coreutils` from the `Brewfile` (**required dependencie** for `GACLI`'s cross-platform compatibility)


Apply changes by restarting your terminal or running:
```bash
gacli update
```

---

## 🔄 Update

`GACLI` performs 4 steps while updating:
1. `brew update` → Updates `Homebrew` itself (core system and metadata)
2. `brew bundle --file=Brewfile` → Installs all `formulae` and `casks` listed in the Brewfile
3. `brew upgrade` → Upgrades all installed packages (if newer versions are available)
4. `brew cleanup` → Removes old versions and cached files to free up disk space

If auto-update is enabled and due, this is done automatically.

You can also run it manually:

```bash
gacli update
```

---

## 🧹 Uninstall

Run:

```bash
gacli uninstall
```

This will:
- Remove the `config` file
- Clean `~/.zshrc` entries created by `GACLI`

It will **NOT**:
- Uninstall `Homebrew`
- Uninstall any `formula` or `cask`
- Delete `gacli` folder

Feel free to remove those manually if you want to fully clean your environment.

---

Made with ❤️ by [guillaumeast](https://github.com/guillaumeast)
