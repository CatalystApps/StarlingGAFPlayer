/**
 * Created by Nazar on 27.11.2014.
 */
package
{
	public class SequencePlaybackInfo
	{
		private var _name: String;
		private var _looped: Boolean;

		public function SequencePlaybackInfo(name: String, looped: Boolean)
		{
			_name = name;
			_looped = looped;
		}

		public function get name(): String
		{
			return _name;
		}

		public function get looped(): Boolean
		{
			return _looped;
		}
	}
}
