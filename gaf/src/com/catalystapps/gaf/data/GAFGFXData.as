package com.catalystapps.gaf.data
{
	import flash.display3D.Context3DTextureFormat;
	import starling.core.Starling;
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.utils.DebugUtility;

	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.textures.Texture;

	/**
	 * Graphical data storage that used by <code>GAFTimeline</code>. It contain all created textures and all
	 * saved images as <code>BitmapData</code> (in case when <code>ZipToGAFAssetConverter.keepImagesInRAM = true</code> was set before asset conversion).
	 * Used as shared graphical data storage between several GAFTimelines if they are used the same texture atlas (bundle created using "Create bundle" option)
	 */
	public class GAFGFXData
	{
		public static const BGRA: String = Context3DTextureFormat.BGRA;
		public static const BGR_PACKED: String = Context3DTextureFormat.BGR_PACKED;
		public static const BGRA_PACKED: String = Context3DTextureFormat.BGRA_PACKED;
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
			if(!this._imagesDictionary[scale])
			{
				this._imagesDictionary[scale] = {};
			}
			
			if(!this._imagesDictionary[scale][csf])
			{
				this._imagesDictionary[scale][csf] = {};
			}
			
			if(!this._imagesDictionary[scale][csf][imageID])
			{
				this._imagesDictionary[scale][csf][imageID] = image;
			}
		}
		
		/**
		 * Returns image as BitmapData by unique key consist of scale + csf + imageID
		 */
		public function getImage(scale: Number, csf: Number, imageID: String): BitmapData
		{
			if(this._imagesDictionary)
			{
				if(this._imagesDictionary[scale])
				{
					if(this._imagesDictionary[scale][csf])
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
			if(this._imagesDictionary)
			{
				if(this._imagesDictionary[scale])
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
			// Dispose only if starling does not handle lost context
			if (!Starling.handleLostContext)
			{
				for (var tmpScale: String in _imagesDictionary)
				{
					if (isNaN(scale) || scale == Number(tmpScale))
					{
						for (var tmpCsf: String in _imagesDictionary[tmpScale])
						{
							if (isNaN(csf) || csf == Number(tmpCsf))
							{
								for (var tmpImageID: String in _imagesDictionary[tmpScale][tmpCsf])
								{
									if (!imageID || imageID == tmpImageID)
									{
										var tmpBitmapData: BitmapData = _imagesDictionary[tmpScale][tmpCsf][tmpImageID];
										tmpBitmapData.dispose();
									}
								}
							}
						}
					}
				}
			}

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
		 * Creates textures from all images for specified scale and csf.
		 * @param format defines the values to use for specifying a texture format. Supported formats: BGRA, BGR_PACKED, BGRA_PACKED
		 * @see #createTexture()
		 */
		public function createTextures(scale: Number, csf: Number, format: String = BGRA): Boolean
		{
			var images: Object = this.getImages(scale, csf);
			if (images)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};
				
				for(var imageAtlasID: String in images)
				{
					addTexture(this._texturesDictionary[scale][csf], csf, images[imageAtlasID], imageAtlasID, format);
				}
				
				return true;
			}
			
			return false;
		}
		
		/** 
		 * Creates texture from specified image.
		 * @param format defines the values to use for specifying a texture format. Supported formats: BGRA, BGR_PACKED, BGRA_PACKED
		 * @see #createTextures()
		 */
		public function createTexture(scale: Number, csf: Number, imageID: String, format: String = BGRA): Boolean
		{
			var image: BitmapData = this.getImage(scale, csf, imageID);
			if (image)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};
				
				addTexture(this._texturesDictionary[scale][csf], csf, image, imageID, format);
				
				return true;
			}
			
			return false;
		}
		
		/**
		 * Returns texture by unique key consist of scale + csf + imageID
		 */
		public function getTexture(scale: Number, csf: Number, imageID: String): Texture
		{
			if(this._texturesDictionary)
			{
				if(this._texturesDictionary[scale])
				{
					if(this._texturesDictionary[scale][csf])
					{
						if(this._texturesDictionary[scale][csf][imageID])
						{
							return this._texturesDictionary[scale][csf][imageID];
						}
					}
				}
			}
			
			// in case when there is no texture created
			// create texture and check if it successfully created
			if(this.createTexture(scale, csf, imageID))
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
			if(this._texturesDictionary)
			{
				if(this._texturesDictionary[scale])
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
			if(isNaN(scale))
			{
				for(var scaleToDispose: String in this._texturesDictionary)
				{
					this.disposeTextures(Number(scaleToDispose));
				}
				
				this._texturesDictionary = null;
			}
			else
			{
				if(isNaN(csf))
				{
					for(var csfToDispose: String in this._texturesDictionary[scale])
					{
						this.disposeTextures(scale, Number(csfToDispose));
					}
					
					delete this._texturesDictionary[scale];
				}
				else
				{
					if(imageID)
					{
						(this._texturesDictionary[scale][csf][imageID] as Texture).dispose();
						
						delete this._texturesDictionary[scale][csf][imageID];
					}
					else
					{
						if (this._texturesDictionary[scale] && this._texturesDictionary[scale][csf])
						{
							for(var atlasIDToDispose: String in this._texturesDictionary[scale][csf])
							{
								this.disposeTextures(scale, csf, atlasIDToDispose);
							}
							delete this._texturesDictionary[scale][csf];
						}
					}
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
		private function addTexture(dictionary: Object, csf: Number, img: BitmapData, imageID: String, format: String): void
		{
			if (DebugUtility.RENDERING_DEBUG)
			{
				img = setGrayScale(img.clone());
			}
			if (!dictionary[imageID])
			{
				dictionary[imageID] = CTextureAtlas.textureFromImg(img, csf, format);
			}
		}
			
		private function setGrayScale(image: BitmapData): BitmapData
		{
			var matrix: Array = [
				0.26231, 0.51799, 0.0697, 0, 81.775,
				0.26231, 0.51799, 0.0697, 0, 81.775,
				0.26231, 0.51799, 0.0697, 0, 81.775,
				0, 0, 0, 1, 0];

			var filter: ColorMatrixFilter = new ColorMatrixFilter(matrix);
			image.applyFilter(image, new Rectangle(0, 0, image.width, image.height), new Point(0, 0), filter);

			return image;
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
	}
}
