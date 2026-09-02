# blog

[build status](https://app.netlify.com/projects/cubething/deploys) | [live site](https://cubething.dev)

This is a dead-simple typst-based static site for a blog and portfolio.

In the era of AI, creating things by hand is a sign that you actually know what
you're doing. Minimalism is the new chic. So instead of having [a shiny,
feature-rich blog,](https://github.com/ada-x64/cubething-quartz) I'd rather have
something that more adequately expresses _foundational skills_ and _taste_ (the
new buzzword), focusing on intentional content rather than my ability to write
the web framework _du jour._

Also, I've always adored the web1.0 aesthetic. Perhaps the [web
revival](https://thoughts.melonking.net/guides/introduction-to-the-web-revival-1-what-is-the-web-revival)
isn't dead, after all.

This approach is inspired by a blog post by [Iris
Merideth,](https://deadsimpletech.com/blog/tech-aint-deep) as well as the layout of
[bear,](https://bearblog.dev/) [harmony corpsesprit's
blog,](https://harmonyzone.org/blog/) and all the lovely, minimalist systems
engineering blogs on [lobste.rs](https://lobste.rs)

## Development

Read the justfile.

## Build benchmarks

**Disclaimer:** gpt-5.6-sol wrote the benchmarking code and helped optimize the
build process. All code was strictly reviewed and modified by hand.

Measured over five runs with Typst 0.15.0 under WSL2 on an Intel Core Ultra 9
285H. Times are wall-clock medians; incremental builds use the development
configuration, including draft posts.

| Build | Median | Range |
| --- | ---: | ---: |
| Clean full build | 1.842 s | 1.827–1.881 s |
| Cached full build | 0.570 s | 0.561–0.585 s |
| Incremental blog post | 0.535 s | 0.529–0.545 s |
| Change to `main.typ` | 0.069 s | 0.067–0.071 s |
| Change to `_template.typ` | 1.681 s | 1.662–1.736 s |

Run the benchmark suite locally with:

```sh
bun run benchmark --suite builds --runs 5
```

## Feature list

- [x] Typst bundle compilation
- [x] Blog posts with metadata
- [x] Blog post index page
- [x] Chronological footer navigation
- [x] Mobile-friendly styling
- [x] Dark mode
- [x] Résumé submodule
- [x] Subsecond recompilation time
- [x] Live reload
