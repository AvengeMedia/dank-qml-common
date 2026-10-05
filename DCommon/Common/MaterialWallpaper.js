.pragma library
.import "../Widgets/MaterialShapes.js" as Shapes
.import "Accents.js" as Accents
.import "Hct.js" as Hct

var presetIds = ["dank", "bloom", "orbit", "garden", "petal", "dune"];
var defaultPreset = "dank";
var defaultPattern = "topography";
var defaultStrength = 0.1;
var defaultSeed = "#d0bcff";
var designWidth = 1920;
var designHeight = 1080;

function layer(shape, x, y, size, rotation, fill, overlap = "none") {
    return {
        shape,
        x,
        y,
        size,
        rotation,
        fill,
        overlap
    };
}

function preset(id, seed = defaultSeed) {
    let layers;
    let pattern = defaultPattern;
    let strength = defaultStrength;
    switch (id) {
    case "bloom":
        layers = [layer("flower", 0.58, -0.08, 1.15, 12, "primaryContainer"), layer("circle", 0.3, 0.4, 0.7, 0, "secondary", "tertiaryContainer"), layer("cookie6", 0.06, 0.12, 0.3, 0, "primary")];
        break;
    case "orbit":
        layers = [layer("circle", 0.45, 0.22, 1.6, 0, "primaryContainer"), layer("pill", 0.12, -0.2, 0.9, -35, "secondary", "secondaryContainer"), layer("circle", 0.08, 0.14, 0.14, 0, "tertiary")];
        pattern = "bubbles";
        strength = 0.08;
        break;
    case "garden":
        layers = [layer("puffy", -0.15, -0.3, 0.95, 0, "tertiary"), layer("circle", 0.28, 0.1, 1.05, 0, "primaryContainer", "tertiaryContainer"), layer("clover4", 0.6, 0.38, 0.95, 15, "secondary", "secondaryContainer"), layer("circle", 0.82, 0.06, 0.18, 0, "primary")];
        pattern = "graph-paper";
        strength = 0.08;
        break;
    case "petal":
        layers = [layer("square", -0.1, -0.18, 0.78, 0, "primary"), layer("softBoom", 0.0, 0.0, 0.85, 0, "primaryContainer", "tertiaryContainer"), layer("arrow", 0.36, 0.3, 1.3, 225, "tertiary"), layer("boom", 0.62, 0.12, 1.15, 10, "secondary", "primaryContainer")];
        pattern = "plus";
        strength = 0.15;
        break;
    case "dune":
        layers = [layer("semiCircle", 0.5, 0.18, 0.75, 0, "secondary"), layer("oval", 0.15, 0.5, 1.4, -10, "primaryContainer", "tertiaryContainer"), layer("sunny", 0.1, 0.1, 0.2, 0, "tertiary")];
        pattern = "wiggle";
        strength = 0.1;
        break;
    default:
        id = defaultPreset;
        layers = [layer("softBurst", 0.42, -0.3, 1.5, 0, "primaryContainer"), layer("dankLogo", 0.735, 0.26, 0.38, 0, "primary"), layer("sunny", 0.06, 0.08, 0.26, 10, "tertiary"), layer("pill", 0.1, 0.66, 0.5, -25, "secondaryContainer")];
    }
    return {
        version: 1,
        preset: id,
        seed,
        layers,
        pattern,
        strength
    };
}

function validSeed(value) {
    return /^#[\da-f]{6}$/i.test(value);
}

function hueOf(seed) {
    return Hct.toHct(Qt.color(seed)).hue;
}

function seedForHue(hue, reference = defaultSeed) {
    const key = Hct.toHct(Qt.color(reference));
    return String(Hct.fromHct(hue, key.chroma, key.tone));
}

var seedCandidateCache = null;

function seedCandidates() {
    if (seedCandidateCache)
        return seedCandidateCache;
    const defaultHue = Hct.toHct(Qt.color(defaultSeed)).hue;
    const distance = slot => Math.abs(Accents.ANCHOR_HUES[slot] - defaultHue);
    const defaultSlot = Accents.SLOTS.reduce((best, slot) => distance(slot) < distance(best) ? slot : best);
    seedCandidateCache = Accents.SLOTS.map(slot => ({
                slot,
                seed: slot === defaultSlot ? defaultSeed : seedForHue(Accents.ANCHOR_HUES[slot])
            }));
    return seedCandidateCache;
}

function normalizeEntry(value) {
    const valid = value && typeof value === "object";
    return {
        preset: valid && presetIds.includes(value.preset) ? value.preset : defaultPreset,
        seed: valid && validSeed(value.seed) ? value.seed.toLowerCase() : defaultSeed
    };
}

function normalizeStore(value) {
    const result = {};
    if (!value || typeof value !== "object" || Array.isArray(value))
        return result;
    for (const key of Object.keys(value).slice(0, 64)) {
        if (key === "__proto__" || key === "constructor" || key === "prototype")
            continue;
        const slots = value[key];
        if (!slots || typeof slots !== "object")
            continue;
        const target = {};
        for (const slot of ["shared", "light", "dark"]) {
            if (slots[slot] && typeof slots[slot] === "object")
                target[slot] = normalizeEntry(slots[slot]);
        }
        result[key] = target;
    }
    return result;
}

function entry(store, key, slot) {
    const target = store[key] ?? store[""] ?? {};
    return target[slot] ?? target.shared ?? store[""]?.[slot] ?? store[""]?.shared ?? normalizeEntry(null);
}

function composition(value) {
    const normalized = normalizeEntry(value);
    return preset(normalized.preset, normalized.seed);
}

function transform(width, height) {
    const scale = Math.max(width / designWidth, height / designHeight);
    return {
        scale,
        x: (width - designWidth * scale) / 2,
        y: (height - designHeight * scale) / 2
    };
}

function cubicsOf(value) {
    return Shapes.catalog[value.shape] ?? Shapes.catalog.circle;
}

function place(ctx, value) {
    const size = value.size * designHeight;
    ctx.translate(value.x * designWidth + size / 2, value.y * designHeight + size / 2);
    ctx.rotate(value.rotation * Math.PI / 180);
    ctx.scale(size, size);
    ctx.translate(-0.5, -0.5);
}

function trace(ctx, value) {
    ctx.save();
    place(ctx, value);
    ctx.beginPath();
    let end = null;
    for (const c of cubicsOf(value)) {
        if (!end || end[0] !== c[0] || end[1] !== c[1]) {
            if (end)
                ctx.closePath();
            ctx.moveTo(c[0], c[1]);
        }
        ctx.bezierCurveTo(c[2], c[3], c[4], c[5], c[6], c[7]);
        end = [c[6], c[7]];
    }
    ctx.closePath();
    ctx.restore();
}
