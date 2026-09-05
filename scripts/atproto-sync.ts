/// <reference types="node" />

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const cacheDir = path.join(root, "src", "typst", "blog", ".cache", "published");
const bskyOutFile = path.join(root, "out", "bsky-posts.json");
const standardOutFile = path.join(root, "out", "standard-docs.json");
const atprotoDidOutFile = path.join(root, "out", ".well-known", "atproto-did");
const publicationFile = path.join(
	root,
	"src",
	"public",
	".well-known",
	"site.standard.publication",
);

const siteBase = (
	process.env.ATPROTO_POST_URL_BASE ?? "https://cubething.dev/blog"
).replace(/\/$/, "");
const pds = process.env.ATPROTO_PDS_URL ?? "https://bsky.social";
const identifier = process.env.ATPROTO_DID?.trim() ?? ""; // handle or did
const appPassword = process.env.ATPROTO_APP_PASSWORD?.trim() ?? "";

const searchBases = process.env.ATPROTO_APPVIEW_URL
	? [process.env.ATPROTO_APPVIEW_URL]
	: ["https://bsky.social", "https://api.bsky.app"];

const autoPostEnabled = (process.env.ATPROTO_AUTOPOST ?? "false") === "true";
const deployContext = process.env.CONTEXT ?? process.env.NETLIFY_CONTEXT ?? "";
const deployBranch = process.env.BRANCH ?? "";
const canCreate =
	autoPostEnabled && deployContext === "production" && deployBranch === "main";

type Entry = {
	slug: string;
	title: string;
	description: string;
	canonicalUrl: string;
	atprotoId: string;
	publishedAt: string;
};
type Session = { did: string; jwt: string };
type SearchPostsResponse = {
	posts?: Array<{ uri?: string; author?: { did?: string } }>;
};

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

function parsePublishedAt(value: string | null): string {
	if (!value) return new Date().toISOString();
	const raw = value.trim();
	if (!raw || raw === "none") return new Date().toISOString();

	const plain = parseTypstString(raw);
	const iso = plain.match(/^(\d{4})-(\d{2})-(\d{2})/);
	if (iso) {
		return new Date(
			Date.UTC(Number(iso[1]), Number(iso[2]) - 1, Number(iso[3])),
		).toISOString();
	}

	const year = raw.match(/year:\s*(\d{4})/);
	const month = raw.match(/month:\s*(\d{1,2})/);
	const day = raw.match(/day:\s*(\d{1,2})/);
	if (year && month && day) {
		return new Date(
			Date.UTC(Number(year[1]), Number(month[1]) - 1, Number(day[1])),
		).toISOString();
	}

	return new Date().toISOString();
}

function parseEntry(text: string): Entry | null {
	const pathValue = text.match(/path:\s*"([^"]+)"/)?.[1] ?? "";
	const slug = pathValue
		.replace(/^\.\//, "")
		.replace(/\.html$/, "")
		.trim();
	if (!slug) return null;

	const titleRaw = text.match(/^\s*title:\s*(.+?),\s*$/m)?.[1] ?? null;
	const descRaw = text.match(/^\s*description:\s*(.+?),\s*$/m)?.[1] ?? null;
	const dateRaw = text.match(/^\s*date:\s*(.+?),\s*$/m)?.[1] ?? null;
	const atprotoRaw = text.match(/^\s*atproto_id:\s*(.+?),\s*$/m)?.[1] ?? null;

	return {
		slug,
		title: parseTypstString(titleRaw),
		description: parseTypstString(descRaw),
		canonicalUrl: `${siteBase}/${slug}`,
		atprotoId: parseTypstString(atprotoRaw),
		publishedAt: parsePublishedAt(dateRaw),
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

async function searchPostUri(
	canonicalUrl: string,
	ownerDid: string,
	jwt: string,
): Promise<string | null> {
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
			const uri =
				posts.find((post) => post.author?.did === ownerDid && post.uri)?.uri ??
				null;
			if (uri) return uri;
		} catch {
			// Try next host.
		}
	}

	return null;
}

async function getRecordUri(
	session: Session,
	collection: string,
	rkey: string,
): Promise<string | null> {
	const url = new URL("/xrpc/com.atproto.repo.getRecord", pds);
	url.searchParams.set("repo", session.did);
	url.searchParams.set("collection", collection);
	url.searchParams.set("rkey", rkey);

	const res = await fetch(url, {
		headers: { authorization: `Bearer ${session.jwt}` },
	});

	if (res.status === 400 || res.status === 404) return null;
	if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.url}`);

	const data = (await res.json()) as { uri?: string };
	return data.uri ?? null;
}

function makeText(entry: Entry): string {
	const text = entry.title
		? `${entry.title}\n\n${entry.canonicalUrl}`
		: entry.canonicalUrl;
	return text.length <= 300 ? text : entry.canonicalUrl;
}

function upsertAtprotoInCache(text: string, uri: string): string {
	const line = `            atproto_id: ${JSON.stringify(uri)},`;
	if (/^\s*atproto_id:\s*.+?,\s*$/m.test(text)) {
		return text.replace(/^\s*atproto_id:\s*.+?,\s*$/m, line);
	}
	return text.replace(
		/^(\s*)draft:\s*(true|false)\s*$/m,
		`${line}\n$1draft: $2`,
	);
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

	if (!data.uri)
		throw new Error(`createRecord returned no uri for ${entry.slug}`);
	return data.uri;
}

async function createStandardDocument(
	entry: Entry,
	session: Session,
	publicationUri: string,
): Promise<string> {
	const url = new URL("/xrpc/com.atproto.repo.createRecord", pds);
	const data = await fetchJson<{ uri?: string }>(url, {
		method: "POST",
		headers: {
			"content-type": "application/json",
			authorization: `Bearer ${session.jwt}`,
		},
		body: JSON.stringify({
			repo: session.did,
			collection: "site.standard.document",
			rkey: entry.slug,
			record: {
				$type: "site.standard.document",
				site: publicationUri,
				title: entry.title || entry.slug,
				path: `/${entry.slug}`,
				description: entry.description || undefined,
				publishedAt: entry.publishedAt,
			},
		}),
	});

	if (!data.uri)
		throw new Error(
			`standard.site createRecord returned no uri for ${entry.slug}`,
		);
	return data.uri;
}

async function loadPublicationUri(): Promise<string> {
	try {
		return (await fs.readFile(publicationFile, "utf8")).trim();
	} catch {
		return "";
	}
}

async function writeMaps(
	bsky: Record<string, string>,
	standard: Record<string, string>,
): Promise<void> {
	await fs.writeFile(bskyOutFile, `${JSON.stringify(bsky)}\n`, "utf8");
	await fs.writeFile(standardOutFile, `${JSON.stringify(standard)}\n`, "utf8");
}

async function writeAtprotoDid(did: string): Promise<void> {
	await fs.mkdir(path.dirname(atprotoDidOutFile), { recursive: true });
	await fs.writeFile(atprotoDidOutFile, `${did}\n`, "utf8");
}

async function main(): Promise<void> {
	await fs.mkdir(path.dirname(bskyOutFile), { recursive: true });

	console.log(
		`ATProto sync: autoPost=${autoPostEnabled} context=${deployContext || "unknown"} branch=${deployBranch || "unknown"} canCreate=${canCreate}`,
	);
	if (autoPostEnabled && !canCreate) {
		console.log(
			`::notice title=ATProto sync::autopost is only enabled for context=production and branch=main (got context=${deployContext || "unknown"}, branch=${deployBranch || "unknown"})`,
		);
	}

	if (!identifier || !appPassword) {
		if (identifier.startsWith("did:")) {
			await writeAtprotoDid(identifier);
			console.log(
				`Wrote DID to ${path.relative(root, atprotoDidOutFile)} from ATPROTO_DID`,
			);
		}
		await writeMaps({}, {});
		console.log(
			"ATPROTO_DID and ATPROTO_APP_PASSWORD are required; wrote empty maps",
		);
		return;
	}

	const session = await openSession();
	await writeAtprotoDid(session.did);
	const publicationUri = await loadPublicationUri();
	if (!publicationUri) {
		console.log(
			"::notice title=ATProto sync::missing src/public/.well-known/site.standard.publication; standard.site documents will not be created",
		);
	}

	const files = await fs
		.readdir(cacheDir)
		.then((entries) =>
			entries.filter((name) => name.endsWith(".post.typ")).sort(),
		)
		.catch(() => [] as string[]);

	const bskyMap: Record<string, string> = {};
	const standardMap: Record<string, string> = {};
	let createdPosts = 0;
	let createdStandard = 0;

	for (const name of files) {
		const filePath = path.join(cacheDir, name);
		const text = await fs.readFile(filePath, "utf8");
		const entry = parseEntry(text);
		if (!entry) continue;

		let bskyUri = entry.atprotoId || null;
		if (!bskyUri) {
			bskyUri = await searchPostUri(
				entry.canonicalUrl,
				session.did,
				session.jwt,
			);
		}
		if (!bskyUri && canCreate) {
			try {
				bskyUri = await createPost(entry, session);
				createdPosts += 1;
				console.log(
					`::notice title=ATProto sync::created post for ${entry.canonicalUrl}`,
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				console.log(
					`::warning title=ATProto sync::create failed for ${entry.canonicalUrl}: ${message}`,
				);
			}
		}

		if (bskyUri) {
			bskyMap[entry.slug] = bskyUri;
			if (!entry.atprotoId) {
				const next = upsertAtprotoInCache(text, bskyUri);
				if (next !== text) await fs.writeFile(filePath, next, "utf8");
			}
		} else {
			console.log(
				`::warning title=ATProto sync::no post found for ${entry.canonicalUrl}`,
			);
		}

		let standardUri: string | null = null;
		try {
			standardUri = await getRecordUri(
				session,
				"site.standard.document",
				entry.slug,
			);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			console.log(
				`::warning title=ATProto sync::standard lookup failed for ${entry.slug}: ${message}`,
			);
		}

		if (!standardUri && canCreate && publicationUri) {
			try {
				standardUri = await createStandardDocument(
					entry,
					session,
					publicationUri,
				);
				createdStandard += 1;
				console.log(
					`::notice title=ATProto sync::created standard.site document for ${entry.canonicalUrl}`,
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				console.log(
					`::warning title=ATProto sync::standard create failed for ${entry.canonicalUrl}: ${message}`,
				);
			}
		}

		if (standardUri) {
			standardMap[entry.slug] = standardUri;
		}
	}

	await writeMaps(bskyMap, standardMap);
	console.log(
		`Wrote ${Object.keys(bskyMap).length} post IDs to ${path.relative(root, bskyOutFile)}${createdPosts ? ` (created ${createdPosts})` : ""}`,
	);
	console.log(
		`Wrote ${Object.keys(standardMap).length} standard docs to ${path.relative(root, standardOutFile)}${createdStandard ? ` (created ${createdStandard})` : ""}`,
	);
	console.log(`Wrote DID to ${path.relative(root, atprotoDidOutFile)}`);
}

await main();
