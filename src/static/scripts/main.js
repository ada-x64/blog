function rearrange_notes() {
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
}

const STORED_THEME = window.localStorage.getItem("theme");
let isDark = STORED_THEME ? STORED_THEME == "dark" : window.matchMedia("(prefers-color-scheme: dark)").matches;
if (isDark) {
  document.querySelector("html").classList.add("dark");
  window.localStorage.setItem("theme", "dark")
} else {
  window.localStorage.setItem("theme", "light")
}

document.addEventListener("DOMContentLoaded", () => {
  try {
    rearrange_notes()
  } catch {}

  document.querySelector("#toggle-lights").addEventListener("click", (event) => {
    isDark = !isDark;
    document.querySelector("html").classList.toggle("dark")
    window.localStorage.setItem("theme", isDark ? "dark" : "light");
  })
})
