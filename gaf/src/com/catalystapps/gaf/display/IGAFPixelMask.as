/**
 * Created by Nazar on 02.03.2015.
 */
package com.catalystapps.gaf.display
{
	import starling.core.RenderSupport;

	public interface IGAFPixelMask
	{
		function renderAsMask(support: RenderSupport, quadBatch: MaskQuadBatch, parentAlpha: Number): void;
		function get isMask(): Boolean;
		function set isMask(value: Boolean): void;
	}
}
