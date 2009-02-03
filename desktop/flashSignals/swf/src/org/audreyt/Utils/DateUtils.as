package org.audreyt.Utils {
    public class DateUtils {
        static public function fromISO8601(string:String):Date {
            var regexp:String = "([0-9]{4})(-([0-9]{2})(-([0-9]{2})" +
                "([T ]([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]+))?)?" +
                "(Z|(([-+])([0-9]{2}):([0-9]{2})))?)?)?)?";
            var d:Array = string.match(new RegExp(regexp));
        
            var offset:Number = 0;
            var date:Date = new Date(d[1], 0, 1);
        
            if (d[3]) { date.setMonth(d[3] - 1); }
            if (d[5]) { date.setDate(d[5]); }
            if (d[7]) { date.setHours(d[7]); }
            if (d[8]) { date.setMinutes(d[8]); }
            if (d[10]) { date.setSeconds(d[10]); }
            if (d[12]) { date.setMilliseconds(Number("0." + d[12]) * 1000); }
            if (d[14]) {
                offset = (Number(d[16]) * 60) + Number(d[17]);
                offset *= ((d[15] == '-') ? 1 : -1);
            }
        
            offset -= date.getTimezoneOffset();
            var time:Number = (Number(date) + (offset * 60 * 1000));
            var newDate:Date = new Date();
            newDate.setTime(Number(time));
            return newDate;
        }
    	static private function prettyDateDelta(minutes:Number):String {
		    minutes = Math.abs(minutes);
		    if (minutes < 1) return "less than a minute";
		    if (minutes == 1) return "one minute";
		    if (minutes < 50) return String(minutes) + " minutes";
		    if (minutes < 90) return "about one hour";
		    if (minutes < 1080) return String(Math.round(minutes/60)) + " hours";
		    if (minutes < 1440) return "one day";
		    if (minutes < 2880) return "about one day";
		    return String(Math.round(minutes/1440)) + " days";
		}

		static public function getAgoString(string:String):String {
		    var now:Number = Number(new Date());
		    var then:Number = Number(fromISO8601(string));
    		var delta_minutes:Number = Math.floor((now-then) / (60 * 1000));
		    return prettyDateDelta(delta_minutes) + " ago";
		}
    }
}
