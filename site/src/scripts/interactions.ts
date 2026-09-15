// All homepage micro-interactions live here: sticky header shrink, scroll
// reveals, the one-shot Mole Moment dig sequence, and a very subtle cursor
// follow on the hero mascot. Every effect short-circuits under
// prefers-reduced-motion, leaving elements in their final, static state.

const reduceMotion = window.matchMedia(
  "(prefers-reduced-motion: reduce)",
).matches;

// --- Sticky header shrink -------------------------------------------------
const header = document.getElementById("site-header");
if (header) {
  const onScroll = () => {
    header.classList.toggle("is-scrolled", window.scrollY > 24);
  };
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
}

// --- Scroll reveals --------------------------------------------------------
const revealEls = document.querySelectorAll<HTMLElement>(".reveal");

if (reduceMotion || !("IntersectionObserver" in window)) {
  revealEls.forEach((el) => el.classList.add("is-visible"));
} else {
  const revealObserver = new IntersectionObserver(
    (entries, obs) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          obs.unobserve(entry.target);
        }
      }
    },
    { threshold: 0.2, rootMargin: "0px 0px -10% 0px" },
  );
  revealEls.forEach((el) => revealObserver.observe(el));
}

// Note: the Mole Moment mound animation is now a real looping GIF the maker
// authored (MoleArt pose "dig-loop"), swapped for a static frame under
// prefers-reduced-motion via CSS alone — see MoleMoment.astro. No JS needed.

// --- Hero mascot: very subtle cursor-follow + blink ------------------------
const heroMole = document.querySelector<HTMLElement>(".hero-mole");
if (heroMole && !reduceMotion && matchMedia("(hover: hover)").matches) {
  let raf = 0;
  const onMove = (e: MouseEvent) => {
    if (raf) return;
    raf = requestAnimationFrame(() => {
      const rect = heroMole.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      const dx = Math.max(-1, Math.min(1, (e.clientX - cx) / 300));
      const dy = Math.max(-1, Math.min(1, (e.clientY - cy) / 300));
      heroMole.style.transform = `translate(${dx * 3}px, ${dy * 2}px)`;
      raf = 0;
    });
  };
  window.addEventListener("mousemove", onMove, { passive: true });
}
