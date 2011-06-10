package components
{
	import com.adobe.webapis.awss3.*;
	
	import flash.errors.EOFError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.formatters.DateFormatter;
	import mx.formatters.NumberFormatter;
	import mx.utils.StringUtil;

	[Event(name="objectDeleted",           type="com.adobe.webapis.awss3.AWSS3Event")]

	public class Movie extends EventDispatcher
	{
		private static var gDateExp:RegExp = /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/;
		private static var gSizeFormat:NumberFormatter = new NumberFormatter();
		private static var gTimeFormat:DateFormatter = new DateFormatter();
		
		public var txt:MetaS3Key;
		public var mp4:MetaS3Key;
		public var png:MetaS3Key;
		public var listing:Object;
		public var parts:Vector.<S3Object>;

		[Bindable]
		public var thumbnail:String;
		
		// download
		public var streamOut:FileStream = null
		public var downloadLocation:File = null;

		private var _errorFlag:Boolean = false;
		private var _doneFlag:Boolean = false;
		private var _startTime:Date;
		private var _kps:String;

		public static var s3errors:Array = [
			IOErrorEvent.IO_ERROR,
			AWSS3Event.ERROR,
			AWSS3Event.REQUEST_FORBIDDEN
		];
		
		public function get startTime():Date {
			return _startTime;
		}
		
		public function set errorFlag(v:Boolean):void {
			_errorFlag = v;
			dispatchEvent(new Event("download_change"));
			closeDownloadStream();
		}
		
		public function get errorFlag():Boolean {
			return _errorFlag;
		}
		
		public function set doneFlag(v:Boolean):void {
			_doneFlag = v;
			closeDownloadStream();
			dispatchEvent(new Event("download_change"));
		}
		
		public function get doneFlag():Boolean {
			return _doneFlag;
		}
		
		public function set startTime(d:Date):void {
			_startTime = d;
			dispatchEvent(new Event("download_change"));
		}
		
		[Bindable(event='download_change')]
		public function get elapsed():String {
			var newDate:Date = new Date();
		    var difSec:Number = Math.floor((newDate.getTime() - startTime.getTime()) / 1000);
		    var sec:int = difSec % 60;
		    var difMin:int = Math.floor(difSec/60);
		    var min:int = difMin % 60;
		    var difHours:int = Math.floor(difMin/60);
		    var hours:int = difHours % 24;
		    var s:String = sec.toString();
		    var m:String = min.toString();
		    var h:String = hours.toString();
		    if (sec < 10) {
		        s = "0" + s;
		    }
		    if (min < 10) {
		        m = "0" + m;
		    }
		    if (hours < 10) {
		        h = "0" + h;
		    }
		    return "" + h + " Hr " + m + " Min " + s + " Sec";
		}

		[Bindable(event='download_change')]
		public function get kps():String {
			if(streamOut == null)
				return _kps;
			var newDate:Date = new Date();
			var elapsedSec:Number = (newDate.getTime() - startTime.getTime()) / 1000;
			
			var bytesPerSec:Number = streamOut.position / elapsedSec;
			_kps = size_labelFunc(bytesPerSec) + "/s";
			return _kps;
		}

		[Bindable(event='download_change')]
		public function get action():String {
			if(streamOut == null)
				return doneFlag ? "Done!" : "Waiting...";
			if(errorFlag)
				return "ERROR";
			return "Downloading %3%%";
		}
		
		[Bindable(event='download_change')]
		public function get state():String {
			if(errorFlag) {
				return "error";
			} else if(doneFlag) {
				return "done";
			} else if(streamOut != null) {
				return "download";
			}
			return "hold";
		}

		public function openDownloadStreamAsync():FileStream {
			if (downloadLocation == null)
				return null;
			
			startTime = new Date();
			errorFlag = false;
			doneFlag = false;
			streamOut = new FileStream();
			streamOut.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, function(evt:Event):void {
				dispatchEvent(new Event("download_change"));
			});
			var f:File = downloadLocation.isDirectory ? downloadLocation.resolvePath(filename) : downloadLocation;
			streamOut.openAsync(f, FileMode.WRITE);
			dispatchEvent(new Event("download_change"));
			return streamOut;
		}
		
		public function closeDownloadStream():void {
			if (streamOut == null)
				return;
			
			streamOut.close();
			streamOut = null;
			downloadLocation = null;
			if(!errorFlag)
				doneFlag = true;
		}
		
		[Bindable(event='movieChanged')]
		public function get title():String {
			return listing["title"];
		}
		
		[Bindable(event='movieChanged')]
		public function get category():String {
			return listing["category"];
		}
		
		[Bindable(event='movieChanged')]
		public function get description():String {
			return listing["description"];
		}
		
		[Bindable(event='movieChanged')]
		public function get channel():String {
			return listing["channame"] + " " + listing["channum"];
		}
		
		[Bindable(event='movieChanged')]
		public function get host():String {
			return listing["hostname"];
		}
		
		[Bindable(event='movieChanged')]
		public function get record():String {
			return basename(txt.key);
		}
		
		[Bindable(event='movieChanged')]
		public function get stars():String {
			var v:Number = new Number(listing["stars"]);
			gSizeFormat.precision = 1;
		    return gSizeFormat.format(v * 4.0) + "/4";
		}
		
		[Bindable(event='movieChanged')]
		public function get subtitle():String {
			return listing["subtitle"] ? listing["title"] + " - " + listing["subtitle"] : listing["title"];
		}

		[Bindable(event='movieChanged')]
		public function get filename():String {
			var s:String = subtitle;
			s = s.replace(/:/mg, "-");
			return s + ".m4v";
		}

		[Bindable(event='movieChanged')]
		public function get url():String {
			return "";
		}
		
		static public function size_labelFunc(value:Number):String {
			gSizeFormat.precision = 2;
			gSizeFormat.useThousandsSeparator = true;

			if(value > 1024*1024*1024) {
				value /= 1024.0*1024.0*1024;
		    	return gSizeFormat.format(value) + " Gb";
		 	}
			else if(value > 1024*1024) {
				value /= 1024.0*1024.0;
		    	return gSizeFormat.format(value) + " Mb";
			} else if(value > 1024) {
				value /= 1024.0;
		    	return gSizeFormat.format(value) + " Kb";
			}
		    return gSizeFormat.format(value) + " bytes";
		}

		[Bindable(event='movieChanged')]
		public function get sizelabel():String {
		    return size_labelFunc(mp4.size);
		}
		
		private function parseDate(d:String):Date {
	        var reg:* = gDateExp.exec(d);
	        if(!reg)
	        	return new Date();
	        var year:Number = Number(reg[1]);
	        var month:Number = Number(reg[2]) - 1;
	        var day:Number = Number(reg[3]);
	        var hour:Number = Number(reg[4]);
	        var minute:Number = Number(reg[5]);
	        var sec:Number = Number(reg[6]);
	        
	        return new Date(year, month, day, hour, minute, sec);
		}
		
		[Bindable(event='movieChanged')]
		public function get starttime():Date {
	        return parseDate(listing['starttime']);
		}
		
		[Bindable(event='movieChanged')]
		public function get endtime():Date {
	        return parseDate(listing['endtime']);
		}
		
		[Bindable(event='movieChanged')]
		public function get totaltime():Number {
	        return endtime.getTime() - starttime.getTime();
		}
		
		[Bindable(event='movieChanged')]
		public function get totaltimestr():String {
			var d:Date = new Date();
			d.setTime(totaltime);
			var res:String = d.hoursUTC.toString() + ":";
			if(d.minutesUTC < 10)
				res += '0';
			res += d.minutesUTC.toString();
	        return res;
		}
		
		[Bindable(event='movieChanged')]
		public function get itouch():String {
			return listing["itouch"];
		}
		
		[Bindable(event='movieChanged')]
		public function get ipod():String {
			return listing["ipod"];
		}
		
		static public function basename(filename:String):String {
			var i:int = filename.lastIndexOf(".");
			if(i == -1)
				return filename;
			return filename.slice(0, i);
		}

		static public function extension(filename:String):String {
			var i:int = filename.lastIndexOf(".");
			if(i == -1)
				return "";
			return filename.slice(i);
		}

		static public function finds3(s3objects:Vector.<S3Object>, s:String):MetaS3Key {
			for each(var o:S3Object in s3objects) {
				if(o.key.toLowerCase() == s.toLowerCase())
					return new MetaS3Key(o.key, o.size, o.lastModified);
			}
			return null;
		}
		
		public function finds3parts(s3objects:Vector.<S3Object>, s:String):Number {
			parts = new Vector.<S3Object>();
			var r:RegExp = /^(?P<movie>\w+\.[A-Za-z0-9]+)_(?P<suffix>\d+)$/;
			var size:Number = 0;
			for each(var o:S3Object in s3objects) {
				var a:Array = r.exec(o.key);
				if(a && a["movie"] == s) {
					trace(o.key + ": " + int(a["suffix"]).toString());
					parts.push(o);
					size += o.size;
				}
			}
			parts.sort(function(a:S3Object, b:S3Object):Number {
				var a_ind:int = int(r.exec(a.key)["suffix"]);
				var b_ind:int = int(r.exec(b.key)["suffix"]);
				return a_ind < b_ind ? -1 : (a_ind > b_ind ? 1 : 0);
			});
			return size;
		}
		
		static public function getAllValidTxt(s3objects:Vector.<S3Object>):Vector.<S3Object> {
			var result:Vector.<S3Object> = new Vector.<S3Object>();
			
			for each(var o:S3Object in s3objects) {
				var base:String = basename(o.key);
				var ext:String = extension(o.key);
				
				if(ext.toLowerCase() != ".txt")
					continue;
				
				var mp4:MetaS3Key = finds3(s3objects, base + '.m4v')
				if(mp4 == null)
					mp4 = finds3(s3objects, base + '.mp4');
				if(mp4 == null)
					mp4 = finds3(s3objects, base + '.m4v' + "_000");
				
				var png1:MetaS3Key = finds3(s3objects, base + '.mpg.png')
				var png2:MetaS3Key = finds3(s3objects, base + '.nuv.png')
				
				if(mp4 == null || (png1 == null && png2 == null))
					continue;
				
				result.push(o);
			}
			return result;
		}

		static public function getCredentialS3Object(s3objects:Vector.<S3Object>):S3Object {
			for each(var o:S3Object in s3objects) {
				if(o.key == "credentials.txt")
					return o;
			}
			return null;
		}

		static public function getCategories(movies:Array):ArrayCollection {
			var result:ArrayCollection = new ArrayCollection();
			var categories:Array = new Array();
			
			for each(var m:Movie in movies) {
				var category:String = m.listing['category'];
				if(categories.hasOwnProperty(category))
					categories[category] += 1;
				else
					categories[category] = 1;
			}
			var names:Array = new Array();
			for(var c:String in categories) {
				names.push(c);
			}
			names.sort();
			
			result.addItem({name:"All", value:"All"});
			for each(var k:String in names) {
				var o:Object = {name:k + " (" + categories[k].toString() + ")", value:k};
				result.addItem(o);
			}
			return result;
		}

		static public function getTitles(movies:Array):ArrayCollection {
			var result:ArrayCollection = new ArrayCollection();
			var titles:Array = new Array();
			
			for each(var m:Movie in movies) {
				var title:String = m.listing['title'];
				if(titles.hasOwnProperty(title))
					titles[title] += 1;
				else
					titles[title] = 1;
			}
			var names:Array = new Array();
			for(var c:String in titles) {
				names.push(c);
			}
			names.sort();
			
			result.addItem({name:"All", value:"All"});
			for each(var k:String in names) {
				var o:Object = {name:k + " (" + titles[k].toString() + ")", value:k};
				result.addItem(o);
			}
			return result;
		}

		public function Movie(txt:S3Object, txtContent:File, s3objects:Vector.<S3Object>) {
			var fs:FileStream = new FileStream();
			fs.open(txtContent, FileMode.READ);
			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes);
			fs.close();

			var reader:ByteArrayReader = new ByteArrayReader(bytes);
			var base:String = basename(txt.key);

			listing = new Object();
			this.txt = new MetaS3Key(txt.key, txt.size, txt.lastModified);
			mp4 = finds3(s3objects, base + '.m4v');
			if(mp4 == null)
				mp4 = finds3(s3objects, base + '.mp4');
			if(mp4 == null) {
				mp4 = finds3(s3objects, base + '.m4v_000');
				if(mp4) {
					mp4.size = finds3parts(s3objects, base + '.m4v');
				}
			}
			png = finds3(s3objects, base + '.mpg.png');
			if(png == null)
				png = finds3(s3objects, base + '.nuv.png');
			//thumbnail = s3.getTemporaryObjectURL("aubonbeurre", png.key, 3600 * 24);		

			var pattern1:RegExp = /(.*)[\s]=[\s](.*)/i;
			var pattern2:RegExp = /(.*)[\s]=/i;
			var res:Array;
			var k:String;
			var v:String;
			try {
				while(1) {
					var line:String = reader.readLine();
					line = StringUtil.trim(line);
					k = null;
					v = null;
					
					res = pattern1.exec(line);
					if(res) {
						k = res[1];
						v = res[2];
					} else {
						res = pattern2.exec(line);
						if(res) {
							k = res[1];
							v = "";
						}
					}
					
					if(k != null && v != null) {
						if(listing.hasOwnProperty(k))
							k += "2";
						listing[k] = v;
					}
				}
			} catch(e:EOFError) {
				
			}			
		}
		
		//dispatchEvent(new Event("movieChanged"));
	}
}