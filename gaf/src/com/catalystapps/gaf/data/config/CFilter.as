package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.utils.VectorUtility;

	/**
	 * @private
	 */
	public class CFilter
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private var _filterConfigs: Vector.<ICFilterData> = new Vector.<ICFilterData>();

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function clone(): CFilter
		{
			var result: CFilter = new CFilter();

			for each (var filterData: ICFilterData in _filterConfigs)
			{
				result.filterConfigs.push(filterData.clone());
			}

			return result;
		}

		public function addBlurFilter(blurX: Number, blurY: Number): String
		{
			var filterData: CBlurFilterData = new CBlurFilterData();
			filterData.blurX = blurX;
			filterData.blurY = blurY;
			filterData.color = -1;

			_filterConfigs.push(filterData);

			return "";
		}

		public function addGlowFilter(blurX: Number, blurY: Number, color: uint, alpha: Number,
									  strength: Number = 1, inner: Boolean = false, knockout: Boolean = false): String
		{
			var filterData: CBlurFilterData = new CBlurFilterData();
			filterData.blurX = blurX;
			filterData.blurY = blurY;
			filterData.color = color;
			filterData.alpha = alpha;
			filterData.strength = strength;
			filterData.inner = inner;
			filterData.knockout = knockout;

			_filterConfigs.push(filterData);

			return "";
		}

		public function addDropShadowFilter(blurX: Number, blurY: Number, color: uint, alpha: Number, angle: Number, distance: Number,
											strength: Number = 1, inner: Boolean = false, knockout: Boolean = false): String
		{
			var filterData: CBlurFilterData = new CBlurFilterData();
			filterData.blurX = blurX;
			filterData.blurY = blurY;
			filterData.color = color;
			filterData.alpha = alpha;
			filterData.angle = angle;
			filterData.distance = distance;
			filterData.strength = strength;
			filterData.inner = inner;
			filterData.knockout = knockout;

			_filterConfigs.push(filterData);

			return "";
		}

		public function addColorTransform(params: Vector.<Number>): void
		{
			if (getColorMatrixFilter())
			{
				return;
			}

			var filterData: CColorMatrixFilterData = new CColorMatrixFilterData();
			VectorUtility.fillMatrix(filterData.matrix,
					Number(params[1]), 0, 0, 0, Number(params[2]),
					0, Number(params[3]), 0, 0, Number(params[4]),
					0, 0, Number(params[5]), 0, Number(params[6]),
								   0, 0, 0, 1, 0);
			_filterConfigs.push(filterData);
		}

		public function addColorMatrixFilter(params: Vector.<Number>): String
		{
			var i: uint;

			for (i = 0; i < params.length; i++)
			{
				if (i % 5 == 4)
				{
					params[i] = params[i] / 255;
				}
			}

//			var colorMatrixFilterConfig: CColorMatrixFilterData = getColorMatrixFilter();
//
//			if (colorMatrixFilterConfig)
//			{
//				return WarningConstants.CANT_COLOR_ADJ_CT;
//			}
//			else
//			{
				var colorMatrixFilterConfig: CColorMatrixFilterData = new CColorMatrixFilterData();
				VectorUtility.copyMatrix(colorMatrixFilterConfig.matrix, params);
				_filterConfigs.push(colorMatrixFilterConfig);
//			}

			return "";
		}

		public function getBlurFilter(): CBlurFilterData
		{
			for each (var filterConfig: ICFilterData in _filterConfigs)
			{
				if (filterConfig is CBlurFilterData)
				{
					return filterConfig as CBlurFilterData;
				}
			}

			return null;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function getColorMatrixFilter(): CColorMatrixFilterData
		{
			for each (var filterConfig: ICFilterData in _filterConfigs)
			{
				if (filterConfig is CColorMatrixFilterData)
				{
					return filterConfig as CColorMatrixFilterData;
				}
			}

			return null;
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		public function get filterConfigs(): Vector.<ICFilterData>
		{
			return this._filterConfigs;
		}

	}
}
