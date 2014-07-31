/**
 * Created by Nazar on 22.04.2014.
 */
package com.catalystapps.gaf.utils
{
	/**
	 * @private
	 */
	public class VectorUtility
	{
		[Inline]
		public static function fillMatrix(v: Vector.<Number>,
				a00: Number, a01: Number, a02: Number, a03: Number, a04: Number,
				a10: Number, a11: Number, a12: Number, a13: Number, a14: Number,
				a20: Number, a21: Number, a22: Number, a23: Number, a24: Number,
				a30: Number, a31: Number, a32: Number, a33: Number, a34: Number): void
		{
			v[0] = a00;  v[1] = a01;  v[2] = a02;  v[3] = a03;  v[4] = a04;
			v[5] = a10;  v[6] = a11;  v[7] = a12;  v[8] = a13;  v[9] = a14;
			v[10] = a20; v[11] = a21; v[12] = a22; v[13] = a23; v[14] = a24;
			v[15] = a30; v[16] = a31; v[17] = a32; v[18] = a33; v[19] = a34;
		}

		[Inline]
		public static function copyMatrix(source: Vector.<Number>, dest: Vector.<Number>): void
		{
			var l: int = dest.length;
			for (var i: int = 0; i < l; i++)
			{
				source[i] = dest[i];
			}
		}
	}
}
