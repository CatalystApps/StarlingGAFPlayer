/**
 * Created by Nazar on 19.05.2014.
 */
package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CSoundData;
	import com.catalystapps.gaf.data.config.CStage;

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
		private var _stageConfig: CStage;

		private var _timelines: Vector.<GAFTimelineConfig>;
		private var _sounds: Vector.<CSoundData>;

		public function GAFAssetConfig(id: String)
		{
			this._id = id;
			this._scaleValues = new Vector.<Number>();
			this._csfValues = new Vector.<Number>();

			this._timelines = new Vector.<GAFTimelineConfig>();
		}

		public function addSound(soundData: CSoundData): void
		{
			this._sounds ||= new Vector.<CSoundData>();
			this._sounds.push(soundData);
		}

		public function dispose(): void
		{
			for each(var timeline: GAFTimelineConfig in this._timelines)
			{
				timeline.dispose();
			}
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

		public function get timelines(): Vector.<GAFTimelineConfig>
		{
			return this._timelines;
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

		public function get sounds(): Vector.<CSoundData>
		{
			return _sounds;
		}
	}
}
