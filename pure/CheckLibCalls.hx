package pure;
import haxe.ds.StringMap;

/**
 * This class checks for standard library functions, which cannot contain @pure meta, and therefore
 * must be listed. If they are not listed, it DOES NOT throw any error.
 * @author Shalmu
 */

 

class CheckLibCalls{

	public function new() {
		init();
	}
	function init() {
		inf = new StringMap();
		var data = LibPureFuncsList.data;
		for (d in data) {
			var pc:ParsedClass = { yes:null, no:null };
			if (!empty(d.no)) 
				pc.no = initParseMethods(d.no);
			if (!empty(d.yes)) 
				pc.yes = initParseMethods(d.yes);
			inf.set(d.c, pc);
		}
	}
	function initParseMethods(s:String) {
		var arr = s.split(',');
		var r = new StringMap<Bool>();
		Lambda.iter(arr, function(a) {
			r.set(StringTools.trim(a), true);
		});
		return r;
	}
	/**
	 * ckecks if this functinon Haxe built-in function and pure.
	 * @param	className class name, which contains the function. Package must be here too (sep. by dot)
	 * @param	funcName function name
	 * @param	staticCall is this call static?
	 * @return true if it's pure, false if it's not pure, null if not found in standard library
	 */
	public function isPure(className:String, funcName:String, staticCall:Null<Bool>):Null<Bool> {
		return 
			if (!inf.exists(className)) {
				null;
			}else {
				var c = inf.get(className);
				if (c.yes != null)
					c.yes.exists(funcName);
				else if (c.no != null)
					!c.no.exists(funcName);
				else
					true;
			}
	}
	function empty(s:String) return s == '' || s == null;
	var inf:StringMap<ParsedClass>;

}

typedef ParsedClass = {
	yes:StringMap<Bool>,
	no:StringMap<Bool>,
}





