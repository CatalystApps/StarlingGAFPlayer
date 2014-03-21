/**
 * Created by Nazar on 21.03.2014.
 */
package com.catalystapps.gaf.data
{
	public class GAFAssetConfigs
	{
		private var _linkages: Object;
		private var _configs: Vector.<GAFAssetConfig>;

		public function GAFAssetConfigs()
		{
			this._configs = new <GAFAssetConfig>[];
			this._linkages = {};
		}

		public function get configs(): Vector.<GAFAssetConfig>
		{
			return this._configs;
		}

		public function get linkages(): Object
		{
			return this._linkages;
		}
	}
}
