package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.data.config.CFilter;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.Event;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	import starling.filters.FragmentFilter;
	import starling.textures.RenderTexture;

	/**
	 * @private
	 */
	public class GAFPixelMaskDisplayObject extends PixelMaskDisplayObject implements IGAFDisplayObject
	{
		private static const PADDING: uint = 1;

		private var _zIndex: uint;
		private var _maskBounds: Rectangle;

		private var _mustReorder: Boolean;

		public function GAFPixelMaskDisplayObject(scaleFactor: Number = -1, isAnimated: Boolean = true)
		{
			super(scaleFactor, isAnimated);
			_maskBounds = new Rectangle();
		}

		public function get zIndex(): uint
		{
			return _zIndex;
		}

		public function set zIndex(value: uint): void
		{
			_zIndex = value;
		}

		override public function set mask(mask: DisplayObject): void
		{
			// clean up existing mask if there is one
			if (_mask)
			{
				_mask = null;
				_maskBounds.setEmpty();
			}

			if (mask)
			{
				_mask = mask;

				if (_mask.width == 0 || _mask.height == 0)
				{
					throw new Error("Mask must have dimensions. Current dimensions are " + _mask.width + "x" + _mask.height + ".");
				}

				_maskBounds.copyFrom(_mask.bounds);

				refreshRenderTextures(null);
			}
			else
			{
				clearRenderTextures();
			}
		}

		public function get mask(): DisplayObject
		{
			return _mask;
		}

		public function set maskBounds(bounds: Rectangle): void
		{
			if (bounds)
			{
				_maskBounds.copyFrom(bounds);
				refreshRenderTextures(null);
			}
			else if (_mask)
			{
				_maskBounds.copyFrom(_mask.bounds);
				refreshRenderTextures(null);
			}
			else
			{
				_maskBounds.setEmpty();
				clearRenderTextures();
			}
		}

		public function get maskBounds(): Rectangle
		{
			return _maskBounds;
		}

		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
		}

		override protected function refreshRenderTextures(event: Event = null): void
		{
			if (Starling.current.contextValid)
			{
				if (_mask)
				{
					clearRenderTextures();

					_maskRenderTexture = new RenderTexture(_maskBounds.width + PADDING * 2, _maskBounds.height + PADDING * 2, false, _scaleFactor);
					_renderTexture = new RenderTexture(_maskBounds.width, _maskBounds.height, false, _scaleFactor);

					// create image with the new render texture
					_image = new Image(_renderTexture);
					_image.x = _maskBounds.x;
					_image.y = _maskBounds.y;
					// create image to blit the mask onto
					_maskImage = new Image(_maskRenderTexture);
					_maskImage.x = _maskBounds.x - PADDING;
					_maskImage.y = _maskBounds.y - PADDING;
					// set the blending mode to MASK (ZERO, SRC_ALPHA)
					if (_inverted)
					{
						_maskImage.blendMode = MASK_MODE_INVERTED;
					}
					else
					{
						_maskImage.blendMode = MASK_MODE_NORMAL;
					}
				}
				_maskRendered = false;
			}
		}

		override public function render(support: RenderSupport, parentAlpha: Number): void
		{
			if (_isAnimated || (!_isAnimated && !_maskRendered))
			{
				if (_superRenderFlag || !_mask)
				{
					var alpha: Number = parentAlpha * this.alpha;
					var nChildren: Number = numChildren;
					var blendMode: String = support.blendMode;

					for (var i: int = 0; i < nChildren; ++i)
					{
						var child: DisplayObject = getChildAt(i);

						if (child.hasVisibleArea)
						{
							var filter: FragmentFilter = child.filter;

							support.pushMatrix();
							support.transformMatrix(child);
							support.blendMode = child.blendMode;

							if (filter)
							{
								filter.render(child, support, alpha);
							}
							else
							{
								child.render(support, alpha);
							}

							support.blendMode = blendMode;
							support.popMatrix();
						}
					}
				}
				else
				{
					if (_mask)
					{
						_tx = _mask.transformationMatrix.tx;
						_ty = _mask.transformationMatrix.ty;

						_mask.transformationMatrix.tx -= _maskBounds.x;
						_mask.transformationMatrix.ty -= _maskBounds.y;
						_maskRenderTexture.draw(_mask);

						_mask.transformationMatrix.tx = _tx;
						_mask.transformationMatrix.ty = _ty;

						_renderTexture.drawBundled(drawRenderTextures);
						support.pushMatrix();
						support.transformMatrix(_image);
						_image.render(support, parentAlpha);
						support.popMatrix();

						_maskRendered = true;
					}
				}
			}
			else
			{
				support.pushMatrix();
				support.transformMatrix(_image);
				_image.render(support, parentAlpha);
				support.popMatrix();
			}
		}

		override protected function drawRenderTextures(object: DisplayObject = null, matrix: Matrix = null, alpha: Number = 1.0): void
		{
			_a = this.transformationMatrix.a;
			_b = this.transformationMatrix.b;
			_c = this.transformationMatrix.c;
			_d = this.transformationMatrix.d;
			_tx = this.transformationMatrix.tx;
			_ty = this.transformationMatrix.ty;

			this.transformationMatrix.copyFrom(_image.transformationMatrix);
			this.transformationMatrix.invert();

			_superRenderFlag = true;
			_renderTexture.draw(this);
			_superRenderFlag = false;

			this.transformationMatrix.a = _a;
			this.transformationMatrix.b = _b;
			this.transformationMatrix.c = _c;
			this.transformationMatrix.d = _d;
			this.transformationMatrix.tx = _tx;
			this.transformationMatrix.ty = _ty;

			_maskImage.transformationMatrix.identity();
			_renderTexture.draw(_maskImage);

			_maskImage.transformationMatrix.a = _a;
			_maskImage.transformationMatrix.b = _b;
			_maskImage.transformationMatrix.c = _c;
			_maskImage.transformationMatrix.d = _d;
			_maskImage.transformationMatrix.tx = _tx;
			_maskImage.transformationMatrix.ty = _ty;
		}

		public function get mustReorder(): Boolean
		{
			return _mustReorder;
		}

		public function set mustReorder(value: Boolean): void
		{
			_mustReorder = value;
		}
	}
}
