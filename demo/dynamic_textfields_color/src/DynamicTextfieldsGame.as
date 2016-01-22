package
{
	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.display.GAFTextField;

	import flash.text.TextFormat;

	import starling.events.TouchPhase;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;

	/**
	 * @author Nazar Levitsky
	 */
	public class DynamicTextfieldsGame extends Sprite
	{
		private var mc: GAFMovieClip;

		[Embed(source="../design/cooper-black.ttf", fontName="Cooper Black", embedAsCFF="false")]
		private var EmbeddedFont: Class;

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
			var bundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			var timeline: GAFTimeline = bundle.getGAFTimeline("text_field_demo", "rootTimeline");
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
						this.setTextColor(this.mc.dynamic_txt, Math.random() * 0xFFFFFF);
						this.mc.dynamic_txt.text = this.mc.input_txt.text + "\n";
					break;
				}
			}
		}

		private function setTextColor(txt: GAFTextField, color: uint): void
		{
			var textFormat: TextFormat = txt.textEditorProperties.textFormat;
			textFormat.color = color;
			txt.textEditorProperties.textFormat = textFormat;
		}
	}
}
