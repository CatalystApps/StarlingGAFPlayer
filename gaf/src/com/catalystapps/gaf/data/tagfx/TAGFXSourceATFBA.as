/**
 * Created by Nazar on 13.01.2016.
 */
package com.catalystapps.gaf.data.tagfx
{
	import com.catalystapps.gaf.data.GAF;

	import flash.utils.ByteArray;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class TAGFXSourceATFBA extends TAGFXBase
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

		public function TAGFXSourceATFBA(source: ByteArray)
		{
			this._source = source;
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
			return SOURCE_TYPE_ATF_BA;
		}

		override public function get texture(): Texture
		{
			if (!this._texture)
			{
				this._texture = Texture.fromAtfData(this._source, this._textureScale, GAF.useMipMaps, this.onTextureCreated);
				this._texture.root.onRestore = function(): void
				{
					_texture.root.uploadAtfData(_source, 0, onTextureCreated);
				};
			}

			return this._texture;
		}

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		private function onTextureCreated(texture: Texture): void
		{
			if (this._clearSourceAfterTextureCreated)
				(this._source as ByteArray).clear();
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
