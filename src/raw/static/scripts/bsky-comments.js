(() => {
  const container = document.getElementById("bsky-comments");
  if (!container) return;

  const match = window.location.pathname.match(
    /^\/blog\/([^\/.]+)(?:\.html)?\/?$/,
  );
  const slug = match?.[1];
  if (!slug) return;

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

  const atToWeb = (uri) =>
    uri
      .replace("at://", "https://bsky.app/profile/")
      .replace("/app.bsky.feed.post/", "/post/");

  const render = (node) => {
    const post = node?.post;
    if (!post?.record) return "";
    const replies = (node.replies || []).map(render).filter(Boolean).join("");
    return `<li>
      <p>
        <a href="${atToWeb(post.uri)}" target="_blank" rel="noopener noreferrer">
          ${esc(post.author?.displayName || post.author?.handle || "unknown")}
        </a>
      </p>
      <p>
        ${esc(post.record.text || "").replace(/\n/g, "<br>")}
      </p>

      ${replies ? `<ul>${replies}</ul>` : ""}
      </li>`;
  };

  fetch("/static/bsky-posts.json")
    .then((res) => (res.ok ? res.json() : {}))
    .then((map) => {
      const uri = map?.[slug];
      if (!uri) {
        container.remove();
        return;
      }

      const threadUrl = `https://public.api.bsky.app/xrpc/app.bsky.feed.getPostThread?depth=8&uri=${encodeURIComponent(uri)}`;
      return fetch(threadUrl)
        .then((res) => (res.ok ? res.json() : Promise.reject()))
        .then((data) => {
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
            </p>${replies ? `<ul>${replies}</ul>` : "<p>No replies yet.</p>"}`;
        });
    })
    .catch(() => {
      container.remove();
    });
})();
