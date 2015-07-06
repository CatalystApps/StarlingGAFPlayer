package com.catalystapps.gaf.utils
{
	/**
	 * @private
	 */
	public class MathUtility
	{
		public static const epsilon: Number = 0.00001;

		public static const PI_Q:Number = Math.PI / 4.0;

		[Inline]
		public static function equals(a: Number, b: Number): Boolean
		{
			if (isNaN(a) || isNaN(b))
			{
				return false;
			}
			return Math.abs(a - b) < epsilon;
		}
	}
}
