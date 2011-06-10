package components
{
	import com.adobe.webapis.awss3.AWSS3Event;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.Dictionary;
	import flash.utils.IDataOutput;
	
	import mx.controls.Alert;

	[Bindable] 
	public class S3Queue
	{
		[Embed(source="icons/dialog-error.png")]
		private var errorIcon:Class;
	
		public var _onError:Function;
		
		private var OnFileDownloaded:Function = null;
		private var _s3Dict:Dictionary;

		public function S3Queue(callback:Function, onerror:Function) {
			OnFileDownloaded = callback;
			_onError = onerror != null ? onerror : function(e:Event) : void {trace(e.toString())};
			_s3Dict = new Dictionary();
		}

		public function download_stream(m:Movie):void {
			_s3Dict[m] = new S3();
			_s3Dict[m]._m = m;
			_s3Dict[m]._mindex = -1;
			_s3Dict[m]._mstream = m.openDownloadStreamAsync();
			
			for each(var err:String in S3.s3errors) {
				_s3Dict[m].addEventListener(err, _onFileDownloadedError);
			}
			
			_s3Dict[m].addEventListener(ProgressEvent.PROGRESS, _onFileProgress);
			_s3Dict[m].addEventListener(AWSS3Event.OBJECT_RETRIEVED_STREAM, _onFileDownloadedStream);
			
			if(m.parts) {
				_s3Dict[m]._mindex = 0;
				_s3Dict[m].getObjectStream("aubonbeurre", m.parts[0].key, _s3Dict[m]._mstream);
			}
			else
				_s3Dict[m].getObjectStream("aubonbeurre", m.mp4.key, _s3Dict[m]._mstream);
		}

		public function queue():Array {
			var res:Array = [];
			for(var m:* in _s3Dict) {
				res.push(m);
			}
			return res;
		}
		
		private function _onFileProgress(e:ProgressEvent):void
		{
			var m:Movie = e.currentTarget._m;
			var mindex:int = e.currentTarget._mindex;
			if(mindex != -1) {
				e = e.clone() as ProgressEvent;
				for(var i:int = 0; i < mindex; ++i) {
					e.bytesLoaded += m.parts[i].size;					
				}
				e.bytesTotal = m.mp4.size;
			}
			m.dispatchEvent(e);
		}
		
		private function _onFileDownloadedStream(e:AWSS3Event):void
		{
			var m:Movie = e.currentTarget._m;
			var mindex:int = e.currentTarget._mindex;
			
			if(mindex != -1 && mindex+1 < m.parts.length) {
				mindex += 1;
				e.currentTarget._mindex = mindex;
				_s3Dict[m].getObjectStream("aubonbeurre", m.parts[mindex].key, _s3Dict[m]._mstream);
				return;
			}
			
			delete _s3Dict[m];
			
			if(OnFileDownloaded != null)
				OnFileDownloaded(m);
		}

		private function _onFileDownloadedError(e:Event):void
		{
			_onError(e);

			var m:Movie = e.currentTarget._m;
			delete _s3Dict[m];
			m.errorFlag = true;
		}
	}
}