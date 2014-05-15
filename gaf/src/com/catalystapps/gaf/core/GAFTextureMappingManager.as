package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFTexture;
	import com.catalystapps.gaf.display.IGAFTexture;

	import flash.geom.Matrix;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class GAFTextureMappingManager
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private static var _timelinesCollection: Object = {};

		private static var _tmpTexture: Texture;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public static function addGAFTimeline(timeline: GAFTimeline): void
		{
			if (!_timelinesCollection[timeline.uniqueID])
			{
				_timelinesCollection[timeline.uniqueID] = timeline;
			}
		}

		public static function getMappedTexture(id: String, mappedAssetID: String): IGAFTexture
		{
			var result: IGAFTexture;

			var timeline: GAFTimeline;

			if (mappedAssetID)
			{
				timeline = _timelinesCollection[mappedAssetID];

				if (timeline)
				{
					result = timeline.textureAtlas.getTexture(id, "", true);

					if (result)
					{
						return result;
					}
				}
			}
			else
			{
				for each (timeline in _timelinesCollection)
				{
					result = timeline.textureAtlas.getTexture(id, "", true);

					if (result)
					{
						return result;
					}

				}
			}

			// when there is no mapped texture

			if (!_tmpTexture)
			{
				_tmpTexture = Texture.fromColor(10, 50, 0xFF0000);
			}

			result = new GAFTexture("tmpTexture", _tmpTexture, new Matrix());

			return result;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------
	}
}
