package com.catalystapps.gaf.display
{
	import flash.utils.getQualifiedClassName;
	import starling.textures.Texture;

	import flash.geom.Matrix;

	/**
	 * @private
	 */
	public class GAFTexture implements IGAFTexture
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

		private var _id: String;
		private var _texture: Texture;
		private var _pivotMatrix: Matrix;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function GAFTexture(id: String, texture: Texture, pivotMatrix: Matrix)
		{
			this._id = id;
			this._texture = texture;
			this._pivotMatrix = pivotMatrix;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		public function copyFrom(newTexture: IGAFTexture): void
		{
			if (newTexture is GAFTexture)
			{
				this._id = newTexture.id;
				this._texture = newTexture.texture;
				this._pivotMatrix.copyFrom(newTexture.pivotMatrix);
			}
			else
			{
				throw new Error("Incompatiable types GAFexture and "+getQualifiedClassName(newTexture));
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

		public function get texture(): Texture
		{
			return this._texture;
		}

		public function get pivotMatrix(): Matrix
		{
			return this._pivotMatrix;
		}

		public function get id(): String
		{
			return this._id;
		}

		public function clone(): IGAFTexture
		{
			return new GAFTexture(this._id, this._texture, this._pivotMatrix.clone());
		}
	}
}
