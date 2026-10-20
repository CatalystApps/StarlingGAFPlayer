package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.utils.VectorUtility;

	/**
	 * @private
	 */
	public class CColorMatrixFilterData implements ICFilterData
	{
		public var matrix: Vector.<Number> = new Vector.<Number>(20, true);
		// true for the state color transform (Tint), false for an Adjust Color filter
		public var isColorTransform: Boolean;

		public function clone(): ICFilterData
		{
			var copy: CColorMatrixFilterData = new CColorMatrixFilterData();

			VectorUtility.copyMatrix(copy.matrix, this.matrix);
			copy.isColorTransform = this.isColorTransform;

			return copy;
		}
	}
}
