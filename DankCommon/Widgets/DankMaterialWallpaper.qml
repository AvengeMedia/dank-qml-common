import QtQuick
import "../Common/MaterialWallpaper.js" as MaterialWallpaper

Canvas {
    id: root

    required property var palette
    property var composition: MaterialWallpaper.preset(MaterialWallpaper.defaultPreset)
    readonly property real pixelRatio: Window.window?.devicePixelRatio ?? Screen.devicePixelRatio
    property bool ready: false
    readonly property string patternSource: composition.pattern === "none" ? "" : Qt.resolvedUrl("wallpaper-patterns/" + composition.pattern + ".svg")
    property string loadedPattern: ""
    readonly property string renderKey: JSON.stringify([composition, palette, width, height, pixelRatio])

    signal invalidated

    contextType: "2d"
    renderStrategy: Canvas.Immediate

    function repaint() {
        ready = false;
        invalidated();
        requestPaint();
    }

    onRenderKeyChanged: repaint()
    onAvailableChanged: if (available)
        repaint()
    onPatternSourceChanged: {
        if (loadedPattern)
            unloadImage(loadedPattern);
        loadedPattern = patternSource;
        if (loadedPattern)
            loadImage(loadedPattern);
        repaint();
    }
    onImageLoaded: repaint()
    onPainted: ready = !patternSource || isImageLoaded(patternSource) || isImageError(patternSource)
    onPaint: {
        const ctx = getContext("2d");
        if (!ctx || width <= 0 || height <= 0)
            return;
        ctx.reset();
        const view = MaterialWallpaper.transform(width, height);
        ctx.translate(view.x, view.y);
        ctx.scale(view.scale, view.scale);
        const left = -view.x / view.scale;
        const top = -view.y / view.scale;
        const w = width / view.scale;
        const h = height / view.scale;
        if (patternSource && isImageLoaded(patternSource)) {
            ctx.globalAlpha = composition.strength;
            ctx.fillStyle = ctx.createPattern(patternSource, "repeat");
            ctx.fillRect(left, top, w, h);
            ctx.globalAlpha = 1;
            ctx.globalCompositeOperation = "source-in";
            ctx.fillStyle = palette.primary;
            ctx.fillRect(left, top, w, h);
            ctx.globalCompositeOperation = "destination-over";
        }
        ctx.fillStyle = palette.surface;
        ctx.fillRect(left, top, w, h);
        ctx.globalCompositeOperation = "source-over";
        const layers = composition.layers;
        for (let i = 0; i < layers.length; i++) {
            const value = layers[i];
            MaterialWallpaper.trace(ctx, value);
            ctx.fillStyle = palette[value.fill] ?? palette.primary;
            ctx.fill();
            if (value.overlap === "none")
                continue;
            for (let j = 0; j < i; j++) {
                ctx.save();
                MaterialWallpaper.trace(ctx, layers[j]);
                ctx.clip();
                MaterialWallpaper.trace(ctx, value);
                ctx.fillStyle = palette[value.overlap] ?? palette.primary;
                ctx.fill();
                // the base fill already anti-aliased this edge, so filling it again leaves a lighter hairline; a one-pixel stroke repaints it
                ctx.strokeStyle = ctx.fillStyle;
                ctx.lineWidth = 1 / view.scale;
                ctx.lineJoin = "round";
                ctx.stroke();
                ctx.restore();
            }
        }
    }
}
