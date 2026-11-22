# Notices and attributions — Kopia for TerraMaster TOS 7

Package: **Kopia** (App Center ID `kopiadocker`), version
`20261110.0.231742-3`, published by **Moechz**. Independent community package
for TerraMaster TOS 7; not affiliated with the Kopia project or with
TerraMaster.

## 1. Upstream application — Kopia (Apache-2.0)

- Project: <https://github.com/kopia/kopia>
- Licence: **Apache License 2.0** (<https://github.com/kopia/kopia/blob/master/LICENSE>)
- Copyright: the Kopia authors and contributors.
- Documentation: <https://kopia.io/docs/>
- Trademark: "Kopia" and the Kopia logo belong to the Kopia project. This
  package uses the name only to describe the software it installs; the icon in
  the App Center is the upstream project icon, unmodified.

The application binary is **not** rebuilt or modified by this package. It is
used as the unmodified upstream container image:

| | |
|---|---|
| Image | `kopia/kopia:20261110.0.231742` |
| Digest | `kopia/kopia@sha256:efc5fd7aa9df34f5513a6ef2253adf9601b96ca50edeba78f6dc8e3069baac2f` |
| Registry | Docker Hub (`docker.io/kopia/kopia`, official upstream repository) |
| Version string | `20261110.0.231742 build: 07d64c2273e2297c4b669180ce2e58a0345c3fec from: kopia/kopia` |
| Build date | 2026-11-10 (upstream CI) |
| Base OS | Ubuntu 22.04.5 LTS (upstream image) |

The Ubuntu base image contains the usual Debian/Ubuntu userland (glibc,
OpenSSL, zlib, ca-certificates, Perl, curl, …) under their respective
licences (GPL-2.0, LGPL-2.1, BSD, MIT, OpenSSL/SSLeay). No source code of
these components is redistributed here; they are shipped inside the upstream
image, which is pulled from Docker Hub at install time.

## 2. Web front — Caddy (Apache-2.0)

The package runs a second, internal container that serves a public landing
page on the published port and reverse-proxies the Kopia UI:

| | |
|---|---|
| Image | `caddy:2.11.4-alpine` (Docker Official Image, Docker Hub) |
| Licence | **Apache-2.0** (<https://github.com/caddyserver/caddy/blob/master/LICENSE>) |
| Copyright | Matthew Holt and the Caddy authors |
| Base | Alpine Linux 3.x (musl libc, BusyBox — GPL-2.0 / MIT) |

Caddy is used unmodified. It holds no configuration files outside the
container, stores no data on the NAS and has no credentials of its own.

## 3. Packaging (MIT)

Everything original in this repository — `config.ini`, `kopiadocker.lang`,
`kopiadocker.svg`, `docker-compose.yml`, the two entrypoint wrappers, the build
and verification scripts and the documentation — is released under the **MIT
licence**; see [LICENSE](LICENSE). The Kopia application itself stays under
Apache-2.0.

## 4. Development tooling in the source repository

`TOSAppSelfTestingTool` is an official TerraMaster utility, redistributed here
unmodified so that contributors can reproduce the package check
(`./TOSAppSelfTestingTool -c out/kopiadocker.tar.gz`). It is **not** part of the
installed application and is not shipped inside `kopiadocker.tar.gz`.

## 5. Vulnerability scan note (review item T1)

The review reported high/critical CVEs for this version. The findings are in
the **base operating system packages of the upstream image** (Ubuntu 22.04.5),
not in Kopia's own code, and this package cannot patch them without rebuilding
and republishing the upstream image:

- the pinned tag `20261110.0.231742` is the **newest upstream build** we can
  obtain: it is a 2026-11-10 CI build, i.e. newer than the latest tagged
  release `v0.23.1` (2026-06-16);
- upstream rebuilds the image continuously, so a newer nightly may appear at
  any time — the follow-up plan is to re-pin to the newest digest at each
  maintenance round (tracked in CHANGELOG.md);
- the application exposes no privileged, host-network or Docker-socket
  surface, and the only listening service is the operator's own web UI on the
  LAN; the package runs both containers as uid 1000 with all capabilities
  dropped by default.

If a rebuilt upstream image is required for a specific CVE, it has to come from
the Kopia project (or a documented fork); this package will not ship a locally
patched binary under the upstream name.
