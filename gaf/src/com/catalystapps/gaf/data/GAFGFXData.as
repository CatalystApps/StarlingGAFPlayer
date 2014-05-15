package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.utils.DebugUtility;

	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.textures.Texture;

	/**
	 * Graphical data storage that used by <code>GAFAsset</code>. It contain all created textures and all
	 * saved images as <code>BitmapData</code> (in case when <code>ZipToGAFAssetConverter.keepImagesInRAM = true</code> was set before asset conversion).
	 * Used as shared graphical data storage between several GAFAssets if they are used the same texture atlas (bundle created using "Create bundle" option)
	 */
	public class GAFGFXData
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

		private var _texturesDictionary: Object;
		private var _imagesDictionary: Object;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function GAFGFXData()
		{
			this._texturesDictionary = {};
			this._imagesDictionary = {};
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Add image to storage. Unique key for image is combination scale + csf + imageID
		 */
		public function addImage(scale: Number, csf: Number, imageID: String, image: BitmapData): void
		{
			if (!this._imagesDictionary[scale])
			{
				this._imagesDictionary[scale] = new Object();
			}

			if (!this._imagesDictionary[scale][csf])
			{
				this._imagesDictionary[scale][csf] = new Object();
			}

			if (!this._imagesDictionary[scale][csf][imageID])
			{
				this._imagesDictionary[scale][csf][imageID] = image;
			}
		}

		/**
		 * Returns image as BitmapData by unique key consist of scale + csf + imageID
		 */
		public function getImage(scale: Number, csf: Number, imageID: String): BitmapData
		{
			if (this._imagesDictionary)
			{
				if (this._imagesDictionary[scale])
				{
					if (this._imagesDictionary[scale][csf])
					{
						return this._imagesDictionary[scale][csf][imageID];
					}
				}
			}

			return null;
		}

		/**
		 * Returns images for specified scale and csf in Object as combination key-value where key - is imageID and value - is image as BitmapData
		 */
		public function getImages(scale: Number, csf: Number): Object
		{
			if (this._imagesDictionary)
			{
				if (this._imagesDictionary[scale])
				{
					return this._imagesDictionary[scale][csf];
				}
			}

			return null;
		}

		/**
		 * Removes specified image or images for specified combination scale and csf. If nothing was specified - removes all images
		 */
		public function removeImages(scale: Number = NaN, csf: Number = NaN, imageID: String = null): void
		{
			if (isNaN(scale))
			{
				this._imagesDictionary = null;
			}
			else
			{
				if (isNaN(csf))
				{
					delete this._imagesDictionary[scale];
				}
				else
				{
					if (imageID)
					{
						delete this._imagesDictionary[scale][csf][imageID];
					}
					else
					{
						delete this._imagesDictionary[scale][csf];
					}
				}
			}
		}

		/**
		 * Creates texture from specified image. If imageID is not specified creates textures from all images for specified scale and csf
		 */
		public function createTextures(scale: Number, csf: Number, imageID: String = null): Boolean
		{
			var image: BitmapData;

			function createMissedObjects(dictionary: Object): void
			{
				if (!dictionary[scale])
				{
					dictionary[scale] = {};
				}

				if (!dictionary[scale][csf])
				{
					dictionary[scale][csf] = {};
				}
			}

			function addTexture(dictionary: Object, img: BitmapData, imageAtlasID: String, debug: Boolean = false): void
			{
				if (debug)
				{
					var img: BitmapData = setGrayScale(img.clone());
				}
				if (!dictionary[scale][csf][imageAtlasID])
				{
					dictionary[scale][csf][imageAtlasID] = CTextureAtlas.textureFromImg(img, csf);
				}
			}

			function setGrayScale(obj: BitmapData): BitmapData
			{
				var matrix: Array = [
					0.26231, 0.51799, 0.0697, 0, 81.775,
					0.26231, 0.51799, 0.0697, 0, 81.775,
					0.26231, 0.51799, 0.0697, 0, 81.775,
					0, 0, 0, 1, 0];

				var filter: ColorMatrixFilter = new ColorMatrixFilter(matrix);
				obj.applyFilter(obj, new Rectangle(0, 0, obj.width, obj.height), new Point(0, 0), filter);

				return obj;
			}

			////////////////////////////////////

			if (imageID)
			{
				image = this.getImage(scale, csf, imageID);

				if (image)
				{
					createMissedObjects(this._texturesDictionary);

					addTexture(this._texturesDictionary, image, imageID, DebugUtility.RENDERING_DEBUG);

					return true;
				}

				return false;
			}
			else
			{
				var images: Object = this.getImages(scale, csf);

				if (images)
				{
					createMissedObjects(this._texturesDictionary);

					for (var imageAtlasID: String in images)
					{
						image = images[imageAtlasID];

						addTexture(this._texturesDictionary, image, imageAtlasID, DebugUtility.RENDERING_DEBUG);
					}

					return true;
				}

				return false;
			}
		}

		/**
		 * Returns texture by unique key consist of scale + csf + imageID
		 */
		public function getTexture(scale: Number, csf: Number, imageID: String): Texture
		{
			if (this._texturesDictionary)
			{
				if (this._texturesDictionary[scale])
				{
					if (this._texturesDictionary[scale][csf])
					{
						if (this._texturesDictionary[scale][csf][imageID])
						{
							return this._texturesDictionary[scale][csf][imageID];
						}
					}
				}
			}

			// in case when there is no texture created
			// creare texture and check if it successfully created
			if (this.createTextures(scale, csf, imageID))
			{
				return this._texturesDictionary[scale][csf][imageID];
			}

			return null;
		}

		/**
		 * Returns textures for specified scale and csf in Object as combination key-value where key - is imageID and value - is Texture
		 */
		public function getTextures(scale: Number, csf: Number): Object
		{
			if (this._texturesDictionary)
			{
				if (this._texturesDictionary[scale])
				{
					return this._texturesDictionary[scale][csf];
				}
			}

			return null;
		}

		/**
		 * Dispose specified texture or textures for specified combination scale and csf. If nothing was specified - dispose all texturea
		 */
		public function disposeTextures(scale: Number = NaN, csf: Number = NaN, imageID: String = null): void
		{
			if (isNaN(scale))
			{
				for (var scaleToDispose: String in this._texturesDictionary)
				{
					this.disposeTextures(Number(scaleToDispose));
				}

				this._texturesDictionary = null;
			}
			else
			{
				if (isNaN(csf))
				{
					for (var csfToDispose: String in this._texturesDictionary[scale])
					{
						this.disposeTextures(scale, Number(csfToDispose));
					}

					delete this._texturesDictionary[scale];
				}
				else
				{
					if (imageID)
					{
						(this._texturesDictionary[scale][csf][imageID] as Texture).dispose();

						delete this._texturesDictionary[scale][csf][imageID];
					}
					else
					{
						for (var atlasIDToDispose: String in this._texturesDictionary[scale][csf])
						{
							this.disposeTextures(scale, csf, atlasIDToDispose);
						}

						delete this._texturesDictionary[scale][csf];
					}
				}
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
	}
}
