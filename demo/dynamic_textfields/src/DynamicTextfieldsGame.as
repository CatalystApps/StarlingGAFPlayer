package 
{
	import starling.events.TouchPhase;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;

	/**
	 * @author Ivan Avdeenko
	 */
	public class DynamicTextfieldsGame extends Sprite
	{
		private var mc: GAFMovieClip;

		[Embed(source="../design/text_field_demo.zip", mimeType="application/octet-stream")]
		private var zip: Class;

		public function DynamicTextfieldsGame()
		{
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(new zip());
		}

		private function onConverted(event: Event): void
		{
			var timeline: GAFTimeline = (event.target as ZipToGAFAssetConverter).gafTimeline;
			this.mc = new GAFMovieClip(timeline);
			
			this.addChild(mc);
			this.mc.swapBtn.addEventListener(TouchEvent.TOUCH, onTouch);
			this.mc.swapBtn.useHandCursor = true;
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this);
			if (touch)
			{
				switch (touch.phase)
				{
					case TouchPhase.BEGAN:
						this.mc.swapBtn.gotoAndStop("Down");
					break;
					case TouchPhase.ENDED:
						this.mc.swapBtn.gotoAndStop("Up");
						this.mc.dynamic_txt.text = this.mc.input_txt.text + "\n";
					break;
				}
			}
		}
	}
}
