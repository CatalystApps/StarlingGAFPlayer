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
	import com.catalystapps.gaf.filter.GAFFilterChain;
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
	import starling.display.MeshBatch;
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
	public class GAFScale9Image extends Sprite implements IValidating, IGAFImage, IMaxSize, IGAFDebug
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
		private static var sHelperImage: Image;
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
		private var _batch: MeshBatch;
		private var _isValidating: Boolean = false;
		private var _isInvalid: Boolean = false;
		private var _validationQueue: ValidationQueue;
		private var _depth: int = -1;

		private var _debugColors: Vector.<uint>;
		private var _debugAlphas: Vector.<Number>;

        private var _filterChain:GAFFilterChain;
		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		private var _maxSize: Point;

		private var _pivotChanged: Boolean;

		gaf_internal var __debugOriginalAlpha: Number = NaN;

		private var _orientationChanged: Boolean;

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
			this.invalidateSize();

			this._batch = new MeshBatch();
			this._batch.touchable = false;
			this.addChild(this._batch);

//			this.addEventListener(Event.FLATTEN, this.flattenHandler);
			this.addEventListener(Event.ADDED_TO_STAGE, this.addedToStageHandler);
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates a new instance of GAFScale9Image.
		 */
		public function copy(): GAFScale9Image
		{
			return new GAFScale9Image(this._textures, this._textureScale);
		}

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
			if (!this._isInvalid)
			{
				return;
			}
			if (this._isValidating)
			{
				if(this._validationQueue)
				{
					//we were already validating, and something else told us to
					//validate. that's bad.
					this._validationQueue.addControl(this);
				}
				return;
			}
			this._isValidating = true;
			if (this._propertiesChanged || this._layoutChanged || this._renderingChanged)
			{
				this._batch.batchable = !this._useSeparateBatch;
				this._batch.clear();

				if (!sHelperImage)
				{
					//because Scale9Textures enforces it, we know for sure that
					//this texture will have a size greater than zero, so there
					//won't be an error from Quad.
					sHelperImage = new Image(this._textures.middleCenter);
				}
				sHelperImage.textureSmoothing = this._smoothing;

				if (!setDebugVertexColors([0, 1, 2, 3]))
				{
					sHelperImage.color = this._color;
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
						this.setDebugColor(0);
						sHelperImage.texture = this._textures.topLeft;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledLeftWidth;
						sHelperImage.height = scaledTopHeight;
						sHelperImage.x = scaledLeftWidth - sHelperImage.width;
						sHelperImage.y = scaledTopHeight - sHelperImage.height;
						this._batch.addMesh(sHelperImage);
					}

					if (scaledCenterWidth > 0)
					{
						this.setDebugVertexColors([0, 1, 0, 1]);
						sHelperImage.texture = this._textures.topCenter;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledCenterWidth;
						sHelperImage.height = scaledTopHeight;
						sHelperImage.x = scaledLeftWidth;
						sHelperImage.y = scaledTopHeight - sHelperImage.height;
						this._batch.addMesh(sHelperImage);
					}

					if (scaledRightWidth > 0)
					{
						this.setDebugColor(1);
						sHelperImage.texture = this._textures.topRight;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledRightWidth;
						sHelperImage.height = scaledTopHeight;
						sHelperImage.x = this._width - scaledRightWidth;
						sHelperImage.y = scaledTopHeight - sHelperImage.height;
						this._batch.addMesh(sHelperImage);
					}
				}

				if (scaledMiddleHeight > 0)
				{
					if (scaledLeftWidth > 0)
					{
						this.setDebugVertexColors([0, 0, 2, 2]);
						sHelperImage.texture = this._textures.middleLeft;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledLeftWidth;
						sHelperImage.height = scaledMiddleHeight;
						sHelperImage.x = scaledLeftWidth - sHelperImage.width;
						sHelperImage.y = scaledTopHeight;
						this._batch.addMesh(sHelperImage);
					}

					if (scaledCenterWidth > 0)
					{
						this.setDebugVertexColors([0, 1, 2, 3]);
						sHelperImage.texture = this._textures.middleCenter;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledCenterWidth;
						sHelperImage.height = scaledMiddleHeight;
						sHelperImage.x = scaledLeftWidth;
						sHelperImage.y = scaledTopHeight;
						this._batch.addMesh(sHelperImage);
					}

					if (scaledRightWidth > 0)
					{
						this.setDebugVertexColors([1, 1, 3, 3]);
						sHelperImage.texture = this._textures.middleRight;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledRightWidth;
						sHelperImage.height = scaledMiddleHeight;
						sHelperImage.x = this._width - scaledRightWidth;
						sHelperImage.y = scaledTopHeight;
						this._batch.addMesh(sHelperImage);
					}
				}

				if (scaledBottomHeight > 0)
				{
					if (scaledLeftWidth > 0)
					{
						this.setDebugColor(2);
						sHelperImage.texture = this._textures.bottomLeft;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledLeftWidth;
						sHelperImage.height = scaledBottomHeight;
						sHelperImage.x = scaledLeftWidth - sHelperImage.width;
						sHelperImage.y = this._height - scaledBottomHeight;
						this._batch.addMesh(sHelperImage);
					}

					if (scaledCenterWidth > 0)
					{
						this.setDebugVertexColors([2, 3, 2, 3]);
						sHelperImage.texture = this._textures.bottomCenter;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledCenterWidth;
						sHelperImage.height = scaledBottomHeight;
						sHelperImage.x = scaledLeftWidth;
						sHelperImage.y = this._height - scaledBottomHeight;
						this._batch.addMesh(sHelperImage);
					}

					if (scaledRightWidth > 0)
					{
						this.setDebugColor(3);
						sHelperImage.texture = this._textures.bottomRight;
						sHelperImage.readjustSize();
						sHelperImage.width = scaledRightWidth;
						sHelperImage.height = scaledBottomHeight;
						sHelperImage.x = this._width - scaledRightWidth;
						sHelperImage.y = this._height - scaledBottomHeight;
						this._batch.addMesh(sHelperImage);
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
			this.invalidateSize();
		}

		public function invalidateSize(): void
		{
			var mtx: Matrix = this.transformationMatrix;
			var scaleX: Number = Math.sqrt(mtx.a * mtx.a + mtx.b * mtx.b);
			var scaleY: Number = Math.sqrt(mtx.c * mtx.c + mtx.d * mtx.d);

			if (scaleX < 0.99 || scaleX > 1.01
					|| scaleY < 0.99 || scaleY > 1.01)
			{
				this._width = this._frame.width * scaleX;
				this._height = this._frame.height * scaleY;

				HELPER_POINT.x = mtx.a;
				HELPER_POINT.y = mtx.b;
				HELPER_POINT.normalize(1);
				mtx.a = HELPER_POINT.x;
				mtx.b = HELPER_POINT.y;

				HELPER_POINT.x = mtx.c;
				HELPER_POINT.y = mtx.d;
				HELPER_POINT.normalize(1);
				mtx.c = HELPER_POINT.x;
				mtx.d = HELPER_POINT.y;
			}
			else
			{
				this._width = this._frame.width;
				this._height = this._frame.height;
			}

			this._layoutChanged = true;
			this.invalidate();
		}

		/** @private */
		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
			if (!Starling.current.contextValid)
			{
				return;
			}

			if (this._filterConfig != value || this._filterScale != scale)
			{
				if (value)
				{
					this._filterConfig = value;
					this._filterScale = scale;
                    if(this._filterChain)
                    {
                        _filterChain.dispose();
                    }
                    else
                    {
                        _filterChain = new GAFFilterChain();
                    }

                    _filterChain.setFilterData(_filterConfig);
					this._batch.filter = _filterChain;
				}
				else
				{
					if (this._batch.filter)
					{
						this._batch.filter.dispose();
						this._batch.filter = null;
					}

					this._filterChain = null;
					this._filterConfig = null;
					this._filterScale = NaN;
				}
			}
		}

		/** @private */
		public function invalidateOrientation(): void
		{
			this._orientationChanged = true;
			invalidateSize();
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 */
		public function invalidate(): void
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
			this._validationQueue.dispose();//addControl(this);
		}

		private function setDebugColor(idx: int): void
		{
			if (this._debugColors)
			{
				sHelperImage.color = this._debugColors[idx];
				sHelperImage.alpha = this._debugAlphas[idx];
			}
		}

		private function setDebugVertexColors(indexes: Array): Boolean
		{
			if (this._debugColors)
			{
				var i: int;
				for (i = 0; i < indexes.length; i++)
				{
					sHelperImage.setVertexColor(i, this._debugColors[indexes[i]]);
					sHelperImage.setVertexAlpha(i, this._debugAlphas[indexes[i]]);
				}
			}
			return this._debugColors != null;
		}

		gaf_internal function __debugHighlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

		gaf_internal function __debugResetLight(): void
		{
			use namespace gaf_internal;
			if (!isNaN(this.__debugOriginalAlpha))
			{
				this.alpha = this.__debugOriginalAlpha;
				this.__debugOriginalAlpha = NaN;
			}
		}

		[Inline]
		private final function updateTransformMatrix(): void
		{
			if (this._orientationChanged)
			{
				this.transformationMatrix = this.transformationMatrix;
				this._orientationChanged = false;
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
		override public function hitTest(localPoint: Point): DisplayObject
		{
			if ( (!this.visible || !this.touchable))
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

			super.width = value;

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

			super.height = value;

			this._height = this._hitArea.height = value;
			this._layoutChanged = true;
			this.invalidate();
		}

		override public function set scaleX(value: Number): void
		{
			if (this.scaleX != value)
			{
				super.scaleX = value;

				this._layoutChanged = true;
				this.invalidate();
			}
		}

		override public function set scaleY(value: Number): void
		{
			if (this.scaleY != value)
			{
				super.scaleY = value;

				this._layoutChanged = true;
				this.invalidate();
			}
		}

		override public function set pivotX(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotX = value;
		}

		override public function set pivotY(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotY = value;
		}

		override public function get x(): Number
		{
			updateTransformMatrix();
			return super.x;
		}

		override public function get y(): Number
		{
			updateTransformMatrix();
			return super.y;
		}

		override public function get rotation(): Number
		{
			updateTransformMatrix();
			return super.rotation;
		}

		override public function get scaleX(): Number
		{
			updateTransformMatrix();
			return super.scaleX;
		}

		override public function get scaleY(): Number
		{
			updateTransformMatrix();
			return super.scaleY;
		}

		override public function get skewX(): Number
		{
			updateTransformMatrix();
			return super.skewX;
		}

		override public function get skewY(): Number
		{
			updateTransformMatrix();
			return super.skewY;
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
				this._validationQueue.dispose();//addControl(this, false);
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
		 * image.textureSmoothing = TextureSmoothing.NONE;</listing>
		 *
		 * @default starling.textures.TextureSmoothing.BILINEAR
		 *
		 * @see starling.textures.TextureSmoothing
		 */
		public function get textureSmoothing(): String
		{
			return this._smoothing;
		}

		public function set textureSmoothing(smoothing:String): void
		{
			this._smoothing = smoothing;
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

		/** @private */
		public function get maxSize(): Point
		{
			return this._maxSize;
		}

		/** @private */
		public function set maxSize(value: Point): void
		{
			this._maxSize = value;
		}

		/** @private */
		public function get pivotMatrix(): Matrix
		{
			HELPER_MATRIX.copyFrom(this._textures.pivotMatrix);

			if (this._pivotChanged)
			{
				HELPER_MATRIX.tx = HELPER_MATRIX.a * this.pivotX;
				HELPER_MATRIX.ty = HELPER_MATRIX.d * this.pivotY;
			}

			return HELPER_MATRIX;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
