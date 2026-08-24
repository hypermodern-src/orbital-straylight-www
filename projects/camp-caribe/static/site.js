(function () {
  "use strict";

  var root = document.documentElement;
  var body = document.body;
  var header = document.querySelector("[data-site-header]");
  var menuToggle = document.querySelector("[data-menu-toggle]");
  var navigation = document.querySelector("[data-primary-nav]");
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var scrollTicking = false;

  function setMenu(open, restoreFocus) {
    body.classList.toggle("menu-open", open);
    if (menuToggle) {
      menuToggle.setAttribute("aria-expanded", String(open));
      menuToggle.setAttribute("aria-label", menuToggle.getAttribute(open ? "data-menu-close-label" : "data-menu-open-label") || "Menu");
    }
    if (open && navigation) {
      var firstLink = navigation.querySelector("a");
      if (firstLink) window.setTimeout(function () { firstLink.focus(); }, 0);
    } else if (restoreFocus && menuToggle) {
      menuToggle.focus();
    }
  }

  if (menuToggle && navigation) {
    menuToggle.addEventListener("click", function () {
      setMenu(!body.classList.contains("menu-open"));
    });

    navigation.addEventListener("click", function (event) {
      if (event.target.closest("a")) setMenu(false);
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && body.classList.contains("menu-open")) setMenu(false, true);
    });
  }

  function updateScrollUi() {
    if (header) header.classList.toggle("is-scrolled", window.scrollY > 28);
    var scrollRange = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
    root.style.setProperty("--scroll-progress", String(Math.min(1, window.scrollY / scrollRange)));
    scrollTicking = false;
  }

  function queueScrollUi() {
    if (scrollTicking) return;
    scrollTicking = true;
    window.requestAnimationFrame(updateScrollUi);
  }

  updateScrollUi();
  window.addEventListener("scroll", queueScrollUi, { passive: true });
  window.addEventListener("resize", queueScrollUi, { passive: true });

  var revealItems = Array.prototype.slice.call(document.querySelectorAll("[data-reveal]"));
  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealItems.forEach(function (item) { item.classList.add("is-visible"); });
  } else {
    var revealObserver = new IntersectionObserver(function (entries, observer) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { rootMargin: "0px 0px -8%", threshold: 0.08 });

    revealItems.forEach(function (item) { revealObserver.observe(item); });
    root.classList.add("js");
  }

  var lightbox = document.getElementById("gallery-lightbox");
  var lightboxImage = lightbox && lightbox.querySelector("[data-lightbox-image]");
  var lightboxCaption = lightbox && lightbox.querySelector("[data-lightbox-caption]");
  var lightboxClose = lightbox && lightbox.querySelector("[data-lightbox-close]");
  var activeLightboxTrigger = null;

  function closeLightbox() {
    if (!lightbox || !lightbox.open) return;
    lightbox.close();
    body.classList.remove("lightbox-open");
  }

  document.querySelectorAll("[data-lightbox-src]").forEach(function (trigger) {
    trigger.addEventListener("click", function () {
      if (!lightbox || !lightboxImage || !lightboxCaption || !lightbox.showModal) return;
      activeLightboxTrigger = trigger;
      lightboxImage.src = trigger.getAttribute("data-lightbox-src") || "";
      lightboxImage.alt = trigger.getAttribute("data-lightbox-alt") || "";
      lightboxCaption.textContent = trigger.getAttribute("data-lightbox-alt") || "";
      lightbox.showModal();
      body.classList.add("lightbox-open");
    });
  });

  if (lightboxClose) lightboxClose.addEventListener("click", closeLightbox);
  if (lightbox) {
    lightbox.addEventListener("click", function (event) {
      if (event.target === lightbox) closeLightbox();
    });
    lightbox.addEventListener("close", function () {
      body.classList.remove("lightbox-open");
      if (activeLightboxTrigger) activeLightboxTrigger.focus();
      activeLightboxTrigger = null;
    });
  }

  var briefingForm = document.getElementById("briefing-form");
  if (briefingForm) {
    briefingForm.addEventListener("submit", function (event) {
      event.preventDefault();
      if (!briefingForm.reportValidity()) return;

      var data = new FormData(briefingForm);
      var spanish = briefingForm.getAttribute("data-language") === "es";
      var recipient = briefingForm.getAttribute("data-recipient") || "";
      var labels = spanish
        ? {
            name: "Nombre",
            organization: "Pareja o planificador",
            email: "Correo",
            phone: "Teléfono",
            size: "Cantidad de invitados",
            dates: "Fechas",
            purpose: "Propósito",
            message: "Detalles"
          }
        : {
            name: "Name",
            organization: "Partner or planner",
            email: "Email",
            phone: "Phone",
            size: "Guest count",
            dates: "Dates",
            purpose: "Purpose",
            message: "Details"
          };

      var name = String(data.get("name") || "");
      var subject = spanish
        ? "Consulta de evento en Camp Caribe — " + name
        : "Camp Caribe event inquiry — " + name;
      var lines = [
        labels.name + ": " + name,
        labels.organization + ": " + String(data.get("organization") || "—"),
        labels.email + ": " + String(data.get("email") || ""),
        labels.phone + ": " + String(data.get("phone") || "—"),
        labels.size + ": " + String(data.get("group-size") || ""),
        labels.dates + ": " + String(data.get("dates") || ""),
        labels.purpose + ": " + String(data.get("purpose") || ""),
        "",
        labels.message + ":",
        String(data.get("message") || "—")
      ];

      window.location.href = "mailto:" + recipient
        + "?subject=" + encodeURIComponent(subject)
        + "&body=" + encodeURIComponent(lines.join("\n"));
    });
  }
})();
