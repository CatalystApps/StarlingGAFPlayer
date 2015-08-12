package
{
	import starling.core.Starling;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	[SWF(backgroundColor="#999999", frameRate="60", width="800", height="600")]
	public class SequencesMain extends Sprite
	{
		private var _starling: Starling;

		public function SequencesMain()
		{
			_starling = new Starling(SequencesStarling, stage, new Rectangle(0, 0, 800, 600));
			_starling.showStats = true;
			_starling.start();
		}
	}
}
