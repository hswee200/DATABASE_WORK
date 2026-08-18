// Deterministic color per course ID so a course's card is always the same
// color across the overview, without storing a color anywhere.
const PALETTE = ['#2f5fd6', '#0f9d58', '#e08a1c', '#7e3fd6', '#d6336c', '#0d9488'];

export function courseColor(courseId) {
  let hash = 0;
  for (let i = 0; i < courseId.length; i++) {
    hash = (hash * 31 + courseId.charCodeAt(i)) >>> 0;
  }
  return PALETTE[hash % PALETTE.length];
}
