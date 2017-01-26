package
{
	import com.catalystapps.gaf.data.GAFTimeline;

	import starling.text.TextField;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;

   import starling.text.TextFormat;

   /**
	 * @author Ivan Avdeenko
	 */
	public class NamedPartsStarling extends Sprite
	{
		[Embed(source="../design/robot_plain.zip", mimeType="application/octet-stream")]
		private var PlainZip: Class;
		[Embed(source="../design/robot_nesting.zip", mimeType="application/octet-stream")]
		private var NestingZip: Class;
		private var robotPlain: GAFMovieClip;
		private var robotNesting: GAFMovieClip;

		public function NamedPartsStarling()
		{
			this.convertPlain();
		}

		private function convertPlain(): void
		{
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onPlainConverted);
			converter.convert(new PlainZip());
		}

		private function onPlainConverted(event: Event): void
		{
			var converter: ZipToGAFAssetConverter = event.target as ZipToGAFAssetConverter;
			converter.removeEventListener(Event.COMPLETE, this.onPlainConverted);

			var gafTimeline: GAFTimeline = converter.gafBundle.getGAFTimeline("robot");

			this.robotPlain = new GAFMovieClip(gafTimeline);
			this.robotPlain.play();

			this.addChild(this.robotPlain);

			this.convertNesting();
		}

		private function convertNesting(): void
		{
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onNestingConverted);
			converter.convert(new NestingZip());
		}

		private function onNestingConverted(event: Event): void
		{
			var converter: ZipToGAFAssetConverter = event.target as ZipToGAFAssetConverter;
			converter.removeEventListener(Event.COMPLETE, this.onNestingConverted);

			var gafTimeline: GAFTimeline = converter.gafBundle.getGAFTimeline("robot");

			this.robotNesting = new GAFMovieClip(gafTimeline);
			this.robotNesting.x = this.robotNesting.width;
			this.robotNesting.play(true);

			this.addChild(this.robotNesting);

			this.initTextFileds();

			this.robotPlain.addEventListener(TouchEvent.TOUCH, this.onTouch);
			this.robotNesting.addEventListener(TouchEvent.TOUCH, this.onTouch);
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this, TouchPhase.BEGAN);
			if (touch)
			{
				// TODO: add description
				this.robotPlain.body_gun.visible = !this.robotPlain.body_gun.visible;

				// TODO: add description
				this.robotNesting.body.gun.visible = !this.robotNesting.body.gun.visible;
			}
		}

		private function initTextFileds(): void
		{
			var textFormat:TextFormat = new TextFormat("Arial", 24);

			var title: TextField = new TextField(stage.stageWidth, 100, "Click the robots to show/hide guns", textFormat);
			var plain: TextField = new TextField(this.robotPlain.width, 100, "Plain", textFormat);
			var nesting: TextField = new TextField(this.robotNesting.width, 100, "Nesting", textFormat);

			nesting.x = Math.round(this.robotNesting.x);
			nesting.y = stage.stageHeight - 100;
			plain.y = stage.stageHeight - 100;

			this.addChild(title);
			this.addChild(plain);
			this.addChild(nesting);
		}
	}
}
