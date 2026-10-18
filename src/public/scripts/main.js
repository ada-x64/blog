function rearrange_notes() {
	const notes = document.querySelector('body > section[role="doc-endnotes"]');
	const footer = document.querySelector("body > footer");

	if (notes && footer) {
		footer.before(notes);
	}

	const child = document.createElement("h2");
	child.innerText = "Notes";
	notes.querySelector("ol").before(child);
}

let isDark = document.documentElement.classList.contains("dark");

document.addEventListener("DOMContentLoaded", () => {
	try {
		rearrange_notes();
	} catch {}

	for (const wrap of document.querySelectorAll(".carousel-wrap")) {
		const list = wrap.querySelector(".carousel");
		wrap.querySelector(".prev").addEventListener("click", () => {
			list.scrollBy({ left: -list.clientWidth, behavior: "smooth" });
		});
		wrap.querySelector(".next").addEventListener("click", () => {
			list.scrollBy({ left: list.clientWidth, behavior: "smooth" });
		});
	}

	document
		.querySelector(".toggle-lights")
		.addEventListener("click", (_event) => {
			isDark = !isDark;
			document.querySelector("html").classList.toggle("dark");
			window.localStorage.setItem("theme", isDark ? "dark" : "light");
		});
});
