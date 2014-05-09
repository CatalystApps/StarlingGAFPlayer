package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CAnimationFrames;
	import com.catalystapps.gaf.data.config.CAnimationObjects;
	import com.catalystapps.gaf.data.config.CAnimationSequences;
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextFieldObjects;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;

	/**
	 * @private
	 */
	public class GAFAssetConfig
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
		private var _version: String;
		private var _stageConfig: CStage;

		private var _id: String;

		private var _allTextureAtlases: Vector.<CTextureAtlasScale>;
		private var _textureAtlas: CTextureAtlasScale;

		private var _animationConfigFrames: CAnimationFrames;
		private var _animationObjects: CAnimationObjects;
		private var _animationSequences: CAnimationSequences;
		private var _textFields: CTextFieldObjects;

		private var _namedParts: Object;

		private var _debugRegions: Vector.<GAFDebugInformation>;

		private var _warnings: Vector.<String>;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function GAFAssetConfig(version: String)
		{
			this._version = version;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function dispose(): void
		{
			for each(var cTextureAtlasScale: CTextureAtlasScale in this._allTextureAtlases)
			{
				cTextureAtlasScale.dispose();
			}
		}

		public function getTextureAtlasForScale(scale: Number): CTextureAtlasScale
		{
			for each(var cTextureAtlas: CTextureAtlasScale in this._allTextureAtlases)
			{
				if (cTextureAtlas.scale == scale)
				{
					return cTextureAtlas;
				}
			}

			return null;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		public function addWarning(text: String): void
		{
			if (!text)
			{
				return;
			}

			if (!this._warnings)
			{
				this._warnings = new Vector.<String>();
			}

			if (this._warnings.indexOf(text) == -1)
			{
				trace(text);
				this._warnings.push(text);
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

		public function get textureAtlas(): CTextureAtlasScale
		{
			return this._textureAtlas;
		}

		public function set textureAtlas(textureAtlas: CTextureAtlasScale): void
		{
			this._textureAtlas = textureAtlas;
		}

		public function get animationObjects(): CAnimationObjects
		{
			return this._animationObjects;
		}

		public function set animationObjects(animationObjects: CAnimationObjects): void
		{
			this._animationObjects = animationObjects;
		}

		public function get animationConfigFrames(): CAnimationFrames
		{
			return this._animationConfigFrames;
		}

		public function set animationConfigFrames(animationConfigFrames: CAnimationFrames): void
		{
			this._animationConfigFrames = animationConfigFrames;
		}

		public function get animationSequences(): CAnimationSequences
		{
			return this._animationSequences;
		}

		public function set animationSequences(animationSequences: CAnimationSequences): void
		{
			this._animationSequences = animationSequences;
		}

		public function get textFields(): CTextFieldObjects
		{
			return this._textFields;
		}

		public function set textFields(textFields: CTextFieldObjects): void
		{
			this._textFields = textFields;
		}

		public function get allTextureAtlases(): Vector.<CTextureAtlasScale>
		{
			return this._allTextureAtlases;
		}

		public function set allTextureAtlases(allTextureAtlases: Vector.<CTextureAtlasScale>): void
		{
			this._allTextureAtlases = allTextureAtlases;
		}

		public function get version(): String
		{
			return this._version;
		}

		public function get debugRegions(): Vector.<GAFDebugInformation>
		{
			return this._debugRegions;
		}

		public function set debugRegions(debugRegions: Vector.<GAFDebugInformation>): void
		{
			this._debugRegions = debugRegions;
		}

		public function get warnings(): Vector.<String>
		{
			return this._warnings;
		}

		public function get id(): String
		{
			return this._id;
		}

		public function set id(value: String): void
		{
			this._id = value;
		}

		public function get namedParts(): Object
		{
			return this._namedParts;
		}

		public function set namedParts(value: Object): void
		{
			this._namedParts = value;
		}

		public function get stageConfig(): CStage
		{
			return _stageConfig;
		}

		public function set stageConfig(stageConfig: CStage): void
		{
			_stageConfig = stageConfig;
		}
	}
}
