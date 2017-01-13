package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.converters.ErrorConstants;
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CFrameSound;
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.display.IGAFTexture;
	import com.catalystapps.gaf.sound.GAFSoundData;
	import com.catalystapps.gaf.sound.GAFSoundManager;

	import flash.media.Sound;

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

		private var _config: GAFTimelineConfig;

		private var _gafSoundData: GAFSoundData;
		private var _gafgfxData: GAFGFXData;
		private var _gafAsset: GAFAsset;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates an GAFTimeline object
		 * @param timelineConfig GAF timeline config
		 */
		public function GAFTimeline(timelineConfig: GAFTimelineConfig)
		{
			this._config = timelineConfig;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		// --------------------------------------------------------------------------

		/**
		 * Returns GAF Texture by name of an instance inside a timeline.
		 * @param animationObjectName name of an instance inside a timeline
		 * @return GAF Texture
		 */
		public function getTextureByName(animationObjectName: String): IGAFTexture
		{
			var instanceID: String = this._config.getNamedPartID(animationObjectName);
			if (instanceID)
			{
				var part: CAnimationObject = this._config.animationObjects.getAnimationObject(instanceID);
				if (part)
				{
					return this.textureAtlas.getTexture(part.regionID);
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
			this._config = null;
			this._gafAsset = null;
			this._gafgfxData = null;
			this._gafSoundData = null;
		}

		/**
		 * Load all graphical data connected with this asset in device GPU memory. Used in case of manual control of GPU memory usage.
		 * Works only in case when all graphical data stored in RAM.
		 *
		 * @param content content type that should be loaded. Available types: <code>CONTENT_ALL, CONTENT_DEFAULT, CONTENT_SPECIFY</code>
		 * @param scale in case when specified content is <code>CONTENT_SPECIFY</code> scale and csf should be set in required values
		 * @param csf in case when specified content is <code>CONTENT_SPECIFY</code> scale and csf should be set in required values
		 */
		public function loadInVideoMemory(content: String = "contentDefault", scale: Number = NaN, csf: Number = NaN): void
		{
			if (!this._config.textureAtlas || !this._config.textureAtlas.contentScaleFactor.elements)
			{
				return;
			}

			var textures: Object;
			var csfConfig: CTextureAtlasCSF;

			switch (content)
			{
				case CONTENT_ALL:
					for each (var scaleConfig: CTextureAtlasScale in this._config.allTextureAtlases)
					{
						for each (csfConfig in scaleConfig.allContentScaleFactors)
						{
							this._gafgfxData.createTextures(scaleConfig.scale, csfConfig.csf);

							textures = this._gafgfxData.getTextures(scaleConfig.scale, csfConfig.csf);
							if (!csfConfig.atlas && textures)
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

					if (!csfConfig.atlas && this._gafgfxData.createTextures(this.scale, this.contentScaleFactor))
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

					if (!csfConfig.atlas && this._gafgfxData.createTextures(scale, csf))
					{
						csfConfig.atlas = CTextureAtlas.createFromTextures(this._gafgfxData.getTextures(scale, csf), csfConfig);
					}
					return;
			}
		}

		/**
		 * Unload all all graphical data connected with this asset from device GPU memory. Used in case of manual control of video memory usage
		 *
		 * @param content content type that should be loaded (CONTENT_ALL, CONTENT_DEFAULT, CONTENT_SPECIFY)
		 * @param scale in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 * @param csf in case when specified content is CONTENT_SPECIFY scale and csf should be set in required values
		 */
		public function unloadFromVideoMemory(content: String = "contentDefault", scale: Number = NaN, csf: Number = NaN): void
		{
			if (!this._config.textureAtlas || !this._config.textureAtlas.contentScaleFactor.elements)
			{
				return;
			}

			var csfConfig: CTextureAtlasCSF;

			switch (content)
			{
				case CONTENT_ALL:
					this._gafgfxData.disposeTextures();
					this._config.dispose();
					return;
				case CONTENT_DEFAULT:
					this._gafgfxData.disposeTextures(this.scale, this.contentScaleFactor);
					this._config.textureAtlas.contentScaleFactor.dispose();
					return;
				case CONTENT_SPECIFY:
					csfConfig = this.getCSFConfig(scale, csf);
					if (csfConfig)
					{
						this._gafgfxData.disposeTextures(scale, csf);
						csfConfig.dispose();
					}
					return;
			}
		}

		/** @private */
		public function startSound(frame: uint): void
		{
			var frameSoundConfig: CFrameSound = this._config.getSound(frame);
			if (frameSoundConfig)
			{
				use namespace gaf_internal;

				if (frameSoundConfig.action == CFrameSound.ACTION_STOP)
				{
					GAFSoundManager.getInstance().stop(frameSoundConfig.soundID, this._config.assetID);
				}
				else
				{
					var sound: Sound;
					if (frameSoundConfig.linkage)
					{
						sound = this.gafSoundData.getSoundByLinkage(frameSoundConfig.linkage);
					}
					else
					{
						sound = this.gafSoundData.getSound(frameSoundConfig.soundID, this._config.assetID);
					}
					var soundOptions: Object = {};
					soundOptions["continue"] = frameSoundConfig.action == CFrameSound.ACTION_CONTINUE;
					soundOptions["repeatCount"] = frameSoundConfig.repeatCount;
					GAFSoundManager.getInstance().play(sound, frameSoundConfig.soundID, soundOptions, this._config.assetID);
				}
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

			if (scaleConfig)
			{
				var csfConfig: CTextureAtlasCSF = scaleConfig.getTextureAtlasForCSF(csf);

				if (csfConfig)
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
			return this.config.id;
		}

		/**
		 * Timeline linkage in a *.fla file library
		 */
		public function get linkage(): String
		{
			return this.config.linkage;
		}

		/** @private
		 * Asset identifier (name given at animation's upload or assigned by developer)
		 */
		public function get assetID(): String
		{
			return this.config.assetID;
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
			return this._config;
		}

		////////////////////////////////////////////////////////////////////////////

		/**
		 * Texture atlas scale that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different scale assign appropriate scale to <code>GAFTimeline</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
		public function set scale(value: Number): void
		{
			var scale: Number = this._gafAsset.gaf_internal::getValidScale(value);
			if (isNaN(scale))
			{
				throw new Error(ErrorConstants.SCALE_NOT_FOUND);
			}
			else
			{
				this._gafAsset.scale = scale;
			}

			if (!this._config.textureAtlas)
			{
				return;
			}

			var csf: Number = this.contentScaleFactor;
			var taScale: CTextureAtlasScale = this._config.getTextureAtlasForScale(scale);
			if (taScale)
			{
				this._config.textureAtlas = taScale;

				var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);

				if (taCSF)
				{
					this._config.textureAtlas.contentScaleFactor = taCSF;
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
			return this._gafAsset.scale;
		}

		/**
		 * Texture atlas content scale factor (csf) that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different csf assign appropriate csf to <code>GAFTimeline</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
		public function set contentScaleFactor(csf: Number): void
		{
			if (this._gafAsset.gaf_internal::hasCSF(csf))
			{
				this._gafAsset.csf = csf;
			}

			if (!this._config.textureAtlas)
			{
				return;
			}

			var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);

			if (taCSF)
			{
				this._config.textureAtlas.contentScaleFactor = taCSF;
			}
			else
			{
				throw new Error("There is no csf " + csf + "in timeline config");
			}
		}

		public function get contentScaleFactor(): Number
		{
			return this._gafAsset.csf;
		}

		/**
		 * Graphical data storage that used by <code>GAFTimeline</code>.
		 */
		public function set gafgfxData(gafgfxData: GAFGFXData): void
		{
			this._gafgfxData = gafgfxData;
		}

		public function get gafgfxData(): GAFGFXData
		{
			return this._gafgfxData;
		}

		/** @private */
		public function get gafAsset(): GAFAsset
		{
			return this._gafAsset;
		}

		/** @private */
		public function set gafAsset(asset: GAFAsset): void
		{
			this._gafAsset = asset;
		}

		/** @private */
		public function get gafSoundData(): GAFSoundData
		{
			return this._gafSoundData;
		}

		/** @private */
		public function set gafSoundData(gafSoundData: GAFSoundData): void
		{
			this._gafSoundData = gafSoundData;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
