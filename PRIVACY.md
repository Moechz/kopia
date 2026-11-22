# Privacy Policy — Kopia for TerraMaster TOS 7

This policy covers the TOS 7 application package **Kopia** (App Center ID
`kopiadocker`, published by **Moechz**). It describes what the packaged
application stores on your NAS, what it sends over the network, how long it is
kept and how you can access, correct or delete it.

The application itself is the open-source **Kopia** project
(<https://github.com/kopia/kopia>, Apache-2.0). The container image is the
unmodified upstream build `kopia/kopia:20261110.0.231742`; a second, internal
**Caddy** container (Apache-2.0) only serves a public landing page and proxies
the web UI. This package adds TOS metadata, the data-directory mapping and the
two first-start wrappers.

Last updated: 2026-11-22 (package version 20261110.0.231742-3).

Contact for any privacy question or request: open an issue at
<https://github.com/Moechz/kopia/issues> (public repository).

---

## 1. What the application does

Kopia is a backup tool that runs entirely on your own NAS:

- it reads the folders **you** select and stores them in a **repository** that
  **you** create — on a local disk, an S3-compatible bucket, Backblaze B2,
  Azure Blob Storage, Google Cloud Storage, Google Drive, an SFTP server, a
  WebDAV share, an rclone remote, or another Kopia server;
- everything is encrypted and deduplicated **on the NAS before it is stored**,
  with a key derived from the repository password you choose;
- it serves a web interface on `http://<NAS-IP>:8143/` (behind HTTP Basic auth)
  where you create or connect the repository, start snapshots, browse and
  restore file versions, and set retention and scheduling policies.

There is no Kopia account, no vendor cloud and no subscription. The package
author and TerraMaster operate no service that this application talks to.

## 2. Data stored on your NAS

All persistent data is kept below `/Volume1/DockerAppData/kopiadocker/`:

| What | Where | Why |
|---|---|---|
| Repository connection settings (storage type, bucket/path, region) | `config/kopia.config` | so the server knows which repository to open |
| **Repository password** | `config/kopia.config.kopia-password`, mode `600`, written by Kopia because the package starts it with `--persist-credentials` | lets the server reconnect after a reboot so scheduled snapshots continue; delete this file if you prefer to re-enter the password every time |
| Web-UI password (HTTP Basic Auth, user `kopia`) | `config/.server-password`, mode `600`, random, generated on first start | keeps other hosts on the LAN out of the backup configuration |
| Local cache of repository data (encrypted blobs and metadata) | `config/cache/` | speeds up browsing and restores; safe to delete at any time |
| Backups (snapshots) of the folders you selected | `data/` when you choose a filesystem repository; otherwise they are written to the storage you configured | this is the backup itself — encrypted |
| Container log | `docker logs kopiadocker` and `docker logs kopiadocker-web` (stdout/stderr) | troubleshooting |

Nothing else on the NAS is written. File logging inside the container is
disabled (`--disable-file-logging`), the Caddy front keeps its state in the
container-private `/tmp`, and no data volume is mounted into it. The
`TOSAppSelfTestingTool` that ships in the source repository is not part of the
installed package.

**No telemetry, no analytics, no crash reporting, no update check.** Kopia has
no usage reporting. The image sets `KOPIA_CHECK_FOR_UPDATES=false` and the
package also passes `--no-check-for-updates`, so the server does not even ask
GitHub for a new release. Neither the package author nor TerraMaster receives
any data from the running application.

## 3. Data sent to third parties (API disclosure)

Nothing is uploaded until **you** create a repository or a notification
profile. The table lists every endpoint the application can contact, what is
sent and where it goes. "Region" is the region of the provider **you** chose —
the package does not pin, proxy or route data through any intermediary, and no
data goes to the packager.

| Endpoint (host) | When | Data sent | Destination / region |
|---|---|---|---|
| none — `filesystem` repository | you pick a folder (default suggestion: `/data`) | nothing leaves the NAS | local disk only |
| `s3.<region>.amazonaws.com`, or any S3-compatible host you type (MinIO, Wasabi, Hetzner, …) | you create/connect an `s3` repository | encrypted repository blobs (snapshot data, indexes), bucket name, access key id | the bucket's region / the host you entered |
| `api.backblazeb2.com` + `s3.<region>.backblazeb2.com` | `b2` repository | encrypted blobs, key id | Backblaze region you chose |
| `<account>.blob.core.windows.net` | `azure` repository | encrypted blobs, account name | Azure region of the storage account |
| `storage.googleapis.com`, `iamcredentials.googleapis.com`, `oauth2.googleapis.com`, `accounts.google.com` | `gcs` repository | encrypted blobs, OAuth token requests | Google Cloud region / global OAuth |
| `www.googleapis.com` (Google Drive) | `gdrive` repository | encrypted blobs, folder id | Google Drive (Google's region) |
| your SFTP host | `sftp` repository | encrypted blobs, user name, SSH host key | the server you entered |
| your WebDAV URL | `webdav` repository | encrypted blobs, Basic credentials | the server you entered |
| your rclone remote (any provider rclone supports) | `rclone` repository | encrypted blobs | whatever that remote is |
| another Kopia server (`https://…`) | `repository connect server` | encrypted blobs, Basic credentials of that server | the server you entered |
| `api.pushover.net/1/messages.json` | only if you add a Pushover notification profile | notification title/text, your user key and app token | Pushover (US) |
| your SMTP host | only if you add an e-mail notification profile | notification text, SMTP credentials | the mail server you entered |
| any webhook URL you enter | only if you add a webhook notification profile | notification text (JSON) | that URL |
| `api.github.com/repos/kopia/kopia/releases/latest` | **disabled** in this package (`--no-check-for-updates`, `KOPIA_CHECK_FOR_UPDATES=false`) | nothing | would be GitHub (US) |
| `registry-1.docker.io`, `auth.docker.io` | only while the App Center installs or updates the app | image pull, no user data | Docker Hub (US) |

The **repository password never leaves the NAS**: it is used locally to derive
the encryption key. What is transmitted is ciphertext.

## 4. Retention

- **Backups** stay in your repository until you delete the snapshot or the
  retention policy you configured expires it. Kopia's default policy keeps
  hourly/daily/weekly/monthly/annual snapshots (48/7/4/24/3) and prunes older
  ones automatically; you can change or disable that per folder in the UI
  ("Policies").
- **Repository password, UI password, connection settings, cache** stay until
  you delete the files or the application data directory.
- **Container logs** are kept by the Docker daemon's logging driver (TOS
  default `json-file`) and are removed together with the container.
- Deleting a snapshot removes its data from the repository at the next
  maintenance run; deleting the repository directory removes everything.

## 5. Your rights: access, correction, deletion

You are the only party with access to this data (NAS administrator). There is
no account with the packager, so requests are handled locally:

- **Access / export** — browse every snapshot in the web UI
  (`/snapshots`), run `kopia snapshot list`, or copy the repository directory.
  The UI password is in `DockerAppData/kopiadocker/config/.server-password`,
  the repository password in `…/config/kopia.config.kopia-password`; both are
  mode `600`.
- **Correction** — delete a wrong snapshot in the UI (`Snapshots → Delete`),
  edit policies, or restore a previous version over the current file. Source
  paths and schedule are edited in `Policies` / `Snapshots → New`.
- **Deletion** — delete individual snapshots in the UI; remove the whole
  backup by uninstalling the app in App Center **with its data**, or by deleting
  `/Volume1/DockerAppData/kopiadocker/` (see README §"Data and uninstall").
  Delete `config/kopia.config.kopia-password` to require the repository
  password again.
- **Objection / questions** — open an issue at
  <https://github.com/Moechz/kopia/issues>.

## 6. Security measures

- Both containers run as **uid/gid 1000** (non-root), without `privileged`,
  without `cap_add`, without host networking and without the Docker socket.
- The web UI is protected by **HTTP Basic authentication** with a random
  20-character password generated on first start; the password is stored
  mode `600` and is never printed to the log or passed on a command line.
- The landing page served on the published port contains **no secrets, no
  configuration and no backup data**; it only explains where the password is.
- Snapshots are encrypted with **AES-256-GCM** (key derived from the
  repository password with scrypt) and content-hashed with BLAKE2B; the
  repository password is not recoverable, so a lost password means lost
  backups.
- The UI speaks **plain HTTP** on the LAN. Put a TLS reverse proxy in front
  before exposing it to the internet.
- The container image is pinned by tag and digest
  (`kopia/kopia@sha256:efc5fd7a…`) and is pulled from Docker Hub only.

## 7. Children / special categories

The application is a backup tool for the NAS administrator. It does not ask for
any personal data, does not create user profiles and does not process special
categories of data on its own. Whatever your backups contain is your
responsibility and is encrypted with your password.

## 8. Changes to this policy

The policy is versioned with the package: every change is listed in
[CHANGELOG.md](CHANGELOG.md) and the current text always lives at
<https://github.com/Moechz/kopia/blob/main/PRIVACY.md> (the `help` link of the
App Center entry points here).

## 9. Contact

- Issues and data requests: <https://github.com/Moechz/kopia/issues>
- Publisher: Moechz (independent community packager; not affiliated with the
  Kopia project or TerraMaster)
