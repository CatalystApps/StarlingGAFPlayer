package 
com.catalystapps
{
	import starling.core.Starling;
	import starling.events.Event;

	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class GafMultiResolution extends Sprite
	{
		private var starling: Starling;
		private var scale: Point;
		
		public function GafMultiResolution()
		{
			var xScale: Number = stage.fullScreenWidth / stage.stageWidth;
			var yScale: Number = stage.fullScreenHeight / stage.stageHeight;
			var viewport: Rectangle = new Rectangle(0, 0, stage.fullScreenWidth, stage.fullScreenHeight);
			scale = new Point(xScale, yScale);
			
			//this block is needed to run multi_resolution.swf on desktop
			//it disables scaling feature, required for mobile devices
			//if you want to use it: add -define+=CONFIG::RELEASE,!{debug} to your compiler arguments
			CONFIG::RELEASE
			{
				if (Capabilities.version.indexOf("WIN") != -1
				||  Capabilities.version.indexOf("MAC") != -1
				||  Capabilities.version.indexOf("LNX") != -1)
				{
					viewport.setTo(0, 0, stage.stageWidth, stage.stageHeight);
					scale.setTo(1, 1);
				}
			}
			
			Starling.handleLostContext = true;
			starling = new Starling(MainStarling, stage, viewport);
			starling.addEventListener(Event.ROOT_CREATED, onRootCreated);
			starling.showStats = true;
       		starling.start();
		}

		private function onRootCreated(): void
		{
			starling.removeEventListener(Event.ROOT_CREATED, onRootCreated);
			(starling.root as MainStarling).setScale(scale.x, scale.y);
		}
	}
}