/**
 * Created by Nazar on 21.03.2014.
 */
package com.catalystapps.gaf.data
{
	public class GAFTimelineConfigs
	{
		private var _configs: Vector.<GAFTimelineConfig>;

		public function GAFTimelineConfigs()
		{
			this._configs = new Vector.<GAFTimelineConfig>();
		}

		public function get configs(): Vector.<GAFTimelineConfig>
		{
			return this._configs;
		}
	}
}
