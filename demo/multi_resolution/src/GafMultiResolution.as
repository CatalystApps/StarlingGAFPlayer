package
{
	import starling.utils.SystemUtil;
	import starling.core.Starling;
	import starling.events.Event;

	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;

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
			
			/**This block is needed to run multi_resolution.swf on desktop.
			 * It disables scaling feature, required for mobile devices.
			 * Remove the block below to run the demo on mobile devices.
			 */
			//start block
			if (SystemUtil.isDesktop)
			{
				viewport.setTo(0, 0, stage.stageWidth, stage.stageHeight);
				scale.setTo(1, 1);
			}
			//end block

			starling = new Starling(MainStarling, stage, viewport);
			starling.addEventListener(Event.ROOT_CREATED, onRootCreated);
			starling.skipUnchangedFrames = true; //TODO - дописать почему!)
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