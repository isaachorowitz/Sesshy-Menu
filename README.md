<div align="center">

# Sesshy

**Native macOS menubar app that shows all your active terminal connections at a glance.**

SSH sessions · Database connections · Port forwards · all in one click.

[Ziplyne](https://ziplyne.agency) · [Isaac Horowitz](https://iowitz.com)

</div>

---

## What it does

Sesshy sits in your macOS menubar and scans your running processes in real time. Click the icon to see every active remote session across all your terminal windows — no setup, no agents, no configuration files.

---

## Everything Sesshy detects

### Remote Access

| Command | What Sesshy shows |
|---------|-------------------|
| `ssh user@host` | Host or `user@host` target, connected socket endpoint, terminal app, TTY, elapsed time, working directory |
| `ssh -i key.pem host` | Correctly skips key flag, resolves `host` as the target |
| `ssh -o ProxyCommand="..." host` | Handles quoted option values, resolves the final `host` |
| `ssh host tail -f /var/log/app.log` | Detects host even when a remote command follows |
| `scp src user@host:dest` | Detected as a remote session, target resolved from arguments |
| `sftp user@host` | Detected as a remote session |
| `mosh-client` | Detected as a remote session (Mosh underlying transport process) |

### Databases

| Command | What Sesshy shows |
|---------|-------------------|
| `psql postgresql://user@host:5432/dbname` | Host (`host`), database name (`dbname`) |
| `psql postgresql://host/dbname` | Host, database name |
| `psql -h host -d dbname` | Host via `-h` / `--host`, database via `-d` / `--dbname` |
| `psql -h host dbname` | Host and positional database name |

### Tunnels & Port Forwards

| Command | What Sesshy shows |
|---------|-------------------|
| `kubectl port-forward deployment/api 8080:80` | Resource (`deployment/api`), port mapping (`8080:80`) |
| `kubectl port-forward pod/mypod 5432:5432 -n staging` | Resource, port mapping, ignores namespace flag |
| `kubectl port-forward svc/myservice 3000:3000` | Service name and port mapping |

---

## Supported terminals

Sesshy walks the process tree to identify which terminal app each session belongs to:

| Terminal | Detected as |
|----------|-------------|
| Apple Terminal | `Terminal` |
| iTerm2 | `iTerm2` |
| Ghostty | `Ghostty` |
| Warp | `Warp` |
| Kitty | `Kitty` |
| Alacritty | `Alacritty` |
| WezTerm | `WezTerm` |
| Hyper | `Hyper` |

Any unrecognized terminal falls back to the TTY identifier (e.g. `ttys003`).

---

## Per-session details

For every detected session, Sesshy displays:

- **Title** — connection type (SSH, Postgres, Port Forward)
- **Target** — the hostname, `user@host`, Kubernetes resource, or database host
- **Subtitle** — database name, port mapping, or remote socket endpoint
- **Terminal** — which terminal app the session is running in
- **TTY** — the tty identifier
- **Duration** — how long the session has been alive (`5s`, `12m`, `2h 4m`, `1d 3h`)
- **Working directory** — the cwd at the time of the session

---

## Requirements

- macOS 14 Sonoma or later
- Xcode 15+ (to build from source)

## Build & Run

```bash
# Clone
git clone https://github.com/isaachorowitz/Sesshy-Menu.git
cd Sesshy-Menu

# Build release
swift build -c release

# Or open in Xcode
open SessionMenu.xcodeproj
```

> **Important:** Run the built `.app` bundle — not `swift run`. The menubar icon only appears when launched as an `.app`.

## Run tests

```bash
swift test
```

## License

MIT — see [LICENSE](LICENSE)

---

<div align="center">

Built by **[Ziplyne](https://ziplyne.agency)** — Product development & engineering  
**[Isaac Horowitz](https://iowitz.com)**

</div>
