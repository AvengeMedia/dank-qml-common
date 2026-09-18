.pragma library
.import "Contrast.js" as Contrast

var SLOTS = ["red", "orange", "yellow", "green", "teal", "blue", "purple", "pink"];
var ANCHOR_HUES = {
    "red": 25,
    "orange": 55,
    "yellow": 90,
    "green": 145,
    "teal": 195,
    "blue": 260,
    "purple": 300,
    "pink": 345
};
var MAX_HARMONIZE_DEGREES = 15;
var NEUTRAL_CHROMA = 0.02;
var FILL_LIGHTNESS_DARK = 0.80;
var FILL_LIGHTNESS_LIGHT = 0.88;
var FILL_CHROMA_MIN = 0.04;
var FILL_CHROMA_MAX = 0.09;
var GLYPH_LIGHTNESS_MAX = 0.42;
var GLYPH_LIGHTNESS_MIN = 0.15;
var GLYPH_CHROMA_MIN = 0.06;
var GLYPH_CHROMA_MAX = 0.14;
var TARGET_RATIO = 4.5;

function linearize(v) {
    return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
}

function delinearize(v) {
    return v <= 0.0031308 ? v * 12.92 : 1.055 * Math.pow(v, 1 / 2.4) - 0.055;
}

function toOklch(color) {
    const r = linearize(color.r);
    const g = linearize(color.g);
    const b = linearize(color.b);
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    const L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    const A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    const B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    const C = Math.sqrt(A * A + B * B);
    const H = (Math.atan2(B, A) * 180 / Math.PI + 360) % 360;
    return {
        L,
        C,
        H
    };
}

function oklchToLinear(L, C, H) {
    const A = C * Math.cos(H * Math.PI / 180);
    const B = C * Math.sin(H * Math.PI / 180);
    const l = Math.pow(L + 0.3963377774 * A + 0.2158037573 * B, 3);
    const m = Math.pow(L - 0.1055613458 * A - 0.0638541728 * B, 3);
    const s = Math.pow(L - 0.0894841775 * A - 1.2914855480 * B, 3);
    return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s];
}

function inGamut(rgb) {
    return rgb.every(v => v >= -0.0005 && v <= 1.0005);
}

function fromOklch(L, C, H) {
    let rgb = oklchToLinear(L, C, H);
    if (!inGamut(rgb)) {
        let low = 0;
        let high = C;
        for (let i = 0; i < 10; i++) {
            const mid = (low + high) / 2;
            if (inGamut(oklchToLinear(L, mid, H)))
                low = mid;
            else
                high = mid;
        }
        rgb = oklchToLinear(L, low, H);
    }
    const clamp = v => Math.min(1, Math.max(0, delinearize(Math.min(1, Math.max(0, v)))));
    return Qt.rgba(clamp(rgb[0]), clamp(rgb[1]), clamp(rgb[2]), 1);
}

function hueDifference(from, to) {
    let diff = (to - from) % 360;
    if (diff > 180)
        diff -= 360;
    if (diff < -180)
        diff += 360;
    return diff;
}

// Material Color Utilities Blend.harmonize: rotate at most 15 degrees toward the key hue.
function harmonize(hue, keyHue) {
    const diff = hueDifference(hue, keyHue);
    const rotation = Math.min(Math.abs(diff) * 0.5, MAX_HARMONIZE_DEGREES);
    return (hue + Math.sign(diff) * rotation + 360) % 360;
}

function clampChroma(value, min, max) {
    return Math.min(max, Math.max(min, value));
}

function readableGlyph(fill, chroma, hue) {
    let low = GLYPH_LIGHTNESS_MIN;
    let high = GLYPH_LIGHTNESS_MAX;
    if (Contrast.ratio(fromOklch(high, chroma, hue), fill) >= TARGET_RATIO)
        return fromOklch(high, chroma, hue);
    for (let i = 0; i < 8; i++) {
        const mid = (low + high) / 2;
        if (Contrast.ratio(fromOklch(mid, chroma, hue), fill) >= TARGET_RATIO)
            low = mid;
        else
            high = mid;
    }
    return fromOklch(low, chroma, hue);
}

function derive(primary, isLight, overrides) {
    const key = toOklch(primary);
    const neutralKey = key.C < NEUTRAL_CHROMA;
    const fillLightness = isLight ? FILL_LIGHTNESS_LIGHT : FILL_LIGHTNESS_DARK;
    const accents = {};
    for (const slot of SLOTS) {
        const override = overrides && overrides[slot] ? toOklch(Qt.color(overrides[slot])) : null;
        const hue = override ? override.H : (neutralKey ? ANCHOR_HUES[slot] : harmonize(ANCHOR_HUES[slot], key.H));
        const chromaRef = override ? override.C : key.C;
        const fill = fromOklch(fillLightness, clampChroma(chromaRef * 0.8, FILL_CHROMA_MIN, FILL_CHROMA_MAX), hue);
        accents[slot] = {
            "container": fill,
            "onContainer": readableGlyph(fill, clampChroma(chromaRef, GLYPH_CHROMA_MIN, GLYPH_CHROMA_MAX), hue)
        };
    }
    return accents;
}
