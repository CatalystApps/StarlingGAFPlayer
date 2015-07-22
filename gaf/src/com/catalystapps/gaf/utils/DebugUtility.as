/**
 * Created by Nazar on 18.03.2014.
 */
package com.catalystapps.gaf.utils
{
	import com.catalystapps.gaf.data.GAF;
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;

	/**
	 * @private
	 */
	public class DebugUtility
	{
		public static var RENDERING_DEBUG: Boolean = false;

		public static const RENDERING_NEUTRAL_COLOR: uint = 0xCCCCCCCC;
		public static const RENDERING_FILTER_COLOR: uint = 0xFF00FFFF;
		public static const RENDERING_MASK_COLOR: uint = 0xFFFF0000;
		public static const RENDERING_ALPHA_COLOR: uint = 0xFFFFFF00;

		private static const cHR: Vector.<uint> = new <uint>[255, 255, 0, 0, 0, 255, 255];
		private static const cHG: Vector.<uint> = new <uint>[0, 255, 255, 255, 0, 0, 0];
		private static const cHB: Vector.<uint> = new <uint>[0, 0, 0, 255, 255, 255, 0];

		private static const aryRGB: Vector.<Vector.<uint>> = new <Vector.<uint>>[cHR, cHG, cHB];

		public static function getRenderingDifficultyColor(instance: CAnimationFrameInstance,
		                                                   alphaLess1: Boolean = false, masked: Boolean = false,
		                                                   hasFilter: Boolean = false): Vector.<uint>
		{
			var colors: Vector.<uint> = new <uint>[];
			if (instance.maskID || masked)
			{
				colors.push(RENDERING_MASK_COLOR);
			}
			if (instance.filter || hasFilter)
			{
				colors.push(RENDERING_FILTER_COLOR);
			}
			if (instance.alpha < GAF.gaf_internal::maxAlpha || alphaLess1)
			{
				colors.push(RENDERING_ALPHA_COLOR);
			}
			if (colors.length == 0)
			{
				colors.push(RENDERING_NEUTRAL_COLOR);
			}

			return colors;
		}

		/**
		 * Returns color that objects would be painted
		 * @param difficulty value from 0 to 255
		 * @return color in ARGB format (from green to red)
		 */
		private static function getColor(difficulty: uint): uint
		{
			if (difficulty > 255)
			{
				difficulty = 255;
			}

			var colorArr: Vector.<uint> = getRGB(120 - 120 / (255 / difficulty));

			var color: uint = (((difficulty >> 1) + 0x7F) << 24) | colorArr[0] << 16 | colorArr[1] << 8;

			return color;
		}

		// return RGB color from hue circle rotation
		// [0]=R, [1]=G, [2]=B
		private static function getRGB(rot: int): Vector.<uint>
		{
			var retVal: Vector.<uint> = new <uint>[];
			var aryNum: uint;
			// 0 ~ 360
			while (rot < 0 || rot > 360)
			{
				rot += (rot < 0) ? 360 : -360;
			}
			aryNum = Math.floor(rot / 60);
			// get color
			retVal = getH(rot, aryNum);
			return retVal;
		}

		// rotation　=> hue
		private static function getH(rot: uint, aryNum: uint): Vector.<uint>
		{
			var retVal: Vector.<uint> = new <uint>[0, 0, 0];
			var nextNum: uint = aryNum + 1;
			for (var i: int = 0; i < 3; i++)
			{
				retVal[i] = getHP(aryRGB[i], rot, aryNum, nextNum);
			}
			return retVal;
		}

		private static function getHP(_P: Vector.<uint>, rot: uint, aryNum: uint, nextNum: uint): uint
		{
			var retVal: uint;
			var aryC: uint;
			var nextC: uint;
			var rH: int;
			var rotR: Number;
			aryC = _P[aryNum];
			nextC = _P[nextNum];
			rotR = (aryC + nextC) / 60 * (rot - 60 * aryNum);
			rH = (_P[nextNum] == 0) ? aryC - rotR : aryC + rotR;
			retVal = Math.round(Math.min(255, Math.abs(rH)));
			return retVal;
		}

		public static function getObjectMemoryHash(obj: *): String
		{
			var memoryHash: String;

			try
			{
				FakeClass(obj);
			}
			catch (e: Error)
			{
				memoryHash = String(e).replace(/.*([@|\$].*?) to .*$/gi, '$1');
			}

			return memoryHash;
		}
	}
}

internal final class FakeClass
{
}
