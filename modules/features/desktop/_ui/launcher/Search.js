// Ranking for the launcher: plain functions, no QML.
.pragma library

// Higher is better; 0 is no match. Name prefix beats word prefix beats
// substring beats letters in order, and keywords rank below the name.
function score(query, text) {
  const haystack = (text ?? "").toLowerCase();
  if (haystack === "") return 0;
  if (haystack.startsWith(query)) return 100;
  if (haystack.split(/[\s\-_.]+/).some(word => word.startsWith(query))) return 80;
  if (haystack.includes(query)) return 60;

  let position = 0;
  for (const letter of query) {
    position = haystack.indexOf(letter, position);
    if (position < 0) return 0;
    position += 1;
  }
  return 30;
}

function scoreEntry(query, name, extras) {
  const best = Math.max(0, ...extras.map(extra => score(query, extra) - 40));
  return Math.max(score(query, name), best);
}

// How much use lifts a result, fading over weeks of not being used. Capped below
// the gap between match tiers in score, so it orders similar matches but never
// lifts a worse match over a better one.
function usageBonus(usage, now) {
  if (!usage) return 0;

  const days = (now - usage.last) / 86400000;
  const weight = usage.count / (1 + Math.max(0, days) / 7);
  return Math.min(15, Math.log2(1 + weight) * 4);
}

// Only digits and operators reach Function, so this can only be arithmetic.
function calculate(query) {
  if (!/^[0-9+\-*/%().^\s]*$/.test(query) || !/[+\-*/%^]/.test(query) || !/[0-9]/.test(query))
    return null;

  try {
    const value = new Function(`return (${query.replace(/\^/g, "**")})`)();
    return typeof value === "number" && isFinite(value) ? String(Math.round(value * 1e10) / 1e10) : null;
  } catch (error) {
    return null;
  }
}
