package
{
	import com.catalystapps.gaf.sound.GAFSoundManager;

	import starling.events.Touch;

	import starling.events.TouchEvent;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	import starling.events.TouchPhase;

	public class SoundExampleDemo extends Sprite
	{
		private var converter: ZipToGAFAssetConverter;
		private var timeline : GAFTimeline;
		private var mc : GAFMovieClip;
		private var muteBtn: GAFMovieClip;

		private var mute: Boolean;

		[Embed(source="../design/SoundsExample_Tank.zip", mimeType="application/octet-stream")]
		private const asset: Class;

		public function SoundExampleDemo()
		{
			this.init();
		}

		private function init(): void
		{
			var zip: ByteArray = new asset();

			converter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			timeline = converter.gafTimeline;
			mc = new GAFMovieClip(timeline);
			muteBtn = mc.mute_btn;

			addChild(mc);

			mc.play(true);

			muteBtn.addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this, TouchPhase.BEGAN);
			if (touch)
			{
				if (mute)
				{
					GAFSoundManager.instance.setVolume(1);
					muteBtn.gotoAndStop(1);
				}
				else
				{
					GAFSoundManager.instance.setVolume(0);
					muteBtn.gotoAndStop(2);
				}

				mute = !mute;
			}
		}
	}
}
