# dd-compose-stacks

Seed environments that pre-fill Docker Desktop with realistic state for usability testing.

All apps are **unmodified [awesome-compose](https://github.com/docker/awesome-compose) samples** (vendored under `*/vendor/`, pinned to commit `30f4b7f`). Study-specific changes live in small overlay files (`compose.*.yaml`) that are layered on with `docker compose -f`, so every deviation from upstream fits on one screen.

## Prerequisites

- Docker Desktop (Compose v2.24+ for the `!override` tag)
- [Task](https://taskfile.dev/installation/) (macOS: `brew install go-task`, Windows: `winget install Task.Task`)
- For the GUI v2 tasks: `jq` (macOS: `brew install jq`, Linux: `sudo apt install jq`, Windows: `winget install jqlang.jq`). On Windows you also need [Git for Windows](https://gitforwindows.org/), which provides Git Bash.
- Free ports: 80, 3000, 3001, 8081, 8082, 9090

## Usage

```sh
task prewarm   # once per machine: pull and build everything (several GB)
task task1     # Task 1 state
task task2     # Task 2 state (includes Task 1 state)
task task3     # Task 3 state: break the Task 1 app (run after task1 or task2)
task task3:undo  # put the app back to healthy
task task4     # Task 4 state: one project built with `include` (resets everything else first)
task status    # check what's set up
task reset     # between participants: remove all containers and volumes (keeps images)
```

`task task2` takes under a minute once the machine is prewarmed. Run it a few minutes before the task starts, so Docker Desktop already has some CPU history for the worker.

## Enabling GUI v2

```sh
task gui:v2        # set "PreferredGUI": "v2" in Docker Desktop's settings-store.json
task gui:restore   # put settings-store.json back to how it was before gui:v2
```

The scripts are in `settings-scripts/` and can also be run directly.

| OS | Settings file |
|---|---|
| macOS | `~/Library/Group Containers/group.com.docker/settings-store.json` |
| Linux | `~/.docker/desktop/settings-store.json` |
| Windows | `%APPDATA%\Docker\settings-store.json` |

On Windows, run the tasks from a Git Bash terminal. From PowerShell or cmd, `bash` may resolve to WSL, which would edit a settings file inside Linux instead of the Windows one.

## NOTICE
The directories under */vendor/ are unmodified copies of samples from
docker/awesome-compose (https://github.com/docker/awesome-compose),
commit 30f4b7f6a6c3b0c0ecf4d4efb0de203c48d11562, released under CC0 1.0 Universal.