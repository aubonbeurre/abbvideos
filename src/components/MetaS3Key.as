package components
{
	import com.adobe.webapis.awss3.AWSS3Event;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	[Event(name="meta_changed")]

	public class MetaS3Key extends EventDispatcher
	{
		private var _key:String;
		private var _size:Number;
		private var _lastModified:Date;
		
		public function MetaS3Key(key:String, size:Number, lastModified:Date)
		{
			super();
			
			_key = key;
			_size = size;
			_lastModified = lastModified;
			
			//dispatchEvent(new Event("meta_changed"));
		}
		
		[Bindable(event='meta_changed')]
		public function get key():String {
			return _key;
		}
		
		[Bindable(event='meta_changed')]
		public function get size():Number {
			return _size;
		}
		public function set size(s:Number):void {
			_size = s;
			this.dispatchEvent(new Event("meta_changed"));
		}
		
		[Bindable(event='meta_changed')]
		public function get lastModified():Date {
			return _lastModified;
		}
	}
}
