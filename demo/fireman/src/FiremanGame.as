package
{
	import com.catalystapps.gaf.data.GAFBundle;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author mitvad
	 */
	public class FiremanGame extends Sprite
	{
		[Embed(source="../design/fireman.zip", mimeType="application/octet-stream")]
		private const FiremanZip: Class;

		public function FiremanGame()
		{
			var zip: ByteArray = new FiremanZip();
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.addEventListener(ErrorEvent.ERROR, this.onError);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			var gafBundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			var gafTimeline: GAFTimeline = gafBundle.getGAFTimeline("fireman");
			var mc: GAFMovieClip = new GAFMovieClip(gafTimeline);

			this.addChild(mc);
			mc.play();
		}

		private function onError(event: ErrorEvent): void
		{
			trace(event);
		}
	}
}
