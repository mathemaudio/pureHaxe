package pure;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * 
 * To enable pure functions, do this:
	 1. Add this line to your hxml:
					--macro pure.Pure.p()
	 2. Add this before class declaration, which will contain pure functions:
		  @:build(pure.Pure.build()) class YourClass{...}
	 3. Put "@pure" or "@p" meta tag before your pure function, like so:
		  @pure function doSomething(a:Float, b:Float){...}
		What is going to happen then:
		Each pure functions will:
			* make the function static and public
			* return the last expression and won't allow you to use "return" keyword
			* make each variable immutable, i.e. you won't be able to change it once it's created
			* won't let you use loops (like "for" or "while")
			* won't allow you to use outer mutable variables.
			* will make sure that all functions, called within this pure function are pure too.
						for example it will let you use "Math.sin" and "Math.cos", but will throw error
						if you try to use "Math.random"
 * 
 * 
 * @author Shalmu
 */

typedef Warning = {	msg:String,	pos:Position, }
 
class Pure{

	
	
	public static var libCalls(default, null):CheckLibCalls;
	public static inline var pureStr1 = 'pure';
	public static inline var pureStr2 = 'p';
	/**
	 * @return
	 */
	static function initLibCalls() {
		libCalls = new CheckLibCalls();
	}
  macro static public function build():Array<Field> {
		initLibCalls();
		initWarnings();
		
    var fields = Context.getBuildFields();
		for (f in fields) {
			switch(f.kind) {
				case FFun(fnc):
					/// find if any of meta is "pure":
					var pure = false;
					for (m in f.meta) 
						if (m.name==pureStr1 || m.name==pureStr2) {
							pure = true;
							break;
						}
					if (pure) {
						/// test for variables, if they are really constants:
						switch(fnc.expr.expr) {
							case EBlock(exs): checkFuncBody(exs);
							default: checkFuncBody([fnc.expr]);
						}
						/// make it return its contents:
						fnc.expr = { expr:EReturn(fnc.expr), pos:Context.currentPos() };
						/// make it public and static:
						f.access = [APublic, AStatic];
					}
				default:
					//warn('Kind is unknown: '+Std.string(f.kind), f.pos);
			}
		}

		dumpWarnings();
    return fields;
  }
	
	
	public static function initWarnings() {
		warnings = [];
	}
	public static function dumpWarnings() {
		if (warnings.length > 0) {
				for (w in warnings)
					Context.warning(w.msg, w.pos);
				Context.fatalError('*** Unable to compile due to errors above', Context.currentPos());
		}
	}
	static var s = [];
	static var warnings:Array<Warning>;
	static function checkFuncBody(exs:Array<Expr>) {
		createdVars = new Map();
		checkExpr(exs);
	}
	
	static var createdVars:Map<String, Var>;
	static function chExpr1(e:Expr) if(e!=null)checkExpr([e]);
	static function checkExpr(exs:Array<Expr>) {
		for (e in exs)
		if (e != null) {
			switch(e.expr) {
				case EReturn(what):
					warn('do not use "return" keyword, the last expression is returned anyway!', e.pos);
				case EVars(vars):
					for (v in vars) {
						createdVars.set(v.name, v);
						chExpr1(v.expr);
					}
				case ECall(b, a):
					checkCall(b);
					checkExpr(a);
				case EBinop(op, e1, e2):				
					checkExpr([e1, e2]);
					/// here we test for assignment:
					switch(op) {
						case OpAssign:
							assignError(e);
						case OpAssignOp(op2):
							assignError(e);
						default:
					}
				case _:
					ExprTools.iter(e, chExpr1);
			}
		}
	}
	
	static function checkCall(e:Expr) {
		switch(e.expr) {
			case EField(fe, fld):
				switch(fe.expr) {
					case EConst(c):
						switch(c) {
							case CIdent(s):
								var staticCall = true;
								var classN = s;
								if (createdVars.exists(s)) {
									staticCall = false;
									classN = getClassName(createdVars.get(s));
								}																
								if (!allowedPureLib(classN, fld, staticCall))
									notPureCallError(classN, fld, e);
							default:
						}						
					case EField(fe2, fld2):
						//getPathToEField(fe);
						var path = ExprTools.toString(e);
						if (path.indexOf('.') != -1) {
							var arr = path.split('.');
							var fn = arr.pop();
							var classN = arr.join('.');
							//if (!allowedPureLib(classN, fl, staticCall))
								//notPureCallError(classN, fld, e);
						}
					default:
						warn('I dunno expression: ' + Std.string(fe.expr), fe.pos);
				}
			case EConst(c):
				switch(c) {
					case CIdent(s):
						var loc = Context.getLocalClass();
						if (loc != null) {
							var clType:ClassType = loc.get();
						}else {
							warn('I dunno, loc is null:', e.pos);
						}
						
					default:
						warn('I dunno EConst enum: ' + Std.string(c), e.pos);
				}
			default:
				warn('I dunno call type: ' + Std.string(e), e.pos);
		}
	}
	static function getPathToEField(e:Expr) {
		
	}
	static function getClassName(v:Var) {
		if (v.type != null) {
			switch(v.type) {
				case TPath(p):
					return (p.pack.length>0?(p.pack.join('.')+'.'):'')+p.name;
				default:
			}
		}
		switch(v.expr.expr) {
			case ECall(e, params):
				switch(e.expr) {
					case EField(fe, fld):
						switch(fe.expr) {
							case EConst(c):
								switch(c) {
									case CIdent(s):
										return s;
									default:
								}
							default:
						}
					default:
				}
			default:
		}
		return 'a';
	}
	
	static function allowedPureLib(className:String, funcName:String, staticCall:Bool) {
		var r = libCalls.isPure(className, funcName, staticCall);
		return r == null || r;
	}
	
	
	static function assignError(e) {
		warn( 'You can not reassign vars in pure functions',e.pos);
	}
	public static function notPureCallError(className, funcName, e) {
		warn( '"' + className+'.' + funcName+'" doesn\'t look pure. If it is your func, '
																		+'then put @pure before it. If it is lib func and you are sure it is pure, add it to the "LibPureFuncsList" please.', e.pos);
	}
	
	public static function warn(msg:String, pos:Position) {
		warnings.push( { msg:msg, pos:pos } );
	}
	
	
	
	
	
	/// for a full check, put it into the hxml:
	/// --macro pure.Pure.p()
	static public function p() {
		initLibCalls();
		Context.onGenerate(checkPureCalls);
	}
	static function checkPureCalls(types:Array<Type>) {
		new OnGeneratePure(types);
	}	
}

























