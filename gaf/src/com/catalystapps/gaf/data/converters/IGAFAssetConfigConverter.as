package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.GAFAssetConfig;

	import flash.events.IEventDispatcher;
	/**
	 * @author Programmer
	 */
	public interface IGAFAssetConfigConverter extends IEventDispatcher
	{
		function convert(): void;
		function get config(): GAFAssetConfig;
	}
}
