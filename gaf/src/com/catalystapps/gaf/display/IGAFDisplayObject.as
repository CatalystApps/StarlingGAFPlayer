package com.catalystapps.gaf.display
{
	import starling.display.DisplayObjectContainer;
	import starling.filters.FragmentFilter;
	import flash.geom.Matrix;
	/**
	 * @private
	 */
	public interface IGAFDisplayObject
	{
		function get alpha(): Number;
		function set alpha(value: Number): void;
		
		function get filter(): FragmentFilter;
		function set filter(value: FragmentFilter): void;
		
		function get parent(): DisplayObjectContainer;
		
//		function get smoothing(): String;
//		function set smoothing(value: String): void;
		
		function get visible(): Boolean;
		function set visible(value: Boolean): void;
		
		function get zIndex(): uint;
		function set zIndex(zIndex: uint): void;
		
		function get transformationMatrix(): Matrix;
		function set transformationMatrix(matrix: Matrix): void;
		
		function dispose(): void;
	}
}
