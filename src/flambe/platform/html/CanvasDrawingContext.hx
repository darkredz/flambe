//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.html;

import flambe.display.BlendMode;
import flambe.display.DrawingContext;
import flambe.display.Texture;
import flambe.math.FMath;

// TODO(bruno): Remove pixel snapping once most browsers get canvas acceleration.
class CanvasDrawingContext
    implements DrawingContext
{
    public function new (canvas :Dynamic)
    {
        _canvasCtx = canvas.getContext("2d");

        // Initialize to the standard opaque white
        _canvasCtx.fillStyle = "#ffffff";
        _canvasCtx.fillRect(0, 0, canvas.width, canvas.height);
    }

    public function save ()
    {
        _canvasCtx.save();
    }

    public function translate (x :Float, y :Float)
    {
        _canvasCtx.translate(Std.int(x), Std.int(y));
    }

    public function scale (x :Float, y :Float)
    {
        _canvasCtx.scale(x, y);
    }

    public function rotate (rotation :Float)
    {
        _canvasCtx.rotate(FMath.toRadians(rotation));
    }

    public function transform (m00 :Float, m10 :Float, m01 :Float, m11 :Float, m02 :Float, m12 :Float)
    {
        _canvasCtx.transform(m00, m10, m01, m11, m02, m12);
    }

    public function restore ()
    {
        _canvasCtx.restore();
    }

    public function drawImage (texture :Texture, x :Float, y :Float)
    {
        if (_firstDraw) {
            _firstDraw = false;
            _canvasCtx.globalCompositeOperation = "copy";
            drawImage(texture, x, y);
            _canvasCtx.globalCompositeOperation = "source-over";
            return;
        }

        var htmlTexture :HtmlTexture = cast texture;
        _canvasCtx.drawImage(htmlTexture.image, x, y);
    }

    public function drawSubImage (texture :Texture, destX :Float, destY :Float,
        sourceX :Float, sourceY :Float, sourceW :Float, sourceH :Float)
    {
        if (_firstDraw) {
            _firstDraw = false;
            _canvasCtx.globalCompositeOperation = "copy";
            drawSubImage(texture, destX, destY, sourceX, sourceY, sourceW, sourceH);
            _canvasCtx.globalCompositeOperation = "source-over";
            return;
        }

        var htmlTexture :HtmlTexture = cast texture;
        _canvasCtx.drawImage(htmlTexture.image,
            Std.int(sourceX), Std.int(sourceY), Std.int(sourceW), Std.int(sourceH),
            Std.int(destX), Std.int(destY), Std.int(sourceW), Std.int(sourceH));
    }

    public function drawPattern (texture :Texture, x :Float, y :Float, width :Float, height :Float)
    {
        if (_firstDraw) {
            _firstDraw = false;
            _canvasCtx.globalCompositeOperation = "copy";
            drawPattern(texture, x, y, width, height);
            _canvasCtx.globalCompositeOperation = "source-over";
            return;
        }

        var htmlTexture :HtmlTexture = cast texture;
        if (htmlTexture.pattern == null) {
            htmlTexture.pattern = _canvasCtx.createPattern(htmlTexture.image, "repeat");
        }
        _canvasCtx.fillStyle = htmlTexture.pattern;
        _canvasCtx.fillRect(Std.int(x), Std.int(y), Std.int(width), Std.int(height));
    }

    public function fillRect (color :Int, x :Float, y :Float, width :Float, height :Float)
    {
        if (_firstDraw) {
            _firstDraw = false;
            _canvasCtx.globalCompositeOperation = "copy";
            fillRect(color, x, y, width, height);
            _canvasCtx.globalCompositeOperation = "source-over";
            return;
        }

        // Use slice() here rather than Haxe's substr monkey patch
        _canvasCtx.fillStyle = untyped "#" + ("00000" + color.toString(16)).slice(-6);
        _canvasCtx.fillRect(Std.int(x), Std.int(y), Std.int(width), Std.int(height));
    }

    public function multiplyAlpha (factor :Float)
    {
        _canvasCtx.globalAlpha *= factor;
    }

    public function setBlendMode (blendMode :BlendMode)
    {
        var op;
        switch (blendMode) {
            case Normal: op = "source-over";
            case Add: op = "lighter";
        };
        _canvasCtx.globalCompositeOperation = op;
    }

    public function willRender ()
    {
        // Disable blending for the first draw call. This squeezes a bit of performance out of games
        // that have a single large background sprite, especially on older devices
        _firstDraw = true;
    }

    private var _canvasCtx :Dynamic;
    private var _firstDraw :Bool = true;
}
