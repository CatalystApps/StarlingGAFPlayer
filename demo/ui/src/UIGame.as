package
{
	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	import starling.display.Sprite;
	import starling.text.TextField;

	/**
	 * @author mitvad
	 */
	public class UIGame extends Sprite
	{
		public function UIGame()
		{
			this.loadZip();
		}
		
		private function loadZip(): void
		{
			var request: URLRequest = new URLRequest("assets/ui/ui.zip");
			var urlLoader: URLLoader = new URLLoader(request);
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, this.onLoaded);
		}

		private function onLoaded(event: Event): void
		{
			var zip: ByteArray = (event.target as URLLoader).data;
			
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.addEventListener(ErrorEvent.ERROR, this.onError);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			var gafAsset: GAFAsset = (event.target as ZipToGAFAssetConverter).gafAsset;
			
			var mc: GAFMovieClip = new GAFMovieClip(gafAsset);
			
			this.addChild(mc);
			
			mc.play();
		}
		
		private function onError(event: ErrorEvent): void
		{
			trace(event);
		}
		
	}
}
