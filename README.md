# 🚀 GACLI

✌️ *Managing and cloning your local dev environment has never been so easy* ⚡

✨ `GACLI` **automates** everything: `Homebrew`, `formulae`, `casks` and `status display`.

⏰ Choose an **auto-update** frequency, and `GACLI` takes care of the rest.

---

## 🧰 Features

- Automatically installs `Homebrew` if missing
- Installs all tools defined in the `Brewfile`
- Manages automatic updates with custom frequency defined in `.config`
- Displays each tool’s status (installed or not) at terminal startup
- Partial support for Linux (built-in fallbacks)


---

## 🗂️ Structure

```
gacli/
├── Brewfile         # List of tools to install (formulae and casks)
├── .config          # Generated config file with update frequency
├── main.zsh         # Main script
├── tools.zsh        # Utility functions (e.g. date computing)
├── style.zsh        # Styling & colors
├── install.zsh      # Installs GACLI (Homebrew + formulae + casks + .config file)
└── update.zsh       # Updates GACLI (Homebrew + formulae + casks + .config file) 
```


---

## ⚙️ Installation

```bash
git clone https://github.com/guillaumeast/gacli.git
cd gacli
zsh main.zsh
```

No need to preinstall `Homebrew`, `coreutils` or anything else: `GACLI` detects and installs them if needed 💡


---

## 🧠 How it works

1. `GACLI` asks your desired auto-update frequency (in days), stored in `.config`
2. `GACLI` installs everything (`Homebrew`, `formulae`, `casks`) defined in the `Brewfile`
3. On every run, `GACLI` updates if needed and shows **tools status** 📊


---

## 📜 Brewfile

Feel free to add or remove `formulae` and `casks` from the `Brewfile`!

♻️ Make any changes at any time, then just restart your terminal or run:
```bash
update_tools
```

📄 Here is an example of a minimalist recommended `Brewfile`:
```ruby
brew "jq"
brew "tree"
cask "iterm2"
```


---

## 📅 Update

⏰ If the configured update date is reached, `GACLI` automatically performs an update.
⚠️ If `coreutils` is not installed, `GACLI` will skip the date check and disable auto-update.

👉 You also can manually update at any time simply by running:
```bash
update_tools
```

📦 `Homebrew`, `formulae` and `casks` are updated at once so you don't have to deal with multiple command lines.

💡 `update_tools` runs the following `Homebrew` commands before updating the `next_update` date in the `.config` file :
```bash
brew update
brew bundle --file="<path>/Brewfile"
brew upgrade
brew cleanup
```

⚠️ `formulae` and `casks` removed from the `Brewfile` are **NOT** automatically uninstalled  
(because it would also delete your previously installed `formulae` and `casks`)

To remove them manually, you can run the following commands:
```bash
# Uninstall a formula
brew uninstall <formula_name>

# Uninstall a cask
brew uninstall --cask <cask_name>
```

Or, to uninstall all `formulae` and `casks` that are **NOT** in the `Brewfile`:
```bash
brew bundle --file="<path>/Brewfile" --cleanup
```

---

## 🧹 Uninstall

1. Delete the `gacli` folder
2. Remove the following lines from your `.zshrc` file:
```txt
# GACLI
export PATH="$PATH:/<path>/gacli"
source "/<path>/gacli/main.zsh"
```

💡 Uninstalling `GACLI` will **NOT** uninstall `Homebrew`, `formulae` or `casks`.


---

Made with ❤️ by [guillaumeast](https://github.com/guillaumeast)
