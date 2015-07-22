/**
 * Created by Nazar on 19.05.2014.
 */
package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CSound;
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;

	/**
	 * @private
	 */
	public class GAFAssetConfig
	{
		public static const MAX_VERSION: uint = 5;

		private var _id: String;
		private var _compression: int;
		private var _versionMajor: uint;
		private var _versionMinor: uint;
		private var _fileLength: uint;
		private var _scaleValues: Vector.<Number>;
		private var _csfValues: Vector.<Number>;
		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;

		private var _stageConfig: CStage;

		private var _timelines: Vector.<GAFTimelineConfig>;
		private var _allTextureAtlases: Vector.<CTextureAtlasScale>;
		private var _sounds: Vector.<CSound>;

		public function GAFAssetConfig(id: String)
		{
			this._id = id;
			this._scaleValues = new Vector.<Number>();
			this._csfValues = new Vector.<Number>();

			this._timelines = new Vector.<GAFTimelineConfig>();
			this._allTextureAtlases = new Vector.<CTextureAtlasScale>();
		}

		public function addSound(soundData: CSound): void
		{
			this._sounds ||= new Vector.<CSound>();
			this._sounds.push(soundData);
		}

		public function dispose(): void
		{
			this._allTextureAtlases = null;
			this._stageConfig = null;
			this._scaleValues = null;
			this._csfValues = null;
			this._timelines = null;
			this._sounds = null;
		}

		public function get compression(): int
		{
			return this._compression;
		}

		public function set compression(value: int): void
		{
			this._compression = value;
		}

		public function get versionMajor(): uint
		{
			return this._versionMajor;
		}

		public function set versionMajor(value: uint): void
		{
			this._versionMajor = value;
		}

		public function get versionMinor(): uint
		{
			return this._versionMinor;
		}

		public function set versionMinor(value: uint): void
		{
			this._versionMinor = value;
		}

		public function get fileLength(): uint
		{
			return this._fileLength;
		}

		public function set fileLength(value: uint): void
		{
			this._fileLength = value;
		}

		public function get scaleValues(): Vector.<Number>
		{
			return this._scaleValues;
		}

		public function get csfValues(): Vector.<Number>
		{
			return this._csfValues;
		}

		public function get defaultScale(): Number
		{
			return this._defaultScale;
		}

		public function set defaultScale(value: Number): void
		{
			this._defaultScale = value;
		}

		public function get defaultContentScaleFactor(): Number
		{
			return this._defaultContentScaleFactor;
		}

		public function set defaultContentScaleFactor(value: Number): void
		{
			this._defaultContentScaleFactor = value;
		}

		public function get timelines(): Vector.<GAFTimelineConfig>
		{
			return this._timelines;
		}

		public function get allTextureAtlases(): Vector.<CTextureAtlasScale>
		{
			return this._allTextureAtlases;
		}

		public function get stageConfig(): CStage
		{
			return this._stageConfig;
		}

		public function set stageConfig(value: CStage): void
		{
			this._stageConfig = value;
		}

		public function get id(): String
		{
			return this._id;
		}

		public function get sounds(): Vector.<CSound>
		{
			return this._sounds;
		}
	}
}
