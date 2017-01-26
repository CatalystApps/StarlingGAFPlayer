/**
 * Created by Roman Lipovskiy on 17.01.2017.
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

    public class StencilMaskDemo extends Sprite
    {
        [Embed(source="../design/stencil_mask.zip", mimeType="application/octet-stream")]
        private const StencilMaskDemoZIP: Class;

        private var _maskScene:StencilMask;

        public function StencilMaskDemo()
        {
            var zip: ByteArray = new StencilMaskDemoZIP();

            var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
            converter.addEventListener(Event.COMPLETE, this.onConverted);
            converter.addEventListener(ErrorEvent.ERROR, this.onError);
            converter.convert(zip);
        }

        private function onConverted(event: Event): void
        {
            var timeline: GAFTimeline = (event.target as ZipToGAFAssetConverter).gafBundle.getGAFTimeline("stencil_mask", "rootTimeline");

            _maskScene = new StencilMask(timeline);

            this.addChild(_maskScene);

            _maskScene.play();
        }

        private function onError(event: ErrorEvent): void
        {
            trace(event);
        }

    }
}