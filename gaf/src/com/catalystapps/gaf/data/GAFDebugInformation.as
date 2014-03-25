package com.catalystapps.gaf.data
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author p0d04Va
	 */
	public class GAFDebugInformation
	{
		public static const TYPE_POINT: uint = 0;
		public static const TYPE_RECT: uint = 1;

		public var type: uint;
		public var point: Point;
		public var rect: Rectangle;
		public var color: uint;
		public var alpha: Number;
	}
}
