/**
 * Created by Nazar on 12.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;

	import starling.errors.AbstractClassError;
	import starling.errors.AbstractMethodError;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class TAGFXBase implements ITAGFX
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

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

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
