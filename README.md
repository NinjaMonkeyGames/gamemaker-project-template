# GAMEMAKER TEMPLATE PROJECT NAME HERE

<!-- markdownlint-disable MD013 -->
[![Common Changelog](https://common-changelog.org/badge.svg)](https://common-changelog.org)
![Signed Commits](https://img.shields.io/badge/commits-signed-blue.svg)
![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)
![GitHub Release](https://img.shields.io/github/v/release/NinjaMonkeyGames/project_name_here)
<!-- markdownlint-enable MD013 -->
---

## TABLE OF CONTENTS

- [GAMEMAKER TEMPLATE PROJECT NAME HERE](#gamemaker-template-project-name-here)
  - [TABLE OF CONTENTS](#table-of-contents)
  - [SUMMERY DESCRIPTION](#summery-description)
  - [WHAT IS THE PURPOSE OF THIS PROJECT ?](#what-is-the-purpose-of-this-project-)
  - [WHO IS THIS REPOSITORY FOR ?](#who-is-this-repository-for-)
  - [QUICKSTART](#quickstart)
  - [API OVERVIEW](#api-overview)
  - [ENVIRONMENT DEPENDENCY MANIFESTO](#environment-dependency-manifesto)
    - [GAMEMAKER](#gamemaker)
    - [IDE](#ide)
      - [VSC (Visual Studio Codium)](#vsc-visual-studio-codium)
      - [VSC EXTENSIONS](#vsc-extensions)
    - [CI TOOLS](#ci-tools)
    - [SUPPORTING TOOLS](#supporting-tools)
  - [INSTALLATION](#installation)
  - [USAGE](#usage)
  - [SUPPORTING DOCUMENTATION](#supporting-documentation)
  - [KNOWN ISSUES](#known-issues)
  - [CONTACT INFORMATION](#contact-information)
  - [COPYRIGHT](#copyright)

---

## SUMMERY DESCRIPTION

Replace this with a short description of what the project is...

---

## WHAT IS THE PURPOSE OF THIS PROJECT ?

The purpose of this project is...

---

## WHO IS THIS REPOSITORY FOR ?

This project is for anyone who...

---

## QUICKSTART

Quickstart information here...

---

## API OVERVIEW

Example, replace with relivenet API information.

| Method                    | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| `get_x([_x])`             | Returns the column index under the given X coordinate (mouse X by default). |
| `get_y([_y])`             | Returns the row index under the given Y coordinate (mouse Y by default).    |
| `shift_x(_value)`         | Shifts the visible columns left/right.                                      |
| `shift_y(_value)`         | Shifts the visible rows up/down.                                            |
| `update_row(_value)`      | Changes the number of rows.                                                 |
| `update_column(_value)`   | Changes the number of columns.                                              |
| `zoom([_zoom_direction])` | Zooms in (`true`) or out (`false`) while preserving on-screen grid size.    |
| `set_coords()`            | Highlights the row/column labels under the current mouse position.          |
| `set_cursor()`            | Sets the mouse pointer graphic depending on whether it's over the grid.     |
| `step()`                  | Handles default mouse-wheel zoom and arrow-key panning input.               |
| `draw()`                  | Draws the grid lines, labels, and any tile data.                            |
| `destroy()`               | Frees GPU resources and removes the instance from `global.grid_list`.       |

## ENVIRONMENT DEPENDENCY MANIFESTO

### GAMEMAKER

- GameMaker version: `2026.0.0.16`
- Runtime version: `2026.0.0.23`
- Target platforms: Windows, Linux

### IDE

#### VSC (Visual Studio Codium)

Version: 1.121.03429
Commit: 824c4c46a288b839f13b24022655329c2aeb9f81
Date: 2026-05-19T23:32:58Z
Electron: 39.8.8
ElectronBuildId: undefined
Chromium: 142.0.7444.265
Node.js: 22.22.1
V8: 14.2.231.22-electron.0
OS: Linux x64 6.12.105+deb13-amd64

#### VSC EXTENSIONS

| Extension Name                                                    | Version   |
| ----------------------------------------------------------------- | --------- |
| streetsidesoftware.code-spell-checker                             | 4.7.3     |
| streetsidesoftware.code-spell-checker-cspell-bundled-dictionaries | 2.0.15    |
| github.vscode-github-actions                                      | 0.32.3    |
| yzhang.markdown-all-in-one                                        | 3.6.2     |
| davidanson.vscode-markdownlint                                    | 0.62.1    |
| redhat.vscode-yaml                                                | 1.24.0    |
| joshbolduc.commitlint                                             | 2.6.3     |

### CI TOOLS

| Tool                                  | Version                           |
|---------------------------------------|-----------------------------------|
| npm                                   | 11.18.0                           |
| cSpell                                | 10.2.2                            |
| Markdownlint-Cli2                     | 0.23.0                            |
| Markdownlint                          | 0.41.0                            |
| Commitlint                            | 21.2.2                            |
| Commitlint config-conventional        | 21.2.2                            |

### SUPPORTING TOOLS

Local tool versions.

| Tool                           | Version               |
|--------------------------------|-----------------------|
| NPM                            | 11.18.0               |
| Node                           | 24.11.1               |
| GitHub Desktop                 | 3.4.9-linux1 (x64)    |
| Git                            | 2.47.3-0+deb13u1      |

## INSTALLATION

1. Clone the repository.
2. Open `project-name.yyp` in GameMaker.
3. Open the demo room.
4. Run the project using the target platform of your choice.

## USAGE

Provide example API usage examples here...

## SUPPORTING DOCUMENTATION

- CONTRIBUTING.md
- CHANGELOG.md
- DEVELOPER.md
- LICENSE.md
- README.md

## KNOWN ISSUES

There are currently no known limitations or bugs...

## CONTACT INFORMATION

Author: Daniel Mallett (Monkey Knuckles)

If you have any problems with the repository or have any suggestions please contact us at <info@ninjamonkeygames.com>.

You may also contact us via our [website](https://ninjamonkeygames.com).

Any bugs should be raised as an [issue](https://github.com/NinjaMonkeyGames/grid-utility-professional/issues) on
GitHub.

---

## COPYRIGHT

*NinjaMonkeyGames™ Copyright © 2026 All rights reserved.*

