# 3D Printer Toolkit

A modular shell toolkit for my 3D printers. It includes application setup, maintenance, and customization, inspired by the popular **Creality Helper Script**.

## Why this project exists

I built this toolkit for my own 3D printers. It brings application setup, maintenance, and customization into one menu and can grow with the tools I use. 

## Current status

This is work in progress. 

## Usage

The entry point is `main.sh`, invoked with `sh` using its full path when outside the project directory. Copy `.env.example` to `.env` to configure startup. Its default model is `K1C`; choose `generic` for development. Settings are shell code and must be trusted. See [configuration](docs/configuration.md) for current variable names and defaults.

Menus use numbered prompts by default, with a shared header, bordered options, and a footer. Set `MENU_INTERACTIVE=1` in `.env` or pass `--interactive` to `main.sh` to enable arrow keys or `j`/`k` and Enter to select. Interactive navigation requires a terminal; piped input always uses numbered prompts. Use `b` to return from a submenu and `q` to exit. When using a terminal, action output remains visible until Enter is pressed, in both numbered and interactive modes. The menu header shows the selected printer model. Changing menus clears supported terminals; action output is cleared only after the Enter prompt. Menu width, border characters, and colors can be configured in `.env`.

| Main menu key | Destination |
| --- | --- |
| 1 | Install / Update |
| 2 | Remove |
| 3 | Tools |
| 4 | Customize |
| 5 | Info |
| 6 | Self Update, only when an update is detected |
| 0 | Exit |

## Project layout

| Path | Purpose |
| --- | --- |
| `main.sh` | Startup and main menu routing |
| `modules/` | Shared shell functions, sourced in filename order |
| `menue/` | Action registrations, sourced after printer initialization |
| `actions/` | Scripts executed when an action is selected |
| `actions/on-select/` | Automatic startup hooks for selected printers |
| `files/` | Assets and configuration templates |
| `docs/` | Architecture, configuration, and function reference |

## Documentation

- [Startup lifecycle](docs/README.md)
- [Action registration and shared functions](docs/actions.md)
- [Printer settings, paths, and self updates](docs/configuration.md)
