import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const rgba = (r, g, b, a = 1) => ({ r, g, b, a });
const hex = value => rgba(...[1, 3, 5].map(i => parseInt(value.slice(i, i + 2), 16) / 255));
const contrast = vm.createContext({ Qt: { rgba } });
vm.runInContext(readFileSync(new URL("../DankCommon/Common/Contrast.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), contrast);

const black = hex("#000000");
const white = hex("#ffffff");

test("ratio follows WCAG relative luminance", () => {
    assert.ok(Math.abs(contrast.ratio(white, black) - 21) < 1e-9);
    assert.ok(Math.abs(contrast.ratio(black, white) - 21) < 1e-9);
    assert.ok(Math.abs(contrast.ratio(hex("#777777"), white) - 4.48) < 0.01);
});

test("tonal containers keep the surface text, accent containers do not", () => {
    assert.ok(contrast.isTonal(hex("#4F378B"), hex("#E6E0E9")));
    assert.ok(!contrast.isTonal(hex("#88c0d0"), hex("#eceff4")));
});

test("readableOn takes the first candidate that meets the target, else the best", () => {
    const nord = hex("#88c0d0");
    const surfaceText = hex("#eceff4");
    const surface = hex("#2e3440");
    assert.equal(contrast.readableOn(nord, [surfaceText, surface, white, black]), surface);
    assert.deepEqual(contrast.readableOn(hex("#4F378B"), [hex("#E6E0E9"), surface]), hex("#E6E0E9"));
    assert.deepEqual(contrast.readableOn(hex("#777777"), [hex("#888888"), hex("#666666")], 21), hex("#666666"));
});

test("tintedContainer uses the strongest tint that keeps the text readable", () => {
    const base = hex("#444b6a");
    const tint = hex("#7aa2f7");
    const text = hex("#c0caf5");
    const strong = contrast.tintedContainer(hex("#1d2024"), hex("#42a5f5"), hex("#e0e2e8"));
    assert.deepEqual(strong, contrast.mix(hex("#1d2024"), hex("#42a5f5"), 0.36));
    const limited = contrast.tintedContainer(base, tint, text);
    const amount = (limited.r - base.r) / (tint.r - base.r);
    assert.ok(amount >= 0.12 && amount < 0.36);
    assert.ok(contrast.ratio(limited, text) >= contrast.ratio(contrast.mix(base, tint, amount + 0.01), text));
});
