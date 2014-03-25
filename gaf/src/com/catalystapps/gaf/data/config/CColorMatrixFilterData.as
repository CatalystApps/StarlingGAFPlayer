package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.utils.copyArray;

	/**
	 * @author p0d04Va
	 */
	public class CColorMatrixFilterData implements ICFilterData
	{
		public var matrix: Array = [];

		public function clone(): ICFilterData
		{
			var copy: CColorMatrixFilterData = new CColorMatrixFilterData();

			copyArray(this.matrix, copy.matrix);

			return copy;
		}
	}
}
