package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.tagfx.ITAGFX;
	import com.catalystapps.gaf.data.tagfx.TAGFXBase;
	import com.catalystapps.gaf.utils.DebugUtility;


	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.textures.Texture;

	/**
	 * Dispatched when he texture is decoded. It can only be used when the callback has been executed.
	 */
	[Event(name="texturesReady", type="flash.events.Event")]

	/**
	 * Graphical data storage that used by <code>GAFTimeline</code>. It contain all created textures and all
	 * saved images as <code>BitmapData</code>.
	 * Used as shared graphical data storage between several GAFTimelines if they are used the same texture atlas (bundle created using "Create bundle" option)
	 */
	public class GAFGFXData extends EventDispatcher
	{
		public static const EVENT_TYPE_TEXTURES_READY: String = "texturesReady";

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
		private var _taGFXDictionary: Object = {};

		private var _textureLoadersSet: Dictionary = new Dictionary();

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function GAFGFXData()
		{
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function addTAGFX(scale: Number, csf: Number, imageID: String, taGFX: ITAGFX): void
		{
			this._taGFXDictionary[scale] ||= {};
			this._taGFXDictionary[scale][csf] ||= {};
			this._taGFXDictionary[scale][csf][imageID] ||= taGFX;
		}

		/** @private */
		public function getTAGFXs(scale: Number, csf: Number): Object
		{
			if (this._taGFXDictionary)
			{
				if (this._taGFXDictionary[scale])
				{
					return this._taGFXDictionary[scale][csf];
				}
			}

			return null;
		}

		/** @private */
		public function getTAGFX(scale: Number, csf: Number, imageID: String): ITAGFX
		{
			if (this._taGFXDictionary)
			{
				if (this._taGFXDictionary[scale])
				{
					if (this._taGFXDictionary[scale][csf])
					{
						return this._taGFXDictionary[scale][csf][imageID];
					}
				}
			}

			return null;
		}

		/**
		 * Creates textures from all images for specified scale and csf.
		 * @param scale
		 * @param csf
		 * @return {Boolean}
		 * @see #createTexture()
		 */
		public function createTextures(scale: Number, csf: Number): Boolean
		{
			var taGFXs: Object = this.getTAGFXs(scale, csf);
			if (taGFXs)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};

				for (var imageAtlasID: String in taGFXs)
				{
					if (taGFXs[imageAtlasID])
					{
						addTexture(this._texturesDictionary[scale][csf], taGFXs[imageAtlasID], imageAtlasID);
					}
				}
				return true;
			}

			return false;
		}

		/**
		 * Creates texture from specified image.
		 * @param scale
		 * @param csf
		 * @param imageID
		 * @return {Boolean}
		 * @see #createTextures()
		 */
		public function createTexture(scale: Number, csf: Number, imageID: String): Boolean
		{
			var taGFX: ITAGFX = this.getTAGFX(scale, csf, imageID);
			if (taGFX)
			{
				this._texturesDictionary[scale] ||= {};
				this._texturesDictionary[scale][csf] ||= {};

				addTexture(this._texturesDictionary[scale][csf], taGFX, imageID);

				return true;
			}

			return false;
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
			// create texture and check if it successfully created
			if (this.createTexture(scale, csf, imageID))
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
						if (this._texturesDictionary[scale] && this._texturesDictionary[scale][csf])
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
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function addTexture(dictionary: Object, tagfx: ITAGFX, imageID: String): void
		{
			if (DebugUtility.RENDERING_DEBUG)
			{
				var bitmapData: BitmapData;
				if (tagfx.sourceType == TAGFXBase.SOURCE_TYPE_BITMAP_DATA)
				{
					bitmapData = setGrayScale(tagfx.source.clone());
				}

				if(bitmapData)
				{
                    dictionary[imageID] = Texture.fromBitmapData(bitmapData, GAF.useMipMaps, false, tagfx.textureScale, tagfx.textureFormat);
				}
				else
				{
					if(tagfx.texture)
					{
                        dictionary[imageID] = tagfx.texture;
					}
					else
					{
						throw new Error("GAFGFXData texture for rendering not found!")
					}
				}
			}
			else if (!dictionary[imageID])
			{
				if (!tagfx.ready)
				{
					_textureLoadersSet[tagfx] = tagfx;
					tagfx.addEventListener(TAGFXBase.EVENT_TYPE_TEXTURE_READY, this.onTextureReady);
				}

				dictionary[imageID] = tagfx.texture;
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
		private function onTextureReady(event: Event): void
		{
			var tagfx: ITAGFX = event.currentTarget as ITAGFX;
			tagfx.removeEventListener(TAGFXBase.EVENT_TYPE_TEXTURE_READY, this.onTextureReady);

			delete _textureLoadersSet[tagfx];

			if (this.isTexturesReady)
				this.dispatchEvent(new Event(EVENT_TYPE_TEXTURES_READY));
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function get isTexturesReady(): Boolean
		{
			var empty: Boolean = true;
			for (var tagfx:* in this._textureLoadersSet)
			{
				empty = false;
				break;
			}

			return empty;
		}
	}
}
