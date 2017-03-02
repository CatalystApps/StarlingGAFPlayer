package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.data.config.CFilter;

	import flash.display3D.Context3DBlendFactor;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.textures.RenderTexture;

	/**
	 * @private
	 */
    [Deprecated(replacement="Use GAFStencilMaskStyle for styling Starling display objects", message="Starling 2.0+ support stencil mask")]
	public class GAFPixelMaskDisplayObject extends DisplayObjectContainer
	{
		private static const MASK_MODE: String = "mask";

		private static const PADDING: uint = 1;

		private static const sHelperRect: Rectangle = new Rectangle();

		protected var _mask: DisplayObject;

		protected var _renderTexture: RenderTexture;
		protected var _maskRenderTexture: RenderTexture;

		protected var _image: Image;
		protected var _maskImage: Image;

		protected var _superRenderFlag: Boolean = false;

		private var _maskSize: Point;
		private var _staticMaskSize: Boolean;
		private var _scaleFactor: Number;

		private var _mustReorder: Boolean;

		public function GAFPixelMaskDisplayObject(scaleFactor: Number = -1)
		{
			this._scaleFactor = scaleFactor;
			this._maskSize = new Point();

			BlendMode.register(MASK_MODE, Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);

			// Handle lost context. By using the conventional event, we can make a weak listener.
			// This avoids memory leaks when people forget to call "dispose" on the object.
			Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
					this.onContextCreated, false, 0, true);
		}

		override public function dispose(): void
		{
			this.clearRenderTextures();
			Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			super.dispose();
		}

		private function onContextCreated(event: Object): void
		{
			this.refreshRenderTextures();
		}

		public function set pixelMask(value: DisplayObject): void
		{
			// clean up existing mask if there is one
			if (this._mask)
			{
				this._mask = null;
				this._maskSize.setTo(0, 0);
			}

			if (value)
			{
				this._mask = value;

				if (this._mask.width == 0 || this._mask.height == 0)
				{
					throw new Error("Mask must have dimensions. Current dimensions are " + this._mask.width + "x" + this._mask.height + ".");
				}

				var objectWithMaxSize: IMaxSize = this._mask as IMaxSize;
				if (objectWithMaxSize && objectWithMaxSize.maxSize)
				{
					this._maskSize.copyFrom(objectWithMaxSize.maxSize);
					this._staticMaskSize = true;
				}
				else
				{
					this._mask.getBounds(null, sHelperRect);
					this._maskSize.setTo(sHelperRect.width, sHelperRect.height);
					this._staticMaskSize = false;
				}

				this.refreshRenderTextures(null);
			}
			else
			{
				this.clearRenderTextures();
			}
		}

		public function get pixelMask(): DisplayObject
		{
			return this._mask;
		}

		protected function clearRenderTextures(): void
		{
			// clean up old render textures and images
			if (this._maskRenderTexture)
			{
				this._maskRenderTexture.dispose();
			}

			if (this._renderTexture)
			{
				this._renderTexture.dispose();
			}

			if (this._image)
			{
				this._image.dispose();
			}

			if (this._maskImage)
			{
				this._maskImage.dispose();
			}
		}

		protected function refreshRenderTextures(event: Event = null): void
		{
			if (Starling.current.contextValid)
			{
				if (this._mask)
				{
					this.clearRenderTextures();

					this._renderTexture = new RenderTexture(this._maskSize.x, this._maskSize.y, false, this._scaleFactor);
					this._maskRenderTexture = new RenderTexture(this._maskSize.x + PADDING * 2, this._maskSize.y + PADDING * 2, false, this._scaleFactor);

					// create image with the new render texture
					this._image = new Image(this._renderTexture);
					// create image to blit the mask onto
					this._maskImage = new Image(this._maskRenderTexture);
					this._maskImage.x = this._maskImage.y = -PADDING;
					// set the blending mode to MASK (ZERO, SRC_ALPHA)
					this._maskImage.blendMode = MASK_MODE;
				}
			}
		}

		override public function render(painter:Painter): void
		{
			if (this._superRenderFlag || !this._mask)
			{
				super.render(painter);
			}
			else if (this._mask)
			{
				var previousStencilRefValue: uint = painter.stencilReferenceValue;
				if (previousStencilRefValue)
                    painter.stencilReferenceValue = 0;

				_tx = this._mask.transformationMatrix.tx;
				_ty = this._mask.transformationMatrix.ty;

				this._mask.getBounds(null, sHelperRect);

				if (!this._staticMaskSize
							//&& (sHelperRect.width > this._maskSize.x || sHelperRect.height > this._maskSize.y)
						&& (sHelperRect.width != this._maskSize.x || sHelperRect.height != this._maskSize.y))
				{
					this._maskSize.setTo(sHelperRect.width, sHelperRect.height);
					this.refreshRenderTextures();
				}

				this._mask.transformationMatrix.tx = _tx - sHelperRect.x + PADDING;
				this._mask.transformationMatrix.ty = _ty - sHelperRect.y + PADDING;
//				this._maskRenderTexture.draw(this._mask);
				this._image.transformationMatrix.tx = sHelperRect.x;
				this._image.transformationMatrix.ty = sHelperRect.y;
				this._mask.transformationMatrix.tx = _tx;
				this._mask.transformationMatrix.ty = _ty;

//				this._renderTexture.drawBundled(this.drawRenderTextures);

				if (previousStencilRefValue)
                    painter.stencilReferenceValue = previousStencilRefValue;

//				support.pushMatrix();
//				support.transformMatrix(this._image);

                painter.drawMask(_mask,_image);
				super.render(painter);
                painter.eraseMask(_mask,_image);
//				support.popMatrix();
			}
		}

		protected static var _a: Number;
		protected static var _b: Number;
		protected static var _c: Number;
		protected static var _d: Number;
		protected static var _tx: Number;
		protected static var _ty: Number;

		protected function drawRenderTextures(object: DisplayObject = null, matrix: Matrix = null, alpha: Number = 1.0): void
		{
			_a = this.transformationMatrix.a;
			_b = this.transformationMatrix.b;
			_c = this.transformationMatrix.c;
			_d = this.transformationMatrix.d;
			_tx = this.transformationMatrix.tx;
			_ty = this.transformationMatrix.ty;

			this.transformationMatrix.copyFrom(this._image.transformationMatrix);
			this.transformationMatrix.invert();

			this._superRenderFlag = true;
			this._renderTexture.draw(this);
			this._superRenderFlag = false;

			this.transformationMatrix.a = _a;
			this.transformationMatrix.b = _b;
			this.transformationMatrix.c = _c;
			this.transformationMatrix.d = _d;
			this.transformationMatrix.tx = _tx;
			this.transformationMatrix.ty = _ty;

			//-----------------------------------------------------------------------------------------------------------------

			this._renderTexture.draw(this._maskImage);
		}

		public function get mustReorder(): Boolean
		{
			return this._mustReorder;
		}

		public function set mustReorder(value: Boolean): void
		{
			this._mustReorder = value;
		}
	}
}
