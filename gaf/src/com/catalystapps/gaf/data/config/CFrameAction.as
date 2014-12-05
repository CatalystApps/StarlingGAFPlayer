package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CFrameAction
	{
		public var type: int;
		public var scope: String;
		public var params: Vector.<String> = new Vector.<String>();
		
		public static const STOP: int = 0;
		public static const PLAY: int = 1;
		public static const GOTO_AND_STOP: int = 2;
		public static const GOTO_AND_PLAY: int = 3;
		public static const DISPATCH_EVENT: int = 4;
	}
}
