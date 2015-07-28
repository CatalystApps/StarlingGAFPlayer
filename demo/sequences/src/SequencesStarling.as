package
{
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.data.GAFBundle;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author Ivan Avdeenko
	 */
	public class SequencesStarling extends Sprite
	{
		private var _gafMovieClip: GAFMovieClip;

		[Embed(source="../design/RedRobot.zip", mimeType="application/octet-stream")]
		private var asset: Class;

		public function SequencesStarling()
		{
			var zip: ByteArray = new asset();
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			var gafBundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			//"RedRobot" - the name of the SWF which was converted to GAF
			var gafTimeline: GAFTimeline = gafBundle.getGAFTimeline("RedRobot");

			this._gafMovieClip = new GAFMovieClip(gafTimeline);
			this.setSequence("stand");

			this.addChild(this._gafMovieClip);

			stage.addEventListener(TouchEvent.TOUCH, this.onTouch);
		}

		private function setSequence(sequence: String): void
		{
			this._gafMovieClip.setSequence(sequence);
			this._gafMovieClip.sequence.text = sequence;
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this, TouchPhase.BEGAN);
			if (touch)
			{
				if (this._gafMovieClip.currentSequence == "walk")
				{
					this.setSequence("stand");
				}
				else
				{
					this.setSequence("walk");
				}
			}
		}
	}
}
