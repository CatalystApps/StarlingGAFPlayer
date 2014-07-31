package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CTextureAtlasCSF
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

		private var _scale: Number;
		private var _csf: Number;

		private var _sources: Vector.<CTextureAtlasSource>;

		private var _elements: CTextureAtlasElements;

		private var _atlas: CTextureAtlas;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextureAtlasCSF(csf: Number, scale: Number)
		{
			this._csf = csf;
			this._scale = scale;

			this._sources = new Vector.<CTextureAtlasSource>();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function dispose(): void
		{
			(this._atlas) ? this._atlas.dispose() : null;

			this._atlas = null;
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

		public function get csf(): Number
		{
			return _csf;
		}

		public function get sources(): Vector.<CTextureAtlasSource>
		{
			return _sources;
		}

		public function set sources(sources: Vector.<CTextureAtlasSource>): void
		{
			_sources = sources;
		}

		public function get atlas(): CTextureAtlas
		{
			return _atlas;
		}

		public function set atlas(atlas: CTextureAtlas): void
		{
			_atlas = atlas;
		}

		public function get elements(): CTextureAtlasElements
		{
			return _elements;
		}

		public function set elements(elements: CTextureAtlasElements): void
		{
			_elements = elements;
		}
	}
}
