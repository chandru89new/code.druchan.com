const as = document.querySelectorAll("article a");
Array.from(as).forEach((a) => {
  try {
    let href = a.getAttribute("href");
    if (href.startsWith("http")) {
      a.setAttribute("target", "_blank");
      return;
    }
    let linkEl = document.createElement("link");
    linkEl.setAttribute("rel", "next");
    linkEl.setAttribute("rel", "prefetch");
    linkEl.setAttribute("href", href);
  } catch (e) {
    console.warn(e);
  }
});
