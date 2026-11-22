# Changelog

All notable user-visible changes to the Kopia TOS application package.

## 20261110.0.231742-3 — 2026-11-22

Remediation of the App Center listing review of `20261110.0.231742-2`
(aarch64: C2, C3, C4, C5, C6, C7, C8, C10, T1 plus F5/F10 in the report body;
x86_64: installation blocker — "installed but could not be opened, HTTP 401 at
the default landing page").

### Fixed

- **Open check / F5 — the app could not be opened.** The Kopia server answers
  `401 Unauthorized` on *every* path, `/` included, until Basic credentials
  arrive, so the App Center saw only 401. A second container
  (`kopiadocker-web`, `caddy:2.11.4-alpine`) now owns the published port: it
  serves a public, secret-free landing page on `/` with **HTTP 200** and
  reverse-proxies everything else to the Kopia server, which keeps its own
  Basic auth. The UI is reached at `/snapshots`. Verified: `/` → 200,
  `/` with the landing cookie → 401 challenge, `/` + credentials → 200,
  `/snapshots` + credentials → 200.
- **F10 — sensitive information in the log.** The wrapper no longer prints
  `user=kopia password=…`. The generated password is stored mode `600` in
  `config/.server-password` and handed to the server through
  `KOPIA_SERVER_PASSWORD`, so it appears neither in the container log nor in
  `docker inspect` / the process arguments.
- **F5 — declared functionality.** The description no longer advertises
  mounting snapshots (no FUSE device in the container); restores are
  downloads. `--persist-credentials` is enabled so a repository created in the
  UI reconnects after a restart and scheduled snapshots keep running.
- **T1 — CVE scan.** The pinned image `20261110.0.231742` is the newest
  upstream build obtainable (2026-11-10 CI build, newer than the latest tagged
  release v0.23.1 of 2026-06-16); the reported findings are in the Ubuntu
  22.04.5 base packages of the upstream image, which this package cannot patch
  without shipping a patched binary under the upstream name. The position and
  the re-pin plan are documented in NOTICE.md §5; both containers run
  unprivileged with no capability, host-network or Docker-socket surface.

### Added

- **C3/C4/C5/C7 — privacy policy.** New `PRIVACY.md` (public URL, also the
  `help` link of the App Center entry): what is stored where, retention, user
  rights (access/correction/deletion), security measures, third-party sharing,
  deletion channel and contact.
- **C8 — third-party API disclosure.** Endpoint → data → destination/region
  table in PRIVACY.md §3, covering every repository backend Kopia supports
  (filesystem, S3/S3-compatible, B2, Azure, GCS, Google Drive, SFTP, WebDAV,
  rclone, another Kopia server), notification profiles (Pushover, SMTP,
  webhook), the disabled update check and the Docker Hub image pull.
- **C6 — declaration aligned with behaviour.** Documented and enforced: no
  telemetry/analytics (Kopia has none), update check off
  (`--no-check-for-updates`, `KOPIA_CHECK_FOR_UPDATES=false`, endpoint
  `api.github.com`), file logging disabled, and the repository password
  persisted locally mode `600` — all of it is now stated in PRIVACY.md,
  README and `important`.
- **C2 — notices.** New `NOTICE.md`: Kopia Apache-2.0 (upstream authors),
  Caddy Apache-2.0, Alpine/Ubuntu base components, image tag **and digest**,
  trademark statement, MIT packaging licence, T1 note.
- **C10 — repository and README.** README rewritten with repository layout,
  how it works, privacy, notices, build, data/uninstall, upgrade and
  troubleshooting sections; `tools/verify.py` additionally fails the build if
  the embedded wrappers differ from `src/`.

### Changed

- `docker-compose.yml`: two services (`kopiadocker` + `kopiadocker-web`), the
  Kopia port is internal (`expose: 51515`), only 8143 is published. Port 8143
  is unchanged (no port-conflict rework).
- `tosapp.json`/`config.ini`/`kopiadocker.lang`: version `-3`, `help` →
  `…/blob/main/PRIVACY.md`, `container_port` 8080 (the front), refreshed
  `descript`/`important`/`release_note` and zh-cn/zh-hk translations, refreshed
  probe (real 401 behaviour of the bare image), removed the stale `mount`
  claim.

## 20261110.0.231742-2 — 2026-11-15

### Changed
- Re-release of `-1` (identical package) to keep a submission slot for the
  review; no functional change.

## 20261110.0.231742-1 — 2026-11-15

### Added
- First release. Kopia (`kopia/kopia:20261110.0.231742`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8143 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/kopiadocker/`.
