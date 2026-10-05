#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 hoursFirstRect;
    vec4 hoursSecondRect;
    vec4 minutesFirstRect;
    vec4 minutesSecondRect;
    vec4 lightColor;
    vec4 darkColor;
    vec4 outlineColor;
} ubuf;

layout(binding = 1) uniform sampler2D hoursFirst;
layout(binding = 2) uniform sampler2D hoursSecond;
layout(binding = 3) uniform sampler2D minutesFirst;
layout(binding = 4) uniform sampler2D minutesSecond;

vec4 compositeGlyph(sampler2D tex, vec4 rect, vec4 color, vec4 under) {
    vec2 uv = (qt_TexCoord0 - rect.xy) / rect.zw;
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0))))
        return under;

    vec4 mask = texture(tex, uv);
    float rim = max(0.0, mask.a - mask.r) * under.a;
    return color * mask.r + ubuf.outlineColor * rim + under * (1.0 - mask.a);
}

void main() {
    vec4 stack = compositeGlyph(hoursFirst, ubuf.hoursFirstRect, ubuf.darkColor, vec4(0.0));
    stack = compositeGlyph(hoursSecond, ubuf.hoursSecondRect, ubuf.lightColor, stack);
    stack = compositeGlyph(minutesFirst, ubuf.minutesFirstRect, ubuf.lightColor, stack);
    stack = compositeGlyph(minutesSecond, ubuf.minutesSecondRect, ubuf.darkColor, stack);
    fragColor = stack * ubuf.qt_Opacity;
}
