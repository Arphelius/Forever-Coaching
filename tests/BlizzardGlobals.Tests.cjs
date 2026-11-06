// Writing a Blizzard global from addon code taints it, even with the same value. SlashCmdList is read
// by every macro line, so `SlashCmdList = SlashCmdList or {}` gets /startattack blocked in macros.
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const root = path.join(__dirname, "..", "addons", "ForeverCoaching");
const pattern = /(^|[;\s])(SlashCmdList|UISpecialFrames|StaticPopupDialogs|UIPanelWindows)\s*=\s*\2\s+or\b/;

function luaFiles(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) return luaFiles(full);
        return entry.name.endsWith(".lua") ? [full] : [];
    });
}

const bad = [];
for (const file of luaFiles(root)) {
    fs.readFileSync(file, "utf8").split("\n").forEach((line, i) => {
        if (pattern.test(line)) bad.push(`${path.relative(root, file)}:${i + 1}`);
    });
}
assert.deepStrictEqual(bad, [], "Blizzard globals reassigned from addon code");
console.log("BlizzardGlobals tests passed");
