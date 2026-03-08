<div align="center">

# Sesshy Menu

*Native macOS menubar app for seeing active terminal connections across all your terminal sessions*

[Ziplyne](https://ziplyne.agency) · [Isaac Horowitz](https://iowitz.com)

</div>

---

## Features

| Area | Description |
|------|--------------|
| **Authenticated CLIs** | gh, vercel, supabase, railway, flyctl, eas, npm, pnpm, aws, gcloud, firebase, heroku, wrangler, netlify, render, pulumi, 1Password, doppler, sentry-cli, bb, and more |
| **Active Sessions** | ssh, scp, sftp, mosh, psql, kubectl port-forward |
| **Connected Contexts** | Docker context, kubectl current-context |

Provider directory via info button. "Kill Connection" for supported providers and live sessions. Card-style dropdown UI.

## Requirements

- macOS
- Xcode 15+ (or Swift 5.9+)

## Build

```bash
swift build
```

Or open `SessionMenu.xcodeproj` in Xcode and build. Run the built `.app` bundle (not `swift run`) for the menubar icon to appear correctly.

## License

MIT

---

<div align="center">

**Built by [Ziplyne](https://ziplyne.agency)** — Product development & engineering  
**[Isaac Horowitz](https://iowitz.com)** — Personal profile

</div>
