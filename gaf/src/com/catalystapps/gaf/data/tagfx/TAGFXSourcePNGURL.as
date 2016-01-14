/**
 * Created by Nazar on 12.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import com.catalystapps.gaf.data.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class TAGFXSourcePNGURL extends TAGFXBase
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

		private var _pngLoader: Loader;
		private var _pngIsLoading: Boolean;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function TAGFXSourcePNGURL(source: String, textureSize: Point, format: String = "bgra")
		{
			super();

			this._source = source;
			this._textureSize = textureSize;
			this._textureFormat = format;

			this._pngLoader = new Loader();
			this._pngLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onPNGLoadComplete);
			this._pngLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onPNGLoadError);
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

		private function loadBitmapData(url: String): void
		{
			if (this._pngIsLoading)
			{
				try { this._pngLoader.close(); } catch (e: Error) {}
			}

			this._pngLoader.load(new URLRequest(url), new LoaderContext());
			this._pngIsLoading = true;
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		override public function get sourceType(): String
		{
			return SOURCE_TYPE_PNG_URL;
		}

		override public function get texture(): Texture
		{
			if (!this._texture)
			{
				_texture = Texture.empty(this._textureSize.x, this._textureSize.y, true, GAF.useMipMaps, false,
						this._textureScale, this._textureFormat, false);
				_texture.root.onRestore = function(): void
				{
					loadBitmapData(_source);
				};

				loadBitmapData(_source);
			}

			return _texture;
		}

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		private function onPNGLoadComplete(event: Event): void
		{
			this._pngIsLoading = false;

			var info: LoaderInfo = event.currentTarget as LoaderInfo;
			var bmpd: BitmapData = Bitmap(info.content).bitmapData;
			this._texture.root.uploadBitmapData(bmpd);

			this._pngLoader.unload();
			bmpd.dispose();
		}

		private function onPNGLoadError(event: IOErrorEvent): void
		{
			this._pngIsLoading = false;

			var info: LoaderInfo = event.currentTarget as LoaderInfo;
			throw new Error("Can't restore lost context from a PNG file. Can't load file: " + info.url, event.errorID);
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
