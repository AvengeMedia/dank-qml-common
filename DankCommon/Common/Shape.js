.pragma library

var corners = { xxs: 2, xs: 4, s: 8, m: 12, l: 16, lIncreased: 20, xl: 28, xlIncreased: 32, xxl: 48 };

function normalizeStrength(value) {
    if (typeof value !== "number" || !isFinite(value))
        return 50;
    return Math.round(Math.max(0, Math.min(100, value)));
}

function strengthFromRadius(radius) {
    if (typeof radius !== "number" || !isFinite(radius))
        return 50;
    if (radius <= 12)
        return normalizeStrength(radius * 50 / 12);
    return normalizeStrength(50 + (radius - 12) * 2.5);
}

function scaleForStrength(strength) {
    const value = normalizeStrength(strength);
    if (value <= 50)
        return value / 50;
    return 1 + (value - 50) / 30;
}

function radius(token, scale) {
    return Math.round(corners[token] * scale);
}

function scaledRadius(radius, limit, scale) {
    return Math.max(0, Math.min(limit, radius * scale));
}

function fullRadius(width, height, scale) {
    return Math.max(0, Math.min(width, height)) / 2 * Math.min(1, scale);
}

function buttonRadius(width, height, sizeHeight, pressed, round, scale) {
    if (!pressed && round)
        return fullRadius(width, height, scale);
    return radius(buttonCorner(sizeHeight, pressed), scale);
}

function buttonCorner(sizeHeight, pressed) {
    if (sizeHeight <= 40)
        return pressed ? "s" : "m";
    if (sizeHeight <= 56)
        return pressed ? "m" : "l";
    return pressed ? "l" : "xl";
}
