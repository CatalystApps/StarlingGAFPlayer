package com.catalystapps.gaf.data.config
{
	import flash.media.Sound;
	/**
	 * @author Ivan Avdeenko
	 * @private
	 */
	public class CSound
	{
		public static const GAF_PLAY_SOUND: String = "gafPlaySound";
		public static const WAV: uint = 0;
		public static const MP3: uint = 1;

		public var soundID: uint;
		public var linkageName: String;
		public var source: String;
		public var format: uint;
		public var rate: uint;
		public var sampleSize: uint;
		public var sampleCount: uint;
		public var stereo: Boolean;
		public var sound: Sound;
	}
}
