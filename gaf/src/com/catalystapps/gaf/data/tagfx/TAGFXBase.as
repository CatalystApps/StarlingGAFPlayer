/**
 * Created by Nazar on 12.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;

	import starling.errors.AbstractClassError;
	import starling.errors.AbstractMethodError;

	import starling.textures.Texture;

	/**
	 * Dispatched when he texture is decoded. It can only be used when the callback has been executed.
	 */
	[Event(name="textureReady", type="flash.events.Event")]

	/**
	 * @private
	 */
	public class TAGFXBase extends EventDispatcher implements ITAGFX
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

		public static const EVENT_TYPE_TEXTURE_READY: String = "textureReady";

		public static const SOURCE_TYPE_BITMAP_DATA: String = "sourceTypeBitmapData";
		public static const SOURCE_TYPE_BITMAP: String = "sourceTypeBitmap";
		public static const SOURCE_TYPE_PNG_BA: String = "sourceTypePNGBA";
		public static const SOURCE_TYPE_ATF_BA: String = "sourceTypeATFBA";
		public static const SOURCE_TYPE_PNG_URL: String = "sourceTypePNGURL";
		public static const SOURCE_TYPE_ATF_URL: String = "sourceTypeATFURL";

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		protected var _texture: Texture;
		protected var _textureSize: Point;
		protected var _textureScale: Number = -1;
		protected var _textureFormat: String;
		protected var _source: *;
		protected var _clearSourceAfterTextureCreated: Boolean;
		protected var _isReady: Boolean;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function TAGFXBase()
		{
			if (Capabilities.isDebugger &&
					getQualifiedClassName(this) == "com.catalystapps.gaf.data::TAGFXBase")
			{
				throw new AbstractClassError();
			}
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

		protected function onTextureReady(texture: Texture): void
		{
			this._isReady = true;
			this.dispatchEvent(new Event(EVENT_TYPE_TEXTURE_READY));
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		public function get texture(): Texture
		{
			return this._texture;
		}

		public function get textureSize(): Point
		{
			return this._textureSize;
		}

		public function set textureSize(value: Point): void
		{
			this._textureSize = value;
		}

		public function get textureScale(): Number
		{
			return this._textureScale;
		}

		public function set textureScale(value: Number): void
		{
			this._textureScale = value;
		}

		public function get textureFormat(): String
		{
			return this._textureFormat;
		}

		public function set textureFormat(value: String): void
		{
			this._textureFormat = value;
		}

		public function get sourceType(): String
		{
			throw new AbstractMethodError();
		}

		public function get source(): *
		{
			return _source;
		}

		public function get clearSourceAfterTextureCreated(): *
		{
			return this._clearSourceAfterTextureCreated;
		}

		public function set clearSourceAfterTextureCreated(value: Boolean): void
		{
			this._clearSourceAfterTextureCreated = value;
		}

		public function get ready(): Boolean
		{
			return this._isReady;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
