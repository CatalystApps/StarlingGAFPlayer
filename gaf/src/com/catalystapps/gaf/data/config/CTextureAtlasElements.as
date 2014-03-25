package com.catalystapps.gaf.data.config
{
	/**
	 * @author mitvad
	 */
	public class CTextureAtlasElements
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

		private var _elementsVector: Vector.<CTextureAtlasElement>;
		private var _elementsDictionary: Object;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextureAtlasElements(): void
		{
			this._elementsVector = new Vector.<CTextureAtlasElement>();
			this._elementsDictionary = new Object();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function addElement(element: CTextureAtlasElement): void
		{
			if (!this._elementsDictionary[element.id])
			{
				this._elementsDictionary[element.id] = element;

				this._elementsVector.push(element);
			}
		}

		public function getElement(id: String): CTextureAtlasElement
		{
			if (this._elementsDictionary[id])
			{
				return this._elementsDictionary[id];
			}
			else
			{
				return null;
			}
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

		public function get elementsVector(): Vector.<CTextureAtlasElement>
		{
			return _elementsVector;
		}

	}
}
