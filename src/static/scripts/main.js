document.addEventListener("DOMContentLoaded", () => {
  const notes = document.querySelector(
    'body > section[role="doc-endnotes"]'
  );
  const footer = document.querySelector('body > footer');

  if (notes && footer) {
    footer.before(notes);
  }

  const child = document.createElement("h2")
  child.innerText = "Notes"
  notes.querySelector("ol").before(child)
})
