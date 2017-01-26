/**
 * Created by Roman Lipovskiy on 26.01.2017.
 */
package com.catalystapps.gaf.filter
{
    import com.catalystapps.gaf.data.config.CBlurFilterData;
    import com.catalystapps.gaf.data.config.CColorMatrixFilterData;
    import com.catalystapps.gaf.data.config.CFilter;
    import com.catalystapps.gaf.data.config.ICFilterData;

    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.filters.DropShadowFilter;

    import starling.filters.FilterChain;

    public class GAFFilterChain extends FilterChain {

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
        private var _filterData:CFilter = null;

        //--------------------------------------------------------------------------
        //
        //  CONSTRUCTOR
        //
        //--------------------------------------------------------------------------
        public function GAFFilterChain()
        {
            super();
        }

        //--------------------------------------------------------------------------
        //
        //  PUBLIC METHODS
        //
        //--------------------------------------------------------------------------
        public function setFilterData(filterData:CFilter):void
        {
            _filterData = filterData;

            createFiltersChain();
        }

        //--------------------------------------------------------------------------
        //
        //  PRIVATE METHODS
        //
        //--------------------------------------------------------------------------
        private function createFiltersChain():void
        {
            var currentFilterConfig:ICFilterData;

            var blurFilter:BlurFilter;
            var dropShadowFilter:DropShadowFilter;
            var colorMatrixFilter:ColorMatrixFilter;

            for (var i:uint = 0; i < _filterData.filterConfigs.length; i++)
            {
                currentFilterConfig = _filterData.filterConfigs[i];

                if (currentFilterConfig is CBlurFilterData)
                {
                    if((currentFilterConfig as CBlurFilterData).distance != 0)
                    {
                        dropShadowFilter = new DropShadowFilter();
                        dropShadowFilter.distance = (currentFilterConfig as CBlurFilterData).distance;
                        dropShadowFilter.angle = (currentFilterConfig as CBlurFilterData).angle;
                        dropShadowFilter.color = (currentFilterConfig as CBlurFilterData).color;
                        dropShadowFilter.alpha = (currentFilterConfig as CBlurFilterData).strength;
                        dropShadowFilter.blur = (currentFilterConfig as CBlurFilterData).blurX;

                        addFilter(dropShadowFilter);
                    }
                    else
                    {
                        blurFilter = new BlurFilter();
                        blurFilter.blurX = (currentFilterConfig as CBlurFilterData).blurX;
                        blurFilter.blurY = (currentFilterConfig as CBlurFilterData).blurY;

                        addFilter(blurFilter);
                    }
                }
                else if (currentFilterConfig is CColorMatrixFilterData)
                {
                    colorMatrixFilter = new ColorMatrixFilter();
                    colorMatrixFilter.matrix = (currentFilterConfig as CColorMatrixFilterData).matrix;

                    addFilter(colorMatrixFilter);
                }
            }
        }

        //--------------------------------------------------------------------------
        //
        // OVERRIDDEN METHODS
        //
        //--------------------------------------------------------------------------
        override public function dispose():void
        {
            super.dispose();
        }

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
    }
}
