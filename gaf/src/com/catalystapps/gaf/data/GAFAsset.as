package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	
	/**
	 * <p>GAFAsset represents converted GAF file. It is like a library symbol in Flash IDE that contains all information about GAF animation. 
	 * It is used to create <code>GAFMovieClip</code> that is ready animation object to be used in starling display list</p>
	 */
	public class GAFAsset
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------
		
		public static const CONTENT_ALL: String = "contentAll";
		public static const CONTENT_DEFAULT: String = "contentDefault";
		public static const CONTENT_SPECIFY: String = "contentSpecify";
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------
		
		private var _id: String;
		private var _config: GAFAssetConfig;
		
		private var _gafgfxData: GAFGFXData;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Creates an GAFAsset object
		 * 
		 * @param config GAF asset config
		 */
		public function GAFAsset(config: GAFAssetConfig)
		{
			this._config = config;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Disposes the underlying GAF asset config
		 */
		public function dispose(): void
		{
			this._config.dispose();
		}
		
		/**
		 * Load all all grafical data connected with this asset in device GPU memory. Used in case of manual control of GPU memory usage.
		 * Works only in case when all graphical data stored in RAM (<code>ZipToGAFAssetConverter.keepImagesInRAM</code> should be set to <code>true</code>
		 * before asset conversion)
		 * 
		 * @param content - content type that should be loaded (CONTENT_ALL, CONTENT_DEFAULT, CONTENT_SPECIFY)
		 * @param scale - in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 * @param csf - in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 */
		public function loadInVideoMemory(content: String = CONTENT_DEFAULT, scale: Number = NaN, csf: Number = NaN): void
		{
			var csfConfig: CTextureAtlasCSF;
			
			switch(content)
			{
				case CONTENT_ALL:
					for each(var scaleConfig: CTextureAtlasScale in this._config.allTextureAtlases)
					{
						for each(csfConfig in scaleConfig.allContentScaleFactors)
						{
							this._gafgfxData.createTextures(scaleConfig.scale, csfConfig.csf);
							
							csfConfig.atlas = CTextureAtlas.createFromTextures(this._gafgfxData.getTextures(scaleConfig.scale, csfConfig.csf), csfConfig);
						}
					}
					return;
					
				case CONTENT_DEFAULT:
					csfConfig = this._config.textureAtlas.contentScaleFactor;

					if (csfConfig == null) return;

					this._gafgfxData.createTextures(this.scale, this.contentScaleFactor);
					
					csfConfig.atlas = CTextureAtlas.createFromTextures(this._gafgfxData.getTextures(this.scale, this.contentScaleFactor), csfConfig);
					return;
				
				case CONTENT_SPECIFY:
					csfConfig = this.getCSFConfig(scale, csf);

					if (csfConfig == null) return;

					this._gafgfxData.createTextures(scale, csf);
					
					csfConfig.atlas = CTextureAtlas.createFromTextures(this._gafgfxData.getTextures(scale, csf), csfConfig);
					return;
			}
			
		}
		
		/**
		 * Unload all all grafical data connected with this asset from device GPU memory. Used in case of manual control of video memory usage
		 * 
		 * @param content - content type that should be loaded (CONTENT_ALL, CONTENT_DEFAULT, CONTENT_SPECIFY)
		 * @param scale - in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 * @param csf - in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 */
		public function unloadFromVideoMemory(content: String = CONTENT_DEFAULT, scale: Number = NaN, csf: Number = NaN): void
		{
			var csfConfig: CTextureAtlasCSF;
			
			switch(content)
			{
				case CONTENT_ALL:
					for each(var scaleConfig: CTextureAtlasScale in this._config.allTextureAtlases)
					{
						for each(csfConfig in scaleConfig.allContentScaleFactors)
						{
							this._gafgfxData.disposeTextures(scaleConfig.scale, csfConfig.csf);
							csfConfig.atlas.dispose();
							csfConfig.atlas = null;
						}
					}
					return;
				
				case CONTENT_DEFAULT:
					this._gafgfxData.disposeTextures(this.scale, this.contentScaleFactor);
					this._config.textureAtlas.contentScaleFactor.atlas.dispose();
					this._config.textureAtlas.contentScaleFactor.atlas = null;
					return;
				
				case CONTENT_SPECIFY:
					csfConfig = this.getCSFConfig(scale, csf);
					if(csfConfig)
					{
						this._gafgfxData.disposeTextures(scale, csf);
						csfConfig.atlas.dispose();
						csfConfig.atlas = null;
					}
					return;
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
		private function getCSFConfig(scale: Number, csf: Number): CTextureAtlasCSF
		{
			var scaleConfig: CTextureAtlasScale = this._config.getTextureAtlasForScale(scale);
			
			if(scaleConfig)
			{
				var csfConfig: CTextureAtlasCSF = scaleConfig.getTextureAtlasForCSF(csf);
				
				if(csfConfig)
				{
					return csfConfig;
				}
				else
				{
					return null;
				}
			}
			else
			{
				return null;
			}
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
		
		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Asset idintifier (name given at animation's upload or assigned by developer)
		 */
		public function get id(): String
		{
			return _id;
		}

		public function set id(id: String): void
		{
			_id = id;
		}
		
		/** @private */
		public function get textureAtlas(): CTextureAtlas
		{
			if(!this._config.textureAtlas.contentScaleFactor.atlas)
			{
				this.loadInVideoMemory(CONTENT_DEFAULT);
			}
			
			return this._config.textureAtlas.contentScaleFactor.atlas;
		}
		
		/** @private */
		public function get config(): GAFAssetConfig
		{
			return _config;
		}
		
		////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Texture atlas scale that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different scale assign apropriate scale to <code>GAFAsset</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
		public function set scale(scale: Number): void
		{
			var csf: Number = this.contentScaleFactor;
			
			var taScale: CTextureAtlasScale = this._config.getTextureAtlasForScale(scale);
			
			if(taScale)
			{
				_config.textureAtlas = taScale;
				
				var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);
				
				if(taCSF)
				{
					_config.textureAtlas.contentScaleFactor = taCSF;
				}
				else
				{
					throw new Error("There is no csf " + csf + "in asset config for scalse " + scale);
				}
			}
			else
			{
				throw new Error("There is no scale " + scale + "in asset config");
			}
		}
		
		public function get scale(): Number
		{
			return _config.textureAtlas.scale;
		}
		
		/**
		 * Texture atlas content scale factor (csf) that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different csf assign apropriate csf to <code>GAFAsset</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
		public function set contentScaleFactor(csf: Number): void
		{
			var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);
			
			if(taCSF)
			{
				_config.textureAtlas.contentScaleFactor = taCSF;
			}
			else
			{
				throw new Error("There is no csf " + csf + "in asset config");
			}
		}
		
		public function get contentScaleFactor(): Number
		{
			return this._config.textureAtlas.contentScaleFactor.csf;
		}
		
		/**
		 * Graphical data storage that used by <code>GAFAsset</code>.
		 */
		public function set gafgfxData(gafgfxData: GAFGFXData): void
		{
			_gafgfxData = gafgfxData;
		}
		
		public function get gafgfxData(): GAFGFXData
		{
			return _gafgfxData;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
