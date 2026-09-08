import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

for (const fixture of ["slider", "foreground", "states"]) {
    test(`${fixture} component behavior`, () => {
        const directory = mkdtempSync(join(tmpdir(), "dank-widgets-"));
        try {
            for (const name of ["DankCommon", "Common", "Services"])
                symlinkSync(fileURLToPath(new URL(`../${name}`, import.meta.url)), join(directory, name));
            copyFileSync(new URL(`qml/${fixture}.qml`, import.meta.url), join(directory, "shell.qml"));
            mkdirSync(join(directory, "runtime"), { mode: 0o700 });
            const output = execFileSync("qs", ["-p", directory], {
                encoding: "utf8",
                timeout: 30000,
                env: {
                    ...process.env,
                    QT_QPA_PLATFORM: "offscreen",
                    XDG_RUNTIME_DIR: join(directory, "runtime"),
                    XDG_CONFIG_HOME: join(directory, "config"),
                    XDG_CACHE_HOME: join(directory, "cache"),
                    XDG_DATA_HOME: join(directory, "data")
                }
            });
            assert.match(output, /PASS/);
        } finally {
            rmSync(directory, { recursive: true, force: true });
        }
    });
}
