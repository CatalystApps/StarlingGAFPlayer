/**
 * Created by Roman Lipovskiy on 18.01.2017.
 */
package
{
    import com.catalystapps.gaf.data.GAFTimeline;
import com.catalystapps.gaf.display.GAFImage;
import com.catalystapps.gaf.display.GAFMovieClip;
import com.catalystapps.gaf.display.IGAFImage;

import flash.geom.Rectangle;

    public dynamic class SliceScale extends GAFMovieClip
    {
        public static const SLICE_9_GRID_SCALE:uint = 9;
        public static const SLICE_3_GRID_SCALE:uint = 3;

        private var _slice9ScaleBtn:GAFImage;
        private var _slice3ScaleBtn:GAFImage;

        public function SliceScale(gafTimeline: GAFTimeline):void
        {
            super(gafTimeline);
            play(true);

            _slice3ScaleBtn = this.slice_3_btn;
            _slice9ScaleBtn = this.slice_9_btn;

            correctPivotAndPosition(_slice3ScaleBtn);
            correctPivotAndPosition(_slice9ScaleBtn);
        }

        /**
         * scale by sliced grid texture by modifier.
         * @param modifier
        */
        public function sliceScaleByModifier(modifier:uint):void
        {
           switch (modifier)
           {
               case SLICE_3_GRID_SCALE:
                   _slice3ScaleBtn.scale9Grid = new Rectangle(20,0,20,20);
                   _slice3ScaleBtn.scaleX = 2;
                   break;
               case SLICE_9_GRID_SCALE:
                   _slice9ScaleBtn.scale9Grid = new Rectangle(15,15,15,15);;
                   _slice9ScaleBtn.scaleX = 2.5;
                   _slice9ScaleBtn.scaleY = 2;
                   break;
           }
        }

        private function correctPivotAndPosition(img:GAFImage):void
        {
            img.pivotX = img.width / 2;
            img.pivotY = img.height / 2;
            img.x += img.width / 2;
            img.y += img.height / 2;
        }

        public function get slice9ScaleBtn():GAFImage
        {
            return _slice9ScaleBtn;
        }

        public function get slice3ScaleBtn():GAFImage
        {
            return _slice3ScaleBtn;
        }
    }
}