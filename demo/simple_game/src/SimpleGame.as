package
{
	import starling.events.TouchPhase;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import com.catalystapps.gaf.data.GAFBundle;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author mitvad
	 */
	public class SimpleGame extends Sprite
	{
		[Embed(source="../design/mini_game.zip", mimeType="application/octet-stream")]
		private const FiremanZip: Class;

		public function SimpleGame()
		{
			var zip: ByteArray = new FiremanZip();
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			var gafBundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			var gafTimeline: GAFTimeline = gafBundle.getGAFTimeline("mini_game");
			var mc: GAFMovieClip = new GAFMovieClip(gafTimeline);
			mc.play(true);

			this.addChild(mc);

			initController(mc);
		}

		private function initController(mc: GAFMovieClip): void
		{
			var rocket: GAFMovieClip;
			var rocketAnimation: GAFMovieClip;
			for (var i: int = 0; i < 4; i++)
			{
				rocketAnimation = mc["Rocket_with_guide" + (i + 1)];
				rocket = rocketAnimation["Rocket" + (i + 1)];
				rocket.addEventListener(TouchEvent.TOUCH, onTouch);
				rocket.setSequence("idle");
			}
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this, TouchPhase.BEGAN);
			if (touch)
			{
				var rocket: GAFMovieClip = event.currentTarget as GAFMovieClip;
				rocket.setSequence("explode");
				rocket.touchable = false;
				rocket.addEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onRocketExploded);

				(rocket.parent as GAFMovieClip).stop();
			}
		}

		private function onRocketExploded(event: Object): void
		{
			var rocket: GAFMovieClip = event["currentTarget"];
			rocket.removeEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onRocketExploded);
			rocket.setSequence("idle");
			rocket.touchable = true;

			(rocket.parent as GAFMovieClip).gotoAndPlay(1);
		}
	}
}
