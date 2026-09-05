/// <reference types="node" />

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const cacheDir = path.join(root, "src", "typst", "blog", ".cache", "published");
const outFile = path.join(root, "out", "static", "bsky-posts.json");

const siteBase = (process.env.ATPROTO_POST_URL_BASE ?? "https://cubething.dev/blog").replace(/\/$/, "");
const pds = process.env.ATPROTO_PDS_URL ?? "https://bsky.social";
const identifier = process.env.ATPROTO_DID?.trim() ?? ""; // handle or did
const appPassword = process.env.ATPROTO_APP_PASSWORD?.trim() ?? "";

const searchBases = process.env.ATPROTO_APPVIEW_URL
  ? [process.env.ATPROTO_APPVIEW_URL]
  : ["https://bsky.social", "https://api.bsky.app"];

const canCreate =
  process.env.ATPROTO_AUTOPOST === "true" &&
  process.env.NETLIFY_CONTEXT === "production" &&
  process.env.BRANCH === "main";

type Entry = { slug: string; title: string; description: string; canonicalUrl: string; atprotoId: string };
type Session = { did: string; jwt: string };
type SearchPostsResponse = { posts?: Array<{ uri?: string; author?: { did?: string } }> };

function parseTypstString(value: string | null): string {
  if (!value) return "";
  const trimmed = value.trim();
  if (trimmed === "none") return "";
  if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
    try {
      return JSON.parse(trimmed) as string;
    } catch {
      return trimmed.slice(1, -1);
    }
  }
  return trimmed;
}

function parseEntry(text: string): Entry | null {
  const pathValue = text.match(/path:\s*"([^"]+)"/)?.[1] ?? "";
  const slug = pathValue.replace(/^\.\//, "").replace(/\.html$/, "").trim();
  if (!slug) return null;

  const titleRaw = text.match(/^\s*title:\s*(.+?),\s*$/m)?.[1] ?? null;
  const descRaw = text.match(/^\s*description:\s*(.+?),\s*$/m)?.[1] ?? null;
  const atprotoRaw = text.match(/^\s*atproto_id:\s*(.+?),\s*$/m)?.[1] ?? null;

  return {
    slug,
    title: parseTypstString(titleRaw),
    description: parseTypstString(descRaw),
    canonicalUrl: `${siteBase}/${slug}`,
    atprotoId: parseTypstString(atprotoRaw),
  };
}

async function fetchJson<T>(url: URL | string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, init);
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.url}`);
  return (await res.json()) as T;
}

async function openSession(): Promise<Session> {
  const url = new URL("/xrpc/com.atproto.server.createSession", pds);
  const data = await fetchJson<{ accessJwt?: string; did?: string }>(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ identifier, password: appPassword }),
  });

  if (!data.did || !data.accessJwt) throw new Error("session failed");
  return { did: data.did, jwt: data.accessJwt };
}

async function searchPostUri(canonicalUrl: string, ownerDid: string, jwt: string): Promise<string | null> {
  for (const base of searchBases) {
    try {
      const url = new URL("/xrpc/app.bsky.feed.searchPosts", base);
      url.searchParams.set("q", canonicalUrl);
      url.searchParams.set("url", canonicalUrl);
      url.searchParams.set("limit", "50");

      const data = await fetchJson<SearchPostsResponse>(url, {
        headers: { authorization: `Bearer ${jwt}` },
      });

      const posts = data.posts ?? [];
      const uri = posts.find((post) => post.author?.did === ownerDid && post.uri)?.uri ?? null;
      if (uri) return uri;
    } catch {
      // Try next host.
    }
  }

  return null;
}

function makeText(entry: Entry): string {
  const text = entry.title ? `${entry.title}\n\n${entry.canonicalUrl}` : entry.canonicalUrl;
  return text.length <= 300 ? text : entry.canonicalUrl;
}

function upsertAtprotoInCache(text: string, uri: string): string {
  const line = `            atproto_id: ${JSON.stringify(uri)},`;
  if (/^\s*atproto_id:\s*.+?,\s*$/m.test(text)) {
    return text.replace(/^\s*atproto_id:\s*.+?,\s*$/m, line);
  }
  return text.replace(/^(\s*)draft:\s*(true|false)\s*$/m, `${line}\n$1draft: $2`);
}

async function createPost(entry: Entry, session: Session): Promise<string> {
  const url = new URL("/xrpc/com.atproto.repo.createRecord", pds);
  const data = await fetchJson<{ uri?: string }>(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${session.jwt}`,
    },
    body: JSON.stringify({
      repo: session.did,
      collection: "app.bsky.feed.post",
      record: {
        $type: "app.bsky.feed.post",
        text: makeText(entry),
        createdAt: new Date().toISOString(),
        embed: {
          $type: "app.bsky.embed.external",
          external: {
            uri: entry.canonicalUrl,
            title: entry.title || entry.canonicalUrl,
            description: entry.description,
          },
        },
      },
    }),
  });

  if (!data.uri) throw new Error(`createRecord returned no uri for ${entry.slug}`);
  return data.uri;
}

async function main(): Promise<void> {
  await fs.mkdir(path.dirname(outFile), { recursive: true });

  if (!identifier || !appPassword) {
    await fs.writeFile(outFile, "{}\n", "utf8");
    console.log("ATPROTO_DID and ATPROTO_APP_PASSWORD are required; wrote empty bsky-posts.json");
    return;
  }

  const session = await openSession();
  const files = await fs
    .readdir(cacheDir)
    .then((entries) => entries.filter((name) => name.endsWith(".post.typ")).sort())
    .catch(() => [] as string[]);

  const map: Record<string, string> = {};
  let created = 0;

  for (const name of files) {
    const filePath = path.join(cacheDir, name);
    const text = await fs.readFile(filePath, "utf8");
    const entry = parseEntry(text);
    if (!entry) continue;

    let uri = entry.atprotoId || null;

    if (!uri) {
      uri = await searchPostUri(entry.canonicalUrl, session.did, session.jwt);
    }

    if (!uri && canCreate) {
      try {
        uri = await createPost(entry, session);
        created += 1;
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.log(`::warning title=ATProto sync::create failed for ${entry.canonicalUrl}: ${message}`);
      }
    }

    if (uri) {
      map[entry.slug] = uri;
      if (!entry.atprotoId) {
        const next = upsertAtprotoInCache(text, uri);
        if (next !== text) await fs.writeFile(filePath, next, "utf8");
      }
    } else {
      console.log(`::warning title=ATProto sync::no post found for ${entry.canonicalUrl}`);
    }
  }

  await fs.writeFile(outFile, `${JSON.stringify(map)}\n`, "utf8");
  console.log(`Wrote ${Object.keys(map).length} post IDs to ${path.relative(root, outFile)}${created ? ` (created ${created})` : ""}`);
}

await main();
