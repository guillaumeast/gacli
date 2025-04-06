# 🚀 GACLI

✌️ *Managing and cloning your local dev environment has never been so easy* ⚡

✨ `GACLI` **automates** everything: `Homebrew`, `formulae`, `casks` and `status display`.

⏰ Choose an **auto-update** frequency, and `GACLI` takes care of the rest.

---

## 🧰 Features

- Automatically installs `Homebrew` if missing
- Installs all `formulae` and `casks` defined in the `Brewfile`
- Manages automatic updates with custom frequency defined in `.config`
- Displays each tool’s status (installed or not) at terminal startup
- Fully compatible with macOS and Linux


---

## ⚙️ Installation

```bash
git clone https://github.com/guillaumeast/gacli.git
cd gacli
zsh gacli.zsh
```

💡 No need to preinstall `Homebrew`, `coreutils` or anything else: `GACLI` detects and installs them if needed


---

## 🧠 How it works

1. `GACLI` asks your desired auto-update frequency, stored in `.config`
2. `GACLI` installs everything (`Homebrew`, `formulae`, `casks`) defined in the `Brewfile`
3. On every run, `GACLI` updates if needed and shows **tools status** 📊


---

## 🗂️ Structure

```
gacli/
├── Brewfile         # List of tools to install (formulae and casks)
├── .config          # Generated config file with update frequency
├── gacli.zsh        # Main script (command support, install and update trigger)
├── tools.zsh        # Utility functions (e.g. date computing)
├── style.zsh        # Styling & colors
├── install.zsh      # Installs GACLI (Homebrew + formulae + casks + .config file)
└── update.zsh       # Updates GACLI (Homebrew + formulae + casks + .config file) 
```


---

## 📜 Brewfile

Feel free to add `formulae` and `casks` to the `Brewfile`!

♻️ Make any changes at any time, then just restart your terminal or run:
```bash
gacli update
```

⚠️ `formulae` and `casks` removed from the `Brewfile` are **NOT** automatically uninstalled
<details>
<summary>🗑️ Uninstall formulae and casks</summary>

This is because it would also delete your previously installed `formulae` and `casks`

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

</details>  

<details>
<summary>📄 Minimal recommended Brewfile</summary>

```ruby
brew "jq"
brew "tree"
cask "iterm2"
```

</details>


---

## 📅 Update

📦 `Homebrew`, `formulae` and `casks` are updated at once so you don't have to deal with multiple command lines.

<details>
<summary>⏰ Auto-updates</summary>
  
  If the configured update date is reached, `GACLI` automatically performs an update.
  
  ⚠️ If `coreutils` is not installed, `GACLI` will skip the date check and disable auto-update.
  
</details>

<details>
<summary>👉 Manual updates</summary>
  
  ```bash
  gacli update
  ```

</details>

<details>
<summary>💡 See what update does</summary>
  
  `gacli update` runs the following `Homebrew` commands before updating the `next_update` date in the `.config` file :
  ```bash
  brew update
  brew bundle --file="<path>/Brewfile"
  brew upgrade
  brew cleanup
  ```

</details>


---

## 🧹 Uninstall

1. Delete the `gacli` folder
2. Remove the following lines from your `.zshrc` file:
```bash
# GACLI
source "/<path>/gacli/gacli.zsh"
alias gacli="zsh /<path>/gacli/gacli.zsh"
```

💡 Uninstalling `GACLI` will **NOT** uninstall `Homebrew`, `formulae` or `casks`.


---

Made with ❤️ by [guillaumeast](https://github.com/guillaumeast)
