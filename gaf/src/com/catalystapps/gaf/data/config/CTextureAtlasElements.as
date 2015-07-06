package com.catalystapps.gaf.data.config
{
	/**
	 * @private
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
		private var _elementsByLinkage: Object;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextureAtlasElements(): void
		{
			this._elementsVector = new Vector.<CTextureAtlasElement>();
			this._elementsDictionary = {};
			this._elementsByLinkage = {};
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

				if (element.linkage)
				{
					this._elementsByLinkage[element.linkage] = element;
				}
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

		public function getElementByLinkage(linkage: String): CTextureAtlasElement
		{
			if (this._elementsByLinkage[linkage])
			{
				return this._elementsByLinkage[linkage];
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
			return this._elementsVector;
		}

	}
}
