package pure ;

/**
 * ...
 * @author Shalmu
 */
@:build(pure.Pure.build()) class PureTest{

	//@pure var onlyFuncsCanBePure:Bool;
	public function new() {
		Main.log(PureTest.doSomething(2.5, 6.2));
	}

	@pure function doSomething(a:Float, b:Float) {
		var res = a * b, something = a / b; /// ok, making immutable variables
		var lala = OtherTest.anotherSomething(1); /// ok, OtherTest.anotherSomething() is pure
		var lala = somethingElse(res, 2.333); /// ok, somethingElse() is pure
		var lala = Math.pow(a, b); /// ok, Math.pow is pure
		var nana = String.fromCharCode(23); /// ok, String.fromCharCode is pure
		var dt = Date.fromTime(580447733345); /// ok, Date.fromTime is pure too
		var mi = dt.getFullYear() * lala; /// also ok, making immutable from pure and immutable
		var rand = Math.random(1.3); /// stops compilation with "Math.random doesn't look pure"
		var a = cannotUse * 2; /// stops with "You cannot use mutable variables from outsise"
		var b = canUse * 4; /// ok, using outside inline (const) var. If it was mutable, it would stop.
		var c = OtherTest.mutableVar; /// stops with "You cannot use mutable variables from outsise"
		var hash = haxe.crypto.Md5.encode('yo!'); /// alright, Md5.emcode is pure
		lala = 34; /// stops with "you cannot reassign vars in pure functions
		Date.now(); /// stops with "Date.now doesn't look pure
		res *= 34;/// stops, again was trying to set immutable
		res = 33; /// this one too
		switch(res){
			case 2.2: a = 44; /// stops, this one cannot compile!
			default: b = 23; /// stops, yeaaahh!!!
		}
		return a; /// stops with "do not use "return" keyword, the last expression will return anyway
		for (i in 0...100) var h = 2;/// stops with "You cannot use cycles in pure functions"
		while (a == 3) var h = 3;/// stops, can't use cycles!
		var no = false;
		var o = switch(no) {
			case false: 34;
			default: 88;
		}
		o/1000*mi; /// the last expression is returned without "return" word, because pure functions must return something, why bother with "return" keyword?
	}
	static var cannotUse = 23; /// declaring mutable var for tests.
	static inline var canUse = 33; /// declaring immutable
	
	/**
	 * Here goes another pure functon, I want to test in in the upper pure function.
	 * @param	a
	 * @param	b
	 */
	@pure function somethingElse(a:Float, b:Float) {
		var res = a / b;
		1.0001;
	}
}

/**
 * Another class with pure functions, to test it in "PureTest.doSomething"
 */
@:build(pure.Pure.build()) class OtherTest {
	public static var mutableVar = 22.22;
	@p function anotherSomething(v:Int) {
		v * 1.111111;
	}
}