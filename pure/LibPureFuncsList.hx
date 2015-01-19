package pure;

/**
 * ...
 * @author Shalmu
 */
typedef LibClass = {
	c:String,/// class name,
	?yes:String,/// the list of pure functions and constant fields. If null - all are pure, except for "no". Separated by comma.
	?no:String, /// list of inpure functions, in case if most of funcs in this class are pure.	
	/// if both "yes" and "no" are empty - all functions of this class are pure. Separated by comma.
}


 
 
class LibPureFuncsList{

	public static var data:Array<LibClass> = [
		{c:'Math', no:'random'},
		{c:'Date', no:'now' },
		{c:'String', yes:'fromCharCode' },
		{c:'Lambda' },
		{c:'haxe.crypto.Md5', yes:'make,encode' },
		
	]; 		
}