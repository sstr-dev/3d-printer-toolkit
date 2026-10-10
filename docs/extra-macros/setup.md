# Setup

[Extra macros](README.md) · [Setup](setup.md)

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
3. Copy the [loader template](../../files/macros/extra/loader.cfg), named `loader.cfg`, beside `printer.cfg` as **`macros_loader.cfg`**.
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
