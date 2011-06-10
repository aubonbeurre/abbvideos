package components
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class MetaEventDispatcher extends EventDispatcher
	{
		private var completeEvts:Array;
		private var errorEvents:Array;
		public var targets:Array;
		
		/**
		 * Monitor dispatcher targets, for the particular event
		 * 
		 * @param completeEvt: the event to monitor
		 * @param errorEvents: a list of events that are re-broadcast
		 */
		public function MetaEventDispatcher(completeEvts:*, errorEvents:Array=null)
		{
			super();
			
			this.completeEvts=completeEvts is Array ? completeEvts : [completeEvts];
			this.errorEvents=errorEvents != null ? errorEvents : new Array();
			targets = new Array();
		}

		/**
		 * Register a target to monitor. When all events arrived (see the Constructor),
		 * the function will trigger the event
		 */
		public function add_target(target:IEventDispatcher) : void {
			targets.push({target:target, complete:false});
			for each(var completeEvt:String in completeEvts) {
				target.addEventListener(completeEvt, onComplete);
			}
			for each(var s:String in errorEvents) {
				target.addEventListener(s, onError);
			}
		}
		
		private function find_target(target:IEventDispatcher) : Object {
			for each(var o:Object in targets) {
				if(o.target == target)
					return o;
			}
			throw new Error("could not find target");
			return null;
		}
		
		private function num_complete(): uint {
			var cnt:uint = 0;
			for each(var o:Object in targets) {
				if(o.complete)
					cnt += 1;
			}
			trace("Complete " + cnt.toString() + "/" + targets.length.toString());
			return cnt;
		}
		
		private function removeListeners():void {
			for each(var o:Object in targets) {
				for each(var completeEvt:String in completeEvts) {
					o.target.removeEventListener(completeEvt, onComplete);
				}
				for each(var s:String in errorEvents) {
					o.target.removeEventListener(s, onError);
				}
			}
		}

		private function onComplete(evt:Event): void {
			var o:Object = find_target(evt.target as IEventDispatcher);
			o.complete = true;
			num_complete();
			for each(o in targets) {
				if(!o.complete) {
					//evt.stopImmediatePropagation();
					return;
				}
			}
			this.dispatchEvent(evt);
			//removeListeners();
		}

		private function onError(evt:Event): void {
			this.dispatchEvent(evt);
			//removeListeners();
		}
	}
}