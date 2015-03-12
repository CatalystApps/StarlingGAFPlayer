package com.catalystapps.gaf.utils
{
	import flash.display.BitmapData;
	import flash.filters.BitmapFilter;
	import flash.geom.Rectangle;

	/** @private */
	public class DisplayUtility
	{
		public static function getBoundsWithFilters(maxRect: Rectangle, filters: Array): Rectangle
		{
			var filtersLen: uint = filters.length;
			if (filtersLen > 0)
			{
				var filterMinX: Number = 0;
				var filterMinY: Number = 0;
				var filterGeneratorRect: Rectangle = new Rectangle(0, 0, maxRect.width, maxRect.height);
				var bitmapData: BitmapData;
				for (var i: int = 0; i < filtersLen; i++)
				{
					//bitmapData = new BitmapData(filterGeneratorRect.width, filterGeneratorRect.height, true, 0x00000000);
					bitmapData = new BitmapData(1, 1, false, 0x00000000);
					var filter: BitmapFilter = filters[i];
					var filterRect: Rectangle = bitmapData.generateFilterRect(filterGeneratorRect, filter);
					filterRect.width += filterGeneratorRect.width - 1;
					filterRect.height += filterGeneratorRect.height - 1;

					filterMinX += filterRect.x;
					filterMinY += filterRect.y;

					filterGeneratorRect = filterRect.clone();
					filterGeneratorRect.x = 0;
					filterGeneratorRect.y = 0;

					bitmapData.dispose();
				}
				// Reposition filterRect back to global coordinates
				filterRect.x = maxRect.x + filterMinX;
				filterRect.y = maxRect.y + filterMinY;

				maxRect = filterRect.clone();
			}

			return maxRect;
		}
	}
}
