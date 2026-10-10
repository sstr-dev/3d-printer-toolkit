# Troubleshooting

[Extra macros](README.md) · [Setup](setup.md)

- **Unknown command:** enable its include and restart Klipper. The default calibration wildcard does not include `TEST_SPEED`.
- **Missing `_USER_VARIABLES` or startup macro:** the wrapper needs the matching printer configuration. Prepare the printer yourself and use the standalone flow/PA macro when appropriate.
- **Duplicate macro:** remove the duplicate include or choose a single spool provider.
- **Flow calculation has no saved data:** rerun the print, or supply its original multiplier and theoretical thickness explicitly.
- **Parameter seems ignored:** use `DO_RECTRACT` for flow and `DO_RAFT` for PA. The wrapper does not forward standalone tuning parameters.
