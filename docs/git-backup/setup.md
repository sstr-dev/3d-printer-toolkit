# Setup and prerequisites

[Git Backup documentation](README.md)

## Check the printer

Select **Tools → Git Backup: Check prerequisites**, or run:

```sh
sh /usr/data/3dp-toolkit/files/git-backup/test.sh
```

An optional argument selects another configuration directory. The test checks Git, shell utilities, process information, writable target/PID directories and the required `start-stop-daemon` options. Missing `inotifywait` is not a failure: polling is supported. On kernels without `/proc/PID/task/PID/children`, reset finds descendants using `PPid` in `/proc/PID/status`.

Passing these checks does not test remote authentication or a complete service lifecycle.

## Configure the backup

1. Create a repository accessible to your Git login with permission to push. An empty repository avoids conflicting initial histories.
2. Open **Tools → Git Backup** and confirm installation.
3. Choose GitHub, GitLab or Custom. Custom accepts a hostname without protocol or path; HTTPS is fixed.
4. Enter the login username and password/access token. Token permissions must allow repository writes. Password input is hidden.
5. For GitHub/GitLab, choose a personal repository or a full owner/group path. Custom asks for the full owner/group/repository path. Nested groups are accepted.
6. Enter the commit author name and email. Existing global Git values are offered as defaults; Enter accepts them. These values are independent of authentication. A provider-issued no-reply address can be used for commit email.
7. If needed, accept installation of Entware and/or `inotifywait`, or choose polling. Declining both monitoring options cancels setup.

Enter `:q` to cancel the Git Backup prompts. The separately invoked Entware installer has its own confirmation prompts.

The action writes configuration, verifies it, runs installation and restarts Klipper. Installation creates a local repository, sets its commit identity and HTTPS remote, creates the initial commit, pushes to `main`, and installs the service and macro include.

**Current reinstall behavior:** the menu setup removes an existing configuration `.git` directory and the old Git Backup settings directory before installation. Preserve local history/settings before reinstalling. Initial push failures do not automatically roll back local Git changes.

## Configuration and credentials

Settings are stored in `$S_BACKUP_FOLDER/git-backup/.env`, normally `/usr/data/3dp-toolkit-backup/git-backup/.env`. This is separate from the toolkit's startup `.env`.

| Keys | Purpose |
| --- | --- |
| `GIT_HOST`, `AUTH_METHOD` | HTTPS host and password/token authentication |
| `GIT_ACCOUNT`, `REPO_PATH` | Personal repository owner, when applicable, and repository path |
| `REMOTE_URL` | HTTPS URL containing encoded login credentials |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Commit identity |
| `TARGET`, `S_CONFIG_FOLDER`, `ENTWARE_FILE` | Configuration directory, macro destination and package-manager path |

The `.env` is created with restrictive permissions. Credentials are also stored in the local repository's `.git/config` as part of the remote URL.

Verification can be repeated without installation:

```sh
sh /usr/data/3dp-toolkit/files/git-backup/git-backup.sh --verify /usr/data/3dp-toolkit-backup/git-backup/.env
```

`--verify` checks configuration and local prerequisites, not remote credentials. `--install` accepts the same file argument and performs installation.
