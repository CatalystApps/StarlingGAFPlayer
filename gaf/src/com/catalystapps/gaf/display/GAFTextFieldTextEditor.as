/**
 * Created by Nazar on 11.03.2015.
 */
package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.ICFilterData;
	import com.catalystapps.gaf.utils.DisplayUtility;
	import com.catalystapps.gaf.utils.FiltersUtility;

	import feathers.controls.text.TextFieldTextEditor;

	/** @private */
	public class GAFTextFieldTextEditor extends TextFieldTextEditor
	{
		private var _filters: Array;

		public function GAFTextFieldTextEditor()
		{
			super();
		}

		/** @private */
		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
			var filters: Array = [];
			if (value)
			{
				for each (var filter: ICFilterData in value.filterConfigs)
				{
					filters.push(FiltersUtility.getNativeFilter(filter, scale));
				}
			}

			if (this.textField)
			{
				this.textField.filters = filters;
			}
			else
			{
				this._filters = filters;
			}
		}

		/** @private */
		override protected function initialize(): void
		{
			super.initialize();

			if (this._filters)
			{
				this.textField.filters = this._filters;
				this._filters = null;
			}
		}

		/**
		 * @private
		 */
		override protected function refreshSnapshotParameters():void
		{
			super.refreshSnapshotParameters();

			this._textFieldClipRect = DisplayUtility.getBoundsWithFilters(this._textFieldClipRect, this.textField.filters);
			this._textFieldOffsetX -= this._textFieldClipRect.x;
			this._textFieldOffsetY -= this._textFieldClipRect.y;
			this._textFieldClipRect.x = 0;
			this._textFieldClipRect.y = 0;
		}

		/**
		 * @private
		 */
		override protected function positionSnapshot():void
		{
			super.positionSnapshot();

			if (!this.textSnapshot)
			{
				return;
			}

			this.textSnapshot.x -= this._textFieldOffsetX;
			this.textSnapshot.y -= this._textFieldOffsetY;
		}
	}
}
