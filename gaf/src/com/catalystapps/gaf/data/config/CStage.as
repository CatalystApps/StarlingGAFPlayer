package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CStage
	{
		public var fps: uint;
		public var color: uint;
		public var width: int;
		public var height: int;
		
		public function clone(source: Object): CStage
		{
			fps = source.fps;
			color = source.color;
			width = source.width;
			height = source.height;
			
			return this;
		}
	}
}
