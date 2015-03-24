package
com.catalystapps{
	import com.catalystapps.gaf.data.GAFBundle;
	import starling.core.Starling;
	import starling.events.Touch;
	import starling.events.TouchPhase;
	import starling.events.TouchEvent;
	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	/**
	 * @author Programmer
	 */
	public class MainStarling extends Sprite
	{
		private var offset: int;
		private var backSpace : GAFMovieClip;
		private var leftButton: GAFMovieClip;
		private var rightButton: GAFMovieClip;
		private var gafMovieClip: GAFMovieClip;
		
		private var backAnimated: AnimatedBG;
		
		/** actual scale of viewport */
		private var _xScale: Number;
		private var _yScale: Number;
		/** game settings scale*/
		private var _scale: Number;
		private var gafTimeline : GAFTimeline;
		private var urlLoader: URLLoader;
		private var speed: Number;
		
		public function MainStarling()
		{
			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, this.onLoaded);
		}

		private function onLoaded(event: Event): void
		{
			var availableScales: Array = [2, 1, 0.5];
			_scale = availableScales[0];
			var avgScale: Number = 0;
			while (_xScale > avgScale)
			{
				_scale = availableScales.pop();
				if (availableScales.length > 0)
				{
					avgScale = (_scale + availableScales[availableScales.length - 1]) / 2;
				}
				else
				{
					break;
				}
			}
			var zip: ByteArray = urlLoader.data;
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip, _scale, 1);
		}

		private function onConverted(event: Event): void
		{
			var gafScale: Number = _yScale / _scale;
			var converter: ZipToGAFAssetConverter = event.target as ZipToGAFAssetConverter;
			var gafBundle: GAFBundle = converter.gafBundle;
			gafTimeline = converter.gafTimeline;
			
			offset = 50 * gafScale;

			backSpace = new GAFMovieClip(gafBundle.getGAFTimelineByLinkage("back_space"));
			backSpace.scaleX =
			backSpace.scaleY = gafScale;
			backSpace.x = (stage.stageWidth - backSpace.width) / 2; //center background

			leftButton = new GAFMovieClip(gafBundle.getGAFTimelineByLinkage("ArrowLeftButton"));
			leftButton.scaleX =
			leftButton.scaleY = gafScale;
			leftButton.x = leftButton.width + offset;
			leftButton.y = (stage.stageHeight - leftButton.height) / 2;
			
			rightButton = new GAFMovieClip(gafBundle.getGAFTimelineByLinkage("ArrowRightButton"));
			rightButton.scaleX =
			rightButton.scaleY = gafScale;
			rightButton.x = stage.stageWidth - rightButton.width - offset;
			rightButton.y = (stage.stageHeight - rightButton.height) / 2;
			
			gafMovieClip = new GAFMovieClip(gafTimeline);
			gafMovieClip.scaleX =
			gafMovieClip.scaleY = gafScale;
			gafMovieClip.x = (stage.stageWidth - gafMovieClip.width) / 2;
			gafMovieClip.setSequence("stand_right");
			
			backAnimated = new AnimatedBG(gafBundle.getGAFTimelineByLinkage("back_1"), gafScale);
			
			this.addChild(backSpace);
			this.addChild(backAnimated);
			this.addChild(gafMovieClip);
			this.addChild(rightButton);
			this.addChild(leftButton);
			
			this.addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this);
			if (touch)
			{
				switch (touch.phase)
				{
					case TouchPhase.BEGAN:
						if (touch.globalX < stage.stageWidth / 3)
						{
							backAnimated.direction = speed;
							gafMovieClip.setSequence("walk_left");
							leftButton.gotoAndStop(2);
						}
						else if (touch.globalX > stage.stageWidth * 2 / 3)
						{
							backAnimated.direction = -speed;
							gafMovieClip.setSequence("walk_right");
							rightButton.gotoAndStop(2);
						}
						else
						{
							backAnimated.direction = 0;
						}
						gafMovieClip.fps = 60;
						Starling.juggler.add(backAnimated);
						break;
					case TouchPhase.ENDED:
						if (backAnimated.direction > 0)
						{
							gafMovieClip.setSequence("stand_left");
							leftButton.gotoAndStop(1);
						}
						else if (backAnimated.direction < 0)
						{
							gafMovieClip.setSequence("stand_right");
							rightButton.gotoAndStop(1);
						}
						gafMovieClip.fps = 30;
						Starling.juggler.remove(backAnimated);
						break;
				}
			}
		}

		public function setScale(x: Number, y: Number): void
		{
			_xScale = x;
			_yScale = y;
			speed = 10 * _yScale;
			urlLoader.load(new URLRequest("assets/RedRobot.zip"));
		}
	}
}