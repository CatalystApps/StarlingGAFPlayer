package com.catalystapps.gaf.display
{
	import starling.display.Image;
	import starling.textures.TextureSmoothing;

	/**
	 * @private
	 */
	public class GAFImage extends Image implements IGAFImage, IGAFDebug
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

		private var _assetTexture: IGAFTexture;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * GAFImage represents display object that is part of the <code>GAFMovieClip</code>
		 * @param assetTexture The texture displayed by this image.
		 * @see com.catalystapps.gaf.display.GAFScale9Image
		 */
		public function GAFImage(assetTexture: IGAFTexture)
		{
			this._assetTexture = assetTexture;

			super(this._assetTexture.texture);
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

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

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Disposes all resources of the display object
		 */
		override public function dispose(): void
		{
			(this.filter) ? this.filter.dispose() : null;
			this.filter = null;

			super.dispose();
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

		public function get assetTexture(): IGAFTexture
		{
			return _assetTexture;
		}

	}
}
