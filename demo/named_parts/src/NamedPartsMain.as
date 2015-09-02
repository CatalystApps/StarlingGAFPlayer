package
{
	import starling.core.Starling;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	[SWF(backgroundColor="#999999", frameRate="60", width="1024", height="600")]
	public class NamedPartsMain extends Sprite
	{
		private var _starling: Starling;

		public function NamedPartsMain()
		{
			_starling = new Starling(NamedPartsStarling, stage, new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
			_starling.showStats = true;
			_starling.start();
		}
	}
}
