package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.utils.VectorUtils;
	import com.catalystapps.gaf.utils.copyArray;

	/**
	 * @author p0d04Va
	 */
	public class CColorMatrixFilterData implements ICFilterData
	{
		public var matrix: Vector.<Number> = new Vector.<Number>(20, true);

		public function clone(): ICFilterData
		{
			var copy: CColorMatrixFilterData = new CColorMatrixFilterData();

			VectorUtils.copyMatrix(copy.matrix, this.matrix);

			return copy;
		}
	}
}
