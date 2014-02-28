package com.catalystapps.gaf.data.converters
{
	/**
	 * @author p0d04Va
	 */
	public class WarningConstants
	{
		public static const UNSUPPORTED_FILTERS: String = "Unsupported filter in animation";
		public static const UNSUPPORTED_TAG: String = "Unsupported tag found, check for playback library updates";
		
		public static const CANT_STACK_BLUR_FILTERS: String = "Warning! Online preview is not able to stack Blur filters on one object (flash player technical limitation). All other runtimes will display this correctly.";
		public static const CANT_CT_GLOW: String = "Warning! Online preview is not able to display Glow and Colortransform filters applied to one object (flash player technical limitation). All other runtimes will display this correctly.";
		public static const CANT_CT_DROP: String = "Warning! Online preview is not able to display Drop Shadow and Colortransform filters applied to one object (flash player technical limitation). All other runtimes will display this correctly.";
		public static const CANT_BLUR_GLOW: String = "Warning! Online preview is not able to display Glow and Blur filters applied to one object (flash player technical limitation). All other runtimes will display this correctly.";
		public static const CANT_BLUR_DROP: String = "Warning! Online preview is not able to display Drop Shadow and Blur filters applied to one object (flash player technical limitation). All other runtimes will display this correctly.";
		public static const FILTERS_UNDER_MASK: String = "Warning! Animation contains objects with filters under mask! Online preview is not able to display filters applied under masks (flash player technical limitation). All other runtimes will display this correctly.";
	}
}
