package com.catalystapps.gaf.data.config
{
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
		private var _contantScaleFactor: CTextureAtlasCSF;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function CTextureAtlasScale()
		{
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public function dispose(): void
		{
			for each(var cTextureAtlasCSF: CTextureAtlasCSF in this._allContentScaleFactors)
			{
				cTextureAtlasCSF.dispose();
			}
		}
		
		public function getTextureAtlasForCSF(csf: Number): CTextureAtlasCSF
		{
			for each(var textureAtlas: CTextureAtlasCSF in this._allContentScaleFactors)
			{
				if(textureAtlas.csf == csf)
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
			_scale = scale;
		}
		
		public function get scale(): Number
		{
			return _scale;
		}

		public function get allContentScaleFactors(): Vector.<CTextureAtlasCSF>
		{
			return _allContentScaleFactors;
		}

		public function set allContentScaleFactors(allContentScaleFactors: Vector.<CTextureAtlasCSF>): void
		{
			_allContentScaleFactors = allContentScaleFactors;
		}

		public function get contantScaleFactor(): CTextureAtlasCSF
		{
			return _contantScaleFactor;
		}

		public function set contantScaleFactor(contantScaleFactor: CTextureAtlasCSF): void
		{
			_contantScaleFactor = contantScaleFactor;
		}

	}
}
