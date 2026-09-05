import { spawn } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { dirname, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig, type Plugin, type ViteDevServer } from "vite";

const projectRoot = dirname(fileURLToPath(import.meta.url));
const sourceRoot = resolve(projectRoot, "src");
const resumeRoot = resolve(projectRoot, "resume");
const blogRoot = "src/typst/blog/";
const postsIndex = resolve(projectRoot, blogRoot, "_posts.typ");
const fullBuild = Symbol("full-build");
let didRunAtprotoSyncInDev = false;

type Change = string | typeof fullBuild;

function run(
  command: string,
  args: string[],
  options: { env?: NodeJS.ProcessEnv } = {},
): Promise<void> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, {
      cwd: projectRoot,
      env: { ...process.env, ...options.env },
      stdio: "inherit",
    });

    child.on("error", reject);
    child.on("close", (code, signal) => {
      if (code === 0) {
        resolvePromise();
      } else {
        reject(
          new Error(
            `${command} ${args.join(" ")} failed${
              signal ? ` with signal ${signal}` : ` with exit code ${code}`
            }`,
          ),
        );
      }
    });
  });
}

function projectPath(file: string): string {
  return relative(projectRoot, file).split(sep).join("/");
}

function isGeneratedSource(file: string): boolean {
  return (
    file.startsWith(`${blogRoot}.cache/`) ||
    file === `${blogRoot}main.typ` ||
    file === `${blogRoot}index.typ` ||
    file === `${blogRoot}_posts.typ`
  );
}

function isStaticAsset(file: string): boolean {
  return file.startsWith("src/static/");
}

function isResumeSource(file: string): boolean {
  return file.startsWith("resume/");
}

function isMainBundleSource(file: string): boolean {
  return [
    "src/typst/main.typ",
    "src/typst/index.typ",
    "src/typst/now.typ",
  ].includes(file);
}

function isRootTemplate(file: string): boolean {
  return file === "src/typst/_template.typ";
}

function isBlogTemplate(file: string): boolean {
  return file === `${blogRoot}_template.typ`;
}

function isSharedTypstAsset(file: string): boolean {
  return file.startsWith("src/typst/assets/");
}

function isBlogPost(file: string): boolean {
  if (!file.startsWith(blogRoot) || !file.endsWith(".typ")) {
    return false;
  }

  const name = file.slice(blogRoot.length).split("/").at(-1)!;
  return !name.startsWith("_") && name !== "main.typ" && name !== "index.typ";
}

async function syncStaticAssets(): Promise<void> {
  await run("rsync", [
    "-r",
    "--delete",
    "--exclude",
    "resume.pdf",
    "./src/static/",
    "./out/static/",
  ]);
}

async function compileMainBundle(): Promise<void> {
  await run("just", ["_compile_main"]);
}

async function compileBlogBundle(): Promise<void> {
  await run("just", ["_compile_blog"]);
}

async function compileResume(): Promise<void> {
  await run("just", ["build-resume"]);
}

async function updateBlogMetadata(file?: string): Promise<void> {
  const args = file ? ["_generate_blog_idx", file] : ["_generate_blog_idx"];
  await run("just", args, { env: { SHOW_DRAFTS: "true" } });
}

async function compileBlogPost(file: string): Promise<void> {
  const relativePost = file.slice(blogRoot.length);
  const output = resolve(
    projectRoot,
    "out/blog",
    relativePost.replace(/\.typ$/, ".html"),
  );
  const source = resolve(projectRoot, file);

  if (!existsSync(source)) {
    rmSync(output, { force: true });
    return;
  }

  mkdirSync(dirname(output), { recursive: true });
  await run("typst", ["c", source, output, "--format=html"], {
    env: {
      TYPST_FEATURES: "bundle,html",
      TYPST_ROOT: "./src/typst",
    },
  });
}

async function buildChanges(changes: Change[]): Promise<boolean> {
  const files = changes.filter((change): change is string => change !== fullBuild);
  const isKnownSource = (file: string) =>
    isStaticAsset(file) ||
    isResumeSource(file) ||
    isMainBundleSource(file) ||
    isRootTemplate(file) ||
    isBlogTemplate(file) ||
    isSharedTypstAsset(file) ||
    isBlogPost(file);

  if (changes.includes(fullBuild) || files.some((file) => !isKnownSource(file))) {
    const runAtprotoSync = !didRunAtprotoSyncInDev;
    await run("just", ["build"], {
      env: {
        SHOW_DRAFTS: "true",
        ATPROTO_SYNC: runAtprotoSync ? "true" : "false",
      },
    });
    didRunAtprotoSyncInDev = true;
    return true;
  }

  const posts = [...new Set(files.filter(isBlogPost))];
  const blogTemplateChanged = files.some(isBlogTemplate);
  const rootTemplateChanged = files.some(isRootTemplate);
  const sharedAssetChanged = files.some(isSharedTypstAsset);
  const mainSourceChanged = files.some(isMainBundleSource);
  let metadataChanged = false;

  if (posts.length > 0 || blogTemplateChanged) {
    const before = await readFile(postsIndex, "utf8").catch(() => "");
    if (blogTemplateChanged) {
      // The blog template defines post metadata, so let the cache invalidate
      // and refresh every post when that template changes.
      await updateBlogMetadata();
    } else {
      for (const post of posts) {
        await updateBlogMetadata(post);
      }
    }
    const after = await readFile(postsIndex, "utf8").catch(() => "");
    metadataChanged = before !== after;
  }

  const rebuildAllBlogPosts =
    blogTemplateChanged || rootTemplateChanged || sharedAssetChanged || metadataChanged;
  const rebuildMain =
    mainSourceChanged || rebuildAllBlogPosts;
  const tasks: Promise<void>[] = [];

  if (files.some(isStaticAsset)) tasks.push(syncStaticAssets());
  if (files.some(isResumeSource)) tasks.push(compileResume());
  if (rebuildMain) tasks.push(compileMainBundle());
  if (rebuildAllBlogPosts) tasks.push(compileBlogBundle());

  if (!rebuildAllBlogPosts) {
    tasks.push(...posts.map(compileBlogPost));
  } else {
    // Bundle compilation cannot remove output for a deleted source document.
    tasks.push(
      ...posts
        .filter((post) => !existsSync(resolve(projectRoot, post)))
        .map(compileBlogPost),
    );
  }

  await Promise.all(tasks);
  return rebuildMain || rebuildAllBlogPosts || posts.length > 0;
}

function typstDevelopmentPlugin(): Plugin {
  let server: ViteDevServer;
  let debounceTimer: ReturnType<typeof setTimeout> | undefined;
  let building = false;
  const pending = new Set<Change>();

  const reportError = (error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    server.config.logger.error(`\nTypst build failed: ${message}\n`);
  };

  const drainBuildQueue = async () => {
    if (building) return;
    building = true;

    try {
      while (pending.size > 0) {
        const changes = [...pending];
        pending.clear();

        try {
          const reload = await buildChanges(changes);
          if (reload) {
            server.ws.send({ type: "full-reload", path: "*" });
          }
        } catch (error) {
          // Keep serving the last successful output and continue processing any
          // source changes that arrived while this build was running.
          reportError(error);
        }
      }
    } finally {
      building = false;
    }
  };

  const enqueue = (change: Change) => {
    pending.add(change);
    if (building) return;

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(drainBuildQueue, 40);
  };

  return {
    name: "typst-development",
    apply: "serve",
    configureServer(viteServer) {
      server = viteServer;
      server.watcher.add([sourceRoot, resumeRoot]);

      const sourceChanged = (absolutePath: string) => {
        const file = projectPath(absolutePath);
        // This watcher also receives changes under Vite's out/ root. Only
        // source changes should schedule builds; otherwise each generated file
        // starts another build and creates an infinite loop.
        if (
          (!file.startsWith("src/") && !file.startsWith("resume/")) ||
          isGeneratedSource(file)
        ) return;
        enqueue(file);
      };

      server.watcher.on("add", sourceChanged);
      server.watcher.on("change", sourceChanged);
      server.watcher.on("unlink", sourceChanged);

      // Build after Vite starts instead of blocking server startup. A broken
      // document therefore leaves the dev server available for the next save.
      enqueue(fullBuild);
    },
  };
}

export default defineConfig({
  root: "./out",
  appType: "mpa",
  clearScreen: false,
  plugins: [typstDevelopmentPlugin()],
  server: {
    host: "localhost",
    open: true,
    port: 3030,
    watch: {
      // Generated HTML is written as a transaction. The plugin sends one reload
      // only after every affected output has compiled successfully.
      ignored: [
        "**/*.html",
        "**/src/typst/blog/.cache/**",
        "**/src/typst/blog/{main,index,_posts}.typ",
      ],
    },
  },
});
