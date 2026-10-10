# Git Backup

Git Backup commits printer configuration changes and pushes them to a Git repository over HTTPS. The entire configuration directory is the repository; backing up into a subdirectory inside another repository is not supported.

- [Setup and prerequisites](setup.md)
- [Operation, macros and service controls](operation.md)
- [Ignore rules, troubleshooting and recovery](troubleshooting.md)

## Implementation

| File | Purpose |
| --- | --- |
| [Menu action](../../actions/git-backup.sh) | Interactive setup and removal |
| [Backup script](../../files/git-backup/git-backup.sh) | Configuration verification, installation and monitoring |
| [Service template](../../files/git-backup/S52Git-Backup) | Start, stop, restart and emergency reset |
| [Macros](../../files/git-backup/git-backup.cfg) | Pause, stop and resume from the printer UI |
| [Prerequisite test](../../files/git-backup/test.sh) | Read-only capability checks with a temporary sleep process |
| [Gitignore template](../../files/git-backup/templates/gitignore) | Default exclusions for printer configuration backups |

