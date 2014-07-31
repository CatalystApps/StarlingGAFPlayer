package com.catalystapps.gaf.data.config
{
	/**
	 * @private
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
			
			copy.blurX = this.blurX;
			copy.blurY = this.blurY;
			copy.color = this.color;
			copy.angle = this.angle;
			copy.distance = this.distance;
			copy.strength = this.strength;
			copy.alpha = this.alpha;
			copy.inner = this.inner;
			copy.knockout = this.knockout;
			
			return copy;
		}

	}
}