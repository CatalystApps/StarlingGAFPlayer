package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.GAFAssetConfig;

	import flash.events.IEventDispatcher;
	/**
	 * @private
	 */
	public interface IGAFAssetConfigConverter extends IEventDispatcher
	{
		function convert(async: Boolean = false): void;
		function get config(): GAFAssetConfig;
		function set ignoreSounds(ignoreSounds: Boolean): void;
	}
}
