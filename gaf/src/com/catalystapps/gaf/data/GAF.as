package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.core.gaf_internal;
	/**
	 * The GAF class defines global GAF library settings
	 */
	public class GAF
	{
		/**
		 * Optimize draw calls when animation contain mixed objects with alpha &lt; 1 and with alpha = 1.
		 * This is done by setting alpha = 0.99 for all objects that has alpha = 1.
		 * In this case all objects will be rendered by one draw call.
		 * When use99alpha = false the number of draw call may be much more
		 * (the number of draw calls depends on objects order in display list)
		 */
		public static var use99alpha: Boolean;
		
		/**
		 * Play sounds, triggered by the event "gafPlaySound" in a frame of the GAFMovieClip.
		 */
		public static var autoPlaySounds: Boolean = true;
		
		/** @private */
		gaf_internal static var useDeviceFonts: Boolean;
	}
}
