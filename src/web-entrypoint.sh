#!/bin/sh
# ===========================================================================
# Public landing page + reverse proxy for the Kopia UI (container: kopiadocker-web).
#
# Why this container exists: the Kopia server answers 401 on every path -
# including "/" - until the browser sends HTTP Basic credentials, so the App
# Center could not open the app ("installed but could not be opened"). This
# tiny Caddy process owns the published port and:
#
#   * answers GET / with a plain, public 200 landing page (no secrets, no data),
#   * lets that page hand out a one-day marker cookie,
#   * proxies every other request - and every request from a browser that
#     already has the cookie - to the Kopia server, which keeps its own Basic
#     auth. The 401 challenge therefore reaches the browser exactly as before,
#     just after a real page instead of on the very first request.
#
# Caddy runs as uid 1000 (no root, no capabilities) and keeps its state in
# /tmp, which is discarded with the container; no data volume is written.
# ===========================================================================
set -eu

CFG=/tmp/Caddyfile

cat > "$CFG" <<'CADDYFILE'
{
	admin off
	auto_https off
	persist_config off
	storage file_system /tmp/caddy
}

:8080 {
	@landing {
		path /
		not header Cookie *kopia_ui=*
	}

	handle @landing {
		header Set-Cookie "kopia_ui=1; Path=/; Max-Age=86400; SameSite=Lax"
		header Content-Type "text/html; charset=utf-8"
		header -Server
		respond <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kopia - backup for TOS</title>
<style>
 body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;margin:0;
      background:#0f172a;color:#e2e8f0;display:flex;min-height:100vh;
      align-items:center;justify-content:center}
 main{max-width:34rem;padding:2rem;background:#1e293b;border-radius:12px}
 h1{margin:0 0 .25rem;font-size:1.6rem}
 p{line-height:1.55;margin:.75rem 0}
 a.button{display:inline-block;margin-top:1rem;padding:.7rem 1.2rem;
      background:#2563eb;color:#fff;border-radius:8px;text-decoration:none;
      font-weight:600}
 code{background:#0f172a;padding:.15rem .35rem;border-radius:4px;font-size:.9em}
 footer{margin-top:1.5rem;font-size:.8rem;color:#94a3b8}
</style>
</head>
<body>
<main>
<h1>Kopia is running</h1>
<p>Kopia is an encrypted, deduplicated backup tool. The web interface that
manages snapshots, schedules and restores is protected by HTTP Basic
authentication.</p>
<p>User <code>kopia</code> - the password was generated on first start and is
stored on the NAS in
<code>DockerAppData/kopiadocker/config/.server-password</code> (mode 600).</p>
<p><a class="button" href="/snapshots">Open the Kopia web interface</a></p>
<p>The browser will ask for the user name and that password.</p>
<footer>Independent community package for TerraMaster TOS 7. Kopia is
Apache-2.0 software by the Kopia authors; this page and the packaging are not
affiliated with them or with TerraMaster.</footer>
</main>
</body>
</html>
HTML 200
	}

	handle {
		reverse_proxy kopiadocker:51515
	}
}
CADDYFILE

exec caddy run --config "$CFG" --adapter caddyfile
