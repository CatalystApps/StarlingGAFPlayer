package com.catalystapps.gaf.data.config
{
	/**
	 * @author Ivan Avdeenko
	 * @private
	 */
	public class CFrameSound
	{
		public static const ACTION_STOP: uint = 1;
		public static const ACTION_START: uint = 2;
		public static const ACTION_CONTINUE: uint = 3;
		public var soundID: uint;
		public var action: uint;
		public var repeatCount: uint; //0 and 1 means play sound once
		public var linkage: String;

		public function CFrameSound(data: Object)
		{
			this.soundID = data.id;
			this.action = data.action;
			if ("linkage" in data)
			{
				this.linkage = data.linkage;
			}
			if ("repeat" in data)
			{
				this.repeatCount = data.repeat;
			}
		}
	}
}
