# Repository Structure Overview

## Repo structure for LLM

```bash
gacli/
├── installer/
│   ├── Brewfile                    # GACLI dependencies descriptor
│   └── install.sh                  # <----- 1. GACLI AUTO-INSTALLER
├── src/
│   ├── main.zsh                    # <----- 2. GACLI ENTRY POINT
│   ├── data/                       # static JSON (config files, dependencies descriptors)
│   │   ├── config/
│   │   │   └── update.config.json
│   │   └── tools/
│   │       ├── core.tools.json
│   │       ├── user.tools.json
│   │       └── modules.tools.json
│   ├── helpers/                    # basic stateless utilities (files, date, Homebrew tools)
│   │   ├── brew.zsh
│   │   ├── parser.zsh
│   │   └── time.zsh
│   ├── logic/                      # <----- 3. ORCHESTRATION LOGIC (modules, update, uninstall)
│   │   ├── modules.zsh
│   │   ├── update.zsh
│   │   └── uninstall.zsh
│   ├── modules/                    # <----- 4. OPTIONAL DYNAMIC MODULES   
│   │   └── ...                     # 1 folder = 1 module
│   └── .tmp/                       # temporary files (runtime generated)
└── test/                           # bats-core test scripts
    └── unit/
        └── ...                     # Mirroring "src" folder structure
```

## Repo structure for README

```bash
gacli/
├── installer/
│   ├── Brewfile                    # GACLI dependencies descriptor
│   └── install.sh                  # <----- 1. GACLI AUTO-INSTALLER
├── src/
│   ├── main.zsh                    # <----- 2. GACLI ENTRY POINT
│   ├── data/                       # static JSON (config files, dependencies descriptors)
│   ├── helpers/                    # basic stateless utilities (files, date, Homebrew tools)
│   ├── logic/                      # <----- 3. ORCHESTRATION LOGIC (modules, update, uninstall)
│   ├── modules/                    # <----- 4. OPTIONAL DYNAMIC MODULES
│   │   └── ...                     # 1 folder = 1 module
│   └── .tmp/                       # temporary files (runtime generated)
└── test/                           # bats-core test scripts
    └── unit/
        └── ...                     # Mirroring "src" folder structure
```

## Module structure

```bash
gacli/
├── main.zsh                        # <----- 5. MODULE ENTRY POINT <-----
├── tools.yaml                      # Dependencies descriptor (Formulae, casks and modules)
└── ...                             # Optional files
```

