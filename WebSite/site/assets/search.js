// Progressive enhancement only: content never depends on this script.
window.addEventListener("DOMContentLoaded", function () {
  var mount = document.getElementById("search");
  if (!mount || typeof PagefindUI === "undefined") return;
  var ui = new PagefindUI({ element: "#search", showImages: false, resetStyles: false });
  var input = mount.querySelector("input");
  if (input) {
    input.id = "search-input";
    var label = document.createElement("label");
    label.htmlFor = "search-input";
    label.textContent = "Search " + document.title.split(" · ").pop();
    label.className = "search-label";
    input.parentNode.insertBefore(label, input);
  }
  var query = new URLSearchParams(window.location.search).get("q");
  if (query) ui.triggerSearch(query);
});
