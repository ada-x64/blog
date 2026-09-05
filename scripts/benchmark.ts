import { availableParallelism } from "node:os";
import { readdir } from "node:fs/promises";

const root = new URL("../", import.meta.url).pathname;
const baseEnv = {
  ...process.env,
  TYPST_FEATURES: "bundle,html",
  TYPST_ROOT: "./src/typst",
};

type Command = {
  command: string;
  args: string[];
  env?: Record<string, string | undefined>;
};

type Result = {
  name: string;
  samples: number[];
};

function command(command: string, ...args: string[]): Command {
  return { command, args };
}

async function run({ command, args, env }: Command): Promise<void> {
  const process = Bun.spawn([command, ...args], {
    cwd: root,
    env: { ...baseEnv, ...env },
    stdout: "ignore",
    stderr: "ignore",
  });
  const status = await process.exited;
  if (status !== 0) {
    throw new Error(`${command} ${args.join(" ")} exited with status ${status}`);
  }
}

async function timed(action: () => Promise<void>): Promise<number> {
  const start = Bun.nanoseconds();
  await action();
  return (Bun.nanoseconds() - start) / 1e9;
}

function median(values: number[]): number {
  const sorted = values.toSorted((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[middle - 1]! + sorted[middle]!) / 2
    : sorted[middle]!;
}

function report(results: Result[]): void {
  console.log("\nResults");
  console.log("scenario".padEnd(30), "median    mean      min       max       n");
  for (const { name, samples } of results) {
    const mean = samples.reduce((sum, value) => sum + value, 0) / samples.length;
    console.log(
      name.padEnd(30),
      `${median(samples).toFixed(3)}s`.padEnd(9),
      `${mean.toFixed(3)}s`.padEnd(9),
      `${Math.min(...samples).toFixed(3)}s`.padEnd(9),
      `${Math.max(...samples).toFixed(3)}s`.padEnd(9),
      samples.length,
    );
  }
}

async function sample(
  name: string,
  runs: number,
  action: () => Promise<void>,
): Promise<Result> {
  const samples: number[] = [];
  for (let run = 1; run <= runs; run++) {
    const elapsed = await timed(action);
    samples.push(elapsed);
    console.log(`${name} [${run}/${runs}]: ${elapsed.toFixed(3)}s`);
  }
  return { name, samples };
}

const clean = command("just", "clean");
const build = command("just", "build");
const blogPost = "src/typst/blog/general-introduction.typ";

async function incrementalBlogPost(): Promise<void> {
  await run({
    ...command("just", "_generate_blog_idx", blogPost),
    env: { SHOW_DRAFTS: "true" },
  });
  await run(
    command(
      "typst",
      "c",
      `./${blogPost}`,
      "./out/blog/general-introduction.html",
      "--format=html",
    ),
  );
}

async function buildSuite(runs: number): Promise<void> {
  const cleanSamples: number[] = [];
  const cachedSamples: number[] = [];

  // Pair each output-free build with an immediately repeated build.
  for (let runNumber = 1; runNumber <= runs; runNumber++) {
    await run(clean);
    cleanSamples.push(await timed(() => run(build)));
    console.log(`clean full [${runNumber}/${runs}]: ${cleanSamples.at(-1)!.toFixed(3)}s`);

    cachedSamples.push(await timed(() => run(build)));
    console.log(`cached full [${runNumber}/${runs}]: ${cachedSamples.at(-1)!.toFixed(3)}s`);
  }

  await run(build);
  const results: Result[] = [
    { name: "clean full", samples: cleanSamples },
    { name: "cached full", samples: cachedSamples },
    await sample("incremental blog post", runs, incrementalBlogPost),
    await sample("change to main.typ", runs, () => run(command("just", "_compile_main"))),
    await sample("change to _template.typ", runs, () =>
      Promise.all([
        run(command("just", "_compile_main")),
        run(command("just", "_compile_blog")),
      ]).then(() => undefined),
    ),
  ];
  report(results);
}

async function profileSuite(runs: number): Promise<void> {
  const phases: Array<[string, Command]> = [
    ["public rsync", command("rsync", "-r", "./src/public", "./out/")],
    ["metadata generation", command("just", "_generate_blog_idx")],
    [
      "main bundle",
      command("typst", "c", "./src/typst/main.typ", "./out/", "--format=bundle"),
    ],
    [
      "blog bundle",
      command(
        "typst",
        "c",
        "./src/typst/blog/main.typ",
        "./out/blog",
        "--format=bundle",
      ),
    ],
    [
      "resume",
      {
        ...command(
          "typst",
          "c",
          "./resume/resume/main.typ",
          "./out/resume.pdf",
        ),
        env: { TYPST_ROOT: "." },
      },
    ],
  ];
  const results = new Map(phases.map(([name]) => [name, [] as number[]]));

  for (let runNumber = 1; runNumber <= runs; runNumber++) {
    await run(clean);
    for (const [name, phase] of phases) {
      const elapsed = await timed(() => run(phase));
      results.get(name)!.push(elapsed);
      console.log(`${name} [${runNumber}/${runs}]: ${elapsed.toFixed(3)}s`);
    }
  }
  report([...results].map(([name, samples]) => ({ name, samples })));
}

async function metadataSuite(runs: number): Promise<void> {
  // Generate valid aggregate imports before querying posts independently.
  await run(build);
  const entries = await readdir(`${root}src/typst/blog`, { withFileTypes: true });
  const posts = entries
    .filter(
      (entry) =>
        entry.isFile() &&
        entry.name.endsWith(".typ") &&
        !entry.name.startsWith("_") &&
        entry.name !== "main.typ" &&
        entry.name !== "index.typ",
    )
    .map((entry) => `src/typst/blog/${entry.name}`)
    .sort();
  const maximum = Math.min(availableParallelism(), posts.length);
  const workerCounts = [...new Set([1, 2, 4, 8, maximum])]
    .filter((count) => count <= maximum)
    .toSorted((left, right) => left - right);

  async function query(post: string): Promise<void> {
    await run(
      command(
        "typst",
        "eval",
        "query(metadata).first().value",
        "--in",
        post,
        "--target",
        "html",
      ),
    );
  }

  const results: Result[] = [];
  for (const workers of workerCounts) {
    results.push(
      await sample(`metadata (${workers} workers)`, runs, async () => {
        let next = 0;
        await Promise.all(
          Array.from({ length: workers }, async () => {
            while (next < posts.length) {
              const post = posts[next++]!;
              await query(post);
            }
          }),
        );
      }),
    );
  }
  report(results);
}

function option(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}

const suite = option("--suite") ?? "builds";
const runs = Number(option("--runs") ?? 5);
if (!Number.isSafeInteger(runs) || runs < 1) {
  throw new Error("--runs must be a positive integer");
}

switch (suite) {
  case "builds":
    await buildSuite(runs);
    break;
  case "profile":
    await profileSuite(runs);
    break;
  case "metadata":
    await metadataSuite(runs);
    break;
  case "all":
    await buildSuite(runs);
    await profileSuite(runs);
    await metadataSuite(runs);
    break;
  default:
    throw new Error(`unknown suite ${JSON.stringify(suite)}; expected builds, profile, metadata, or all`);
}
