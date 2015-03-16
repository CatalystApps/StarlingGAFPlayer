/*
 Feathers
 Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

 This program is free software. You can redistribute and/or modify it in
 accordance with the terms of the accompanying license agreement.
 */
package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.filter.GAFFilter;
	import com.catalystapps.gaf.utils.MathUtility;

	import feathers.core.IValidating;
	import feathers.core.ValidationQueue;
	import feathers.utils.display.getDisplayObjectDepthFromStage;

	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.MatrixUtil;

	use namespace gaf_internal;

	[Exclude(name="numChildren",kind="property")]
	[Exclude(name="isFlattened",kind="property")]
	[Exclude(name="addChild",kind="method")]
	[Exclude(name="addChildAt",kind="method")]
	[Exclude(name="broadcastEvent",kind="method")]
	[Exclude(name="broadcastEventWith",kind="method")]
	[Exclude(name="contains",kind="method")]
	[Exclude(name="getChildAt",kind="method")]
	[Exclude(name="getChildByName",kind="method")]
	[Exclude(name="getChildIndex",kind="method")]
	[Exclude(name="removeChild",kind="method")]
	[Exclude(name="removeChildAt",kind="method")]
	[Exclude(name="removeChildren",kind="method")]
	[Exclude(name="setChildIndex",kind="method")]
	[Exclude(name="sortChildren",kind="method")]
	[Exclude(name="swapChildren",kind="method")]
	[Exclude(name="swapChildrenAt",kind="method")]
	[Exclude(name="flatten",kind="method")]
	[Exclude(name="unflatten",kind="method")]

	/**
	 * @private
	 */
	public class GAFScale9Image extends Sprite implements IValidating, IGAFImage, IGAFDebug
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private static const HELPER_MATRIX: Matrix = new Matrix();
		private static const HELPER_POINT: Point = new Point();
		private static var helperImage: Image;
		private var _propertiesChanged: Boolean = true;
		private var _layoutChanged: Boolean = true;
		private var _renderingChanged: Boolean = true;
		private var _frame: Rectangle;
		private var _textures: GAFScale9Texture;
		private var _width: Number = NaN;
		private var _height: Number = NaN;
		private var _textureScale: Number = 1;
		private var _smoothing: String = TextureSmoothing.BILINEAR;
		private var _color: uint = 0xffffff;
		private var _useSeparateBatch: Boolean = true;
		private var _hitArea: Rectangle;
		private var _batch: QuadBatch;
		private var _isValidating: Boolean = false;
		private var _isInvalid: Boolean = false;
		private var _validationQueue: ValidationQueue;
		private var _depth: int = -1;

		private var _debugColors: Vector.<uint>;
		private var _debugAlphas: Vector.<Number>;
		private var _zIndex: uint;

		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		gaf_internal var __debugOriginalAlpha: Number = NaN;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * GAFScale9Image represents display object that is part of the <code>GAFMovieClip</code>
		 * Scales an image with nine regions to maintain the aspect ratio of the
		 * corners regions. The top and bottom regions stretch horizontally, and the
		 * left and right regions scale vertically. The center region stretches in
		 * both directions to fill the remaining space.
		 * @param textures  The textures displayed by this image.
		 * @param textureScale The amount to scale the texture. Useful for DPI changes.
		 * @see com.catalystapps.gaf.display.GAFImage
		 */
		public function GAFScale9Image(textures: GAFScale9Texture, textureScale: Number = 1)
		{
			super();

			this.textures = textures;
			this._textureScale = textureScale;
			this._hitArea = new Rectangle();
			this.readjustSize();

			this._batch = new QuadBatch();
			this._batch.touchable = false;
			this.addChild(this._batch);

			this.addEventListener(Event.FLATTEN, flattenHandler);
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function set debugColors(value: Vector.<uint>): void
		{
			this._debugColors = new Vector.<uint>(4);
			this._debugAlphas = new Vector.<Number>(4);

			var alpha0: Number;
			var alpha1: Number;

			switch (value.length)
			{
				case 1:
					this._debugColors[0] = value[0];
					this._debugColors[1] = value[0];
					this._debugColors[2] = value[0];
					this._debugColors[3] = value[0];
					alpha0 = (value[0] >>> 24) / 255;
					this._debugAlphas[0] = alpha0;
					this._debugAlphas[1] = alpha0;
					this._debugAlphas[2] = alpha0;
					this._debugAlphas[3] = alpha0;
					break;
				case 2:
					this._debugColors[0] = value[0];
					this._debugColors[1] = value[0];
					this._debugColors[2] = value[1];
					this._debugColors[3] = value[1];
					alpha0 = (value[0] >>> 24) / 255;
					alpha1 = (value[1] >>> 24) / 255;
					this._debugAlphas[0] = alpha0;
					this._debugAlphas[1] = alpha0;
					this._debugAlphas[2] = alpha1;
					this._debugAlphas[3] = alpha1;
					break;
				case 3:
					this._debugColors[0] = value[0];
					this._debugColors[1] = value[0];
					this._debugColors[2] = value[1];
					this._debugColors[3] = value[2];
					alpha0 = (value[0] >>> 24) / 255;
					this._debugAlphas[0] = alpha0;
					this._debugAlphas[1] = alpha0;
					this._debugAlphas[2] = (value[1] >>> 24) / 255;
					this._debugAlphas[3] = (value[2] >>> 24) / 255;
					break;
				case 4:
					this._debugColors[0] = value[0];
					this._debugColors[1] = value[1];
					this._debugColors[2] = value[2];
					this._debugColors[3] = value[3];
					this._debugAlphas[0] = (value[0] >>> 24) / 255;
					this._debugAlphas[1] = (value[1] >>> 24) / 255;
					this._debugAlphas[2] = (value[2] >>> 24) / 255;
					this._debugAlphas[3] = (value[3] >>> 24) / 255;
					break;
			}
		}

		/**
		 * @copy feathers.core.IValidating#validate()
		 */
		public function validate(): void
		{
			if(!this._isInvalid)
			{
				return;
			}
			if(this._isValidating)
			{
				if(this._validationQueue)
				{
					//we were already validating, and something else told us to
					//validate. that's bad.
					this._validationQueue.addControl(this, true);
				}
				return;
			}
			this._isValidating = true;
			if (this._propertiesChanged || this._layoutChanged || this._renderingChanged)
			{
				this._batch.batchable = !this._useSeparateBatch;
				this._batch.reset();

				if (!helperImage)
				{
					//because Scale9Textures enforces it, we know for sure that
					//this texture will have a size greater than zero, so there
					//won't be an error from Quad.
					helperImage = new Image(this._textures.middleCenter);
				}
				helperImage.smoothing = this._smoothing;

				if (!setDebugVertexColors([0, 1, 2, 3]))
				{
					helperImage.color = this._color;
				}

				const grid: Rectangle = this._textures.scale9Grid;
				var scaledLeftWidth: Number = grid.x * this._textureScale;
				var scaledRightWidth: Number = (this._frame.width - grid.x - grid.width) * this._textureScale;
				var sumLeftAndRight: Number = scaledLeftWidth + scaledRightWidth;
				if (sumLeftAndRight > this._width)
				{
					var distortionScale: Number = (this._width / sumLeftAndRight);
					scaledLeftWidth *= distortionScale;
					scaledRightWidth *= distortionScale;
					sumLeftAndRight + scaledLeftWidth + scaledRightWidth;
				}
				var scaledCenterWidth: Number = this._width - sumLeftAndRight;
				var scaledTopHeight: Number = grid.y * this._textureScale;
				var scaledBottomHeight: Number = (this._frame.height - grid.y - grid.height) * this._textureScale;
				var sumTopAndBottom: Number = scaledTopHeight + scaledBottomHeight;
				if (sumTopAndBottom > this._height)
				{
					distortionScale = (this._height / sumTopAndBottom);
					scaledTopHeight *= distortionScale;
					scaledBottomHeight *= distortionScale;
					sumTopAndBottom = scaledTopHeight + scaledBottomHeight;
				}
				var scaledMiddleHeight: Number = this._height - sumTopAndBottom;

				if (scaledTopHeight > 0)
				{
					if (scaledLeftWidth > 0)
					{
						setDebugColor(0);
						helperImage.texture = this._textures.topLeft;
						helperImage.readjustSize();
						helperImage.width = scaledLeftWidth;
						helperImage.height = scaledTopHeight;
						helperImage.x = scaledLeftWidth - helperImage.width;
						helperImage.y = scaledTopHeight - helperImage.height;
						this._batch.addImage(helperImage);
					}

					if (scaledCenterWidth > 0)
					{
						setDebugVertexColors([0, 1, 0, 1]);
						helperImage.texture = this._textures.topCenter;
						helperImage.readjustSize();
						helperImage.width = scaledCenterWidth;
						helperImage.height = scaledTopHeight;
						helperImage.x = scaledLeftWidth;
						helperImage.y = scaledTopHeight - helperImage.height;
						this._batch.addImage(helperImage);
					}

					if (scaledRightWidth > 0)
					{
						setDebugColor(1);
						helperImage.texture = this._textures.topRight;
						helperImage.readjustSize();
						helperImage.width = scaledRightWidth;
						helperImage.height = scaledTopHeight;
						helperImage.x = this._width - scaledRightWidth;
						helperImage.y = scaledTopHeight - helperImage.height;
						this._batch.addImage(helperImage);
					}
				}

				if (scaledMiddleHeight > 0)
				{
					if (scaledLeftWidth > 0)
					{
						setDebugVertexColors([0, 0, 2, 2]);
						helperImage.texture = this._textures.middleLeft;
						helperImage.readjustSize();
						helperImage.width = scaledLeftWidth;
						helperImage.height = scaledMiddleHeight;
						helperImage.x = scaledLeftWidth - helperImage.width;
						helperImage.y = scaledTopHeight;
						this._batch.addImage(helperImage);
					}

					if (scaledCenterWidth > 0)
					{
						setDebugVertexColors([0, 1, 2, 3]);
						helperImage.texture = this._textures.middleCenter;
						helperImage.readjustSize();
						helperImage.width = scaledCenterWidth;
						helperImage.height = scaledMiddleHeight;
						helperImage.x = scaledLeftWidth;
						helperImage.y = scaledTopHeight;
						this._batch.addImage(helperImage);
					}

					if (scaledRightWidth > 0)
					{
						setDebugVertexColors([1, 1, 3, 3]);
						helperImage.texture = this._textures.middleRight;
						helperImage.readjustSize();
						helperImage.width = scaledRightWidth;
						helperImage.height = scaledMiddleHeight;
						helperImage.x = this._width - scaledRightWidth;
						helperImage.y = scaledTopHeight;
						this._batch.addImage(helperImage);
					}
				}

				if (scaledBottomHeight > 0)
				{
					if (scaledLeftWidth > 0)
					{
						setDebugColor(2);
						helperImage.texture = this._textures.bottomLeft;
						helperImage.readjustSize();
						helperImage.width = scaledLeftWidth;
						helperImage.height = scaledBottomHeight;
						helperImage.x = scaledLeftWidth - helperImage.width;
						helperImage.y = this._height - scaledBottomHeight;
						this._batch.addImage(helperImage);
					}

					if (scaledCenterWidth > 0)
					{
						setDebugVertexColors([2, 3, 2, 3]);
						helperImage.texture = this._textures.bottomCenter;
						helperImage.readjustSize();
						helperImage.width = scaledCenterWidth;
						helperImage.height = scaledBottomHeight;
						helperImage.x = scaledLeftWidth;
						helperImage.y = this._height - scaledBottomHeight;
						this._batch.addImage(helperImage);
					}

					if (scaledRightWidth > 0)
					{
						setDebugColor(3);
						helperImage.texture = this._textures.bottomRight;
						helperImage.readjustSize();
						helperImage.width = scaledRightWidth;
						helperImage.height = scaledBottomHeight;
						helperImage.x = this._width - scaledRightWidth;
						helperImage.y = this._height - scaledBottomHeight;
						this._batch.addImage(helperImage);
					}
				}
			}

			this._propertiesChanged = false;
			this._layoutChanged = false;
			this._renderingChanged = false;
			this._isInvalid = false;
			this._isValidating = false;
		}

		/**
		 * Readjusts the dimensions of the image according to its current
		 * textures. Call this method to synchronize image and texture size
		 * after assigning textures with a different size.
		 */
		public function readjustSize(): void
		{
			this.width = this._frame.width * this._textureScale / this.scaleX;
			this.height = this._frame.height * this._textureScale / this.scaleY;
		}

		public function invalidateSize(): void
		{
//			if (parent)
//			{
//				var matrix: Matrix = parent.transformationMatrix;
//				var mtx: Matrix = matrix.clone();
//				mtx.invert();
//				this.transformationMatrix.concat(mtx);
//				this.width *= Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
//				this.height *= Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d);
//				this.x = this.transformationMatrix.tx;
//				this.y = this.transformationMatrix.ty;
//			}
		}

		/** @private */
		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
			if (!Starling.current.contextValid)
			{
				return;
			}

			if (_filterConfig != value || _filterScale != scale)
			{
				if (value)
				{
					this._filterConfig = value;
					this._filterScale = scale;
					var gafFilter: GAFFilter;
					if (this.filter)
					{
						if (this.filter is GAFFilter)
						{
							gafFilter = this.filter as GAFFilter;
						}
						else
						{
							this.filter.dispose();
							gafFilter = new GAFFilter();
						}
					}
					else
					{
						gafFilter = new GAFFilter();
					}

					gafFilter.setConfig(this._filterConfig, this._filterScale);
					this.filter = gafFilter;
				}
				else
				{
					if (this.filter)
					{
						this.filter.dispose();
						this.filter = null;
					}
					this._filterConfig = null;
					this._filterScale = NaN;
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 */
		protected function invalidate(): void
		{
			if (this._isInvalid)
			{
				return;
			}
			this._isInvalid = true;
			if (!this._validationQueue)
			{
				return;
			}
			this._validationQueue.addControl(this, false);
		}

		private function setDebugColor(idx: int): void
		{
			if (this._debugColors)
			{
				helperImage.color = this._debugColors[idx];
				helperImage.alpha = this._debugAlphas[idx];
			}
		}

		private function setDebugVertexColors(indexes: Array): Boolean
		{
			if (this._debugColors)
			{
				var i: int;
				for (i = 0; i < indexes.length; i++)
				{
					helperImage.setVertexColor(i, this._debugColors[indexes[i]]);
					helperImage.setVertexAlpha(i, this._debugAlphas[indexes[i]]);
				}
			}
			return this._debugColors;
		}

		gaf_internal function __debugHighlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(__debugOriginalAlpha))
			{
				__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(__debugOriginalAlpha))
			{
				__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

		gaf_internal function __debugResetLight(): void
		{
			use namespace gaf_internal;
			if (!isNaN(__debugOriginalAlpha))
			{
				this.alpha = __debugOriginalAlpha;
				__debugOriginalAlpha = NaN;
			}
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 */
		override public function set transformationMatrix(matrix: Matrix): void
		{
			super.transformationMatrix = matrix;
			this._layoutChanged = true;
			this.invalidate();
		}

		/**
		 * @private
		 */
		public override function getBounds(targetSpace: DisplayObject, resultRect: Rectangle = null): Rectangle
		{
			resultRect ||= new Rectangle();

			if (targetSpace == this) // optimization
			{
				resultRect.copyFrom(this._hitArea);
			}
			else
			{
				var minX: Number = Number.MAX_VALUE, maxX: Number = -Number.MAX_VALUE;
				var minY: Number = Number.MAX_VALUE, maxY: Number = -Number.MAX_VALUE;

				this.getTransformationMatrix(targetSpace, HELPER_MATRIX);

				var coordsX: Number;
				var coordsY: Number;

				for (var i: int = 0; i < 4; i++)
				{
					coordsX = i < 2 ? this._hitArea.x : this._hitArea.right;
					coordsY = i % 2 < 1 ? this._hitArea.y : this._hitArea.bottom;
					MatrixUtil.transformCoords(HELPER_MATRIX, coordsX, coordsY, HELPER_POINT);
					minX = Math.min(minX, HELPER_POINT.x);
					maxX = Math.max(maxX, HELPER_POINT.x);
					minY = Math.min(minY, HELPER_POINT.y);
					maxY = Math.max(maxY, HELPER_POINT.y);
				}

				resultRect.x = minX;
				resultRect.y = minY;
				resultRect.width = maxX - minX;
				resultRect.height = maxY - minY;
			}

			return resultRect;
		}

		/**
		 * @private
		 */
		override public function hitTest(localPoint: Point, forTouch: Boolean = false): DisplayObject
		{
			if (forTouch && (!this.visible || !this.touchable))
			{
				return null;
			}
			return this._hitArea.containsPoint(localPoint) ? this : null;
		}

		/**
		 * @private
		 */
		override public function get width(): Number
		{
			return this._width;
		}

		/**
		 * @private
		 */
		override public function set width(value: Number): void
		{
			if (this._width == value)
			{
				return;
			}
			this._width = this._hitArea.width = value;
			this._layoutChanged = true;
			this.invalidate();
		}

		/**
		 * @private
		 */
		override public function get height(): Number
		{
			return this._height;
		}

		/**
		 * @private
		 */
		override public function set height(value: Number): void
		{
			if (this._height == value)
			{
				return;
			}
			this._height = this._hitArea.height = value;
			this._layoutChanged = true;
			this.invalidate();
		}

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		private function flattenHandler(event: Event): void
		{
			this.validate();
		}

		private function addedToStageHandler(event: Event): void
		{
			this._depth = getDisplayObjectDepthFromStage(this);
			this._validationQueue = ValidationQueue.forStarling(Starling.current);
			if (this._isInvalid)
			{
				this._validationQueue.addControl(this, false);
			}
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		public function get assetTexture(): IGAFTexture
		{
			return this._textures;
		}

		/**
		 * The textures displayed by this image.
		 *
		 * <p>In the following example, the textures are changed:</p>
		 *
		 * <listing version="3.0">
		 * image.textures = new Scale9Textures( texture, scale9Grid );</listing>
		 */
		public function get textures(): GAFScale9Texture
		{
			return this._textures;
		}

		/**
		 * @private
		 */
		public function set textures(value: GAFScale9Texture): void
		{
			if (!value)
			{
				throw new IllegalOperationError("Scale9Image textures cannot be null.");
			}

			if (this._textures != value)
			{
				this._textures = value;
				var texture: Texture = this._textures.texture;
				this._frame = texture.frame;
				if (!this._frame)
				{
					this._frame = new Rectangle(0, 0, texture.width, texture.height);
				}
				this._layoutChanged = true;
				this._renderingChanged = true;
				this.invalidate();
			}
		}

		/**
		 * The amount to scale the texture. Useful for DPI changes.
		 *
		 * <p>In the following example, the texture scale is changed:</p>
		 *
		 * <listing version="3.0">
		 * image.textureScale = 2;</listing>
		 *
		 * @default 1
		 */
		public function get textureScale(): Number
		{
			return this._textureScale;
		}

		/**
		 * @private
		 */
		public function set textureScale(value: Number): void
		{
			if (!MathUtility.equals(this._textureScale, value))
			{
				this._textureScale = value;
				this._layoutChanged = true;
				this.invalidate();
			}
		}

		/**
		 * The smoothing value to pass to the images.
		 *
		 * <p>In the following example, the smoothing is changed:</p>
		 *
		 * <listing version="3.0">
		 * image.smoothing = TextureSmoothing.NONE;</listing>
		 *
		 * @default starling.textures.TextureSmoothing.BILINEAR
		 *
		 * @see starling.textures.TextureSmoothing
		 */
		public function get smoothing(): String
		{
			return this._smoothing;
		}

		/**
		 * @private
		 */
		public function set smoothing(value: String): void
		{
			if (this._smoothing != value)
			{
				this._smoothing = value;
				this._propertiesChanged = true;
				this.invalidate();
			}
		}

		/**
		 * The color value to pass to the images.
		 *
		 * <p>In the following example, the color is changed:</p>
		 *
		 * <listing version="3.0">
		 * image.color = 0xff00ff;</listing>
		 *
		 * @default 0xffffff
		 */
		public function get color(): uint
		{
			return this._color;
		}

		/**
		 * @private
		 */
		public function set color(value: uint): void
		{
			if (this._color != value)
			{
				this._color = value;
				this._propertiesChanged = true;
				this.invalidate();
			}
		}

		/**
		 * Determines if the regions are batched normally by Starling or if
		 * they're batched separately.
		 *
		 * <p>In the following example, the separate batching is disabled:</p>
		 *
		 * <listing version="3.0">
		 * image.useSeparateBatch = false;</listing>
		 *
		 * @default true
		 */
		public function get useSeparateBatch(): Boolean
		{
			return this._useSeparateBatch;
		}

		/**
		 * @private
		 */
		public function set useSeparateBatch(value: Boolean): void
		{
			if (this._useSeparateBatch != value)
			{
				this._useSeparateBatch = value;
				this._renderingChanged = true;
				this.invalidate();
			}
		}

		/**
		 * @copy feathers.core.IValidating#depth
		 */
		public function get depth(): int
		{
			return this._depth;
		}

		/**
		 * @private
		 */
		public function get zIndex(): uint
		{
			return _zIndex;
		}

		/**
		 * @private
		 */
		public function set zIndex(value: uint): void
		{
			_zIndex = value;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
