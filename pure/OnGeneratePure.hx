package pure;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import pure.Pure.Warning;
/**
 * ...
 * @author Shalmu
 */
class OnGeneratePure {
	public function new(types:Array<Type>) {
		Pure.initWarnings();
		hTypeA(types);
		Pure.dumpWarnings();
	}
	var warnings:Array<Warning>;
	function warn(msg:Dynamic, pos:Position) 
		Pure.warn(msg, pos);
	function dumpWarnings() {
		if (warnings.length > 0) {
				for (w in warnings)
					Context.warning(w.msg, w.pos);
				Context.fatalError('*** Unable to compile due to errors above', Context.currentPos());
		}
	}
	
	
	
	
		
		
		
		
		
		
		
		
		
		
		
		
		
	function hTypeA(a) 	Lambda.iter(a, hType);

	
	function hType(t:Type) 
		switch (t) {
			case TInst(c, _):
				hClass(c.get());
			case _:
		}
	function hClass(c:ClassType) {
				// Iterate over all member fields.
				for (cf in c.fields.get()) {
					hField(cf);
				}
				// Iterate over all static fields.
				for (cf in c.statics.get()) {
					hField(cf);
				}
				// Handle the constructor if available.
				if (c.constructor != null) {
					hField(c.constructor.get());
				}
	}
	
	function metaHasPure(m:MetaAccess) 
		return m.has(Pure.pureStr1) || m.has(Pure.pureStr2);
		
		
	function hField(cf:ClassField) 
		if (metaHasPure(cf.meta)) 
			switch(cf.type) {
				case TFun(args, ret):
					//warn(Std.string(cf.name)+', kind:'+Std.string(cf.kind), cf.pos);
					var expr = cf.expr();
					if (expr != null) {
						//onlyPure = false;
						hExpr(expr);
					}
				default:
					warn('only functions can be pure, but this is not a function', cf.pos);
			}
		
	
	function hFunc(f:TFunc) {
		for (a in f.args)
			hVar(a.v);
		hType(f.t);
		hExpr(f.expr);
	}
	function hVar(v:TVar) {	
		//warn('VAR: ' + Std.string(v.name), currentE.pos);
		if(v.extra!=null){
			hExpr(v.extra.expr);		
			hParamArr(v.extra.params);	
		}
		hType(v.t);
	}
	var currentE:TypedExpr;
	function hParam(p:TypeParameter) 		
		hType(p.t);	
	function hFields(fields:Array<{name:String, expr:TypedExpr}>) 
		for (f in fields) hExpr(f.expr); 
	function hParamArr(p:Array<TypeParameter>) 		
		Lambda.iter(p, hParam);	
	function hExprA(a:Array<TypedExpr>) 		
		Lambda.iter(a, hExpr);	
	function hExpr(E:TypedExpr) {	
		if (E == null) return;
		currentE = E;
		switch(E.expr) {
			case TLocal(v): 												hVar(v); 
			case TArray(e1, e2): 										hExpr(e1); hExpr(e2);
			case TBinop(op, e1, e2): hExpr(e1); 		hExpr(e2); 
			case TField(e, fa): 										
				handleTField(E, e, fa);  hExpr(e);
			case TParenthesis(e): 									hExpr(e);
			case TObjectDecl(fields): 							hFields(fields);				
			case TArrayDecl(el): 										hExprA(el);
			case TCall(e, el): 											
				//warn('Call! ' + Std.string(E.expr), E.pos);							
				//handleCall(E, e, el);
				/// need those anyway, because inner things might contain smth else too:
				hExpr(e); hExprA(el);
			case TUnop(op, postFix, e):							hExpr(e);
			case TFunction(f):											hFunc(f);
			case TVar(v, expr):				
					
			hVar(v); hExpr(expr);
			case TBlock(el):												hExprA(el);
			case TFor(v, e1, e2):
				noCyclesWarn(E);							
																							hVar(v); hExprA([e1, e2]);
			case TIf(econd, eif, eelse):		hExprA([econd, eif, eelse]);
			case TWhile(econd, e, normalWhile):
				noCyclesWarn(E);
																							hExprA([econd, e]);
			case TSwitch(e, cases, edef):
				hExpr(e); 
				for (c in cases) {
					hExprA(c.values);
					hExpr(c.expr);
				}
				hExpr(edef);
			case TTry(e, catches):
				hExpr(e); 
				for (c in catches) {
					hVar(c.v);
					hExpr(c.expr);
				}
			case TReturn(e):												hExpr(e);
			case TThrow(e): 												hExpr(e);
			case TCast(e, m):												hExpr(e);
			case TMeta(m, e1):											hExpr(e1);
			case TEnumParameter(e1, ef, index):			hExpr(e1); 
			default:
		}

	}
	function handleBinop(E:TypedExpr, callE:TypedExpr, callE2:Array<TypedExpr>) {
		
	}

	function handleTField(E:TypedExpr, e:TypedExpr, fa:FieldAccess) {
		switch(E.t) {
			case TFun(args, ret):
				switch(fa) {
					case FStatic(c, cf):						
						var hasPure = metaHasPure(cf.get().meta);
						if (!hasPure) {
							/// this field has no @pure meta, therefore let's test it for 
							var cl = c.get();
							//warn(c.toString(), E.pos);
							var className = cl.module;// +'.' + cl.name;
							var fn = cf.get().name;
							//warn(className+'/'+fn, E.pos);							
							var res = Pure.libCalls.isPure(className, fn, true);
							if (!res || res == null)
								Pure.notPureCallError(className, fn, E);
						}
					default:
				}
			default:
				warn('You cannot use mutable variables from outside', E.pos);
		}
	}
	
	function noCyclesWarn(E:TypedExpr) 
		warn('You cannot use cycles in pure functions.', E.pos);	

	
}

