/// <reference types="node" />

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outDir = path.join(root, "out");
const headFile = path.join(root, "src", "typst", "head.html");
const standardMapFile = path.join(root, "out", "standard-docs.json");

const HEAD_START = "<!-- injected-head:start -->";
const HEAD_END = "<!-- injected-head:end -->";
const DOC_START = "<!-- injected-standard-doc:start -->";
const DOC_END = "<!-- injected-standard-doc:end -->";

function escapeRegex(value: string): string {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function parseHeadFragment(raw: string): string {
	const headMatch = raw.match(/<head\b[^>]*>([\s\S]*?)<\/head>/i);
	const fragment = (headMatch ? headMatch[1] : raw).trim();
	if (!fragment)
		throw new Error(`empty head fragment in ${path.relative(root, headFile)}`);
	return fragment;
}

function upsertHeadBlock(
	html: string,
	start: string,
	end: string,
	content: string,
): string {
	const markerPattern = new RegExp(
		`${escapeRegex(start)}[\\s\\S]*?${escapeRegex(end)}\\s*`,
		"g",
	);
	const cleaned = html.replace(markerPattern, "");
	if (!content || !/<\/head>/i.test(cleaned)) return cleaned;
	const block = `${start}\n${content}\n${end}`;
	return cleaned.replace(/<\/head>/i, `${block}</head>`);
}

function slugFromOutFile(filePath: string): string | null {
	const rel = path.relative(outDir, filePath).split(path.sep).join("/");
	const match = rel.match(/^blog\/(.+)\.html$/);
	if (!match || match[1] === "index") return null;
	return match[1];
}

async function listHtml(dir: string): Promise<string[]> {
	const entries = await fs
		.readdir(dir, { withFileTypes: true })
		.catch(() => []);
	const children = await Promise.all(
		entries.map(async (entry) => {
			const full = path.join(dir, entry.name);
			if (entry.isDirectory()) return listHtml(full);
			return entry.isFile() && full.endsWith(".html") ? [full] : [];
		}),
	);
	return children.flat();
}

async function loadStandardMap(): Promise<Record<string, string>> {
	try {
		const raw = await fs.readFile(standardMapFile, "utf8");
		return JSON.parse(raw) as Record<string, string>;
	} catch {
		return {};
	}
}

async function main(): Promise<void> {
	const rawHead = await fs.readFile(headFile, "utf8");
	const headFragment = parseHeadFragment(rawHead);
	const standardMap = await loadStandardMap();

	const files = await listHtml(outDir);
	let updated = 0;

	for (const file of files) {
		const html = await fs.readFile(file, "utf8");
		let next = upsertHeadBlock(html, HEAD_START, HEAD_END, headFragment);

		const slug = slugFromOutFile(file);
		const standardUri = slug ? standardMap[slug] : "";
		const docLink = standardUri
			? `<link rel="site.standard.document" href="${standardUri}">`
			: "";
		next = upsertHeadBlock(next, DOC_START, DOC_END, docLink);

		if (next !== html) {
			await fs.writeFile(file, next, "utf8");
			updated += 1;
		}
	}

	console.log(
		`Injected head fragments into ${updated}/${files.length} HTML file(s)`,
	);
}

await main();
