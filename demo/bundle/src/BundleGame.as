package
{
	import com.catalystapps.gaf.data.GAFTimeline;
	import starling.events.TouchPhase;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import com.catalystapps.gaf.data.GAFBundle;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author mitvad
	 */
	public class BundleGame extends Sprite
	{
		private var gafBundle: GAFBundle;
		private var gafMovieClip: GAFMovieClip;
		private var currentAsset: String;

		[Embed(source="../design/bundle.zip", mimeType="application/octet-stream")]
		private const BundleZip: Class;

		public function BundleGame()
		{
			var zip: ByteArray = new BundleZip();
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			this.gafBundle = (event.target as ZipToGAFAssetConverter).gafBundle;

			this.initGAFMovieClip("skeleton");

			this.stage.addEventListener(TouchEvent.TOUCH, this.onTouchEvent);
		}

		private function onTouchEvent(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this.stage, TouchPhase.BEGAN);
			if (touch)
			{
				if (this.currentAsset == "skeleton")
				{
					this.initGAFMovieClip("ufo-monster");
				}
				else
				{
					this.initGAFMovieClip("skeleton");
				}
			}
		}

		private function initGAFMovieClip(swfName: String): void
		{
			this.currentAsset = swfName;

			(this.gafMovieClip) ? this.gafMovieClip.dispose() : null;

			this.removeChildren();

			var timeline: GAFTimeline = this.gafBundle.getGAFTimeline(swfName, "rootTimeline");

			this.gafMovieClip = new GAFMovieClip(timeline);
			this.gafMovieClip.play();

			this.addChild(this.gafMovieClip);
		}
	}
}
