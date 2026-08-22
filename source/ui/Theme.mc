import Toybox.Graphics;
import Toybox.Lang;

// Centralized palette and small drawing helpers. All colors use channel
// values that exist on 64-color MIP displays (each channel is a multiple
// of 0x55), so the app looks identical on the Forerunner 55 and on AMOLED.
module Theme {
    // Warm, orange-forward palette matching the app's orange launcher icon.
    // Every channel is a multiple of 0x55, so the colors render crisply on the
    // 64-color MIP displays (e.g. Forerunner 55) with no dithering.
    const COLOR_BG = 0x000000;
    const COLOR_TEXT = 0xFFFFFF;
    const COLOR_TEXT_DIM = 0xAAAAAA;
    const COLOR_FRAME = 0x555555;    // subtle rings / dividers
    const COLOR_ACCENT = 0xFF5500;   // single brand accent (orange)
    const COLOR_WARM = 0xFFAA00;     // amber
    const COLOR_SUCCESS = 0xFFAA00;  // warm positive (e.g. saved / congrats)
    const COLOR_DANGER = 0xFF0000;   // red (discard / skip)
    const COLOR_PURPLE = 0xAA55FF;   // retained for compatibility (unused)

    // One warm accent per muscle group; keep in sync with the illustrations.
    const GROUP_COLORS = [
        0xFFAA00,  // neck — amber
        0xFF5500,  // wrist / forearm — orange
        0xFF0000,  // shoulder — red
        0xFFAA55,  // torso / back — light orange
        0xAA5500   // legs — dark orange
    ];

    function groupColor(group as Number) as Number {
        if (group >= 0 && group < GROUP_COLORS.size()) {
            return GROUP_COLORS[group] as Number;
        }
        return COLOR_ACCENT;
    }

    // Ring around the screen edge showing phase progress (grows clockwise
    // from 12 o'clock).
    function drawProgressRing(dc as Dc, fraction as Float, color as Number) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = (cx < cy ? cx : cy) - 5;
        dc.setPenWidth(7);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, 90);
        if (fraction > 0.01) {
            var endDeg = 90 - (360.0 * fraction).toNumber();
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, endDeg);
        }
        dc.setPenWidth(1);
    }

    // Thin, subtle frame ring hugging the screen edge.
    function drawFrameRing(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = (cx < cy ? cx : cy) - 3;
        dc.setPenWidth(2);
        dc.setColor(COLOR_FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        dc.setPenWidth(1);
    }

    // Short accent arc centered at 12 o'clock — a quiet brand mark that
    // sits on top of the frame ring.
    function drawBrandArc(dc as Dc, color as Number) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = (cx < cy ? cx : cy) - 3;
        dc.setPenWidth(5);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 106, 74);
        dc.setPenWidth(1);
    }

    // Rounded "pill" button hint with centered text. Returns nothing; the
    // caller positions it by center point.
    function drawPill(dc as Dc, cx as Number, cy as Number, text as String,
                      font as Graphics.FontDefinition, color as Number,
                      filled as Boolean) as Void {
        var th = dc.getFontHeight(font);
        var boxW = dc.getTextWidthInPixels(text, font) + (th / 2 + 2) * 2;
        var boxH = th + (th / 6) * 2;
        var x = cx - boxW / 2;
        var y = cy - boxH / 2;
        if (filled) {
            fillPill(dc, x, y, boxW, boxH, color);
        } else {
            outlinePill(dc, x, y, boxW, boxH, color);
        }
        dc.drawText(cx, cy, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function fillPill(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                      color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, h / 2);
        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
    }

    function outlinePill(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                         color as Number) as Void {
        dc.setPenWidth(2);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, w, h, h / 2);
        dc.setPenWidth(1);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    }

    // Truncates text with an ellipsis so it fits within maxW pixels for the
    // given font. Keeps the whole string when it already fits.
    function fitText(dc as Dc, text as String, font as Graphics.FontDefinition,
                     maxW as Number) as String {
        if (dc.getTextWidthInPixels(text, font) <= maxW) {
            return text;
        }
        var ell = "…";
        var s = text;
        while (s.length() > 1 &&
               dc.getTextWidthInPixels(s + ell, font) > maxW) {
            s = s.substring(0, s.length() - 1);
        }
        return s + ell;
    }

    // Splits a label into at most two lines that fit narrow screens.
    function splitTwoLines(text as String, maxChars as Number) as Array {
        if (text.length() <= maxChars) {
            return [text];
        }
        var breakAt = lastSpaceWithin(text, maxChars);
        if (breakAt <= 0) {
            return [text];
        }
        return [text.substring(0, breakAt), text.substring(breakAt + 1, text.length())];
    }

    // Index of the last space at or before maxChars, or -1 when there is none.
    function lastSpaceWithin(text as String, maxChars as Number) as Number {
        var chars = text.toCharArray();
        var breakAt = -1;
        for (var i = 0; i < chars.size() && i <= maxChars; i++) {
            if (chars[i] == ' ') {
                breakAt = i;
            }
        }
        return breakAt;
    }
}
