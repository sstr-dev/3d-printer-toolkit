# Configuration and self updates

## Settings loading

`main.sh` sources `.env` from `PROJECT_ROOT` before loading modules. Assignments there override inherited environment values. Because the file is sourced as shell code, use trusted POSIX shell assignments and quote values containing spaces. Missing or empty defaulted settings use the defaults described below.

`.env.example` selects `K1C`. Without an explicit model, `PRINTER_MODEL` defaults to `unknown`; the current detection implementation leaves it unknown and prompts for selection.

| Model | Current behavior |
| --- | --- |
| `K1C` | Pre-2025 K1C paths and registered application actions |
| `K1_2025` | 2025 series paths; current Moonraker/nginx/tool/customization registrations exclude this model |
| `generic` | Project-local development paths; skips shared printer startup hooks; current placeholder actions are registered |
| `K1` | Can be configured explicitly, but its selection handler is disabled and it uses fallback local paths |
| `unknown` | Requests printer selection after the incomplete detection step |

The current application, backup, and hostname actions are restricted to `K1C generic`. Info is registered for every model. These settings describe implementation, not validated hardware support.

## Menu navigation

Menus use numbered prompts with a header, bordered options, and footer. Back/Exit options are separated from actions. Enter a displayed key and press Enter.

Supported terminals are cleared when opening a menu or action. After an action, menus wait for Enter before returning to the menu when stdin is a terminal. Piped input skips this pause. Redirected menu output contains no screen-clearing sequences.

| Setting | Default | Description |
| --- | --- | --- |
| `MENU_WIDTH` | `64` | Width inside the border, from `20` to `200`; invalid values use `64`. Full lines are two characters wider |
| `MENU_OUTER_CHAR` | `=` | Character used for the top and bottom borders |
| `MENU_INNER_CHAR` | `-` | Character used for separators |
| `NO_COLOR` | Unset | Setting any value disables named text colors |

Use single characters for borders. Width is fixed rather than automatically fitted to the terminal.

## Paths

`PROJECT_ROOT` is the entry point's directory, independent of the caller's working directory. `set_paths` uses the following defaults, with overrides supported through environment variables or `.env`:

| Variable | K1C | K1_2025 | Generic and other models |
| --- | --- | --- | --- |
| `USR_DATA` | `/usr/data` | `/usr/data` | `PROJECT_ROOT/.local/usr/data` |
| `USR_SHARE` | `/usr/share` | `/usr/share` | `PROJECT_ROOT/.local/usr/share` |
| `INITD_FOLDER` | `/etc/init.d` | `/usr/apps/etc/init.d` | `PROJECT_ROOT/.local/etc/init.d` |
| `BIN_FOLDER` | `/usr/bin` | `/usr/apps/usr/bin` | `PROJECT_ROOT/.local/usr/bin` |

Derived paths also support overrides:

| Variable | Default |
| --- | --- |
| `PRINTER_DATA_FOLDER` | `USR_DATA/printer_data` |
| `PRINTER_DATA_CONFIG_FOLDER` | `PRINTER_DATA_FOLDER/config` |
| `PRINTER_DATA_LOG_FOLDER` | `PRINTER_DATA_FOLDER/logs` |

`S_FILES` and `S_ACTIONS` are always set to the project's `files` and `actions` directories. Path initialization does not create directories.

## Self updates

| Variable | Default | Purpose |
| --- | --- | --- |
| `UPDATE_CHECK_ON_START` | `1` | Only `1` enables startup checking; `0` skips it and leaves Self Update hidden. `--no-update-check` overrides this to `0` for one run |
| `UPDATE_BRANCH` | `main` | Branch eligible for updates |
| `UPDATE_REMOTE` | `origin` | Git remote to fetch |
| `UPDATE_LOW_SPEED_LIMIT` | `1` | HTTP low-speed threshold in bytes per second |
| `UPDATE_LOW_SPEED_TIME` | `15` | Duration below the threshold before an HTTP fetch aborts |

Checks require Git, a project `.git` directory, and a current branch matching `UPDATE_BRANCH`. A worktree with a `.git` file is skipped. The configured branch is fetched quietly; missing configuration or failed checks leave the menu available. No remote repository URL is hard-coded. The low-speed settings are not a total fetch timeout.

Any difference between the current commit and `FETCH_HEAD` marks an update available, even if history has diverged or the local branch is ahead. Applying the update still requires a clean checkout and a successful fast-forward merge. The update prompt accepts `1` or `y` to apply, `0`, `b`, or `n` to return, and `q` to exit.

Self Update is shown only after an update is detected and checks again when selected. Restart the toolkit after updating so changed modules and registrations are loaded.
