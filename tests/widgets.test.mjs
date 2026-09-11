import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

for (const fixture of ["slider", "slider-input", "toggle", "foreground", "states", "selection", "button-group", "window-header", "split-button", "dialog", "analog-clock"]) {
    test(`${fixture} component behavior`, () => {
        const directory = mkdtempSync(join(tmpdir(), "dank-widgets-"));
        try {
            const configDirectory = join(directory, "shell");
            mkdirSync(configDirectory);
            for (const name of ["DankCommon", "Common", "Services"])
                symlinkSync(fileURLToPath(new URL(`../${name}`, import.meta.url)), join(configDirectory, name));
            copyFileSync(new URL(`qml/${fixture}.qml`, import.meta.url), join(configDirectory, "shell.qml"));
            mkdirSync(join(directory, "runtime"), { mode: 0o700 });
            const output = execFileSync("qs", ["-p", configDirectory], {
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
            assert.doesNotMatch(output, /\b(?:ERROR|TypeError|ReferenceError|SyntaxError)\b|Binding loop detected/);
        } catch (error) {
            throw new Error([error.message, error.stdout, error.stderr].filter(Boolean).join("\n"), { cause: error });
        } finally {
            rmSync(directory, { recursive: true, force: true });
        }
    });
}
