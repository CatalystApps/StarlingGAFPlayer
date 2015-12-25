package com.catalystapps.gaf.data {
	import flash.utils.Dictionary;
	import flash.display.Bitmap;
	import flash.display.LoaderInfo;
	import starling.core.Starling;
	import starling.textures.Texture;

	import com.catalystapps.gaf.utils.DebugUtility;
	import com.catalystapps.gaf.utils.MathUtility;

	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display3D.Context3DTextureFormat;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	/**
	 * Graphical data storage that used by <code>GAFTimeline</code>. It contain all created textures and all
	 * saved images as <code>BitmapData</code> (in case when <code>Starling.handleLostContext = true</code> was set before asset conversion).
	 * Used as shared graphical data storage between several GAFTimelines if they are used the same texture atlas (bundle created using "Create bundle" option)
	 */
	public class GAFGFXData
	{
		[Deprecated(since="5.0")]
		public static const ATF: String = "ATF";
		[Deprecated(replacement="Context3DTextureFormat.BGRA", since="5.0")]
		public static const BGRA: String = Context3DTextureFormat.BGRA;
		[Deprecated(replacement="Context3DTextureFormat.BGR_PACKED", since="5.0")]
		public static const BGR_PACKED: String = Context3DTextureFormat.BGR_PACKED;
		[Deprecated(replacement="Context3DTextureFormat.BGRA_PACKED", since="5.0")]
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
		private var _texturesDictionary: Object = {};
		private var _imagesDictionary: Object = {};
		private var _urlsDictionary: Object = {};
		private var _atfDictionary: Object = {};

		private var _callbacksByLoader: Dictionary;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		/** @private */
		public function GAFGFXData()
		{
			if (GAF.restoreTexturesFromFile)
			{
				this._callbacksByLoader = new Dictionary(true);
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		/** @private */
		public function addAtlasURL(scale: Number, csf: Number, imageID: String, url: String): void
		{
			this._urlsDictionary[scale] ||= {};
			this._urlsDictionary[scale][csf] ||= {};
			this._urlsDictionary[scale][csf][imageID] ||= url;
		}
		
		/** 
		 * Add image to storage. Unique key for image is combination scale + csf + imageID
		 */
		public function addImage(scale: Number, csf: Number, imageID: String, image: BitmapData): void
		{
			this._imagesDictionary[scale] ||= {};
			this._imagesDictionary[scale][csf] ||= {};
			this._imagesDictionary[scale][csf][imageID] ||= image;
		}
		
		/**
		 * Returns image as BitmapData by unique key consist of scale + csf + imageID
		 */
		public function getImage(scale: Number, csf: Number, imageID: String): BitmapData
		{
			if (this._imagesDictionary
			&&  this._imagesDictionary[scale]
			&&  this._imagesDictionary[scale][csf])
			{
				return this._imagesDictionary[scale][csf][imageID];
			}
			return null;
		}
		
		/**
		 * Returns images for specified scale and csf in Object as combination key-value where key - is imageID and value - is image as BitmapData
		 */
		public function getImages(scale: Number, csf: Number): Object
		{
			if (this._imagesDictionary
			&&  this._imagesDictionary[scale])
			{
				return this._imagesDictionary[scale][csf];
			}
			return null;
		}
		
		/**
		 * Removes specified image or images for specified combination scale and csf. If nothing was specified - removes all images
		 */
		public function removeImages(scale: Number = NaN, csf: Number = NaN, imageID: String = null): void
		{
			this.remove(this._imagesDictionary, scale, csf, imageID);
			this.remove(this._atfDictionary, scale, csf, imageID);

			if (isNaN(scale))
			{
				this._imagesDictionary = null;
				this._atfDictionary = null;
			}
		}
		
		/** 
		 * Add ATF data to storage. Unique key for ATF is combination scale + csf + atfID
		 */
		public function addATFData(scale: Number, csf: Number, atfID: String, data: ByteArray): void
		{
			this._atfDictionary[scale] ||= {};
			this._atfDictionary[scale][csf] ||= {};
			this._atfDictionary[scale][csf][atfID] ||= data;
		}

		/**
		 * Returns ATF data as ByteArray by unique key consist of scale + csf + atfID
		 */
		public function getATFData(scale: Number, csf: Number, atfID: String): ByteArray
		{
			if (this._atfDictionary
			&&  this._atfDictionary[scale]
			&&  this._atfDictionary[scale][csf])
			{
				return this._atfDictionary[scale][csf][atfID];
			}
			return null;
		}
		
		/**
		 * Returns ATFs for specified scale and csf in Object as combination key-value where key - is atfID and value - is ATF file content as ByteArray
		 */
		public function getATFs(scale: Number, csf: Number): Object
		{
			if (this._atfDictionary
			&&  this._atfDictionary[scale])
			{
				return this._atfDictionary[scale][csf];
			}
			return null;
		}
		
		/**
		 * Removes specified ATF or ATFs for specified combination scale and csf. If nothing was specified - removes all ATFs
		 */
		public function removeATFs(scale: Number = NaN, csf: Number = NaN, atfID: String = null): void
		{
			this.removeImages(scale, csf, atfID);
		}
		
		/** 
		 * Creates textures from all images for specified scale and csf.
		 * @param format defines the values to use for specifying a texture format. Supported formats: BGRA, BGR_PACKED, BGRA_PACKED
		 * @see #createTexture()
		 */
		public function createTextures(scale: Number, csf: Number, format: String = Context3DTextureFormat.BGRA): Boolean
		{
			var result: Boolean;
			var images: Object = this.getImages(scale, csf);
			if (images)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};
				
				for(var imageAtlasID: String in images)
				{
					if (images[imageAtlasID])
					{
						addTexture(scale, csf, images[imageAtlasID], imageAtlasID, format);
					}
				}
				result = true;
			}
			
			var atfs: Object = this.getATFs(scale, csf);
			if (atfs)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};
				
				for(var atfAtlasID: String in atfs)
				{
					addATFTexture(scale, csf, atfAtlasID);
				}
				result = true;
			}
			return result;
		}
		
		/** 
		 * Creates texture from specified image.
		 * @param format defines the values to use for specifying a texture format. Supported formats: BGRA, BGR_PACKED, BGRA_PACKED
		 * @see #createTextures()
		 */
		public function createTexture(scale: Number, csf: Number, imageID: String, format: String = Context3DTextureFormat.BGRA): Boolean
		{
			var image: BitmapData = this.getImage(scale, csf, imageID);
			if (image)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};

				addTexture(scale, csf, image, imageID, format);
				
				return true;
			}
			else
			{
				var atfData: ByteArray = this.getATFData(scale, csf, imageID);
				if (atfData)
				{
					this._texturesDictionary[scale] ||= {};
					this._texturesDictionary[scale][csf] ||= {};

					addATFTexture(scale, csf, imageID);

					return true;
				}
			}

			return false;
		}
		
		/**
		 * Returns texture by unique key consist of scale + csf + imageID
		 */
		public function getTexture(scale: Number, csf: Number, imageID: String): Texture
		{
			if(this._texturesDictionary
			&& this._texturesDictionary[scale]
			&& this._texturesDictionary[scale][csf]
			&& this._texturesDictionary[scale][csf][imageID])
			{
				return this._texturesDictionary[scale][csf][imageID];
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
			if (this._texturesDictionary
			&&  this._texturesDictionary[scale])
			{
				return this._texturesDictionary[scale][csf];
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
					if (!imageID)
					{
						for (var atlasIDToDispose: String in this._texturesDictionary[scale][csf])
						{
							this.disposeTextures(scale, csf, atlasIDToDispose);
						}
						delete this._texturesDictionary[scale][csf];
					}
					else
					{
						(this._texturesDictionary[scale][csf][imageID] as Texture).dispose();

						delete this._texturesDictionary[scale][csf][imageID];
					}
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
		private function addTexture(scale: Number, csf: Number, img: BitmapData, imageID: String, format: String): void
		{
			if (DebugUtility.RENDERING_DEBUG)
			{
				img = setGrayScale(img.clone());
			}
			var texture: Texture = this._texturesDictionary[scale][csf][imageID];
			if (!texture)
			{
				texture = Texture.fromBitmapData(img, GAF.useMipMaps, false, csf, format);

				if (GAF.restoreTexturesFromFile)
				{
					texture.root.onRestore = function():void
					{
						loadBitmapData(texture.root.uploadBitmapData, _urlsDictionary[scale][csf][imageID]);
					};
				}
				this._texturesDictionary[scale][csf][imageID] = texture;
			}
		}

		private function addATFTexture(scale: Number, csf: Number, imageID: String): void
		{
			var texture: Texture = this._texturesDictionary[scale][csf][imageID];
			if (!texture)
			{
				var url: String = this._urlsDictionary[scale][csf][imageID];
				url = url.substring(0, url.lastIndexOf(".png")) + ".atf";
				

				texture = Texture.fromAtfData(this._atfDictionary[scale][csf][imageID], csf, GAF.useMipMaps);

				if (GAF.restoreTexturesFromFile)
				{
					texture.root.onRestore = function():void
					{
						loadATF(texture.root.uploadAtfData, url);
					};
				}
				this._urlsDictionary[scale][csf][imageID] = url;
				this._texturesDictionary[scale][csf][imageID] = texture;
			}
		}

		private function loadBitmapData(callback: Function, url: String): void
		{
			var atlasSourceLoader: Loader = new Loader();
			atlasSourceLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPNGLoadComplete);
			atlasSourceLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onPNGLoadError);
			atlasSourceLoader.load(new URLRequest(url), new LoaderContext());

			this._callbacksByLoader[atlasSourceLoader.contentLoaderInfo] = callback;
		}

		private function loadATF(callback: Function, url: String): void
		{
			var atfSourceLoader: URLLoader = new URLLoader();
			atfSourceLoader.dataFormat = URLLoaderDataFormat.BINARY;
			atfSourceLoader.addEventListener(Event.COMPLETE, onATFLoadComplete);
			atfSourceLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onATFLoadError);
			atfSourceLoader.load(new URLRequest(url));

			this._callbacksByLoader[atfSourceLoader] = callback;
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

		private function remove(dictionary: Object, scale: Number, csf: Number, atlasID: String): void
		{
			var clearMethod: String = dictionary == this._imagesDictionary ? "dispose" : "clear";
			// Dispose only if starling does not handle lost context
			if (GAF.restoreTexturesFromFile || !Starling.handleLostContext)
			{
				for (var tmpScale: String in dictionary)
				{
					if (isNaN(scale) || MathUtility.equals(scale, Number(tmpScale)))
					{
						for (var tmpCSF: String in dictionary[tmpScale])
						{
							if (isNaN(csf) || MathUtility.equals(csf, Number(tmpCSF)))
							{
								for (var tmpAtlasID: String in dictionary[tmpScale][tmpCSF])
								{
									if (!atlasID || atlasID == tmpAtlasID)
									{
										dictionary[tmpScale][tmpCSF][tmpAtlasID][clearMethod]();
									}
								}
							}
						}
					}
				}
			}

			if (isNaN(csf))
			{
				delete dictionary[scale];
			}
			else
			{
				if (atlasID)
				{
					delete dictionary[scale][csf][atlasID];
				}
				else
				{
					delete dictionary[scale][csf];
				}
			}
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
		// --------------------------------------------------------------------------
		private function onPNGLoadComplete(event: Event): void
		{
			var info: LoaderInfo = event.target as LoaderInfo;
			info.removeEventListener(Event.COMPLETE, onPNGLoadComplete);
			var callback: Function = _callbacksByLoader[info];
			callback(Bitmap(info.content).bitmapData);
			delete _callbacksByLoader[info];
		}
		
		private function onATFLoadComplete(event: Event): void
		{
			var loader: URLLoader = event.target as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onATFLoadComplete);
			var callback: Function = _callbacksByLoader[loader];
			callback(loader.data as ByteArray);
			delete _callbacksByLoader[loader];
		}
		
		private function onPNGLoadError(event: Event): void
		{
			var info: LoaderInfo = event.target as LoaderInfo;
			info.removeEventListener(Event.COMPLETE, onPNGLoadComplete);
			info.removeEventListener(IOErrorEvent.IO_ERROR, onPNGLoadError);
			delete _callbacksByLoader[info];
			
			throw new Error("Can't restore lost context from a PNG file. Can't load file: ", info.url);
		}
		
		private function onATFLoadError(event: Event): void
		{
			var loader: URLLoader = event.target as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onATFLoadComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onATFLoadError);
			delete _callbacksByLoader[loader];
			
			throw new Error("Can't restore lost context from an ATF file");
		}
		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------
	}
}
