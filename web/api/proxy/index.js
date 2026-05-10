// Proxy CORS para o Apps Script REST. Usa o modelo legado de Azure Functions
// (function.json + index.js) por compat com Azure Static Web Apps managed
// functions (free tier não suporta o modelo programmatic v4).

const APPS_SCRIPT_URL = process.env.APPS_SCRIPT_URL;

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "Content-Type",
  "access-control-max-age": "86400",
};

function jsonHeaders() {
  return {
    "content-type": "application/json; charset=utf-8",
    ...CORS_HEADERS,
  };
}

module.exports = async function (context, req) {
  if (req.method === "OPTIONS") {
    context.res = { status: 204, headers: CORS_HEADERS };
    return;
  }

  if (!APPS_SCRIPT_URL) {
    context.res = {
      status: 500,
      headers: jsonHeaders(),
      body: { ok: false, error: "proxy_misconfigured" },
    };
    return;
  }

  try {
    const target = new URL(APPS_SCRIPT_URL);

    if (req.method === "GET") {
      for (const k of Object.keys(req.query || {})) {
        target.searchParams.set(k, req.query[k]);
      }
      const r = await fetch(target.toString(), { redirect: "follow" });
      context.res = {
        status: r.status,
        headers: jsonHeaders(),
        body: await r.text(),
      };
      return;
    }

    if (req.method === "POST") {
      const body = typeof req.body === "string" ? req.body : (req.rawBody || "");
      const r = await fetch(target.toString(), {
        method: "POST",
        headers: { "content-type": "text/plain;charset=UTF-8" },
        body,
        redirect: "follow",
      });
      context.res = {
        status: r.status,
        headers: jsonHeaders(),
        body: await r.text(),
      };
      return;
    }

    context.res = {
      status: 405,
      headers: jsonHeaders(),
      body: { ok: false, error: "method_not_allowed" },
    };
  } catch (err) {
    context.log.error("proxy failed", err);
    context.res = {
      status: 502,
      headers: jsonHeaders(),
      body: {
        ok: false,
        error: "proxy_failed",
        detail: err && err.message ? err.message : String(err),
      },
    };
  }
};
