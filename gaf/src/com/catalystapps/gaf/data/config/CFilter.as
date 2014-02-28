package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.data.converters.WarningConstants;
	import com.catalystapps.gaf.utils.copyArray;
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
			if (getBlurFilter())
			{
				return WarningConstants.CANT_STACK_BLUR_FILTERS;
			}
			
			var filterData: CBlurFilterData = new CBlurFilterData();
			filterData.blurX = blurX;
			filterData.blurY = blurY;
			filterData.color = -1;
			
			_filterConfigs.push(filterData);
			
			return "";
		}
		
		public function addGlowFilter(blurX: Number, blurY: Number, color: uint, alpha: Number): String
		{
			if (getBlurFilter())
			{
				return WarningConstants.CANT_BLUR_GLOW;
			}
			
			if (getColorMatrixFilter())
			{
				return WarningConstants.CANT_CT_GLOW;
			}
			
			var filterData: CBlurFilterData = new CBlurFilterData();
			filterData.blurX = blurX;
			filterData.blurY = blurY;
			filterData.color = color;
			filterData.alpha = alpha;
			
			_filterConfigs.push(filterData);
			
			return "";
		}
		
		public function addDropShadowFilter(blurX: Number, blurY: Number, color: uint, alpha: Number, angle: Number, distance: Number): String
		{
			if (getBlurFilter())
			{
				return WarningConstants.CANT_BLUR_DROP;
			}
			
			if (getColorMatrixFilter())
			{
				return WarningConstants.CANT_CT_DROP;
			}
			
			var filterData: CBlurFilterData = new CBlurFilterData();
			filterData.blurX = blurX;
			filterData.blurY = blurY;
			filterData.color = color;
			filterData.alpha = alpha;
			filterData.angle = angle;
			filterData.distance = distance;
			
			_filterConfigs.push(filterData);
			
			return "";
		}
		
		public function addColorTransform(params: Array): void
		{
			if (getColorMatrixFilter())
			{
				return;				
			}
			
			var filterData: CColorMatrixFilterData = new CColorMatrixFilterData();
			filterData.matrix.push(Number(params[1]), 0, 0, 0, Number(params[2]),
								   0, Number(params[3]), 0, 0, Number(params[4]),
								   0, 0, Number(params[5]), 0, Number(params[6]),
								   0, 0, 0, 1, Number(params[0]));	
			
			_filterConfigs.push(filterData);
		}
		
		public function addColorMatrixFilter(params: Array): String
		{
			var i: uint;
			
			for (i = 0; i < params.length; i++)
			{
				if (i % 5 == 4)
				{
					params[i] = params[i] / 255;
				}								
			}
			
			var colorMatrixFilterConfig: CColorMatrixFilterData = getColorMatrixFilter();			
			
			if (colorMatrixFilterConfig)
			{
				i = 0;
				
				var tmpMatrix: Array = [];
				
	            for (var y:int=0; y<4; ++y)
	            {
	                for (var x:int=0; x<5; ++x)
	                {
	                    tmpMatrix[int(i+x)] = 
	                        colorMatrixFilterConfig.matrix[i]        * params[x]           +
	                        colorMatrixFilterConfig.matrix[int(i+1)] * params[int(x +  5)] +
	                        colorMatrixFilterConfig.matrix[int(i+2)] * params[int(x + 10)] +
	                        colorMatrixFilterConfig.matrix[int(i+3)] * params[int(x + 15)] +
	                        (x == 4 ? colorMatrixFilterConfig.matrix[int(i+4)] : 0);
	                }
	                
	                i+=5;
	            }
				
				colorMatrixFilterConfig.matrix = [];
				copyArray(tmpMatrix, colorMatrixFilterConfig.matrix);
			}
			else
			{
				colorMatrixFilterConfig = new CColorMatrixFilterData();
				copyArray(params, colorMatrixFilterConfig.matrix);
				_filterConfigs.push(colorMatrixFilterConfig); 
			}
			
			return "";
		}		

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
		private function getBlurFilter(): CBlurFilterData
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
		
		public function get filterConfigs() : Vector.<ICFilterData>
		{
			return _filterConfigs;
		}
		
	}
}
