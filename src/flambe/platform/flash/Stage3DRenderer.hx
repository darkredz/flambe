//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.flash;

import flash.display3D.Context3D;
import flash.display.BitmapData;
import flash.display.Stage3D;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.Lib;

import flambe.display.Graphics;
import flambe.display.Texture;

class Stage3DRenderer
    implements Renderer
{
    public var batcher (default, null) :Stage3DBatcher;

    public function new ()
    {
        // Use the first available Stage3D
        var stage = Lib.current.stage;
        for (stage3D in stage.stage3Ds) {
            if (stage3D.context3D == null) {
                stage.addEventListener(Event.RESIZE, onResize);

                stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
                stage3D.addEventListener(ErrorEvent.ERROR, onError);

                // The constrained profile is only available in 11.4
                if ((untyped stage3D).requestContext3D.length >= 2) {
                    (untyped stage3D).requestContext3D("auto", "baselineConstrained");
                } else {
                    stage3D.requestContext3D();
                }
                return;
            }
        }

        Log.error("No free Stage3Ds available!");
    }

    public function createTexture (bitmapData :Dynamic) :Stage3DTexture
    {
        if (_context3D == null) {
            return null; // No Stage3D context yet
        }

        var bitmapData :BitmapData = cast bitmapData;
        var texture = new Stage3DTexture(this, bitmapData.width, bitmapData.height);
        texture.init(_context3D, false);
        texture.uploadBitmapData(bitmapData);
        return texture;
    }

    public function createEmptyTexture (width :Int, height :Int) :Stage3DTexture
    {
        if (_context3D == null) {
            return null; // No Stage3D context yet
        }

        var texture = new Stage3DTexture(this, width, height);
        texture.init(_context3D, true);
        return texture;
    }

    public function createGraphics (renderTarget :Stage3DTexture) :Stage3DGraphics
    {
        return new Stage3DGraphics(_context3D, batcher, renderTarget);
    }

    public function willRender () :Graphics
    {
#if flambe_debug_renderer
        trace(">>> begin");
#end
        if (_graphics == null) {
            return null;
        }
        batcher.willRender();
        return _graphics;
    }

    public function didRender ()
    {
        batcher.didRender();
#if flambe_debug_renderer
        trace("<<< end");
#end
    }

    private function onContext3DCreate (event :Event)
    {
        var stage3D :Stage3D = event.target;
        _context3D = stage3D.context3D;

        Log.info("Created new Stage3D context", ["driver", _context3D.driverInfo]);
#if flambe_debug_renderer
        _context3D.enableErrorChecking = true;
#end

        batcher = new Stage3DBatcher(_context3D);
        _graphics = createGraphics(null);
        onResize(null);

        // Signal that the GPU context was (re)created
        System.hasGPU._ = false;
        System.hasGPU._ = true;
    }

    private function onError (event :ErrorEvent)
    {
        Log.error("Unexpected Stage3D failure!", ["error", event.text]);
    }

    private function onResize (_)
    {
        if (_context3D != null) {
            var stage = Lib.current.stage;
            _context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 2, false);
            _graphics.reset(stage.stageWidth, stage.stageHeight);
        }
    }

    private var _context3D :Context3D;
    private var _graphics :Stage3DGraphics;
}
