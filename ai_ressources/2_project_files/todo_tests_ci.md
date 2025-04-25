# TODO — Test Framework & CI Setup

**Goal**: step‑by‑step discovery and implementation of a dual test strategy  
(POSIX for `install.sh`, Zsh for the rest) plus a CI pipeline covering macOS & Linux.

---

## Phase A · Understand the Basics
1. **What is a test framework?**  
   Learn its role, benefits, typical features (assertions, reporting).  
2. **What is Continuous Integration (CI)?**  
   Understand the pipeline: commit → build → test → report.

---

## Phase B · Choose the Tools
3. **Compare frameworks** (`bats-core`, `zunit`, `shunit2`)  
   Decide:  
   - POSIX code (`install.sh`) → **bats-core**  
   - Zsh code → **zunit**
4. **Confirm target environments**  
   - Local macOS  
   - Docker `ubuntu:latest` and others to cover various package managers (`apt`, `dnf`, `pacman`, `yum`)
   - GitHub Actions `macos-latest` & `ubuntu-latest`

---

## Phase C · Prepare Local Environment
5. **Install frameworks**  
   - `brew install bats-core` (macOS)  
   - Add `bats-core` & `zunit` to Brewfile for Linux
6. **Create test tree**  
   ```
   test/
   ├─ unit/posix/   # *.bats
   └─ unit/zsh/     # *.zunit
   ```
   Keep `test/parser/` temporary.

---

## Phase D · Port & Extend Tests
7. **Re‑write parser tests in zunit**  
   One test per private function (`_json_read`, `_brew_add`, …).  
8. **Write bats tests for install.sh**  
   Cases: Homebrew present/absent, deps missing, `--force`.
9. **Add unit tests for `time.zsh` & `brew.zsh`**

---

## Phase E · Set Up CI (GitHub Actions)
10. **Create workflow `.github/workflows/ci.yml`**  
    - OS matrix `macos-latest`, `ubuntu-latest`  
    - Steps: checkout → set up Homebrew/apt → `brew bundle` → install frameworks → run tests
11. **(Optional) Docker job for ubuntu** if matrix lacks needed packages.
12. **Publish test reports**  
    - Upload TAP artifacts (`bats-core`)  
    - Same for zunit or summary in logs

---

## Phase F · Validate & Measure
13. **Run CI until green**  
14. **Review coverage** (manual) and plan extra tests.

