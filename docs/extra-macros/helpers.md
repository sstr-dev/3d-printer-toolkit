# Debugging, spool tracking and compatibility

[Extra macros](README.md) · [Setup](setup.md)

## Search printer variables

Enable `miscs/debugging.cfg`, then search status paths by a case-insensitive substring:

```gcode
_SEARCH_VARS S=extruder
```

`S` is required. Matching paths and nested leaf values appear in the console. This only reads status; it does not modify variables.

## Track a spool

Enable **either** `helpers/spoolman.cfg` **or** `helpers/filaman.cfg`. Both define the same commands and require their matching Moonraker component to provide the remote method.

```gcode
SET_ACTIVE_SPOOL ID=123
CLEAR_ACTIVE_SPOOL
```

Replace `123` with your spool ID. Set it when selecting a spool; clear it when unloading or stopping tracking. These calls update the backend's active spool and do not physically load/unload filament. An unknown remote-method error means the corresponding Moonraker integration is unavailable.

## Compatibility aliases

Enable `miscs/compatibility.cfg` only after checking for macro-name conflicts in your existing configuration.

| Alias | Behavior |
| --- | --- |
| `M701`, `M702` | Call `LOAD_FILAMENT`, `UNLOAD_FILAMENT` |
| `M600`, `M125` | Call `CHANGE_FILAMENT`, `PARK` |
| `M900 K=0.035` | Set pressure advance; optional `E` is a Klipper extruder name |
| `M204 S=3000` | Set acceleration; original command renamed `M204.1`; P/T parameters are not handled |
| `M205 X=5` | Set square corner velocity; Y is used only when X is absent |
| `G00`, `G01`, `G02`, `G04` | Forward parameters to `G0`, `G1`, `G2`, `G4` |
| `G03` | Currently forwards to clockwise `G2`, not counterclockwise `G3`; unsuitable for G-code expecting normal G03 behavior |

Filament and parking aliases require those target macros and do not forward parameters. Arc commands require `[gcode_arcs]`.
