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
└── tests/                          # bats-core test scripts
    ├── unit/                       # zunit unit tests
    ├── _output_/                   # zunit tap reports
    ├── _support_/                  # zunit bootstrap script
    └── fixture/                    # tests ressources
```

## Repo structure for README

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

### Module anatomy

```bash
my_module/
├── main.zsh        # <----- 5. MODULE ENTRY POINT (may implement get_commands)
├── tools.json      # formulae / casks / nested modules
└── …               # optional helpers, docs, etc.
```

