# Ignore rules, troubleshooting and recovery

[Git Backup documentation](README.md)

## Files to exclude

The [template](../../files/git-backup/templates/gitignore) excludes printer-generated backups, archives, logs, temporary/editor files and SQLite database files. The Setup copies it only if the target has no `.gitignore` file.

Ignore rules do not remove files already tracked by Git. To stop tracking e.g. from 2 backup tar.gz: pause Git Backup first, then run:

```sh
cd /usr/data/printer_data/config
git rm --cached -- backup_config.tar.gz backup_database.tar.gz
git commit -m "Stop tracking backup archives"
git push
```

and Resume Git Backup afterward.

## Common problems

| Symptom | Check |
| --- | --- |
| Prerequisite test fails | Missing command, writable configuration/PID directory, or unsupported daemon option |
| No `inotifywait` | Accept polling; Entware is not required if Git and the other prerequisites are already available |
| Initial push fails | Login/token, write permission, repository path, branch protection and conflicting remote history |
| Commits exist locally but not remotely | Connectivity and credentials; check status/upstream and retry the push after resolving the cause |
| Nothing is committed in polling mode | Wait for sixty seconds without further changes; also check ignore rules and unfinished merges |
| Service fails to start | Actual script path, executable permissions, Git availability in the service's PATH and target directory |
| Service does not restart at boot | A previous Stop operation may have renamed it to `disabled.S52Git-Backup`; use Resume |
| Printer macros cannot run commands | The printer must support `gcode_shell_command` and `RESPOND`; check macro include and script paths |

The background service suppresses script output. For interactive diagnosis, pause the service and run the backup script in the foreground with `-b main -t /usr/data/printer_data/config -g origin`. It still commits and pushes real changes; stop it with Ctrl-C before resuming the service.

## Restore configuration

1. Pause automatic backups so restoration is not immediately committed.
2. Download or clone the remote repository into a separate directory and select the desired commit.
3. Preserve a copy of the current printer configuration.
4. Copy the needed configuration files into the printer's configuration directory. Do not copy `.git` metadata or credentials from another installation.
5. Check included files and printer-specific settings, then restart Klipper and validate the configuration.
6. Resume Git Backup when ready; restored changes will become a new backup commit.

This backup the selected configuration directory. It is not a complete firmware, database, uploaded-print-file or full-printer backup.
