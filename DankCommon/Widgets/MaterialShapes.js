.pragma library
.import "MaterialShapeData.js" as Data

var catalog = Data.cubics;

function rotationScale(kind, aspectRatio = 1) {
    const cubics = catalog[kind] ?? catalog.circle;
    let radiusSquared = 0;
    for (const cubic of cubics) {
        const centered = cubic.map((value, index) => (value - 0.5) * (index % 2 === 0 ? aspectRatio : 1));
        radiusSquared = Math.max(radiusSquared, cubicRadiusSquared(centered, 4));
    }
    return radiusSquared > 0 ? 0.5 / Math.sqrt(radiusSquared) : 1;
}

function cubicRadiusSquared(cubic, depth) {
    if (depth === 0) {
        let radiusSquared = 0;
        for (let i = 0; i < cubic.length; i += 2)
            radiusSquared = Math.max(radiusSquared, cubic[i] * cubic[i] + cubic[i + 1] * cubic[i + 1]);
        return radiusSquared;
    }
    const midpoint = (a, b) => [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2];
    const start = cubic.slice(0, 2);
    const control1 = cubic.slice(2, 4);
    const control2 = cubic.slice(4, 6);
    const end = cubic.slice(6, 8);
    const a = midpoint(start, control1);
    const b = midpoint(control1, control2);
    const c = midpoint(control2, end);
    const d = midpoint(a, b);
    const e = midpoint(b, c);
    const split = midpoint(d, e);
    return Math.max(cubicRadiusSquared(start.concat(a, d, split), depth - 1), cubicRadiusSquared(split.concat(e, c, end), depth - 1));
}

function buildPath(kind, width, height, square) {
    if (width <= 0 || height <= 0)
        return "";
    if (square)
        return "M 0 0 H " + width + " V " + height + " H 0 Z";
    const cubics = catalog[kind] ?? catalog.circle;
    const pair = (x, y) => (x * width).toFixed(4) + " " + (y * height).toFixed(4);
    let path = "M " + pair(cubics[0][0], cubics[0][1]);
    for (const cubic of cubics)
        path += " C " + pair(cubic[2], cubic[3]) + " " + pair(cubic[4], cubic[5]) + " " + pair(cubic[6], cubic[7]);
    return path + " Z";
}
