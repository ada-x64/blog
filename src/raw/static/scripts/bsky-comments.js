(() => {
  const container = document.getElementById("bsky-comments");
  if (!container) return;

  const atprotoId = container.getAttribute("data-atproto-id");
  if (!atprotoId) return;

  const api = `https://public.api.bsky.app/xrpc/app.bsky.feed.getPostThread?depth=8&uri=${encodeURIComponent(atprotoId)}`;

  const esc = (value = "") =>
    String(value).replace(/[&<>"']/g, (match) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    }[match]));

  const atToWeb = (uri) =>
    uri
      .replace("at://", "https://bsky.app/profile/")
      .replace("/app.bsky.feed.post/", "/post/");

  const renderPost = (node) => {
    if (!node || !node.post || !node.post.record) return "";

    const post = node.post;
    const author = post.author || {};
    const text = esc(post.record.text || "").replace(/\n/g, "<br>");
    const createdAt = new Date(post.record.createdAt || post.indexedAt || Date.now()).toLocaleString();
    const replies = Array.isArray(node.replies) ? node.replies.map(renderPost).filter(Boolean).join("") : "";

    return `
      <li class="bsky-comment">
        <p class="bsky-comment-meta">
          <a href="${atToWeb(post.uri)}" target="_blank" rel="noopener noreferrer">${esc(author.displayName || author.handle || "unknown")}</a>
          · ${createdAt}
        </p>
        <p class="bsky-comment-text">${text}</p>
        ${replies ? `<ul class="bsky-comment-replies">${replies}</ul>` : ""}
      </li>
    `;
  };

  fetch(api)
    .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`HTTP ${res.status}`))))
    .then((data) => {
      const root = data.thread;
      const rootUri = root?.post?.uri || atprotoId;
      const replies = Array.isArray(root?.replies) ? root.replies.map(renderPost).filter(Boolean).join("") : "";

      container.innerHTML = `
        <p><a href="${atToWeb(rootUri)}" target="_blank" rel="noopener noreferrer">Reply on Bluesky</a></p>
        ${replies ? `<ul class="bsky-comments-list">${replies}</ul>` : "<p>No replies yet.</p>"}
      `;
    })
    .catch(() => {
      container.textContent = "Comments unavailable.";
    });
})();
