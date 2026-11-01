// Menu mobile et lien actif au défilement
const nav = document.getElementById("site-nav");
const btn = document.querySelector(".menu-toggle");
const setMenu = (open) => {
  nav.classList.toggle("is-open", open);
  btn.setAttribute("aria-expanded", String(open));
  btn.textContent = open ? "✕" : "☰";
};
btn.addEventListener("click", () => setMenu(!nav.classList.contains("is-open")));
nav.addEventListener("click", (e) => { if (e.target.tagName === "A") setMenu(false); });

const links = [...nav.querySelectorAll("a")];
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      links.forEach((l) => l.setAttribute("aria-current", String(l.hash === "#" + entry.target.id)));
    }
  });
}, { rootMargin: "-40% 0px -55% 0px" });
document.querySelectorAll("main section[id]").forEach((s) => observer.observe(s));

// Keep contributor profiles legible if GitHub avatars cannot be loaded.
document.querySelectorAll("[data-profile-avatar]").forEach((avatar) => {
  const mark = avatar.parentElement;
  const showFallback = () => mark.classList.add("is-fallback");
  avatar.addEventListener("error", showFallback, { once: true });
  if (avatar.complete && avatar.naturalWidth === 0) showFallback();
});
