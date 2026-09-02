import { spawn } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { dirname, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig, type Plugin, type ViteDevServer } from "vite";

const projectRoot = dirname(fileURLToPath(import.meta.url));
const sourceRoot = resolve(projectRoot, "src");
const blogRoot = "src/typst/blog/";
const fullBuild = Symbol("full-build");

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
  // Keep page names and document metadata in their canonical Typst source.
  await run("typst", ["c", "./src/typst/main.typ", "./out/", "--format=bundle"], {
    env: { TYPST_FEATURES: "bundle,html" },
  });
}

async function updateBlogPost(file: string): Promise<void> {
  await run("just", ["_generate_blog_idx", file], {
    env: { SHOW_DRAFTS: "true" },
  });

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
  const needsFullBuild =
    changes.includes(fullBuild) ||
    files.some((file) => !isStaticAsset(file) && !isBlogPost(file));

  if (needsFullBuild) {
    await run("just", ["build"], { env: { SHOW_DRAFTS: "true" } });
    return true;
  }

  if (files.some(isStaticAsset)) {
    await syncStaticAssets();
  }

  const posts = [...new Set(files.filter(isBlogPost))];
  for (const post of posts) {
    await updateBlogPost(post);
  }

  if (posts.length > 0) {
    await compileMainBundle();
    return true;
  }

  return false;
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
      server.watcher.add(sourceRoot);

      const sourceChanged = (absolutePath: string) => {
        const file = projectPath(absolutePath);
        // This watcher also receives changes under Vite's out/ root. Only
        // source changes should schedule builds; otherwise each generated file
        // starts another build and creates an infinite loop.
        if (!file.startsWith("src/") || isGeneratedSource(file)) return;
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
