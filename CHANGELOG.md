# Changelog

All notable user-visible changes to the Kopia TOS application package.

## 20261110.0.231742-1 — 2026-11-15

### Added
- First release. Kopia (`kopia/kopia:20261110.0.231742`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8143 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/kopiadocker/`.
