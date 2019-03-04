package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OrdsGenerator implements ClassGenerator {
	val Type type

	override className() { Constants.JCATS + "." + type.shortName("Ords") }

	def static List<Generator> generators() {
		Type.values.toList.map[new OrdsGenerator(it) as Generator]
	}

	def ordShortName() { type.ordShortName }
	def ord() { (if (type == Type.OBJECT) ordShortName + "." + "<A>" else "") + type.asc + "()" }
	def typeParam() { if (type == Type.OBJECT) "<A extends Comparable<A>> " else "" }
	def methodName(String name) { type.shortName(name).firstToLowerCase }

	def minOrMax(boolean min) {
		val minOrMax = if (min) "min" else "max"
		val methodName = methodName(if (min) "Min" else "Max")
		val arrayMethodName = methodName(if (min) "ArrayMin" else "ArrayMax")
		val allMethodName = methodName(if (min) "AllMin" else "AllMax")
		'''
		«FOR i : 2 .. Constants.MAX_ARITY»
			public static «typeParam»«type.genericName» «methodName»(«(1..i).map['''final «type.genericName» value«it»'''].join(", ")») {
				return «ord».«minOrMax»(«(1..i).map['''value«it»'''].join(", ")»);
			}

		«ENDFOR»
		«IF type == Type.OBJECT»
			@SafeVarargs
		«ENDIF»
		public static «typeParam»«type.genericName» «methodName»(«(1..Constants.MAX_ARITY+1).map['''final «type.genericName» value«it»'''].join(", ")», final «type.genericName»... values) {
			return «ord».«minOrMax»(«(1..Constants.MAX_ARITY+1).map['''value«it»'''].join(", ")», values);
		}

		«IF type == Type.OBJECT»
			«FOR i : 2 .. Constants.MAX_ARITY»
				«FOR t : Type.values»
					«IF t == Type.OBJECT»
						public static <A, B extends Comparable<B>> A «minOrMax»By(final F<A, B> f, «(1..i).map['''final A value«it»'''].join(", ")») {
							return Ord.<B>asc().«minOrMax»By(f, «(1..i).map['''value«it»'''].join(", ")»);
					«ELSE»
						public static <A> A «minOrMax»By«t.typeName»(final «t.typeName»F<A> f, «(1..i).map['''final A value«it»'''].join(", ")») {
							return «t.javaName»Asc().«minOrMax»By(f, «(1..i).map['''value«it»'''].join(", ")»);
					«ENDIF»
					}

				«ENDFOR»
			«ENDFOR»
			«FOR t : Type.values»
				@SafeVarargs
				«IF t == Type.OBJECT»
					public static <A, B extends Comparable<B>> A «minOrMax»By(final F<A, B> f, «(1..Constants.MAX_ARITY+1).map['''final A value«it»'''].join(", ")», final A... values) {
						return Ord.<B>asc().«minOrMax»By(f, «(1..Constants.MAX_ARITY+1).map['''value«it»'''].join(", ")», values);
				«ELSE»
					public static <A> A «minOrMax»By«t.typeName»(final «t.typeName»F<A> f, «(1..Constants.MAX_ARITY+1).map['''final A value«it»'''].join(", ")», final A... values) {
						return «t.javaName»Asc().«minOrMax»By(f, «(1..Constants.MAX_ARITY+1).map['''value«it»'''].join(", ")», values);
				«ENDIF»
				}

			«ENDFOR»
		«ENDIF»
		public static «typeParam»«type.optionGenericName» «arrayMethodName»(final «type.genericName»[] values) {
			return «ord».array«IF min»Min«ELSE»Max«ENDIF»(values);
		}

		public static «typeParam»«type.optionGenericName» «allMethodName»(final Iterable<«type.genericBoxedName»> iterable) {
			return «ord».all«IF min»Min«ELSE»Max«ENDIF»(iterable);
		}
		«IF type == Type.OBJECT»

			public static <A, B extends Comparable<B>> Option<A> «arrayMethodName»By(final F<A, B> f, final A[] values) {
				return Ord.<B>asc().«arrayMethodName»By(f, values);
			}
			«FOR t : Type.primitives»

				public static <A> Option<A> «arrayMethodName»By«t.typeName»(final «t.typeName»F<A> f, final A[] values) {
					return «t.javaName»Asc().«arrayMethodName»By(f, values);
				}
			«ENDFOR»

			public static <A, B extends Comparable<B>> Option<A> «allMethodName»By(final F<A, B> f, final Iterable<A> values) {
				return Ord.<B>asc().«allMethodName»By(f, values);
			}
			«FOR t : Type.primitives»

				public static <A> Option<A> «allMethodName»By«t.typeName»(final «t.typeName»F<A> f, final Iterable<A> values) {
					return «t.javaName»Asc().«allMethodName»By(f, values);
				}
			«ENDFOR»
		«ENDIF»
	'''}

	override sourceCode() { '''
		package «Constants.JCATS»;

		import «Constants.FUNCTION».*;

		«IF type.primitive»
			import static «Constants.JCATS».«type.ordShortName».*;
		«ELSE»
			«FOR t : Type.primitives»
				import static «Constants.JCATS».«t.ordShortName».*;
			«ENDFOR»
		«ENDIF»

		public final class «name» {

			private «name»() {
			}

			public static «typeParam»Order «methodName("Order")»(final «type.genericName» x, final «type.genericName» y) {
				return «ord».order(x, y);
			}

			public static «typeParam»boolean «methodName("Less")»(final «type.genericName» x, final «type.genericName» y) {
				return «ord».less(x, y);
			}

			public static «typeParam»boolean «methodName("LessOrEqual")»(final «type.genericName» x, final «type.genericName» y) {
				return «ord».lessOrEqual(x, y);
			}

			public static «typeParam»boolean «methodName("Greater")»(final «type.genericName» x, final «type.genericName» y) {
				return «ord».greater(x, y);
			}

			public static «typeParam»boolean «methodName("GreaterOrEqual")»(final «type.genericName» x, final «type.genericName» y) {
				return «ord».greaterOrEqual(x, y);
			}

			public static «typeParam»boolean «methodName("Equal")»(final «type.genericName» x, final «type.genericName» y) {
				return «ord».equal(x, y);
			}

			«minOrMax(true)»

			«minOrMax(false)»
		}
	''' }
}