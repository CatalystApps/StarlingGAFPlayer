package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.data.config.CFilter;

	import starling.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	/**
	 * @private
	 */
	public interface IGAFDisplayObject
	{
		function setFilterConfig(value: CFilter, scale: Number = 1): void;
		function invalidateOrientation(): void;
		function dispose(): void;

		function get alpha(): Number;
		function set alpha(value: Number): void;

		function get parent(): DisplayObjectContainer;

//		function get smoothing(): String;
//		function set smoothing(value: String): void;

		function get visible(): Boolean;
		function set visible(value: Boolean): void;

		function get transformationMatrix(): Matrix;
		function set transformationMatrix(matrix: Matrix): void;

		function get pivotMatrix(): Matrix;

		function get name(): String;
		function set name(value: String): void;
	}
}
