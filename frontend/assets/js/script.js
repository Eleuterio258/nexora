// Scroll para secção vinda de outra página (sem hash na URL)
(function () {
  const section = sessionStorage.getItem("scrollTo");
  if (section) {
    sessionStorage.removeItem("scrollTo");
    const el = document.getElementById(section);
    if (el) {
      requestAnimationFrame(() => {
        window.scrollTo({ top: el.offsetTop - 80, behavior: "smooth" });
      });
    }
  }
})();

// Mobile Menu Toggle
const mobileMenuBtn = document.getElementById("mobileMenuBtn");
const navMenu = document.getElementById("navMenu");

mobileMenuBtn.addEventListener("click", () => {
  navMenu.classList.toggle("active");
});

document.querySelectorAll(".nav-link").forEach((link) => {
  link.addEventListener("click", () => {
    navMenu.classList.remove("active");
  });
});

// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute("href"));
    if (target) {
      window.scrollTo({ top: target.offsetTop - 80, behavior: "smooth" });
    }
  });
});

// Navbar shadow on scroll
window.addEventListener("scroll", () => {
  const nav = document.querySelector(".nav");
  nav.style.boxShadow =
    window.scrollY > 0
      ? "0 2px 8px rgba(0,0,0,0.1)"
      : "0 1px 3px rgba(0,0,0,0.1)";
});

// ── Carousel de Serviços ──────────────────────────────────────
(function () {
  const track = document.getElementById("carouselTrack");
  const prevBtn = document.getElementById("prevBtn");
  const nextBtn = document.getElementById("nextBtn");
  const dotsEl = document.getElementById("carouselDots");

  if (!track) return;

  const slides = Array.from(track.children);
  let current = 0;

  function getSlidesVisible() {
    if (window.innerWidth <= 600) return 1;
    if (window.innerWidth <= 900) return 2;
    return 3;
  }

  function totalPages() {
    return Math.ceil(slides.length / getSlidesVisible());
  }

  // Build dots
  function buildDots() {
    dotsEl.innerHTML = "";
    for (let i = 0; i < totalPages(); i++) {
      const btn = document.createElement("button");
      btn.className = "carousel-dot" + (i === current ? " active" : "");
      btn.setAttribute("aria-label", "Página " + (i + 1));
      btn.addEventListener("click", () => goTo(i));
      dotsEl.appendChild(btn);
    }
  }

  function goTo(index) {
    const pages = totalPages();
    current = Math.max(0, Math.min(index, pages - 1));

    // Calculate slide width including gap (gap = --space-5 = 1.25rem = 20px)
    const gap = 20;
    const slideW = slides[0].offsetWidth + gap;
    const perPage = getSlidesVisible();
    const offset = current * perPage * slideW;

    track.style.transform = `translateX(-${offset}px)`;

    // Update dots
    Array.from(dotsEl.children).forEach((dot, i) => {
      dot.classList.toggle("active", i === current);
    });

    prevBtn.disabled = current === 0;
    nextBtn.disabled = current >= pages - 1;
  }

  prevBtn.addEventListener("click", () => goTo(current - 1));
  nextBtn.addEventListener("click", () => goTo(current + 1));

  window.addEventListener("resize", () => {
    buildDots();
    goTo(0);
  });

  buildDots();
  goTo(0);
})();

// Technology Tabs
document.querySelectorAll(".tech-tab-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tabId = btn.dataset.tab;

    document
      .querySelectorAll(".tech-tab-btn")
      .forEach((b) => b.classList.remove("active"));
    document
      .querySelectorAll(".tech-panel")
      .forEach((p) => p.classList.remove("active"));

    btn.classList.add("active");
    document.getElementById("tab-" + tabId).classList.add("active");
  });
});

// Animate elements on scroll
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = "1";
        entry.target.style.transform = "translateY(0)";
      }
    });
  },
  { threshold: 0.1, rootMargin: "0px 0px -50px 0px" },
);

document.addEventListener("DOMContentLoaded", () => {
  document
    .querySelectorAll(".card, .step, .benefit-card, .about-card, .tech-item")
    .forEach((el) => {
      el.style.opacity = "0";
      el.style.transform = "translateY(20px)";
      el.style.transition = "opacity 0.6s ease, transform 0.6s ease";
      observer.observe(el);
    });
});

// Contact Form — envia para API PHP
const contactForm = document.getElementById("contactForm");
if (contactForm) {
  contactForm.addEventListener("submit", async function (e) {
    e.preventDefault();
    const btn = document.getElementById("btnContacto");
    const msg = document.getElementById("formMsg");

    btn.disabled = true;
    btn.textContent = "A enviar…";
    msg.textContent = "";
    msg.style.color = "";

    try {
      const res = await fetch("api/contacto.php", {
        method: "POST",
        body: new FormData(this),
      });
      const data = await res.json();

      if (data.sucesso) {
        msg.textContent = data.sucesso;
        msg.style.color = "#059669";
        this.reset();
      } else {
        msg.textContent = data.erro || "Erro desconhecido.";
        msg.style.color = "#ef4444";
      }
    } catch {
      msg.textContent = "Erro de ligação. Tente novamente.";
      msg.style.color = "#ef4444";
    } finally {
      btn.disabled = false;
      btn.innerHTML =
        'Enviar Mensagem <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>';
    }
  });
}
