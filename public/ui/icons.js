/* Eluminia — sprite d'icônes SVG (public/ui/icons.js)
   Zéro build : ce script injecte le sprite <symbol> une fois au chargement.
   Usage : <svg class="el-icon"><use href="#icon-play"></use></svg>
   currentColor hérite la couleur du texte du bouton/élément parent — pas
   besoin de variante par couleur. Voir public/ui-styleguide.html pour la
   liste complète rendue. */
(function () {
  var SYMBOLS = {
    play: '<path d="M6 4.5v15l14-7.5-14-7.5z"/>',
    close: '<path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="3" stroke-linecap="round" fill="none"/>',
    check: '<path d="M4 12.5l5.5 5.5L20 7" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    cross: '<path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" fill="none"/>',
    gift: '<path d="M4 10h16v3H4z"/><path d="M5 13h14v7H5z"/><path d="M11 10v10M13 10v10" stroke="#0a1230" stroke-width="1.2"/><path d="M12 10c-1.6 0-4-1-4-3.2C8 5 9.3 4 10.6 4 12 4 12 7 12 10z"/><path d="M12 10c1.6 0 4-1 4-3.2 0-1.8-1.3-2.8-2.6-2.8C12 4 12 7 12 10z"/>',
    egg: '<ellipse cx="12" cy="13" rx="6.2" ry="8"/>',
    settings: '<circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" stroke-width="2.4"/><path d="M12 3.5v2.4M12 18.1v2.4M20.5 12h-2.4M5.9 12H3.5M18 6l-1.7 1.7M7.7 16.3L6 18M18 18l-1.7-1.7M7.7 7.7L6 6" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    menu: '<path d="M4 6.5h16M4 12h16M4 17.5h16" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>',
    back: '<path d="M15 5l-7 7 7 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    chat: '<path d="M4 5h16v10H9l-4 4v-4H4z"/>',
    mail: '<rect x="3.5" y="6" width="17" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M4.5 7.5l7.5 6 7.5-6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
    addPerson: '<circle cx="10" cy="8.5" r="3.5"/><path d="M3.5 20c0-3.6 2.9-6.5 6.5-6.5S16.5 16.4 16.5 20z"/><path d="M19 8v6M22 11h-6" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    crown: '<path d="M4 17h16l1-9-5 3-4-6-4 6-5-3z"/>',
    star: '<path d="M12 3.5l2.7 5.9 6.3.7-4.7 4.4 1.3 6.3L12 17.6l-5.6 3.2 1.3-6.3-4.7-4.4 6.3-.7z"/>',
    coin: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="5.5" fill="none" stroke="#0a1230" stroke-width="1.4"/>',
    gem: '<path d="M4 9.5L12 3l8 6.5L12 21z"/>',
    crystal: '<path d="M12 2l4 6-4 14-4-14z"/>',
    trophy: '<path d="M7 4h10v5a5 5 0 01-10 0z"/><path d="M5 6H3.5C3.5 9 5 10.5 7 10.5M19 6h1.5c0 3-1.5 4.5-3.5 4.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M10 14h4v3h-4z"/><path d="M7 20h10l-1-2.5H8z"/>',
    bolt: '<path d="M13 2L5 14h5l-1 8 8-12h-5z"/>',
    heart: '<path d="M12 20S3.5 14.5 3.5 8.8C3.5 5.6 6 3.5 8.7 3.5c1.6 0 3 .8 3.3 2 .3-1.2 1.7-2 3.3-2 2.7 0 5.2 2.1 5.2 5.3C20.5 14.5 12 20 12 20z"/>',
    paw: '<circle cx="6" cy="9" r="2.1"/><circle cx="11" cy="6.3" r="2.1"/><circle cx="16" cy="9" r="2.1"/><path d="M11 10.5c3 0 5.3 2.3 5.3 4.8 0 2-1.6 3.2-3.4 3.2-1 0-1.3-.5-1.9-.5s-.9.5-1.9.5c-1.8 0-3.4-1.2-3.4-3.2 0-2.5 2.3-4.8 5.3-4.8z"/>',
    question: '<circle cx="12" cy="12" r="9.5"/><path d="M9.3 9.5c0-1.7 1.3-2.8 2.9-2.8s2.7 1 2.7 2.4c0 1.6-1.5 2-2.2 2.9-.3.4-.4.8-.4 1.4" fill="none" stroke="#0a1230" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="17" r="1.1" fill="#0a1230"/>',
    lock: '<rect x="5" y="10.5" width="14" height="10" rx="2"/><path d="M8 10.5V7.5a4 4 0 018 0v3" fill="none" stroke="currentColor" stroke-width="2.4"/>',
    avatar: '<circle cx="12" cy="8.5" r="4"/><path d="M4 20c0-4.4 3.6-7 8-7s8 2.6 8 7z"/>',
    home: '<path d="M4 11.5L12 4l8 7.5V20h-5v-6H9v6H4z"/>',
    trash: '<path d="M5 7h14M9 7V5h6v2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><path d="M6.5 7l1 13h9l1-13z"/>',
    sound: '<path d="M4 9.5h4l5-4v13l-5-4H4z"/><path d="M16.5 9c1 .8 1.6 1.9 1.6 3s-.6 2.2-1.6 3" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    music: '<circle cx="7" cy="18" r="2.6"/><circle cx="17" cy="16" r="2.6"/><path d="M9.6 18V6.5L19.6 4v11.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    info: '<circle cx="12" cy="12" r="9.5"/><rect x="10.7" y="10.2" width="2.6" height="7" rx="1" fill="#0a1230"/><circle cx="12" cy="7.4" r="1.5" fill="#0a1230"/>',
    plus: '<path d="M12 5v14M5 12h14" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>',
    book: '<path d="M4 5.5C4 4.7 4.7 4 5.5 4H11v15H5.5c-.8 0-1.5.7-1.5 1.5z"/><path d="M20 5.5C20 4.7 19.3 4 18.5 4H13v15h5.5c.8 0 1.5.7 1.5 1.5z"/><path d="M11 4v15M13 4v15" stroke="#0a1230" stroke-width="1.4"/>'
  };

  var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('aria-hidden', 'true');
  svg.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden;';
  var defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
  Object.keys(SYMBOLS).forEach(function (name) {
    var symbol = document.createElementNS('http://www.w3.org/2000/svg', 'symbol');
    symbol.setAttribute('id', 'icon-' + name);
    symbol.setAttribute('viewBox', '0 0 24 24');
    symbol.innerHTML = SYMBOLS[name];
    defs.appendChild(symbol);
  });
  svg.appendChild(defs);

  function inject() {
    document.body.insertBefore(svg, document.body.firstChild);
  }
  if (document.body) inject();
  else document.addEventListener('DOMContentLoaded', inject);

  window.ELUMINIA_ICON_NAMES = Object.keys(SYMBOLS);
})();
