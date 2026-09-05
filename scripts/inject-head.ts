/// <reference types="node" />

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outDir = path.join(root, "out");
const headFile = path.join(root, "src", "typst", "head.html");
const START = "<!-- injected-head:start -->";
const END = "<!-- injected-head:end -->";

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function parseHeadFragment(raw: string): string {
  const headMatch = raw.match(/<head\b[^>]*>([\s\S]*?)<\/head>/i);
  const fragment = (headMatch ? headMatch[1] : raw).trim();
  if (!fragment) throw new Error(`empty head fragment in ${path.relative(root, headFile)}`);
  return `${START}\n${fragment}\n${END}`;
}

function injectHeadBlock(html: string, block: string): string {
  const markerPattern = new RegExp(`${escapeRegex(START)}[\\s\\S]*?${escapeRegex(END)}\\s*`, "g");
  const cleaned = html.replace(markerPattern, "");
  if (!/<\/head>/i.test(cleaned)) return html;
  return cleaned.replace(/<\/head>/i, `${block}</head>`);
}

async function listHtml(dir: string): Promise<string[]> {
  const entries = await fs.readdir(dir, { withFileTypes: true }).catch(() => []);
  const children = await Promise.all(
    entries.map(async (entry) => {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) return listHtml(full);
      return entry.isFile() && full.endsWith(".html") ? [full] : [];
    }),
  );
  return children.flat();
}

async function main(): Promise<void> {
  const raw = await fs.readFile(headFile, "utf8");
  const block = parseHeadFragment(raw);

  const files = await listHtml(outDir);
  let updated = 0;

  for (const file of files) {
    const html = await fs.readFile(file, "utf8");
    const next = injectHeadBlock(html, block);
    if (next !== html) {
      await fs.writeFile(file, next, "utf8");
      updated += 1;
    }
  }

  console.log(`Injected head fragment into ${updated}/${files.length} HTML file(s)`);
}

await main();
