package com.catalystapps.gaf.data.config
{
	/**
	 * @author p0d04Va
	 */
	public class CBlurFilterData implements ICFilterData
	{
		public var blurX: Number;
		public var blurY: Number;
		public var color: int;
		public var angle: Number = 0;
		public var distance: Number = 0;
		public var strength: Number = 0;
		public var alpha: Number = 1;
		public var inner: Boolean;
		public var knockout: Boolean;
		
		public function clone(): ICFilterData
		{
			var copy: CBlurFilterData = new CBlurFilterData();
			
			for (var prop: String in this)
			{
				copy[prop] = this[prop];
			}
			
			return copy;
		}
	}
}