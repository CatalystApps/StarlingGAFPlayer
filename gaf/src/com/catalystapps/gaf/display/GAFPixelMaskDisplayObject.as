/**
 * Created by Nazar on 03.03.2015.
 */
package com.catalystapps.gaf.display
{
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;

	public class GAFPixelMaskDisplayObject extends DisplayObjectContainer
	{

		public function GAFPixelMaskDisplayObject()
		{
			super();
		}

		override public function set mask(value: DisplayObject): void
		{
			if (mask && mask is IGAFPixelMask)
			{
				(mask as IGAFPixelMask).isMask = false;
			}

			super.mask = value;

			if (value && value is IGAFPixelMask)
			{
				(value as IGAFPixelMask).isMask = true;
			}
		}
	}
}
