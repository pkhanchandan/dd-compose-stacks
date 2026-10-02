# dd-compose-stacks

Seed environments that pre-fill Docker Desktop with realistic state for usability testing.

All apps are **unmodified [awesome-compose](https://github.com/docker/awesome-compose) samples** (vendored under `*/vendor/`, pinned to commit `30f4b7f`). Study-specific changes live in small overlay files (`compose.*.yaml`) that are layered on with `docker compose -f`, so every deviation from upstream fits on one screen.

## Prerequisites

- Docker Desktop (Compose v2.24+ for the `!override` tag)
- [Task](https://taskfile.dev/installation/) (`brew install go-task`)
- Free ports: 80, 3000, 3001, 8081, 8082, 9090

## Usage

```sh
task prewarm   # once per machine: pull and build everything (several GB)
task task1     # Task 1 state
task task2     # Task 2 state (includes Task 1 state)
task task3     # Task 3 state: break the Task 1 app (run after task1 or task2)
task task3:undo  # put the app back to healthy
task status    # check what's set up
task reset     # between participants: remove all containers and volumes (keeps images)
```

`task task2` takes under a minute once the machine is prewarmed. Run it a few minutes before the task starts, so Docker Desktop already has some CPU history for the worker.

## What each setup state contains

### `01-fullstack-app`: run my application (`task task1`)

| What | Source |
|---|---|
| Compose stack `nginx-golang-postgres`: `proxy` (nginx, http://localhost), `backend` (Go), `db` (Postgres) | [awesome-compose/nginx-golang-postgres](https://github.com/docker/awesome-compose/tree/master/nginx-golang-postgres) |
| Standalone container `adminer` (DB browser, http://localhost:8081), attached to the stack's network | official `adminer` image, started with `docker run` |
| Request lines in the `backend` logs | the sample logs every request; the Taskfile sends 5 requests, and the healthchecks keep adding more |

Overlay `compose.study.yaml`:
- adds healthchecks to `backend` and `proxy` (upstream only has one on `db`), so every service shows a health status
- pins `db` to `postgres:17`. The upstream sample uses an unpinned `postgres`, which no longer starts with 18+ because of a data-directory change.

### `02-busy-environment`: why is Docker taking up resources? (`task task2`)

| What | Source |
|---|---|
| Running stack `prometheus-grafana` (Grafana at :3000, Prometheus at :9090) | [awesome-compose/prometheus-grafana](https://github.com/docker/awesome-compose/tree/master/prometheus-grafana) |
| **`worker` service in that stack, using about 150% CPU** (the culprit) | **invented**: a busybox busy loop, see `compose.monitoring.yaml` |
| Stopped stack `wordpress-mysql` (2 containers, Exited 0, with data volumes) | [awesome-compose/wordpress-mysql](https://github.com/docker/awesome-compose/tree/master/wordpress-mysql) |
| Stopped stack `gitea-postgres` (2 containers, Exited 0, with data volumes) | [awesome-compose/gitea-postgres](https://github.com/docker/awesome-compose/tree/master/gitea-postgres) |
| Unused large images `node:22` and `python:3.12` (about 1.6 GB each) | official images |

Overlays:
- `compose.monitoring.yaml` adds the worker, capped with `cpus: 1.5` so the test laptop doesn't overheat. It also pins `prom/prometheus:v2.55.1`, because Prometheus 3 rejects the sample's config.
- `compose.wordpress.yaml` and `compose.gitea.yaml` move ports that would clash (80 to 8082, 3000 to 3001). They also set `restart: "no"` so the stacks stay stopped if Docker Desktop restarts. Both databases get a healthcheck, so they finish initialising before being stopped. Gitea's db is pinned to `postgres:17-alpine` (same Postgres 18 issue as above), and WordPress stops with SIGTERM. Together these mean every stopped container shows a clean `Exited (0)`.

### Task 3: diagnose a failing service (`task task3`)

This recreates the Task 1 app with overlay `compose.fault.yaml`, which misspells one env var on `db`: `POSTGRES_PASSWORD_FILE` becomes `POSTGRES_PASWORD_FILE`. It starts from a fresh db volume, because the fault only shows on an uninitialised database. Everything else (Task 2 stacks, adminer) stays as it is. It takes about 2 seconds.

**Answer key:**

| Question | What the participant should find |
|---|---|
| Which service? | `db`, restarting over and over. `backend` and `proxy` stay at `Created` (they wait for a healthy db), so http://localhost doesn't respond. |
| What went wrong? | The `db` logs repeat `Error: Database is uninitialized and superuser password is not specified.` |
| Config | The container's environment shows `POSTGRES_PASWORD_FILE` (misspelled). |
| Compose file | The typo is in `compose.fault.yaml`, the third of the project's compose files. `vendor/.../compose.yaml` itself is correct. |

## License

Vendored samples: CC0 1.0 (see `NOTICE`).
