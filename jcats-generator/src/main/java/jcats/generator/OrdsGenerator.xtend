package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OrdsGenerator implements ClassGenerator {
	val Type type
		
	override className() { Constants.JCATS + "." + type.shortName("Ords") }

	def public static List<Generator> generators() {
		Type.values.toList.map[new OrdsGenerator(it) as Generator]
	}

	def ordShortName() { type.ordShortName }
	def ord() { (if (type == Type.OBJECT) ordShortName + "." + "<A>" else  "") + type.asc + "()" }
	def typeParam() { if (type == Type.OBJECT) "<A extends Comparable<A>> " else "" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		«IF type.primitive»
			import static «Constants.JCATS».«type.ordShortName».*;
		«ENDIF»

		public final class «name» {

			private «name»() {
			}

			public static «typeParam»boolean less(final «type.genericName» x, final «type.genericName» y) {
				return «ord».less(x, y);
			}

			public static «typeParam»boolean lessOrEqual(final «type.genericName» x, final «type.genericName» y) {
				return «ord».lessOrEqual(x, y);
			}

			public static «typeParam»boolean greater(final «type.genericName» x, final «type.genericName» y) {
				return «ord».greater(x, y);
			}

			public static «typeParam»boolean greaterOrEqual(final «type.genericName» x, final «type.genericName» y) {
				return «ord».greaterOrEqual(x, y);
			}

			public static «typeParam»boolean equal(final «type.genericName» x, final «type.genericName» y) {
				return «ord».equal(x, y);
			}

			«FOR i : 2 .. Constants.MAX_ARITY»
				public static «typeParam»«type.genericName» min(«(1..i).map['''final «type.genericName» value«it»'''].join(", ")») {
					return «ord».min(«(1..i).map['''value«it»'''].join(", ")»);
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «typeParam»«type.genericName» min(«(1..Constants.MAX_ARITY+1).map['''final «type.genericName» value«it»'''].join(", ")», final «type.genericName»... values) {
				return «ord».min(«(1..Constants.MAX_ARITY+1).map['''value«it»'''].join(", ")», values);
			}

			«FOR i : 2 .. Constants.MAX_ARITY»
				public static «typeParam»«type.genericName» max(«(1..i).map['''final «type.genericName» value«it»'''].join(", ")») {
					return «ord».max(«(1..i).map['''value«it»'''].join(", ")»);
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «typeParam»«type.genericName» max(«(1..Constants.MAX_ARITY+1).map['''final «type.genericName» value«it»'''].join(", ")», final «type.genericName»... values) {
				return «ord».max(«(1..Constants.MAX_ARITY+1).map['''value«it»'''].join(", ")», values);
			}
		}
	''' }
}