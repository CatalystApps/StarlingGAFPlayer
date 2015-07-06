package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CAnimationFrame
	{
		// --------------------------------------------------------------------------
		//
		// PUBLIC VARIABLES
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// PRIVATE VARIABLES
		//
		// --------------------------------------------------------------------------
		private var _instancesDictionary: Object;
		private var _instances: Vector.<CAnimationFrameInstance>;
		private var _actions: Vector.<CFrameAction>;

		private var _frameNumber: uint;

		// --------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		// --------------------------------------------------------------------------
		public function CAnimationFrame(frameNumber: uint)
		{
			this._frameNumber = frameNumber;

			this._instancesDictionary = {};
			this._instances = new Vector.<CAnimationFrameInstance>();
		}

		// --------------------------------------------------------------------------
		//
		// PUBLIC METHODS
		//
		// --------------------------------------------------------------------------
		public function clone(frameNumber: uint): CAnimationFrame
		{
			var result: CAnimationFrame = new CAnimationFrame(frameNumber);

			for each (var instance: CAnimationFrameInstance in this._instances)
			{
				result.addInstance(instance);
				// .clone());
			}

			return result;
		}

		public function addInstance(instance: CAnimationFrameInstance): void
		{
			if (this._instancesDictionary[instance.id])
			{
				if (instance.alpha)
				{
					this._instances[this._instances.indexOf(this._instancesDictionary[instance.id])] = instance;

					this._instancesDictionary[instance.id] = instance;
				}
				else
				{
					// Poping the last element and set it as the removed element
					var index: int = this._instances.indexOf(this._instancesDictionary[instance.id]);
					// If index is last element, just pop
					if (index == (this._instances.length - 1))
					{
						this._instances.pop();
					}
					else
					{
						this._instances[index] = this._instances.pop();
					}

					delete this._instancesDictionary[instance.id];
				}
			}
			else
			{
				this._instances.push(instance);

				this._instancesDictionary[instance.id] = instance;
			}
		}

		public function addAction(action: CFrameAction): void
		{
			_actions ||= new Vector.<CFrameAction>();
			_actions.push(action);
		}

		public function sortInstances(): void
		{
			this._instances.sort(this.sortByZIndex);
		}

		public function getInstanceByID(id: String): CAnimationFrameInstance
		{
			return this._instancesDictionary[id];
		}

		// --------------------------------------------------------------------------
		//
		// PRIVATE METHODS
		//
		// --------------------------------------------------------------------------
		private function sortByZIndex(instance1: CAnimationFrameInstance, instance2: CAnimationFrameInstance): Number
		{
			if (instance1.zIndex < instance2.zIndex)
			{
				return -1;
			}
			else if (instance1.zIndex > instance2.zIndex)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}

		// --------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// EVENT HANDLERS
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// GETTERS AND SETTERS
		//
		// --------------------------------------------------------------------------
		public function get instances(): Vector.<CAnimationFrameInstance>
		{
			return this._instances;
		}

		public function get frameNumber(): uint
		{
			return this._frameNumber;
		}
		public function get actions(): Vector.<CFrameAction>
		{
			return this._actions;
		}
	}
}
