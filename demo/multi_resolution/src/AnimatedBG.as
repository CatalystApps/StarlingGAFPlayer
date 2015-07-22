package
{
	import com.catalystapps.gaf.display.GAFMovieClip;
	import com.catalystapps.gaf.data.GAFTimeline;
	import starling.animation.IAnimatable;
	import starling.core.Starling;
	import starling.display.Sprite;

	import flash.geom.Rectangle;

	/**
	 * @author Ivan Avdeenko
	 */
	public class AnimatedBG extends Sprite implements IAnimatable
	{
		private var backs: Vector.<GAFMovieClip>;
		private var _direction: int;
		private var viewport: Rectangle;
		private var _width: uint;
		
		public function AnimatedBG(gafTimeline: GAFTimeline, scale: Number)
		{
			var mc: GAFMovieClip;
			backs = new Vector.<GAFMovieClip>();

			for (var i: int = 0; i < 4; i++)
			{
				mc = new GAFMovieClip(gafTimeline);
				mc.scaleX =  
				mc.scaleY = scale;
				_width ||= mc.width;
				mc.width = _width;

				backs.push(mc);
				if (i > 0)
				{
					backs[i].x = backs[i - 1].x + _width;
				}
				this.addChild(backs[i]);
			}
			viewport = Starling.current.viewPort;
		}

		public function advanceTime(time: Number): void
		{
			var i: int;
			var next: int;
			for (i = 0; i < backs.length; i++)
			{
				backs[i].x += _direction;
			}
			for (i = 0; i < backs.length; i++)
			{
				if (_direction > 0 && backs[i].x > viewport.width)
				{
					next = i == backs.length - 1 ? 0 : i + 1;
					backs[i].x = backs[next].x - _width;
				}
				else if (_direction < 0 && backs[i].bounds.right < 0)
				{
					next = i == 0 ? backs.length - 1 : i - 1;
					backs[i].x = backs[next].x + _width;
				}
			}
		}

		public function set direction(direction: int): void
		{
			_direction = direction;
		}

		public function get direction(): int
		{
			return _direction;
		}
	}
}
