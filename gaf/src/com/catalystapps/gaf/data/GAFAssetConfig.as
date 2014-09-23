/**
 * Created by Nazar on 19.05.2014.
*/
package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CStage;

	/**
	 * @private
	 */
	public class GAFAssetConfig
	{
		public static const MAX_VERSION: uint = 4;
		
		private var _id: String;
		private var _compression: int;
		private var _versionMajor: uint;
		private var _versionMinor: uint;
		private var _fileLength: uint;
		private var _scaleValues: Vector.<Number>;
		private var _csfValues: Vector.<Number>;
		private var _stageConfig: CStage;

		private var _timelines: Vector.<GAFTimelineConfig>;

		public function GAFAssetConfig(id: String)
		{
			_id = id;
			_scaleValues = new Vector.<Number>();
			_csfValues = new Vector.<Number>();

			_timelines = new Vector.<GAFTimelineConfig>();
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
			return _compression;
		}

		public function set compression(value: int): void
		{
			_compression = value;
		}

		public function get versionMajor(): uint
		{
			return _versionMajor;
		}

		public function set versionMajor(value: uint): void
		{
			_versionMajor = value;
		}

		public function get versionMinor(): uint
		{
			return _versionMinor;
		}

		public function set versionMinor(value: uint): void
		{
			_versionMinor = value;
		}

		public function get fileLength(): uint
		{
			return _fileLength;
		}

		public function set fileLength(value: uint): void
		{
			_fileLength = value;
		}

		public function get scaleValues(): Vector.<Number>
		{
			return _scaleValues;
		}

		public function get csfValues(): Vector.<Number>
		{
			return _csfValues;
		}

		public function get timelines(): Vector.<GAFTimelineConfig>
		{
			return _timelines;
		}

		public function get stageConfig(): CStage
		{
			return _stageConfig;
		}

		public function set stageConfig(value: CStage): void
		{
			_stageConfig = value;
		}

		public function get id(): String
		{
			return _id;
		}
	}
}
