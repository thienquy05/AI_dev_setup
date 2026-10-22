#!/usr/bin/env node
// Usage: merge-json.mjs <base.json> <target.json>
// Deep-merges base into target. Existing scalar values in target WIN (never overwritten);
// arrays are unioned. Writes a .bak copy first. Creates target if missing.
import fs from "node:fs";

const [base, target] = process.argv.slice(2);
const read = (p) => (fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, "utf8") || "{}") : {});
const isObj = (v) => v && typeof v === "object" && !Array.isArray(v);

function merge(t, b) {
  for (const [k, v] of Object.entries(b)) {
    if (isObj(v)) t[k] = merge(isObj(t[k]) ? t[k] : {}, v);
    else if (Array.isArray(v)) t[k] = [...new Set([...(Array.isArray(t[k]) ? t[k] : []), ...v])];
    else if (!(k in t)) t[k] = v;
  }
  return t;
}

const out = merge(read(target), read(base));
if (fs.existsSync(target)) fs.copyFileSync(target, `${target}.bak`);
fs.mkdirSync(new URL(".", `file://${target}`).pathname, { recursive: true });
fs.writeFileSync(target, JSON.stringify(out, null, 2) + "\n");
console.log(`merged ${base} -> ${target}`);
