# Repository Structure Overview

## Repo structure

```bash
gacli/
├── .auto_install/
│   ├── Brewfile                    # GACLI dependencies descriptor
│   ├── install.sh                  # <----- 1. GACLI AUTO-INSTALLER
│   └── uninstall.zsh               # Uninstaller
├── gacli.zsh                       # <----- 2. GACLI ENTRY POINT
├── tools.yaml                      # User tools descriptor (formulae, casks and modules)
├── .data/                          # Config files and dependencies descriptors
│   ├── config/
│   │   └── update.config.yaml
│   └── tools/
│       ├── core.tools.yaml
│       └── modules.tools.yaml
├── .helpers/                       # Scripts to manage files, date and Homebrew
│   ├── time.zsh
│   ├── parser.zsh
│   └── brew.zsh
├── .run/
│   ├── modules.zsh                 # <----- 3. MODULES LOADER
│   └── update.zsh                  # <----- 4. (AUTO) UPDATE PROCESS
└── modules/
    └── ...                         # <----- 5. OPTIONAL MODULES (1 folder = 1 module)
```

## Module structure

```bash
gacli/
├── main.zsh                  # <----- 6. MODULE ENTRY POINT <-----
├── tools.yaml                # Dependencies descriptor (Formulae, casks and modules)
└── ...                       # Optional files
```
