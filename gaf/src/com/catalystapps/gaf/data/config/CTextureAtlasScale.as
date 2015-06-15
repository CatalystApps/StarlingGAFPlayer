package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.utils.MathUtility;
	/**
	 * @private
	 */
	public class CTextureAtlasScale
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

		private var _scale: Number;

		private var _allContentScaleFactors: Vector.<CTextureAtlasCSF>;
		private var _contentScaleFactor: CTextureAtlasCSF;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextureAtlasScale()
		{
			this._allContentScaleFactors = new Vector.<CTextureAtlasCSF>();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function dispose(): void
		{
			for each (var cTextureAtlasCSF: CTextureAtlasCSF in this._allContentScaleFactors)
			{
				cTextureAtlasCSF.dispose();
			}
		}

		public function getTextureAtlasForCSF(csf: Number): CTextureAtlasCSF
		{
			for each (var textureAtlas: CTextureAtlasCSF in this._allContentScaleFactors)
			{
				if (MathUtility.equals(textureAtlas.csf, csf))
				{
					return textureAtlas;
				}
			}

			return null;
		}

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

		public function set scale(scale: Number): void
		{
			this._scale = scale;
		}

		public function get scale(): Number
		{
			return this._scale;
		}

		public function get allContentScaleFactors(): Vector.<CTextureAtlasCSF>
		{
			return this._allContentScaleFactors;
		}

		public function set allContentScaleFactors(value: Vector.<CTextureAtlasCSF>): void
		{
			this._allContentScaleFactors = value;
		}

		public function get contentScaleFactor(): CTextureAtlasCSF
		{
			return this._contentScaleFactor;
		}

		public function set contentScaleFactor(value: CTextureAtlasCSF): void
		{
			this._contentScaleFactor = value;
		}
	}
}
