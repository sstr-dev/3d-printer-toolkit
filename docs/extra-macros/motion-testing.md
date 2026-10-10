# Motion testing

[Extra macros](README.md) · [Setup](setup.md)

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
