/**
 * Created by Nazar on 05.03.14.
 */
package com.catalystapps.gaf.display
{
	import flash.geom.Matrix;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public interface IGAFTexture
	{
		function get texture(): Texture;

		function get pivotMatrix(): Matrix;

		function get id(): String;
	}
}
