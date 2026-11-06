// Writing a Blizzard global from addon code taints it, even with the same value. SlashCmdList is read
// by every macro line, so `SlashCmdList = SlashCmdList or {}` gets /startattack blocked in macros.
// Create one only if it is missing: `if not SlashCmdList then SlashCmdList={} end`.
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const root = path.join(__dirname, "..", "addons", "ForeverCoaching");

// `Name = Name or ...` on any capitalised global that isn't ours. Locals here are lower case.
const selfOr = /(?:^|[;\s(])([A-Z]\w*)\s*=\s*\1\s+or\b/;
// Any plain write to the tables the client's secure code reads, except the missing-only guard.
const secure = /(?:^|[;\s(])(SlashCmdList|UISpecialFrames|UIPanelWindows|StaticPopupDialogs|UIParent|hash_SlashCmdList)\s*=[^=]/;
const guard = /if\s+not\s+(\w+)\s+then\s+\1\s*=\s*\{\s*\}\s*;?\s*end/g;

function problem(line) {
    const code = line.replace(/--.*$/, "");
    const self = code.match(selfOr);
    if (self && !self[1].startsWith("ForeverCoaching")) return true;
    return secure.test(code.replace(guard, ""));
}

function luaFiles(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) return luaFiles(full);
        return entry.name.endsWith(".lua") ? [full] : [];
    });
}

// The check itself: what it must catch and what it must leave alone.
for (const bad of [
    "SlashCmdList = SlashCmdList or {}",
    "SlashCmdList=SlashCmdList or {};SLASH_X1='/x'",
    "  UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,'F')",
    "ChatFrame1 = ChatFrame1 or {}",
    "StaticPopupDialogs = {}",
    "if x then SlashCmdList = t end",
]) assert.ok(problem(bad), `should be caught: ${bad}`);
for (const good of [
    "if not SlashCmdList then SlashCmdList={} end",
    "if not UISpecialFrames then UISpecialFrames={} end;table.insert(UISpecialFrames,'F')",
    "SlashCmdList['FC'] = handler",
    "SlashCmdList.FC = handler",
    "ForeverCoaching = ForeverCoaching or {}",
    "ForeverCoachingDB=ForeverCoachingDB or {}",
    "name = name or 'x'",
    "if SlashCmdList == nil then return end",
    "-- SlashCmdList = SlashCmdList or {}",
]) assert.ok(!problem(good), `should pass: ${good}`);

const bad = [];
for (const file of luaFiles(root)) {
    fs.readFileSync(file, "utf8").split("\n").forEach((line, i) => {
        if (problem(line)) bad.push(`${path.relative(root, file)}:${i + 1}`);
    });
}
assert.deepStrictEqual(bad, [], "Blizzard globals reassigned from addon code");
console.log("BlizzardGlobals tests passed");
