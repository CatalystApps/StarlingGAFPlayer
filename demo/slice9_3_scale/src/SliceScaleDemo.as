/**
 * Created by Roman Lipovskiy on 18.01.2017.
 */
package
{
    import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
import com.catalystapps.gaf.data.GAFTimeline;

import flash.display.Sprite;

import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.utils.ByteArray;

    import starling.display.Sprite;
import starling.events.TouchEvent;
import starling.events.TouchPhase;

public class SliceScaleDemo extends Sprite
    {
        [Embed(source="../design/slice9_3_scale.zip", mimeType="application/octet-stream")]
        private const SliceMaskZIP: Class;

        private var _scaleDemo:SliceScale;

        public function SliceScaleDemo()
        {
            var zip: ByteArray = new SliceMaskZIP();

            var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
            converter.addEventListener(Event.COMPLETE, this.onConverted);
            converter.addEventListener(ErrorEvent.ERROR, this.onError);
            converter.convert(zip);
        }

        private function onConverted(event: Event): void
        {
            var timeline: GAFTimeline = (event.target as ZipToGAFAssetConverter).gafBundle.getGAFTimeline("slice9_3_scale", "rootTimeline");

            _scaleDemo = new SliceScale(timeline);

            this.addChild(_scaleDemo);

            _scaleDemo.play();

            _scaleDemo.slice9ScaleBtn.addEventListener(TouchEvent.TOUCH, slice9scale_handler);
            _scaleDemo.slice3ScaleBtn.addEventListener(TouchEvent.TOUCH, slice3scale_handler)
        }

        private function slice9scale_handler(event:TouchEvent):void
        {
            if(event.touches.length > 0 && event.touches[0].phase == TouchPhase.ENDED)
            {
                _scaleDemo.sliceScaleByModifier(SliceScale.SLICE_9_GRID_SCALE);
            }

        }

        private function slice3scale_handler(event:TouchEvent):void
        {
            if(event.touches.length > 0 && event.touches[0].phase == TouchPhase.ENDED)
            {
                _scaleDemo.sliceScaleByModifier(SliceScale.SLICE_3_GRID_SCALE);
            }

        }

        private function onError(event: ErrorEvent): void
        {
            trace(event);
        }

    }
}