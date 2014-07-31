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

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	/**
	 * @author mitvad
	 */
	public class BundleGame extends Sprite
	{
		private var gafBundle: GAFBundle;
		
		private var gafMovieClip: GAFMovieClip;
		
		private var currentAssetIndex: uint = 0;
		
		public function BundleGame()
		{
			this.loadZip();
		}
		
		private function loadZip(): void
		{
			var request: URLRequest = new URLRequest("assets/bundle.zip");
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
			this.gafBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			
			this.initGAFMovieClip();
			
			this.stage.addEventListener(TouchEvent.TOUCH, this.onTouchEvent);
		}

		private function onTouchEvent(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this.stage, TouchPhase.BEGAN);
			
			if(touch)
			{
				this.currentAssetIndex++;
				
				if(this.currentAssetIndex >= this.gafBundle.timelines.length)
				{
					this.currentAssetIndex = 0;
				}
				
				this.initGAFMovieClip();
			}
		}
		
		private function initGAFMovieClip(): void
		{
			(this.gafMovieClip) ? this.gafMovieClip.dispose() : null;
			
			this.removeChildren();
			
			var timeline: GAFTimeline = this.gafBundle.timelines[this.currentAssetIndex];
			
			this.gafMovieClip = new GAFMovieClip(timeline);
			
			this.addChild(this.gafMovieClip);
			
			this.gafMovieClip.play();
		}
		
		private function onError(event: ErrorEvent): void
		{
			trace(event);
		}
		
	}
}
