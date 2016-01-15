/**
 * Created by Nazar on 13.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import com.catalystapps.gaf.data.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class TAGFXSourceATFURL extends TAGFXBase
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

		protected var _numTextures: int;
		protected var _isCubeMap: Boolean;

		private var _atfLoader: ATFLoader;
		private var _atfIsLoading: Boolean;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function TAGFXSourceATFURL(source: String, atfData: GAFATFData)
		{
			super();

			this._source = source;
			this._textureFormat = atfData.format;
			this._numTextures = atfData.numTextures;
			this._isCubeMap = atfData.isCubeMap;

			this.textureSize = new Point(atfData.width, atfData.height);

			this._atfLoader = new ATFLoader();
			this._atfLoader.dataFormat = URLLoaderDataFormat.BINARY;

			this._atfLoader.addEventListener(Event.COMPLETE, this.onATFLoadComplete);
			this._atfLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onATFLoadIOError);
			this._atfLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onATFLoadSecurityError);
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

		private function loadATFData(url: String): void
		{
			if (this._atfIsLoading)
			{
				try { this._atfLoader.close(); } catch (e: Error) {}
			}

			this._atfLoader.load(new URLRequest(url));
			this._atfIsLoading = true;
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		override public function get sourceType(): String
		{
			return SOURCE_TYPE_ATF_URL;
		}

		override public function get texture(): Texture
		{
			if (!this._texture)
			{
				this._texture = Texture.empty(this._textureSize.x, this._textureSize.y,
						false, GAF.useMipMaps && this._numTextures > 1, false,
						this._textureScale, this._textureFormat, false);

				this._texture.root.onRestore = function(): void
				{
					loadATFData(_source);
				};

				loadATFData(this._source);
			}

			return this._texture;
		}

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		private function onATFLoadComplete(event: Event): void
		{
			this._atfIsLoading = false;

			var loader: ATFLoader = event.currentTarget as ATFLoader;
			var sourceBA: ByteArray = loader.data as ByteArray;
			this._texture.root.uploadAtfData(sourceBA, 0,
					function(texture: Texture): void
					{
						sourceBA.clear();
					});
		}

		private function onATFLoadIOError(event: IOErrorEvent): void
		{
			this._atfIsLoading = false;
			var loader: ATFLoader = event.currentTarget as ATFLoader;
			throw new Error("Can't restore lost context from a ATF file. Can't load file: " + loader.urlRequest.url, event.errorID);
		}

		private function onATFLoadSecurityError(event: SecurityErrorEvent): void
		{
			this._atfIsLoading = false;
			var loader: ATFLoader = event.currentTarget as ATFLoader;
			throw new Error("Can't restore lost context from a ATF file. Can't load file: " + loader.urlRequest.url, event.errorID);
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

import flash.net.URLLoader;
import flash.net.URLRequest;

class ATFLoader extends URLLoader
{
	private var _req: URLRequest;

	public function ATFLoader(request: URLRequest = null)
	{
		super(request);
		this._req = request;
	}

	public override function load(request: URLRequest): void
	{
		this._req = request;
		super.load(request);
	}

	public function get urlRequest(): URLRequest
	{
		return this._req;
	}
}
