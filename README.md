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
task task4     # Task 4 state: one project built with `include` (resets everything else first)
task status    # check what's set up
task reset     # between participants: remove all containers and volumes (keeps images)
```

`task task2` takes under a minute once the machine is prewarmed. Run it a few minutes before the task starts, so Docker Desktop already has some CPU history for the worker.

## What each setup state contains

### 1. Run my application (`task task1`)

| What | Source |
|---|---|
| Compose stack `nginx-golang-postgres`: `proxy` (nginx, http://localhost), `backend` (Go), `db` (Postgres) | [awesome-compose/nginx-golang-postgres](https://github.com/docker/awesome-compose/tree/master/nginx-golang-postgres) |
| Standalone container `adminer` (DB browser, http://localhost:8081), attached to the stack's network | official `adminer` image, started with `docker run` |

### 2. Why is Docker taking up resources? (`task task2`)

| What | Source |
|---|---|
| Running stack `prometheus-grafana` (Grafana at :3000, Prometheus at :9090) | [awesome-compose/prometheus-grafana](https://github.com/docker/awesome-compose/tree/master/prometheus-grafana) |
| **`worker` service in that stack, using about 150% CPU** (the culprit) | **invented**: a busybox busy loop, see `compose.monitoring.yaml` |
| Stopped stack `wordpress-mysql` (2 containers, Exited 0, with data volumes) | [awesome-compose/wordpress-mysql](https://github.com/docker/awesome-compose/tree/master/wordpress-mysql) |
| Stopped stack `gitea-postgres` (2 containers, Exited 0, with data volumes) | [awesome-compose/gitea-postgres](https://github.com/docker/awesome-compose/tree/master/gitea-postgres) |
| Unused large images `node:22` and `python:3.12` (about 1.6 GB each) | official images |

### 3. Diagnose a failing service (`task task3`)

This recreates the Task 1 app with overlay `compose.fault.yaml`, which misspells one env var on `db`: `POSTGRES_PASSWORD_FILE` becomes `POSTGRES_PASWORD_FILE`. It starts from a fresh db volume, because the fault only shows on an uninitialised database. Everything else (Task 2 stacks, adminer) stays as it is. It takes about 2 seconds.

### 4. A project built with `include` (`task task4`)

`03-included-project/compose.yaml` is the only file Task 4 adds that defines services. It assembles one project, `app-with-monitoring`, from two samples plus one service of its own:

| Service(s) | Comes from |
|---|---|
| `proxy`, `backend`, `db` | `include` of the vendored nginx-golang-postgres sample, with `01-fullstack-app/compose.study.yaml` as its override (healthchecks, `postgres:17`) |
| `prometheus`, `grafana` | `include` of the vendored prometheus-grafana sample, with `compose.prometheus-pin.yaml` as its override |
| `adminer` (http://localhost:8081, preset to the `db` server) | defined directly in `compose.yaml` |

It reuses the samples already in `01-fullstack-app/vendor` and `02-busy-environment/vendor`, so nothing is copied twice. It uses the same ports and container names as Tasks 1 and 2, which is why `task task4` runs `task reset` first.

## License

Vendored samples: CC0 1.0 (see `NOTICE`).
