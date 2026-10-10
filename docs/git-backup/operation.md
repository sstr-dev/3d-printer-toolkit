# Operation and service controls

[Git Backup documentation](README.md)

## Change detection

| Mode | Behavior |
| --- | --- |
| `inotifywait` available in the service's PATH | Waits for events with a ten-second timeout, checks Git changes, commits/pushes and waits five seconds after a commit |
| Polling | Checks every ten seconds; commits after staged content stays unchanged for approximately sixty seconds |

Both modes skip commits during a merge. Polling tracks file contents through Git's index, so it stages changes while waiting for the cooldown. Its `POLL_INTERVAL` and `COMMIT_COOLDOWN` environment variables accept positive integer seconds; the menu uses the defaults.

Polling retries a failed push while that process remains running. Pending-push state is not persisted across restarts. The event-based mode pushes after new commits; it has no separate retry queue.

## Macros

The installer links `git-backup.cfg` into `3dp-toolkit/` in the configuration directory and adds its include to `printer.cfg`.

| Macro | Effect |
| --- | --- |
| `GIT_BACKUP_PAUSE` | Stops monitoring; the enabled service can start again at boot |
| `GIT_BACKUP_STOP` | Stops monitoring and renames the service to `disabled.S52Git-Backup`, disabling boot startup |
| `GIT_BACKUP_RESUME` | Re-enables a disabled service and starts monitoring |

## Emergency reset

If normal stop fails:

```sh
/etc/init.d/S52Git-Backup reset
```

Reset checks process identity, freezes the backup, kills its descendants and sends SIGKILL to the parent. It removes the PID file after termination; it does not restart or disable the service. For a disabled service, invoke `/etc/init.d/disabled.S52Git-Backup reset`.

SIGKILL bypasses Git's cleanup too. If Git reports a leftover index lock afterward, first ensure no Git process is still using the repository before removing that lock.

## Removal

Selecting an installed Git Backup in Tools offers removal. The action attempts service stop, then reset, then `killall` as a last fallback. That fallback can affect other processes with the same names. Removal also deletes local Git metadata and backup settings, removes the macro include, and currently attempts to uninstall `inotifywait` when Entware is present. The remote repository is retained.
