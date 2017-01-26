package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.core.gaf_internal;

	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.filter.GAFFilterChain;

	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;

	/**
	 * GAFImage represents static GAF display object that is part of the <code>GAFMovieClip</code>.
	 */
	public class GAFImage extends Image implements IGAFImage, IMaxSize, IGAFDebug
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

		private static const V_DATA_ATTR: String = "position";

		private static const HELPER_POINT: Point = new Point();
		private static const HELPER_POINT_3D: Vector3D = new Vector3D();
		private static const HELPER_MATRIX: Matrix = new Matrix();
		private static const HELPER_MATRIX_3D: Matrix3D = new Matrix3D();

		private var _assetTexture: IGAFTexture;

		private var _filterChain:GAFFilterChain;
		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		private var _maxSize: Point;

		private var _pivotChanged: Boolean;

		/** @private */
		gaf_internal var __debugOriginalAlpha: Number = NaN;

		private var _orientationChanged: Boolean;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates a new <code>GAFImage</code> instance.
		 * @param assetTexture <code>IGAFTexture</code> from which it will be created.
		 */
		public function GAFImage(assetTexture: IGAFTexture)
		{
			this._assetTexture = assetTexture.clone();

			super(this._assetTexture.texture);
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates a new instance of GAFImage.
		 */
		public function copy(): GAFImage
		{
			return new GAFImage(this._assetTexture);
		}

		/** @private */
		public function invalidateOrientation(): void
		{
			this._orientationChanged = true;
		}

		/** @private */
		public function set debugColors(value: Vector.<uint>): void
		{
			var alpha0: Number;
			var alpha1: Number;

			switch (value.length)
			{
				case 1:
					this.color = value[0];
					this.alpha = (value[0] >>> 24) / 255;
					break;
				case 2:
					this.setVertexColor(0, value[0]);
					this.setVertexColor(1, value[0]);
					this.setVertexColor(2, value[1]);
					this.setVertexColor(3, value[1]);

					alpha0 = (value[0] >>> 24) / 255;
					alpha1 = (value[1] >>> 24) / 255;
					this.setVertexAlpha(0, alpha0);
					this.setVertexAlpha(1, alpha0);
					this.setVertexAlpha(2, alpha1);
					this.setVertexAlpha(3, alpha1);
					break;
				case 3:
					this.setVertexColor(0, value[0]);
					this.setVertexColor(1, value[0]);
					this.setVertexColor(2, value[1]);
					this.setVertexColor(3, value[2]);

					alpha0 = (value[0] >>> 24) / 255;
					this.setVertexAlpha(0, alpha0);
					this.setVertexAlpha(1, alpha0);
					this.setVertexAlpha(2, (value[1] >>> 24) / 255);
					this.setVertexAlpha(3, (value[2] >>> 24) / 255);
					break;
				case 4:
					this.setVertexColor(0, value[0]);
					this.setVertexColor(1, value[1]);
					this.setVertexColor(2, value[2]);
					this.setVertexColor(3, value[3]);

					this.setVertexAlpha(0, (value[0] >>> 24) / 255);
					this.setVertexAlpha(1, (value[1] >>> 24) / 255);
					this.setVertexAlpha(2, (value[2] >>> 24) / 255);
					this.setVertexAlpha(3, (value[3] >>> 24) / 255);
					break;
			}
		}

		/**
		 * Change the texture of the <code>GAFImage</code> to a new one.
		 * @param newTexture the new <code>IGAFTexture</code> which will be used to replace existing one.
		 */
		public function changeTexture(newTexture: IGAFTexture): void
		{
			this.texture = newTexture.texture;
			this.readjustSize();
			this._assetTexture.copyFrom(newTexture);
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

					this.filter = _filterChain;
				}
				else
				{
					if (this.filter)
					{
						this.filter.dispose();
						this.filter = null;
					}

                    this._filterChain = null;
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

		/** @private */
		gaf_internal function __debugHighlight(): void
		{
			use namespace gaf_internal;

			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		/** @private */
		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;

			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

		/** @private */
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
		 * Disposes all resources of the display object.
		 */
		override public function dispose(): void
		{
			if (this.filter)
			{
				this.filter.dispose();
				this.filter = null;
			}
			this._assetTexture = null;
			this._filterConfig = null;

			super.dispose();
		}

		override public function getBounds(targetSpace: DisplayObject, resultRect: Rectangle=null): Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();

			if (targetSpace == this) // optimization
			{
				vertexData.getPoint(3,V_DATA_ATTR, HELPER_POINT);
				resultRect.setTo(0.0, 0.0, HELPER_POINT.x, HELPER_POINT.y);
			}
			else if (targetSpace == parent && rotation == 0.0 && isEquivalent(skewX, skewY)) // optimization
			{
				var scaleX: Number = this.scaleX;
				var scaleY: Number = this.scaleY;
				vertexData.getPoint(3,V_DATA_ATTR, HELPER_POINT);
				resultRect.setTo(x - pivotX * scaleX,      y - pivotY * scaleY,
						HELPER_POINT.x * scaleX, HELPER_POINT.y * scaleY);
				if (scaleX < 0) { resultRect.width  *= -1; resultRect.x -= resultRect.width;  }
				if (scaleY < 0) { resultRect.height *= -1; resultRect.y -= resultRect.height; }
			}
			else if (is3D && stage)
			{
				stage.getCameraPosition(targetSpace, HELPER_POINT_3D);
				getTransformationMatrix3D(targetSpace, HELPER_MATRIX_3D);
				vertexData.getBoundsProjected(V_DATA_ATTR,HELPER_MATRIX_3D, HELPER_POINT_3D, 0, 4, resultRect);
			}
			else
			{
				getTransformationMatrix(targetSpace, HELPER_MATRIX);
				vertexData.getBounds(V_DATA_ATTR,HELPER_MATRIX, 0, 4, resultRect);
			}

			return resultRect;
		}

		private final function isEquivalent(a: Number, b: Number, epsilon: Number = 0.0001): Boolean
		{
			return (a - epsilon < b) && (a + epsilon > b);
		}

		/** @private */
		override public function set pivotX(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotX = value;
		}

		/** @private */
		override public function set pivotY(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotY = value;
		}

		/** @private */
		override public function get x(): Number
		{
			updateTransformMatrix();
			return super.x;
		}

		/** @private */
		override public function get y(): Number
		{
			updateTransformMatrix();
			return super.y;
		}

		/** @private */
		override public function get rotation(): Number
		{
			updateTransformMatrix();
			return super.rotation;
		}

		/** @private */
		override public function get scaleX(): Number
		{
			updateTransformMatrix();
			return super.scaleX;
		}

		/** @private */
		override public function get scaleY(): Number
		{
			updateTransformMatrix();
			return super.scaleY;
		}

		/** @private */
		override public function get skewX(): Number
		{
			updateTransformMatrix();
			return super.skewX;
		}

		/** @private */
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

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

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


		/**
		 * Returns current <code>IGAFTexture</code>.
		 * @return current <code>IGAFTexture</code>
		 */
		public function get assetTexture(): IGAFTexture
		{
			return this._assetTexture;
		}

		/** @private */
		public function get pivotMatrix(): Matrix
		{
			HELPER_MATRIX.copyFrom(this._assetTexture.pivotMatrix);

			if (this._pivotChanged)
			{
				HELPER_MATRIX.tx = this.pivotX;
				HELPER_MATRIX.ty = this.pivotY;
			}

			return HELPER_MATRIX;
		}
	}
}
