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
- Shows **tools status** on launch
- 100% compatible with `macOS` and `Linux`

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

When possible, dependencies are automatically installed using `curl` `Homebrew` or your system’s package manager (`apt`, `dnf`, `pacman`, etc.).

- `curl`
  - macOS: preinstalled
  - Linux: auto-installed via your `system's package manager`

- `git`
  - macOS: auto-installed via `xcode-select --install`
  - Linux: auto-installed via your `system's package manager`

- `Homebrew`
  - Auto-installed via `curl`

- `coreutils`  
  - Auto-installed via `Homebrew`

</details>

### Available options

| Option       | Description                                                                    |
|--------------|--------------------------------------------------------------------------------|
| `--custom`   | Choose a custom installation folder (default: `~/.gacli`)                      |
| `--force`    | Overwrite an existing installation (useful for manual updates)                 |

**Combined example**:

```bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/guillaumeast/gacli/refs/heads/master/modules/.install/install.zsh)" -- --custom ~/Repos/gacli --force
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
7. Performs `auto-update` if needed
8. Shows a `status summary` at terminal startup

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
│   └── user_modules                   # Optional user modules (1 folder = 1 module)
```

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

## 🧩 Modules

`GACLI` is fully modular: each optional command is defined in a separate module.

You can add new modules by:
1. Creating a `.zsh` file in `modules/user_modules/<your_module>/`
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

