package com.catalystapps.gaf.display
{
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	/**
	 * @private
	 */
	public class GAFPixelMaskDisplayObject extends PixelMaskDisplayObject implements IGAFDisplayObject
	{
		private var _zIndex: uint;
		public var mustReorder: Boolean;

		public function get zIndex(): uint
		{
			return _zIndex;
		}

		public function set zIndex(value: uint): void
		{
			_zIndex = value;
		}
	}
}
