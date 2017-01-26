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

public class AnimatedFiltersDemo extends Sprite
    {
        [Embed(source="../design/animated_filters.zip", mimeType="application/octet-stream")]
        private const AnimatedFiltersZIP: Class;

        private var _animation:AnimatedFilters;

        public function AnimatedFiltersDemo()
        {
            var zip: ByteArray = new AnimatedFiltersZIP();

            var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
            converter.addEventListener(Event.COMPLETE, this.onConverted);
            converter.addEventListener(ErrorEvent.ERROR, this.onError);
            converter.convert(zip);
        }

        private function onConverted(event: Event): void
        {
            var timeline: GAFTimeline = (event.target as ZipToGAFAssetConverter).gafBundle.getGAFTimeline("animated_filters", "rootTimeline");

            _animation = new AnimatedFilters(timeline);
            this.addChild(_animation);

            _animation.play();
        }

        private function onError(event: ErrorEvent): void
        {
            trace(event);
        }

    }
}