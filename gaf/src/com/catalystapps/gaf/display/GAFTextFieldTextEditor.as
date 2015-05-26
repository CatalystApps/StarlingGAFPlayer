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

	import flash.geom.Rectangle;

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

			var snapshotClipRect: Rectangle;

			try // Feathers revision before bca9b93
			{
				snapshotClipRect = this["_textFieldClipRect"];
			}
			catch (error: Error)
			{
				snapshotClipRect = this["_textFieldSnapshotClipRect"];
			}

			snapshotClipRect.copyFrom(DisplayUtility.getBoundsWithFilters(snapshotClipRect, this.textField.filters));
			this._textFieldOffsetX -= snapshotClipRect.x;
			this._textFieldOffsetY -= snapshotClipRect.y;
			snapshotClipRect.x = 0;
			snapshotClipRect.y = 0;
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
