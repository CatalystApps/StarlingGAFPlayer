package
{
	import starling.display.Sprite;
	import starling.utils.AssetManager;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author Programmer
	 */
	public class MainStarling extends Sprite
	{
		private var gafMovieClip: GAFMovieClip;
		
		private var assetManager: AssetManager;
		
		public function MainStarling()
		{
			assetManager = new AssetManager();
			assetManager.enqueue("assets/step.mp3");
			assetManager.enqueue("assets/RedRobot.zip");
			assetManager.loadQueue(onProgress);
		}

		private function onProgress(percent: Number): void
		{
			if (percent < 1)
			{
				return;
			}

			var zip: ByteArray = assetManager.getByteArray("RedRobot");
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip, 1, 1);
		}

		private function onConverted(event: Event): void
		{
			var converter: ZipToGAFAssetConverter = event.target as ZipToGAFAssetConverter;

			gafMovieClip = new GAFMovieClip(converter.gafTimeline);
			gafMovieClip.addEventListener("playSoundSteps", onPlaySound);
			gafMovieClip.play(true);

			this.addChild(gafMovieClip);
		}

		private function onPlaySound(): void
		{
			assetManager.playSound("step", 0, 2);
		}
	}
}