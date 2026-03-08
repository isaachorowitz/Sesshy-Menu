<div align="center">

# Sesshy

**Native macOS menubar app that shows all your active terminal connections at a glance.**

SSH sessions · Database connections · Port forwards · and more — all in one click.

[Ziplyne](https://ziplyne.agency) · [Isaac Horowitz](https://iowitz.com)

</div>

---

## What it does

Sesshy sits in your macOS menubar and scans your running processes in real time. Click the icon to see every active remote session across all your terminal windows — no setup, no agents, no configuration files.

## Detected connections

### Remote Sessions
| Type | Commands detected |
|------|-------------------|
| **SSH** | `ssh` |
| **Secure Copy** | `scp` |
| **SFTP** | `sftp` |
| **Mosh** | `mosh-client` |

### Database Sessions
| Type | Commands detected |
|------|-------------------|
| **PostgreSQL** | `psql` — via connection URL (`postgresql://host/db`) or flags (`-h`, `-d`) |

### Tunnels & Port Forwards
| Type | Commands detected |
|------|-------------------|
| **kubectl port-forward** | `kubectl port-forward` — shows target resource and port mapping |

For each session Sesshy shows:
- **Target** — hostname, user@host, or Kubernetes resource
- **Terminal** — which app the session is running in
- **TTY** — the tty identifier
- **Duration** — how long the session has been alive
- **Working directory** — the cwd at session start
- **Port mapping** — for tunnels (e.g. `5432:5432`)
- **Database name** — for Postgres connections

## Supported terminals

Sesshy resolves the parent terminal app for each session:

`Terminal` · `iTerm2` · `Ghostty` · `Warp` · `Kitty` · `Alacritty` · `WezTerm` · `Hyper`

## Requirements

- macOS 13 Ventura or later
- Xcode 15+ (to build from source)

## Build & Run

```bash
# Clone
git clone https://github.com/isaachorowitz/Sesshy-Menu.git
cd Sesshy-Menu

# Build
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
