/**
 * Created by Nazar on 12.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import com.catalystapps.gaf.data.GAF;

	import flash.display.BitmapData;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class TAGFXSourceBitmapData extends TAGFXBase
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

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function TAGFXSourceBitmapData(source: BitmapData, format: String)
		{
			this._source = source;
			this._textureFormat = format;
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

		override public function get sourceType(): String
		{
			return SOURCE_TYPE_BITMAP_DATA;
		}

		override public function get texture(): Texture
		{
			if (!this._texture)
			{
				this._texture = Texture.fromBitmapData(this._source, GAF.useMipMaps, false, this._textureScale, this._textureFormat);
				if (this._clearSourceAfterTextureCreated)
					(this._source as BitmapData).dispose();
			}

			return this._texture;
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

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
