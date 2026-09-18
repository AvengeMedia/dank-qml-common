import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const rgba = (r, g, b, a = 1) => ({ r, g, b, a });
const hex = value => rgba(...[1, 3, 5].map(i => parseInt(value.slice(i, i + 2), 16) / 255));
const context = vm.createContext({ Qt: { rgba, color: hex } });
const load = name => vm.runInContext(readFileSync(new URL(`../DankCommon/Common/${name}`, import.meta.url), "utf8").replace(/^\.(pragma|import).*$/gm, ""), context);
load("Contrast.js");
context.Contrast = { ratio: context.ratio };
load("Hct.js");
context.Hct = context;
load("Accents.js");

const PRIMARIES = ["#D0BCFF", "#7fbbb3", "#ff2d95", "#9a9a9a", "#7aa2f7"];

test("every slot stays readable and in gamut for muted, vivid and neutral primaries in both modes", () => {
    for (const primary of PRIMARIES) {
        for (const isLight of [false, true]) {
            const accents = context.derive(hex(primary), isLight, null);
            for (const slot of context.SLOTS) {
                const { container, onContainer } = accents[slot];
                assert.ok(context.ratio(onContainer, container) >= 4.5, `${primary} ${isLight ? "light" : "dark"} ${slot}`);
                for (const c of [container, onContainer])
                    assert.ok(["r", "g", "b"].every(k => c[k] >= 0 && c[k] <= 1), `${primary} ${slot} out of gamut`);
            }
        }
    }
});

test("hues follow the primary by at most 15 degrees and a theme override replaces the slot hue", () => {
    const keyHue = context.toHct(hex("#7aa2f7")).hue;
    const derived = context.derive(hex("#7aa2f7"), false, null);
    const shift = context.toHct(derived.green.container).hue - context.ANCHOR_HUES.green;
    assert.ok(Math.abs(shift) <= 15.5 && Math.sign(shift) === context.rotationDirection(context.ANCHOR_HUES.green, keyHue));
    const overridden = context.derive(hex("#D0BCFF"), false, { "blue": "#00c853" });
    assert.ok(context.differenceDegrees(context.toHct(hex("#00c853")).hue, context.toHct(overridden.blue.container).hue) < 1);
});

test("the slot family holds one tone and one chroma, so no slot reads washed out beside another", () => {
    for (const primary of PRIMARIES) {
        for (const isLight of [false, true]) {
            const fills = context.SLOTS.map(s => context.toHct(context.derive(hex(primary), isLight, null)[s].container));
            const tones = fills.map(f => f.tone);
            const chromas = fills.map(f => f.chroma);
            assert.ok(Math.max(...tones) - Math.min(...tones) < 1, `${primary} tone spread`);
            assert.ok(Math.max(...chromas) / Math.min(...chromas) < 1.05, `${primary} chroma spread`);
        }
    }
});
