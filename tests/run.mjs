import { execFileSync } from "node:child_process";
import { readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";

const directory = new URL("./", import.meta.url);
const tests = readdirSync(directory).filter(name => name.endsWith(".test.mjs")).sort();
if (tests.length === 0)
    throw new Error("No common tests found");

for (const name of tests) {
    try {
        execFileSync(process.execPath, [fileURLToPath(new URL(name, directory))], { stdio: "inherit" });
    } catch {
        process.exitCode = 1;
    }
}
