# kopia-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Kopia](https://github.com/kopia/kopia).

## What this is

A four-file TOS Docker application archive (`kopiadocker.tar.gz`) that installs
Kopia on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `kopiadocker`)
- `kopiadocker.lang` — 23-language superset (TOS requires 14)
- `kopiadocker.svg` — application icon (953 bytes, 4 SVG elements)
- `docker-compose.yml` — one service, image `kopia/kopia:20261110.0.231742`

## How it works

| | |
|---|---|
| Container image | `kopia/kopia:20261110.0.231742` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8143/` (container port 51515) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/kopiadocker/config`, `/data` → `/Volume1/DockerAppData/kopiadocker/data` |
| Logs | `docker logs kopiadocker` (stdout/stderr) |

`/config` holds `kopia.config`, the generated UI password and server logs; `/data` (mounted from `.../data`) is the recommended place for a filesystem repository.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: generates a random UI password (stored in `config/.server-password`), prints the login line and starts the Kopia server with `--ui --insecure`.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 51515.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Password generated once.** No credential is baked into the package: the wrapper creates a random UI password, stores it in the config volume and prints the login line.
- **Repository created in the UI.** The package does not create a repository; the user picks the storage location and the (separate) repository password.

## Privacy

This application runs entirely on your NAS. It does not include analytics, telemetry or advertising SDKs, and the packaging contains no code that sends data to the packager. Data is only exchanged with the services you configure yourself (for example media servers, notification endpoints or model APIs), and only from the container. Everything the application stores lives in the application data folder described above; removing the app with its data deletes it.

## Third-party components

The package runs the upstream image `kopia/kopia:20261110.0.231742` unmodified. Its components and their licences are those of the upstream project (https://github.com/kopia/kopia), which is distributed under **Apache-2.0**. No upstream source code is redistributed in this repository; only the four packaging files are original work.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/kopiadocker/config` | Kopia application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/kopiadocker/data` | Kopia application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/kopiadocker.tar.gz + .sha256
scripts/build.sh 20261110.0.231742-2   # packaging iteration bump
scripts/build.sh 20261110.0.231742-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/kopiadocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v20261110.0.231742-1`**, assets `kopiadocker.tar.gz` +
   `kopiadocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `kopiadocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `20261110.0.231742-1` → automated validation → review.

## License / branding

Kopia is distributed by its upstream authors under **Apache-2.0**. The container image is the official image from Docker Hub (`kopia/kopia:20261110.0.231742`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.
- The repository password is not stored by the package; losing it means losing the restores.
- Snapshot storage grows with the folders you back up; watch free space on the NAS.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
