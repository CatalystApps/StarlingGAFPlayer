/**
 * Created by Nazar on 15.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import com.catalystapps.gaf.data.GAF;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class TAGFXSourcePNGBA extends TAGFXBase
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

		public function TAGFXSourcePNGBA(source: ByteArray, textureSize: Point, format: String = "bgra")
		{
			this._source = source;
			this._textureSize = textureSize;
			this._textureFormat = format;

			this._pngLoader = new Loader();
			this._pngLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onPNGLoadComplete);
			this._pngLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onPNGLoadError);
			this._pngLoader.contentLoaderInfo.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.onPNGLoadAsyncError);
			this._pngLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onPNGLoadSecurityError);
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

		private function loadBitmapData(source: ByteArray): void
		{
			if (this._pngIsLoading)
			{
				try { this._pngLoader.close(); } catch (e: Error) {}
			}

			this._pngLoader.loadBytes(source, new LoaderContext());
			this._pngIsLoading = true;
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		override public function get sourceType(): String
		{
			return SOURCE_TYPE_PNG_BA;
		}

		override public function get texture(): Texture
		{
			if (!this._texture)
			{
				this._texture = Texture.empty(
						this._textureSize.x / this._textureScale, this._textureSize.y / this._textureScale,
						true, GAF.useMipMaps, false, this._textureScale, this._textureFormat, false);
				this._texture.root.onRestore = function(): void
				{
					loadBitmapData(_source);
				};

				loadBitmapData(this._source);
			}

			return this._texture;
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

			if (this._clearSourceAfterTextureCreated)
				(this._source as ByteArray).clear();
		}

		private function onPNGLoadError(event: IOErrorEvent): void
		{
			this._pngIsLoading = false;

			throw new Error("Can't restore lost context from a PNG ByteArray.", event.errorID);
		}

		private function onPNGLoadAsyncError(event: AsyncErrorEvent): void
		{
			this._pngIsLoading = false;

			throw new Error("Can't restore lost context from a PNG ByteArray.", event.errorID);
		}

		private function onPNGLoadSecurityError(event: SecurityErrorEvent): void
		{
			this._pngIsLoading = false;

			throw new Error("Can't restore lost context from a PNG ByteArray.", event.errorID);
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
