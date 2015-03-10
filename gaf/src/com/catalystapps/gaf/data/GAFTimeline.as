package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.display.IGAFTexture;
	
	/**
	 * <p>GAFTimeline represents converted GAF file. It is like a library symbol in Flash IDE that contains all information about GAF animation. 
	 * It is used to create <code>GAFMovieClip</code> that is ready animation object to be used in starling display list</p>
	 */
	public class GAFTimeline
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
		/** @private */
		gaf_internal var _uniqueID: String;
		/** @private */
		gaf_internal var _uniqueLinkage: String;
		
		private var _config: GAFTimelineConfig;

		private var _gafgfxData: GAFGFXData;
		private var _gafBundle: GAFBundle;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Creates an GAFTimeline object
		 * 
		 * @param timelineConfig - GAF timeline config
		 */
		public function GAFTimeline(timelineConfig: GAFTimelineConfig)
		{
			this._config = timelineConfig;

			this.gaf_internal::_uniqueID = timelineConfig.assetID + "::" + timelineConfig.id;
			if (timelineConfig.linkage)
			{
				this.gaf_internal::_uniqueLinkage = timelineConfig.assetID + "::" + timelineConfig.linkage;
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		// --------------------------------------------------------------------------
		
		/** @private */
		public function getTextureByName(animationObjectName: String): IGAFTexture
		{
			var instanceID: String = this._config.getNamedPartID(animationObjectName);
			if (instanceID)
			{
				var part: CAnimationObject = this._config.animationObjects.getAnimationObject(instanceID);
				if (part)
				{
					return textureAtlas.getTexture(part.regionID);
				}
			}
			return null;
		}
		
		/**
		 * Disposes the underlying GAF timeline config
		 */
		public function dispose(): void
		{
			this._config.dispose();
		}
		
		/**
		 * Load all graphical data connected with this asset in device GPU memory. Used in case of manual control of GPU memory usage.
		 * Works only in case when all graphical data stored in RAM (<code>ZipToGAFAssetConverter.keepImagesInRAM</code> should be set to <code>true</code>
		 * before asset conversion)
		 * 
		 * @param content - content type that should be loaded. Available types: <code>CONTENT_ALL, CONTENT_DEFAULT, CONTENT_SPECIFY</code>
		 * @param scale - in case when specified content is <code>CONTENT_SPECIFY</code> scale and csf should be set in required values
		 * @param csf - in case when specified content is <code>CONTENT_SPECIFY</code> scale and csf should be set in required values
		 * @param format - defines the values to use for specifying a texture format. Supported formats: <code>BGRA, BGR_PACKED, BGRA_PACKED</code>
		 */
		public function loadInVideoMemory(content: String = CONTENT_DEFAULT, scale: Number = NaN, csf: Number = NaN, format: String = GAFGFXData.BGRA): void
		{
			if (!this._config.textureAtlas || !this._config.textureAtlas.contentScaleFactor.elements)
			{
				return;
			}

			var textures: Object;
			var csfConfig: CTextureAtlasCSF;
			
			switch(content)
			{
				case CONTENT_ALL:
					for each(var scaleConfig: CTextureAtlasScale in this._config.allTextureAtlases)
					{
						for each(csfConfig in scaleConfig.allContentScaleFactors)
						{
							this._gafgfxData.createTextures(scaleConfig.scale, csfConfig.csf, format);
							
							textures = this._gafgfxData.getTextures(scaleConfig.scale, csfConfig.csf);
							if (textures)
							{
								csfConfig.atlas = CTextureAtlas.createFromTextures(textures, csfConfig);
							}
						}
					}
					return;
					
				case CONTENT_DEFAULT:
					csfConfig = this._config.textureAtlas.contentScaleFactor;
					
					if (csfConfig == null)
					{
						return;
					}

					if (this._gafgfxData.createTextures(this.scale, this.contentScaleFactor, format))
					{
						csfConfig.atlas = CTextureAtlas.createFromTextures(this._gafgfxData.getTextures(this.scale, this.contentScaleFactor), csfConfig);
					}
					
					return;
				
				case CONTENT_SPECIFY:
					csfConfig = this.getCSFConfig(scale, csf);
					
					if (csfConfig == null)
					{
						return;
					}

					
					if (this._gafgfxData.createTextures(scale, csf, format))
					{
						csfConfig.atlas = CTextureAtlas.createFromTextures(this._gafgfxData.getTextures(scale, csf), csfConfig);
					}
					return;
			}
			
		}
		
		/**
		 * Unload all all graphical data connected with this asset from device GPU memory. Used in case of manual control of video memory usage
		 * 
		 * @param content - content type that should be loaded (CONTENT_ALL, CONTENT_DEFAULT, CONTENT_SPECIFY)
		 * @param scale - in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 * @param csf - in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 */
		public function unloadFromVideoMemory(content: String = CONTENT_DEFAULT, scale: Number = NaN, csf: Number = NaN): void
		{
			if (!this._config.textureAtlas || !this._config.textureAtlas.contentScaleFactor.elements)
			{
				return;
			}
			
			var csfConfig: CTextureAtlasCSF;
			
			switch(content)
			{
				case CONTENT_ALL:
					for each(var scaleConfig: CTextureAtlasScale in this._config.allTextureAtlases)
					{
						for each(csfConfig in scaleConfig.allContentScaleFactors)
						{
							this._gafgfxData.disposeTextures(scaleConfig.scale, csfConfig.csf);
							if (csfConfig.atlas)
								csfConfig.atlas.dispose();
							csfConfig.atlas = null;
						}
					}
					return;
				
				case CONTENT_DEFAULT:
					this._gafgfxData.disposeTextures(this.scale, this.contentScaleFactor);
					if (this._config.textureAtlas.contentScaleFactor.atlas)
					{
						this._config.textureAtlas.contentScaleFactor.atlas.dispose();
						this._config.textureAtlas.contentScaleFactor.atlas = null;
					}
					return;
				
				case CONTENT_SPECIFY:
					csfConfig = this.getCSFConfig(scale, csf);
					if(csfConfig)
					{
						this._gafgfxData.disposeTextures(scale, csf);
						if (csfConfig.atlas)
						{
						csfConfig.atlas.dispose();
						csfConfig.atlas = null;
					}
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
		 * Timeline identifier (name given at animation's upload or assigned by developer)
		 */
		public function get id(): String
		{
			return this.config.assetID;
		}
		
		public function set id(value: String): void
		{
			this.config.assetID = value;
		}

		/** @private
		 * Asset identifier (name given at animation's upload or assigned by developer)
		 */
		public function get assetID(): String
		{
			return this.config.assetID;
		}
		
		/** @private */
		gaf_internal function get uniqueID(): String
		{
			return this.gaf_internal::_uniqueID;
		}

		/** @private */
		gaf_internal function get uniqueLinkage(): String
		{
			return this.gaf_internal::_uniqueLinkage;
		}

		/** @private */
		public function get textureAtlas(): CTextureAtlas
		{
			if (!this._config.textureAtlas)
			{
				return null;
			}
			
			if (!this._config.textureAtlas.contentScaleFactor.atlas)
			{
				this.loadInVideoMemory(CONTENT_DEFAULT);
			}
			
			return this._config.textureAtlas.contentScaleFactor.atlas;
		}
		
		/** @private */
		public function get config(): GAFTimelineConfig
		{
			return _config;
		}
		
		////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Texture atlas scale that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different scale assign appropriate scale to <code>GAFTimeline</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
		public function set scale(scale: Number): void
		{
			if (!_config.textureAtlas)
			{
				return;
			}
			var csf: Number = this.contentScaleFactor;
			var taScale: CTextureAtlasScale = this._config.getTextureAtlasForScale(scale);
			if (taScale)
			{
				_config.textureAtlas = taScale;
				
				var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);
				
				if(taCSF)
				{
					_config.textureAtlas.contentScaleFactor = taCSF;
				}
				else
				{
					throw new Error("There is no csf " + csf + "in timeline config for scalse " + scale);
				}
			}
			else
			{
				throw new Error("There is no scale " + scale + "in timeline config");
			}
		}
		
		public function get scale(): Number
		{
			if (_config.textureAtlas)
			{
				return _config.textureAtlas.scale;
			}
			return 1;
		}
		
		/**
		 * Texture atlas content scale factor (csf) that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different csf assign appropriate csf to <code>GAFTimeline</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
		public function set contentScaleFactor(csf: Number): void
		{
			if (!_config.textureAtlas)
			{
				return;
			}
			
			var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);
			
			if(taCSF)
			{
				_config.textureAtlas.contentScaleFactor = taCSF;
			}
			else
			{
				throw new Error("There is no csf " + csf + "in timeline config");
			}
		}
		
		public function get contentScaleFactor(): Number
		{
			if (_config.textureAtlas)
			{
				return _config.textureAtlas.contentScaleFactor.csf;
			}
			return 1;
		}
		
		/**
		 * Graphical data storage that used by <code>GAFTimeline</code>.
		 */
		public function set gafgfxData(gafgfxData: GAFGFXData): void
		{
			_gafgfxData = gafgfxData;
		}
		
		public function get gafgfxData(): GAFGFXData
		{
			return _gafgfxData;
		}

		/** @private */
		public function get gafBundle(): GAFBundle
		{
			return _gafBundle;
		}

		/** @private */
		public function set gafBundle(gafBundle: GAFBundle): void
		{
			_gafBundle = gafBundle;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
