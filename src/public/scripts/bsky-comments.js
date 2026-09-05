(() => {
  const container = document.getElementById("bsky-comments");
  if (!container) return;

  const match = window.location.pathname.match(
    /^\/blog\/([^\/.]+)(?:\.html)?\/?$/,
  );
  const slug = match?.[1];
  if (!slug) return;

  /** @typedef {{ displayName?: string, handle?: string, avatar?: string }} BskyAuthor */
  /** @typedef {{ text?: string }} BskyRecord */
  /** @typedef {{ uri?: string, author?: BskyAuthor, record?: BskyRecord }} BskyPost */
  /** @typedef {{ post?: BskyPost, replies?: BskyThreadNode[] }} BskyThreadNode */
  /** @typedef {{ [slug: string]: string }} BskyPostMap */
  /** @typedef {{ thread?: BskyThreadNode }} BskyThreadResponse */

  /**
   * @param {string} [value]
   * @returns {string}
   */
  const esc = (value = "") =>
    String(value).replace(
      /[&<>"']/g,
      (ch) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#39;",
        })[ch],
    );

  /**
   * @param {string} uri
   * @returns {string}
   */
  const atToWeb = (uri) =>
    uri
      .replace("at://", "https://bsky.app/profile/")
      .replace("/app.bsky.feed.post/", "/post/");

  /**
   * @param {BskyThreadNode | undefined} node
   * @returns {string}
   */
  const render = (node) => {
    const post = node?.post;
    if (!post?.record || !post.uri) return "";

    const linkProps = `href="${atToWeb(post.uri)}" target="_blank" rel="noopener noreferrer"`;
    const replies = (node.replies || []).map(render).filter(Boolean).join("");
    const avatar = post.author?.avatar
      ? `<img class="reply-avatar" src="${esc(post.author.avatar)}" alt="" loading="lazy" decoding="async" />`
      : "";

    return `
      <li>
        <div class="reply-row">
          <div class="reply-icon">
            <a ${linkProps}>
              ${avatar}
            </a>
          </div>
          <div class="reply">
            <p class="reply-author-name">
              <a ${linkProps}>
                ${esc(post.author?.displayName || post.author?.handle || "unknown")}
              </a>
            </p>
            <p class="reply-content">
              ${esc(post.record.text || "").replace(/\n/g, "<br>")}
            </p>
          </div>
        </div>

        ${replies ? `<ul>${replies}</ul>` : ""}
      </li>`;
  };

  fetch("/bsky-posts.json")
    .then((res) => (res.ok ? res.json() : Promise.resolve({})))
    .then(
      /** @param {BskyPostMap} map */
      (map) => {
        const uri = map?.[slug];
        if (!uri) {
          container.remove();
          return;
        }

        const threadUrl = `https://public.api.bsky.app/xrpc/app.bsky.feed.getPostThread?depth=8&uri=${encodeURIComponent(uri)}`;
        return fetch(threadUrl)
          .then((res) => (res.ok ? res.json() : Promise.reject()))
          .then(
            /** @param {BskyThreadResponse} data */
            (data) => {
              const replies = (data.thread?.replies || [])
                .map(render)
                .filter(Boolean)
                .join("");
              container.innerHTML = `
                <h2>Comments</h2>
                <p>
                  <a href="${atToWeb(uri)}" target="_blank" rel="noopener noreferrer">
                    Reply on Bluesky
                  </a>
                </p>${replies ? `<ul>${replies}</ul>` : "<p>No replies yet.</p>"}
                `;
            },
          );
      },
    )
    .catch(() => {
      container.remove();
    });
})();
