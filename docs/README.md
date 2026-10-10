# Developer documentation

Built for my own 3D printers, the toolkit separates shared helpers, menu registration, and action execution so new printer features can reuse the same environment and interface. Its inspiration is Creality Helper Script.

- [Action API and shared functions](actions.md)
- [Configuration and updates](configuration.md)
- [Binary files](bin-files.md)
- [Extra macros: setup and usage](extra-macros.md)
- [Project overview](../README.md)

## Startup lifecycle

1. `main.sh` resolves and makes `PROJECT_ROOT` read-only, then sources the project-local `.env` if present.
2. It applies the `--interactive` command-line option after `.env`, rejects unknown options, clears `TOOLKIT_ENV_READY` and initializes the `ACTIONS` registry and `ACTION_COUNT`.
3. Top-level `modules/*.sh` files are sourced in filename order. Numeric filename prefixes establish dependencies.
4. `detect_model`, `select_printer`, and `set_paths` initialize the selected printer and paths.
5. `TOOLKIT_READY` is set to `1` and made read-only. `run_printer_selection_actions` runs startup hooks.
6. Top-level `menue/*.sh` files are sourced to register actions.
7. Unless disabled, `update_menu` checks for updates and offers confirmation.
8. The main menu dispatches categories to `show_action_menu`; Self Update calls `update_menu` directly.

A failed module, menu file, or startup hook stops startup. Leaving printer selection exits normally.

## Startup hooks

For every model except `generic`, scripts in `actions/on-select/all-printers/` run first. Scripts in `actions/on-select/<PRINTER_MODEL>/` run next, including for `generic`. Each directory is processed in filename order; only top-level `.sh` files are sourced. Missing directories are skipped.

Hooks run once per startup, even when `.env` selected the model. They share the main shell, loaded helpers, and initialized paths. Returning a nonzero status aborts startup. The model must contain only letters, digits, underscores, or hyphens and cannot be empty, `.` or `..`.

Unlike menu actions, hooks run automatically and can change the printer. The current shared hook contains operations to create a `3dp` symlink, remove `/root/.cache`, set permissions, and conditionally copy a factory-reset service. It requires `TOOLKIT_READY=1`, which the entry point sets before running hooks.

## Extension conventions

Keep reusable functions in `modules/`, registrations in `menue/`, and application operations in `actions/`. Use POSIX shell syntax and BusyBox-compatible utilities. Modules and menu files should define helpers or register actions when sourced; put maintenance operations inside selected actions or deliberate startup hooks.

Use `PROJECT_ROOT`, `S_ACTIONS`, and `S_FILES` for project resources so callers need not start in the project directory. Menu actions run in a subshell: variable changes do not propagate back, but filesystem changes persist.
