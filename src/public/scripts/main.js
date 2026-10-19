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

const themeCycle = ["system", "light", "dark"];

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
			const currentTheme = window.localStorage.getItem("theme") ?? "system";
			const nextThemeIdx = themeCycle.indexOf(currentTheme);
			const theme = themeCycle[(nextThemeIdx + 1) % 3];
			const isDark =
				theme === "dark" ||
				(theme === "system" &&
					window.matchMedia("(prefers-color-scheme: dark)").matches);
			const html = document.querySelector("html");
			const className = `${theme} ${isDark && theme === "system" ? "dark" : ""}`;
			html.className = className;
			html.setAttribute("data-madoromi", `natsu-${isDark ? "yoru" : "hiru"}`);
			window.localStorage.setItem("theme", theme);
		});
});
