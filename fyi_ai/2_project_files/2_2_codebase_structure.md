# Repository Structure Overview

## Repo structure

```bash
gacli/
├── .auto_install/
│   ├── install.zsh           # <----- 1. GACLI AUTO-INSTALLER
│   └── uninstall.zsh         # Uninstaller
├── gacli.zsh                 # <----- 2. GACLI ENTRY POINT
├── tools.yaml                # User tools descriptor (formulae, casks and modules)
├── .data/                    # Config files and dependencies descriptors
├── .helpers/                 # Scripts to manage files, date and Homebrew
├── .run/
│   ├── modules.zsh           # <----- 3. MODULES LOADER
│   └── update.zsh            # <----- 4. (AUTO) UPDATE PROCESS
├── modules/
│   └── ...                   # <----- 4. OPTIONAL MODULES (1 folder = 1 module)
└── sys_prompts/              # FYI: My personal prompts for LLMs assistants
```

## Module structure

```bash
gacli/
├── main.zsh                  # <----- 5. MODULE ENTRY POINT <-----
├── tools.yaml                # Dependencies descriptor (Formulae, casks and modules)
└── ...                       # Optional files
```
