package
{
	import starling.events.Event;
	import com.catalystapps.gaf.data.GAFBundle;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author Programmer
	 */
	public class MainStarling extends Sprite
	{
		[Embed(source="../design/fireman.zip", mimeType="application/octet-stream")]
		private const FiremanZip: Class;

		private static const subtitles: Vector.<String> = new <String>
		[
			"- Our game is on fire!",
			"- GAF Team, there is a job for us!",
			"- Go and do your best!"
		];

		private var gafMovieClip: GAFMovieClip;

		public function MainStarling()
		{
			var zip: ByteArray = new FiremanZip();
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(flash.events.Event.COMPLETE, this.onConverted);
			converter.convert(zip);
		}

		private function onConverted(event: flash.events.Event): void
		{
			var bundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;

			gafMovieClip = new GAFMovieClip(bundle.getGAFTimeline("fireman"));
			gafMovieClip.addEventListener("showSubtitles", onShow);
			gafMovieClip.addEventListener("hideSubtitles", onHide);
			gafMovieClip.play(true);

			this.addChild(gafMovieClip);
		}

		private function onHide(event: starling.events.Event): void
		{
			gafMovieClip.subtitles_txt.text = "";
		}

		private function onShow(event: starling.events.Event): void
		{
			gafMovieClip.subtitles_txt.text = subtitles[int(event.data) - 1];
		}
	}
}