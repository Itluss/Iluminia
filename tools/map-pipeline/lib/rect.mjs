// sharp().extract() attend {left, top, width, height} ; nos plans utilisent
// {x, y, width, height} (plus lisible pour la géométrie) — conversion unique
// à cet endroit plutôt que dispersée à chaque appel.
export function toSharpRect(r) {
  return { left: r.x, top: r.y, width: r.width, height: r.height };
}

/** Intersection de deux rects {x,y,width,height} ; null si disjoints ou touchants (aire nulle). */
export function intersectRect(a, b) {
  const x = Math.max(a.x, b.x);
  const y = Math.max(a.y, b.y);
  const right = Math.min(a.x + a.width, b.x + b.width);
  const bottom = Math.min(a.y + a.height, b.y + b.height);
  if (right <= x || bottom <= y) return null;
  return { x, y, width: right - x, height: bottom - y };
}
