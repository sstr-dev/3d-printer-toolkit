# Extra macros

The macros in `files/macros/extra/` provide flow and pressure advance calibration, motion testing, status inspection, G-code compatibility and spool tracking. Run commands from the Fluidd/Mainsail console after enabling the corresponding files.

## Enable the macros

### Automatic installation with the setup

1. Run the toolkit setup, select your K1/K1C printer, and choose **Customize → Extra macros → Install**.
2. Setup links the macro files into `3dp-toolkit/macros/` under the printer configuration directory, creates `3dp-toolkit/macros_loader.cfg` if it does not exist, and adds `[include 3dp-toolkit/macros_loader.cfg]` to `printer.cfg` if needed.
3. Setup restarts Klipper to activate the loader. Calibration macros are enabled by default.
4. To enable an optional feature, edit `3dp-toolkit/macros_loader.cfg`, uncomment its include, and restart Klipper.

Update through the same menu. Setup preserves an existing loader and its selections, links missing macro files and restarts Klipper. The linked files depend on the toolkit checkout remaining in place. Existing destination files are preserved.

### Manual installation without the setup

1. Download or copy the repository's `files/macros/extra/` files. No setup execution is required.
2. In the directory containing your printer's `printer.cfg`, create `macros/`. Copy the `calibration/`, `miscs/` and `helpers/` directories into it, keeping their names and `.cfg` files.
3. Copy the [loader template](../files/macros/extra/loader.cfg), named `loader.cfg`, beside `printer.cfg` as **`macros_loader.cfg`**.
4. Add the following to `printer.cfg`, above any generated `SAVE_CONFIG` block:

   ```ini
   [include macros_loader.cfg]
   ```

5. Edit `macros_loader.cfg` to select optional features, then restart Klipper. Calibration macros are already enabled in the template.

The manual layout is:

```text
printer.cfg
macros_loader.cfg
macros/
  calibration/*.cfg
  miscs/*.cfg
  helpers/*.cfg
```

For manual updates, replace the copied macro files with the new versions while keeping your edited loader. Restart Klipper afterwards. Use one installation method to avoid loading duplicate macros.

Paths in the loader are relative to its location. Do not include the same macros twice through another file or wildcard. Choose only one spool provider. Keep personal macros in a separate file and include that from your local loader.

| Loader selection | Commands | Prerequisites |
| --- | --- | --- |
| `calibration/calib*.cfg` | `CALIBRATE`, `FLOW_MULTIPLIER_CALIBRATION`, `COMPUTE_FLOW_MULTIPLIER`, `PRESSURE_ADVANCE_CALIBRATION` | Print preparation; additional dependencies for `CALIBRATE` below |
| `calibration/test_speed.cfg` | `TEST_SPEED` | `_TILT_CALIBRATE`, clear motion area |
| `miscs/debugging.cfg` | `_SEARCH_VARS` | Klipper status objects |
| `miscs/compatibility.cfg` | M-code and zero-padded G-code aliases | Existing filament/parking macros; arc support |
| `helpers/spoolman.cfg` or `helpers/filaman.cfg` | `SET_ACTIVE_SPOOL`, `CLEAR_ACTIVE_SPOOL` | Matching Moonraker integration |

## Prepare for calibration

Use the filament, nozzle and temperatures you intend to print with. Before calling a standalone flow or pressure advance macro, home the printer, perform your normal leveling/Z-offset preparation, load the appropriate bed mesh and heat the bed and nozzle. These two macros do not perform print startup or shutdown; use your printer's own preparation and finishing routine.

`CALIBRATE` wraps preparation, calibration and `END_PRINT`, but depends on a compatible `_USER_VARIABLES` macro and `START_PRINT`/`END_PRINT` accepting the arguments used in [calibrate.cfg](../files/macros/extra/calibration/calibrate.cfg). It is not a universal stock-printer command.

For a configuration that meets those requirements:

```gcode
CALIBRATE TYPE=flow BED_TEMP=60 EXTRUDER_TEMP=210 MATERIAL=PLA
CALIBRATE TYPE=pressure_advance BED_TEMP=60 EXTRUDER_TEMP=210 MATERIAL=PLA
```

Run one calibration at a time and remove the previous print. The temperatures above are examples; select values suitable for your filament.

| Wrapper parameter | Default | Meaning |
| --- | --- | --- |
| `TYPE` | Required | `flow` or `pressure_advance` |
| `BED_TEMP`, `EXTRUDER_TEMP` | `_USER_VARIABLES` print defaults | Target temperatures in °C |
| `MATERIAL` | `ABS` | Material passed to `START_PRINT` |
| `TOOL` | `0` | MMU tool; an already loaded tool takes precedence when MMU is enabled |

The wrapper uses a 40 mm flow area with `EXTRUSION_WIDTH=0.471`, or a 120 mm PA area. It does not forward other tuning parameters: call the standalone macros for those.

## Flow: print, measure, calculate

![Hollow shell used for flow calibration](images/flow_calibration.png)

1. Prepare the printer as above, then run `FLOW_MULTIPLIER_CALIBRATION` (or the flow wrapper).
2. Note the theoretical shell thickness reported in the console. After the print, measure the average wall thickness using a micrometer or caliper.
3. Supply your actual measurement in millimeters:

   ```gcode
   COMPUTE_FLOW_MULTIPLIER MEASURED_THICKNESS=0.78
   ```

4. Apply the reported **NEW COMPUTED FLOW VALUE** as the extrusion multiplier/flow ratio in your slicer. The macro only reports the value; it does not save a slicer setting.

Do not restart Klipper between printing and computing: the print's multiplier and theoretical thickness are stored in memory. If they are lost, provide `OLD_EXTRUSION_MULTIPLIER` and `THEORICAL_THICKNESS` as well, using the values from that print. The spelling `THEORICAL_THICKNESS` is intentional in this implementation.

The calculation is `new multiplier = theoretical thickness × old multiplier / measured thickness`.

### Flow parameters

Dimensions and filament lengths are millimeters; speeds are mm/s. Defaults below match the code in this repository.

| Parameter | Default | Purpose |
| --- | --- | --- |
| `DO_RAFT` | `1` | Print a supporting base; `0` disables it |
| `DO_RECTRACT` | `0` | Enable travel retraction with `1`; use this exact spelling, not `DO_RETRACT` |
| `PRINT_SIZE`, `HEIGHT` | `40`, `15` | Footprint size and shell height |
| `CORNER_RADIUS` | `8` | Rounded outer corners |
| `PERIMETERS` | `2` | Wall count; a single wall needs more precise measurement |
| `FAN_SPEED` | `20` | Part cooling percentage after the raft |
| `EXTRUSION_MULTIPLIER` | `1.00` | Multiplier used for the test |
| `FILAMENT_DIAMETER` | `1.75` | Filament diameter |
| `EXTRUSION_WIDTH`, `LAYER_HEIGHT` | `0.4`, `0.2` | Target line width and layer height |
| `CONTROL_SPEED`, `RAFT_SPEED` | `100`, `60` | Shell and raft speeds |
| `TRAVEL_SPEED`, `Z_LIFT_SPEED` | `200`, `20` | Travel and Z lift speeds |
| `RETRACT_SPEED`, `RETRACT_LENGTH` | `50`, `0.5` | Retraction speed and distance |
| `PURGE_MM` | `1` | Initial filament purge; `0` disables it |

The flow file includes `[gcode_arcs]` for its rounded corners. Check existing arc configuration when integrating it.

## Pressure advance: compare the bands

![Pressure advance pattern with control and variable-speed lines](images/pa_calibration.png)

Prepare the printer and ensure `pressure_advance` is configured in `[extruder]`. Then run:

```gcode
PRESSURE_ADVANCE_CALIBRATION START=0.02 INCREMENT=0.005 DO_RAFT=1
```

Each band has slow control lines and test lines that change speed. Compare their widths where the test lines accelerate and decelerate. Choose the highest band from the bottom that still resembles its control lines without bulges or gaps.

![Inspecting and counting pressure advance bands](images/pa_calibration_band_count.png)

**Number the bottom band 0.** Calculate:

```text
PA = START + INCREMENT × band_number
```

For band 4 with the command above, `PA = 0.02 + 0.005 × 4 = 0.040`. Set the result as `pressure_advance` in your extruder configuration. The macro restores the configured PA at completion; it does not save the selected result. Repeat with a narrower range and smaller increment if needed.

### Pressure advance parameters

Speeds are mm/s; dimensions and filament lengths are millimeters. This version assumes 1.75 mm filament and derives line dimensions from the configured nozzle diameter.

| Parameter | Default | Purpose |
| --- | --- | --- |
| `START`, `INCREMENT` | `0.02`, `0.005` | First band's PA and increase per band |
| `DO_RAFT` | `1` | Supporting raft; the parameter is not `RAFT` |
| `PRINT_SIZE` | `120` | Maximum pattern footprint |
| `BANDS_LIMIT` | `999` | Upper limit; available space also limits band count |
| `LINES_PER_BAND` | `6` | Control plus test lines; minimum 2 |
| `LINE_SPACING` | `0.4` | Base spacing, adjusted for extrusion multiplier |
| `EXTRUSION_MULTIPLIER` | `1.25` with raft, `1.5` without | Test-line extrusion multiplier |
| `CONTROL_SPEED` | `30` | Control-line speed |
| `OUTER_SPEED`, `INNER_SPEED` | `40`, `120` | Slow ends and fast middle of test lines |
| `RAFT_SPEED`, `TRAVEL_SPEED` | `120`, `200` | Raft and travel speeds |
| `RETRACT_LENGTH` | `0.6` | Retraction distance |
| `PURGE_MM` | `8` | Initial filament purge |

The macro warns that normal cancellation cannot interrupt its queued print reliably; use emergency stop if the test must be stopped immediately.

## Motion speed test

Enable `calibration/test_speed.cfg`. This test moves without printing, re-homes and reports positions before and after the motion pattern. It requires the `_TILT_CALIBRATE` macro used by this printer setup.

```gcode
TEST_SPEED SPEED=200 ACCEL=3000 ITERATIONS=5 WARMUP_SPEED=40 BOUND=20
```

Choose speed and acceleration suitable for your machine. Clear the bed and allow room for the full XY pattern and Z move to `BOUND + 10` mm.

| Parameter | Default | Meaning |
| --- | --- | --- |
| `SPEED` | Configured `max_velocity` | Test speed in mm/s |
| `ACCEL` | Configured `max_accel` | Acceleration in mm/s² |
| `ITERATIONS` | `5` | Pattern repetitions |
| `WARMUP_SPEED` | `max_velocity / 5` | Positioning speed around homing |
| `BOUND` | `20` | XY inset from travel limits in mm |

Compare MCU stepper counts in the two `GET_POSITION` reports. A difference greater than a full step (the configured microstep count) indicates skipped steps. The small center pattern is 20 mm; `SMALLPATTERNSIZE` is not read from command parameters in this version. On normal completion, speed/acceleration return to configured limits and G-code state is restored.

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

## Troubleshooting

- **Unknown command:** enable its include and restart Klipper. The default calibration wildcard does not include `TEST_SPEED`.
- **Missing `_USER_VARIABLES` or startup macro:** the wrapper needs the matching printer configuration. Prepare the printer yourself and use the standalone flow/PA macro when appropriate.
- **Duplicate macro:** remove the duplicate include or choose a single spool provider.
- **Flow calculation has no saved data:** rerun the print, or supply its original multiplier and theoretical thickness explicitly.
- **Parameter seems ignored:** use `DO_RECTRACT` for flow and `DO_RAFT` for PA. The wrapper does not forward standalone tuning parameters.

The calibration illustrations were copied from the companion K1C configuration documentation. Parameter tables here follow this repository's current macros where the companion documentation differs.
