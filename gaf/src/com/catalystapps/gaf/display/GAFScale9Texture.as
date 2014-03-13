/**
 * Created by Nazar on 05.03.14.
 */
package com.catalystapps.gaf.display
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class GAFScale9Texture implements IGAFTexture
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

		/**
		 * @private
		 */
		private static const DIMENSIONS_ERROR: String = "The width and height of the scale9Grid must be greater than zero.";

		private var _id: String;
		private var _texture: Texture;
		private var _pivotMatrix: Matrix;
		private var _scale9Grid: Rectangle;

		private var _topLeft: Texture;
		private var _topCenter: Texture;
		private var _topRight: Texture;
		private var _middleLeft: Texture;
		private var _middleCenter: Texture;
		private var _middleRight: Texture;
		private var _bottomLeft: Texture;
		private var _bottomCenter: Texture;
		private var _bottomRight: Texture;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function GAFScale9Texture(id: String, texture: Texture, pivotMatrix: Matrix, scale9Grid: Rectangle)
		{
			this._id = id;
			this._pivotMatrix = pivotMatrix;

			if (scale9Grid.width <= 0 || scale9Grid.height <= 0)
			{
				throw new ArgumentError(DIMENSIONS_ERROR)
			}
			this._texture = texture;
			this._scale9Grid = scale9Grid;
			this.initialize();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function initialize(): void
		{
			const textureFrame: Rectangle = this._texture.frame;
			const leftWidth: Number = this._scale9Grid.x;
			const centerWidth: Number = this._scale9Grid.width;
			const rightWidth: Number = textureFrame.width - this._scale9Grid.width - this._scale9Grid.x;
			const topHeight: Number = this._scale9Grid.y;
			const middleHeight: Number = this._scale9Grid.height;
			const bottomHeight: Number = textureFrame.height - this._scale9Grid.height - this._scale9Grid.y;

			const regionLeftWidth: Number = leftWidth + textureFrame.x;
			const regionTopHeight: Number = topHeight + textureFrame.y;
			const regionRightWidth: Number = rightWidth - (textureFrame.width - this._texture.width) - textureFrame.x;
			const regionBottomHeight: Number = bottomHeight - (textureFrame.height - this._texture.height) - textureFrame.y;

			const hasLeftFrame: Boolean = regionLeftWidth != leftWidth;
			const hasTopFrame: Boolean = regionTopHeight != topHeight;
			const hasRightFrame: Boolean = regionRightWidth != rightWidth;
			const hasBottomFrame: Boolean = regionBottomHeight != bottomHeight;

			const topLeftRegion: Rectangle = new Rectangle(0, 0, regionLeftWidth, regionTopHeight);
			const topLeftFrame: Rectangle = (hasLeftFrame || hasTopFrame) ? new Rectangle(textureFrame.x,
			                                                                              textureFrame.y, leftWidth,
			                                                                              topHeight) : null;
			this._topLeft = Texture.fromTexture(this._texture, topLeftRegion, topLeftFrame);

			const topCenterRegion: Rectangle = new Rectangle(regionLeftWidth, 0, centerWidth, regionTopHeight);
			const topCenterFrame: Rectangle = hasTopFrame ? new Rectangle(0, textureFrame.y, centerWidth,
			                                                              topHeight) : null;
			this._topCenter = Texture.fromTexture(this._texture, topCenterRegion, topCenterFrame);

			const topRightRegion: Rectangle = new Rectangle(regionLeftWidth + centerWidth, 0, regionRightWidth,
			                                                regionTopHeight);
			const topRightFrame: Rectangle = (hasTopFrame || hasRightFrame) ? new Rectangle(0, textureFrame.y,
			                                                                                rightWidth,
			                                                                                topHeight) : null;
			this._topRight = Texture.fromTexture(this._texture, topRightRegion, topRightFrame);

			const middleLeftRegion: Rectangle = new Rectangle(0, regionTopHeight, regionLeftWidth, middleHeight);
			const middleLeftFrame: Rectangle = hasLeftFrame ? new Rectangle(textureFrame.x, 0, leftWidth,
			                                                                middleHeight) : null;
			this._middleLeft = Texture.fromTexture(this._texture, middleLeftRegion, middleLeftFrame);

			const middleCenterRegion: Rectangle = new Rectangle(regionLeftWidth, regionTopHeight, centerWidth,
			                                                    middleHeight);
			this._middleCenter = Texture.fromTexture(this._texture, middleCenterRegion);

			const middleRightRegion: Rectangle = new Rectangle(regionLeftWidth + centerWidth, regionTopHeight,
			                                                   regionRightWidth, middleHeight);
			const middleRightFrame: Rectangle = hasRightFrame ? new Rectangle(0, 0, rightWidth, middleHeight) : null;
			this._middleRight = Texture.fromTexture(this._texture, middleRightRegion, middleRightFrame);

			const bottomLeftRegion: Rectangle = new Rectangle(0, regionTopHeight + middleHeight, regionLeftWidth,
			                                                  regionBottomHeight);
			const bottomLeftFrame: Rectangle = (hasLeftFrame || hasBottomFrame) ? new Rectangle(textureFrame.x, 0,
			                                                                                    leftWidth,
			                                                                                    bottomHeight) : null;
			this._bottomLeft = Texture.fromTexture(this._texture, bottomLeftRegion, bottomLeftFrame);

			const bottomCenterRegion: Rectangle = new Rectangle(regionLeftWidth, regionTopHeight + middleHeight,
			                                                    centerWidth, regionBottomHeight);
			const bottomCenterFrame: Rectangle = hasBottomFrame ? new Rectangle(0, 0, centerWidth, bottomHeight) : null;
			this._bottomCenter = Texture.fromTexture(this._texture, bottomCenterRegion, bottomCenterFrame);

			const bottomRightRegion: Rectangle = new Rectangle(regionLeftWidth + centerWidth,
			                                                   regionTopHeight + middleHeight, regionRightWidth,
			                                                   regionBottomHeight);
			const bottomRightFrame: Rectangle = (hasBottomFrame || hasRightFrame) ? new Rectangle(0, 0, rightWidth,
			                                                                                      bottomHeight) : null;
			this._bottomRight = Texture.fromTexture(this._texture, bottomRightRegion, bottomRightFrame);
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

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

		public function get id(): String
		{
			return _id;
		}

		public function get pivotMatrix(): Matrix
		{
			return _pivotMatrix;
		}

		public function get texture(): Texture
		{
			return _texture;
		}

		public function get scale9Grid(): Rectangle
		{
			return _scale9Grid;
		}

		public function get topLeft(): Texture
		{
			return _topLeft;
		}

		public function get topCenter(): Texture
		{
			return _topCenter;
		}

		public function get topRight(): Texture
		{
			return _topRight;
		}

		public function get middleLeft(): Texture
		{
			return _middleLeft;
		}

		public function get middleCenter(): Texture
		{
			return _middleCenter;
		}

		public function get middleRight(): Texture
		{
			return _middleRight;
		}

		public function get bottomLeft(): Texture
		{
			return _bottomLeft;
		}

		public function get bottomCenter(): Texture
		{
			return _bottomCenter;
		}

		public function get bottomRight(): Texture
		{
			return _bottomRight;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}