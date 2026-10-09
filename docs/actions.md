# Actions and shared functions

## Register an action

Use `register_action` in a `menue/*.sh` file. It adds a menu entry; it does not run the action.

| Position | Name | Description |
| --- | --- | --- |
| 1 | Label | Required menu text |
| 2 | Target | Required existing function or readable script path |
| 3 | Category | `install`, `remove`, `info`, `update`, `tools`, or `customize`; defaults to `info` |
| 4 | Printer models | Optional model names separated by spaces; empty means all models |

Labels and targets cannot contain pipes or newlines. Function names must use letters, digits, or underscores and cannot start with a digit. Define the function before registering it.

Script paths must start with `/`, `./`, or `../`. Prefer paths based on `S_ACTIONS` or `PROJECT_ROOT`. Scripts must be readable; executable permission is not needed.

Model names are case-sensitive. An action for another model is skipped. Registration returns `0` when added or skipped, and `1` for invalid input. Each submenu numbers its available actions from one.

## Run an action

The selected function or script always receives its category as `$1`. Moonraker uses `install` or `remove` to choose the operation. Scripts such as `install-nginx.sh` can ignore it. There is no extra argument to configure.

Actions run in a subshell with the toolkit's helpers and settings available. Variable changes stay inside that shell; file changes persist. Scripts should check `TOOLKIT_READY=1` and be started through the menu.

Return `0` for success and a nonzero status for failure. Status `130` exits the menu; other failures show an error and leave the submenu open. When input comes from a terminal, both navigation modes wait for Enter after an action.

See [application registrations](../menue/20-applications.sh) and the [Info action](../menue/10-information.sh) for existing usage.

Self Update calls `update_menu` directly. Although `update` is a valid category, extra actions registered there are not displayed by the main menu.

## Function comments

Shell functions have no built-in docstring format. This project uses short `#` comment blocks directly above its main functions. They describe the purpose, arguments, return status, and shared variables where useful. These comments need no documentation tool.

## Shared helpers

| Function | Description |
| --- | --- |
| `detect_model` | Sets `OS_NAME`, `ARCHITECTURE`, and the initial `PRINTER_MODEL`; automatic detection is currently incomplete |
| `select_printer` | Prompts when `PRINTER_MODEL` is `unknown`; returns nonzero when selection is cancelled |
| `set_paths` | Initializes printer and project paths without creating directories |
| `run_printer_selection_actions` | Validates the model and sources shared/model startup hooks; stops on failure |
| `detect_printer_information` | Populates `PRINTER_SN`, `PRINTER_VERSION`, and `PRINTER_IPS` where available |
| `detect_system_information` | Populates hostname, kernel, memory, uptime, load, and disk values in `SYSTEM_*` variables |
| `menu_interactive` | Succeeds when `MENU_INTERACTIVE=1`, stdin and stderr are terminals, and `TERM` is not `dumb` |
| `menu_select` | Accepts a title and newline-separated key/label records separated by pipes; renders to stderr and prints the selected key to stdout; returns `130` on cancellation/input failure |
| `show_action_menu` | Accepts a category and title; dispatches selections, handles failures and back/exit navigation |
| `menu_run` | Clears the display when appropriate and executes the supplied target and arguments in a subshell |
| `menu_pause` | Waits for Enter when stdin is a terminal; returns `130` on input failure |
| `menu_clear` | Clears supported terminal displays in both navigation modes |
| `menu_header`, `menu_option` | Render shared headers and options for both navigation modes; `menu_option` accepts `selected` as its second argument |
| `menu_line` | Renders text and an optional named color, truncating to the configured width |
| `system_line` | Renders a label, value, and optional color; omits empty/unavailable values and wraps long lines |
| `hr`, `top_line`, `outer_line`, `inner_line` | Draw menu borders; `hr` accepts fill, left-edge, and right-edge characters |
| `check_self_update` | Resets update state, fetches the configured branch when eligible, and sets `UPDATE_AVAILABLE` and `UPDATE_TARGET`; prints `true` when heads differ |
| `apply_self_update` | Requires a clean checkout, merges `UPDATE_TARGET` with `--ff-only`, and makes `main.sh` executable |
| `update_menu` | Checks availability, asks for confirmation, and applies an update; returns `130` when exiting |

Both navigation modes use `menu_header`, `menu_option`, and border helpers. Presentation helpers write to stderr so selection output can be captured separately. Menu styling uses `MENU_WIDTH` (default `64`, valid range `20`–`200`), `MENU_OUTER_CHAR` (default `=`), and `MENU_INNER_CHAR` (default `-`). Setting `NO_COLOR` disables named colors in `menu_line`.

`set_permissions` starts a background permission update for the executable referenced by `CURL`, if configured for a non-generic model. It does nothing for `generic` or when `CURL` is empty; background failures are not reported to the caller.
