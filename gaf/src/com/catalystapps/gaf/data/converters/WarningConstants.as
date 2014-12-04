package com.catalystapps.gaf.data.converters
{
	/**
	 * @private
	 */
	public class WarningConstants
	{
		public static const UNSUPPORTED_FILTERS: String = "Unsupported filter in animation";
		public static const UNSUPPORTED_FILE: String = "You are using an old version of GAF library";
		public static const UNSUPPORTED_TAG: String = "Unsupported tag found, check for playback library updates";
		public static const FILTERS_UNDER_MASK: String = "Warning! Animation contains objects with filters under mask! Online preview is not able to display filters applied under masks (flash player technical limitation). All other runtimes will display this correctly.";
		public static const REGION_NOT_FOUND: String = "In the texture atlas element is missing. This is conversion bug. Please report issue <font color='#0000ff'><u><a href='http://gafmedia.com/contact'>here</a></u></font> and we will fix it (use the Request type - Report Issue).";
	}
}
