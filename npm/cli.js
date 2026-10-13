#!/usr/bin/env node
// npx github:thienleeba/dev-flow            install for every AI tool found on this machine
// npx github:thienleeba/dev-flow <repo>     install into one repo (commit the result for your team)
// npx github:thienleeba/dev-flow uninstall [repo]  remove it again (from the machine, or from one repo)
// options: --no-claude  --force (back up files that use DevFlow's names)  --dry-run
"use strict";
const { spawnSync } = require("child_process");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const args = process.argv.slice(2);
const flag = (f) => args.includes(f);
const DRY = flag("--dry-run");
const NO_CLAUDE = flag("--no-claude");
const FORCE = flag("--force");
const positional = args.filter((a) => !a.startsWith("--"));
const uninstall = positional[0] === "uninstall";
const repoPath = !uninstall ? positional[0] : undefined;

const has = (cmd) => spawnSync(process.platform === "win32" ? "where" : "which", [cmd], { stdio: "ignore" }).status === 0;

function run(cmd, cmdArgs, { quiet = false } = {}) {
  const line = [cmd, ...cmdArgs].join(" ");
  if (DRY) { console.log("  would run:", line); return true; }
  const r = spawnSync(cmd, cmdArgs, { stdio: quiet ? "pipe" : "inherit", encoding: "utf8" });
  return r.status === 0;
}

function bash(installArgs) {
  if (!has("bash")) {
    console.error("✗ bash is required (on Windows use Git Bash or WSL).");
    process.exit(1);
  }
  return run("bash", [path.join(ROOT, "install.sh"), ...installArgs]);
}

const claude = !NO_CLAUDE && has("claude");
const extra = [...(NO_CLAUDE ? ["--no-claude"] : []), ...(FORCE ? ["--force"] : [])];

// Earlier versions installed a Claude Code plugin (commands were /dev:morning). Commands are
// now plain /dev-morning skills, so remove that plugin if it is there.
function removeOldPlugin() {
  if (!claude || DRY) return;
  const r = spawnSync("claude", ["plugin", "list"], { encoding: "utf8" });
  if ((r.stdout || "").includes("dev@dev-flow")) {
    run("claude", ["plugin", "uninstall", "dev@dev-flow"], { quiet: true });
    console.log("  (removed the old dev@dev-flow plugin — commands are now /dev-morning …)");
  }
}

console.log("DevFlow — /dev-morning · /dev-plan · /dev-report\n");

if (uninstall) {
  if (positional[1]) process.exit(bash([path.resolve(positional[1]), "--uninstall"]) ? 0 : 1);
  removeOldPlugin();
  process.exit(bash(["--global", "--uninstall"]) ? 0 : 1);
}

if (repoPath) {
  // One repo for the whole team: skills + agents for every tool, committed with the code.
  const ok = bash([path.resolve(repoPath), ...extra]);
  if (ok) console.log("\nCommit the new files so your teammates get the commands too.");
  process.exit(ok ? 0 : 1);
}

removeOldPlugin();
const ok = bash(["--global", ...extra]);
process.exit(ok ? 0 : 1);
