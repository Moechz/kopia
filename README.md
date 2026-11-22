# kopia-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Kopia](https://github.com/kopia/kopia), the encrypted deduplicated backup
> tool.

- App Center ID: **`kopiadocker`** · publisher **Moechz**
- Package version: **`20261110.0.231742-3`** (upstream `kopia/kopia:20261110.0.231742`)
- Architectures: **x86_64** and **aarch64** (one package each)
- Open: `http://<NAS-IP>:8143/`

## What this is

A Docker application archive (`kopiadocker_x86_64.tar.gz` /
`kopiadocker_aarch64.tar.gz`) that installs Kopia on TOS 7 through the App
Center. It contains exactly the four files TOS expects:

| File | Purpose |
|---|---|
| `config.ini` | TOS application metadata (`application_type: docker`, id `kopiadocker`, port 8143) |
| `kopiadocker.lang` | 23-language metadata superset (TOS requires 14) |
| `kopiadocker.svg` | application icon (953 bytes, 24 SVG elements) |
| `docker-compose.yml` | two services: the Kopia server and a small Caddy front |

## How it works

| | |
|---|---|
| Application image | `kopia/kopia:20261110.0.231742` (Docker Hub, used unmodified, digest `sha256:efc5fd7a…`) |
| Web front | `caddy:2.11.4-alpine` (Docker Hub official image, internal only) |
| Published port | **8143 → 8080** (Caddy). Kopia itself listens on 51515 and is not published |
| Open UI | `http://<NAS-IP>:8143/snapshots` (after the landing page and the Basic-auth prompt) |
| Runs as | `1000:1000` in **both** containers — no root, no `privileged`, no `cap_add`, no host network, no Docker socket |
| Persistent data | `/config` → `/Volume1/DockerAppData/kopiadocker/config`, `/data` → `/Volume1/DockerAppData/kopiadocker/data` |
| Logs | `docker logs kopiadocker`, `docker logs kopiadocker-web` |

### Why there are two containers

The Kopia server answers **HTTP 401 on every path, `/` included**, until the
browser sends HTTP Basic credentials, and it refuses to start without an
account. A browser gets a login dialog, but the App Center open check made a
plain request, saw 401 and reported the app as *not openable* — that is the
x86_64 blocker of the `-2` review, and it also made the declared functionality
unusable (F5).

The `kopiadocker-web` container solves it without weakening the app:

- `GET /` **without** the marker cookie → a public, secret-free landing page
  with HTTP **200** (this is what the App Center opens);
- the landing page hands out a one-day marker cookie and links to
  `/snapshots`;
- **every** other request — including `/` once the cookie is present — is
  reverse-proxied to the Kopia server, which keeps its own Basic auth. The 401
  challenge reaches the browser exactly as before, just after a real page.

The landing page contains no credentials, no configuration and no backup data.

### Authentication

Kopia has no built-in account, so the first start generates a random
20-character UI password:

- user `kopia`, password in
  `/Volume1/DockerAppData/kopiadocker/config/.server-password` (mode `600`);
- the password is passed to the server through `KOPIA_SERVER_PASSWORD`, **not**
  on the command line and **not** into the log (that was review item F10);
- delete the file and restart the app to rotate it.

### Repository backends

The repository is created or connected **in the UI**; nothing is created by the
package. Kopia supports, and this package documents and discloses, all of the
upstream backends:

| Backend | Where the data goes |
|---|---|
| `filesystem` | a folder on the NAS — `/data/repository` is the suggested one |
| `s3` | Amazon S3 or any S3-compatible host (MinIO, Wasabi, Hetzner, …) |
| `b2` | Backblaze B2 |
| `azure` | Azure Blob Storage |
| `gcs` | Google Cloud Storage |
| `gdrive` | Google Drive |
| `sftp` | any SFTP server |
| `webdav` | any WebDAV share |
| `rclone` | any rclone remote |
| `server` | another Kopia repository server |

Everything is encrypted on the NAS before it is uploaded. The full
endpoint/data/destination table is in [PRIVACY.md §3](PRIVACY.md#3-data-sent-to-third-parties-api-disclosure).

Because the server is started with `--persist-credentials`, the repository
password is kept in `config/kopia.config.kopia-password` (mode `600`) so that
the repository reconnects after a reboot and scheduled snapshots keep running.
Delete that file if you prefer to be asked again.

## Repository layout

```text
.
├── CHANGELOG.md                  release notes, one section per package version
├── LICENSE                       MIT for the packaging (upstream stays Apache-2.0)
├── NOTICE.md                     upstream licences, image digests, trademark, T1 note
├── PRIVACY.md                    data stored / sent / retained, rights, deletion
├── README.md                     this file
├── TOSAppSelfTestingTool         official TerraMaster check tool (dev only, not shipped)
├── tosapp.json                   package spec consumed by scripts/build.sh
├── scripts/
│   ├── build.sh                   stage → verify → pack one architecture
│   └── build-dual.sh              both architectures + official `-c` check
├── src/
│   ├── config.ini                 TOS metadata template (@@VERSION@@ / @@PLATFORM@@)
│   ├── kopiadocker.lang           generated from tosapp.json (tosdocker lang)
│   ├── kopiadocker.svg            icon
│   ├── docker-compose.yml         the two services + x-app-meta
│   ├── entrypoint.sh              Kopia wrapper (password, flags) — embedded into compose
│   └── web-entrypoint.sh          Caddy wrapper (landing page + proxy) — embedded into compose
├── test/
│   └── install-and-verify.sh      on-device E2E (needs root; never against production data)
├── tools/
│   └── verify.py                  review-standards self-check (hard gate of the build)
└── out/                           build products (git-ignored)
```

`src/entrypoint.sh` and `src/web-entrypoint.sh` are embedded into
`docker-compose.yml` at build time (with `$` doubled for compose
interpolation); `tools/verify.py` fails the build if the embedded copies differ
from the files in `src/`.

## Data and uninstall

Everything persistent lives in **one** directory,
`/Volume1/DockerAppData/kopiadocker/`:

| Path | Content | Delete it? |
|---|---|---|
| `config/` | `kopia.config` (repository connection), `kopia.config.kopia-password` (repository password, 600), `.server-password` (UI password, 600), `cache/` | deleting it removes the connection and the passwords, **not** the backups |
| `data/` | the backups, if you chose a filesystem repository | deleting it deletes those backups — keep a copy elsewhere |

Uninstall:

1. App Center → Kopia → **Uninstall** (and tick "delete data" if offered), or
   `docker compose -p kopiadocker down` from the package directory;
2. delete `/Volume1/DockerAppData/kopiadocker/` to remove the repository, the
   configuration and both passwords. Backups stored on S3/B2/WebDAV/SFTP are
   **not** touched by an uninstall — remove them at the provider if you want
   them gone;
3. no file is left outside that directory: the Caddy front uses the
   container-private `/tmp`, and no system service, cron entry or user is
   created on the NAS.

## Privacy

See [PRIVACY.md](PRIVACY.md) — public URL, linked from the App Center `help`
field. In short:

- everything runs on the NAS; **no telemetry, no analytics, no update check**
  (`--no-check-for-updates` and `KOPIA_CHECK_FOR_UPDATES=false`);
- data leaves the NAS only through the repository backend **you** configure
  (plus notification profiles, if you add them) — full endpoint table in
  PRIVACY §3;
- the UI password and the repository password are stored mode `600` and are
  never logged;
- you can access, correct and delete everything locally; the deletion channel
  and the contact are in PRIVACY §5 and §9.

## Notices

See [NOTICE.md](NOTICE.md): Kopia is Apache-2.0 (upstream authors), Caddy is
Apache-2.0 (Caddy authors), the packaging is MIT, the registry is Docker Hub
only, and the T1/CVE position of the pinned image is documented there.

## Build

```bash
scripts/build-dual.sh 20261110.0.231742-3    # both architectures + official -c
scripts/build.sh 20261110.0.231742-3 aarch64 # single architecture
```

The build stages the four files, substitutes version/platform, embeds both
wrappers, strips CRLF/BOM/AppleDouble, runs `tools/verify.py` (archive layout,
JSON validity, required fields, 14+ languages, version consistency, Docker-Hub
only images, fixed tags, reserved/recommended ports, non-root user in every
service, per-service healthcheck/TZ/restart, data paths below the application
data root, never the `/Volume*` wildcard, comment-free sequence blocks,
`x-app-meta` position, embedded-wrapper round trip, no literal secrets, SVG
limits), and then packs a deterministic GNU tar + gzip.

## Verification

```bash
./TOSAppSelfTestingTool -c out/kopiadocker_x86_64.tar.gz   # official spec check
./TOSAppSelfTestingTool -c out/kopiadocker_aarch64.tar.gz
bash test/install-and-verify.sh                            # on-device E2E (needs root)
python3 ../stage.py . --timeout 300                        # isolated runtime check
```

> A Docker application cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official tool's `-i` mode or
> `docker compose` are the ways to install one for testing.

## Upgrade from `20261110.0.231742-2`

The data layout is unchanged (`config/`, `data/`), so an upgrade keeps the
repository and its password. Two behaviour changes:

1. the app now opens on port **8143** (unchanged) but serves the **landing
   page** first; the UI is one click further, at `/snapshots`;
2. the UI password is no longer printed to the log — read
   `config/.server-password` (it already exists from the previous version, so
   the same password keeps working);
3. `--persist-credentials` is now enabled: after the first start of `-3` your
   repository reconnects automatically and `config/kopia.config.kopia-password`
   appears (mode 600).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Landing page with "Kopia is running" | normal first visit — click *Open the Kopia web interface* |
| Browser asks for user/password | Basic auth: user `kopia`, password from `config/.server-password` |
| Landing page keeps coming back | cookies are blocked for this site; allow the `kopia_ui` cookie or open `http://<NAS-IP>:8143/snapshots` directly |
| `Repository not configured` in the UI | create or connect the repository (`/repo`) — the package intentionally does not create one |
| Scheduled snapshots stopped after a reboot | check `docker logs kopiadocker`; the stored repository password must be readable (`config/kopia.config.kopia-password`, 600) |

## Limitations

- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the
  internet.
- Mounting snapshots as a filesystem is not offered (no FUSE in the
  container); restores are downloads from the UI.
- Snapshot storage grows with the folders you back up; watch free space.
- aarch64 packages are built from the same source and checked with the official
  tool, but the runtime verification in this repository ran on x86_64 hardware.

## License

Packaging: MIT (see [LICENSE](LICENSE)). Kopia: Apache-2.0. Caddy:
Apache-2.0. Full attributions in [NOTICE.md](NOTICE.md).

---

Packaged for TOS 7 by Moechz. Upstream images used unmodified from Docker Hub.
