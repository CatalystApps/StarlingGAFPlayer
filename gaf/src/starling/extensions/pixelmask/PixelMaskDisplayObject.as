package starling.extensions.pixelmask
{
	import flash.display3D.Context3DBlendFactor;
	import flash.geom.Matrix;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.RenderTexture;

	/** @private */
	public class PixelMaskDisplayObject extends DisplayObjectContainer
	{
		protected static const MASK_MODE_NORMAL:String = "mask";
		protected static const MASK_MODE_INVERTED:String = "maskinverted";

		protected var _mask:DisplayObject;
		protected var _renderTexture:RenderTexture;
		protected var _maskRenderTexture:RenderTexture;

		protected var _image:Image;
		protected var _maskImage:Image;

		protected var _superRenderFlag:Boolean = false;
		protected var _inverted:Boolean = false;
		protected var _scaleFactor:Number;
		protected var _isAnimated:Boolean = true;
		protected var _maskRendered:Boolean = false;

		public function PixelMaskDisplayObject(scaleFactor:Number=-1, isAnimated:Boolean=true)
		{
			super();

			_isAnimated = isAnimated;
			_scaleFactor = scaleFactor;

			BlendMode.register(MASK_MODE_NORMAL, Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA);
			BlendMode.register(MASK_MODE_INVERTED, Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);

			// Handle lost context. By using the conventional event, we can make a weak listener.
			// This avoids memory leaks when people forget to call "dispose" on the object.
			Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
					onContextCreated, false, 0, true);
		}

		public function get isAnimated():Boolean
		{
			return _isAnimated;
		}

		public function set isAnimated(value:Boolean):void
		{
			_isAnimated = value;
		}

		override public function dispose():void
		{
			clearRenderTextures();
			Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			super.dispose();
		}

		private function onContextCreated(event:Object):void
		{
			refreshRenderTextures();
		}

		public function get inverted():Boolean
		{
			return _inverted;
		}

		public function set inverted(value:Boolean):void
		{
			_inverted = value;
			refreshRenderTextures(null);
		}

		public function set pixelMask(mask:DisplayObject) : void
		{
			// clean up existing mask if there is one
			if (_mask) {
				_mask = null;
			}

			if (mask) {
				_mask = mask;

				if (_mask.width==0 || _mask.height==0) {
					throw new Error ("Mask must have dimensions. Current dimensions are " + _mask.width + "x" + _mask.height + ".");
				}

				refreshRenderTextures(null);
			} else {
				clearRenderTextures();
			}
		}

		protected function clearRenderTextures() : void
		{
			// clean up old render textures and images
			if (_maskRenderTexture) {
				_maskRenderTexture.dispose();
			}

			if (_renderTexture) {
				_renderTexture.dispose();
			}

			if (_image) {
				_image.dispose();
			}

			if (_maskImage) {
				_maskImage.dispose();
			}
		}

		protected function refreshRenderTextures(e:Event=null) : void
		{
			if (_mask) {

				clearRenderTextures();

				_maskRenderTexture = new RenderTexture(_mask.width, _mask.height, false, _scaleFactor);
				_renderTexture = new RenderTexture(_mask.width, _mask.height, false, _scaleFactor);

				// create image with the new render texture
				_image = new Image(_renderTexture);

				// create image to blit the mask onto
				_maskImage = new Image(_maskRenderTexture);

				// set the blending mode to MASK (ZERO, SRC_ALPHA)
				if (_inverted) {
					_maskImage.blendMode = MASK_MODE_INVERTED;
				} else {
					_maskImage.blendMode = MASK_MODE_NORMAL;
				}
			}
			_maskRendered = false;
		}

		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			if (_isAnimated || (!_isAnimated && !_maskRendered)) {
				if (_superRenderFlag || !_mask) {
					super.render(support, parentAlpha);
				} else {
					if (_mask) {
						_maskRenderTexture.draw(_mask);
						_renderTexture.drawBundled(drawRenderTextures);
						_image.render(support, parentAlpha);
						_maskRendered = true;
					}
				}
			} else {
				_image.render(support, parentAlpha);
			}
		}

		protected static var _a:Number;
		protected static var _b:Number;
		protected static var _c:Number;
		protected static var _d:Number;
		protected static var _tx:Number;
		protected static var _ty:Number;

		protected function drawRenderTextures(object:DisplayObject=null, matrix:Matrix=null, alpha:Number=1.0) : void
		{
			_a = this.transformationMatrix.a;
			_b = this.transformationMatrix.b;
			_c = this.transformationMatrix.c;
			_d = this.transformationMatrix.d;

			_tx = this.transformationMatrix.tx;
			_ty = this.transformationMatrix.ty;

			this.transformationMatrix.a = 1;
			this.transformationMatrix.b = 0;
			this.transformationMatrix.c = 0;
			this.transformationMatrix.d = 1;

			this.transformationMatrix.tx = 0;
			this.transformationMatrix.ty = 0;

			_superRenderFlag = true;
			_renderTexture.draw(this);
			_superRenderFlag = false;

			this.transformationMatrix.a = _a;
			this.transformationMatrix.b = _b;
			this.transformationMatrix.c = _c;
			this.transformationMatrix.d = _d;

			this.transformationMatrix.tx = _tx;
			this.transformationMatrix.ty = _ty;

			_renderTexture.draw(_maskImage);
		}
	}
}
