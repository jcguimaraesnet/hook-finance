import {
  app,
  type HttpRequest,
  type HttpResponseInit,
  type InvocationContext,
} from "@azure/functions";

const APPS_SCRIPT_URL = process.env.APPS_SCRIPT_URL;

async function proxy(
  req: HttpRequest,
  ctx: InvocationContext,
): Promise<HttpResponseInit> {
  if (!APPS_SCRIPT_URL) {
    ctx.error("APPS_SCRIPT_URL not configured");
    return {
      status: 500,
      jsonBody: { ok: false, error: "proxy_misconfigured" },
    };
  }
  try {
    const target = new URL(APPS_SCRIPT_URL);

    if (req.method === "GET") {
      for (const [k, v] of req.query.entries()) {
        target.searchParams.set(k, v);
      }
      const r = await fetch(target.toString(), { redirect: "follow" });
      const body = await r.text();
      return {
        status: r.status,
        headers: { "content-type": "application/json; charset=utf-8" },
        body,
      };
    }

    if (req.method === "POST") {
      const body = await req.text();
      const r = await fetch(target.toString(), {
        method: "POST",
        headers: { "content-type": "text/plain;charset=UTF-8" },
        body,
        redirect: "follow",
      });
      const respBody = await r.text();
      return {
        status: r.status,
        headers: { "content-type": "application/json; charset=utf-8" },
        body: respBody,
      };
    }

    return { status: 405, jsonBody: { ok: false, error: "method_not_allowed" } };
  } catch (err) {
    ctx.error("proxy failed", err);
    return {
      status: 502,
      jsonBody: {
        ok: false,
        error: "proxy_failed",
        detail: err instanceof Error ? err.message : String(err),
      },
    };
  }
}

app.http("proxy", {
  methods: ["GET", "POST"],
  authLevel: "anonymous",
  route: "proxy",
  handler: proxy,
});
