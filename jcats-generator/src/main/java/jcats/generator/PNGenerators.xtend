package jcats.generator

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import java.util.Collections

final class PNGenerators {
	def static List<Generator> generators() {
		(3 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	def static fullName(int arity) { Constants.P + arity }
	def static shortName(int arity) { if (arity == 2) "P" else "P" + arity }
	def static parameters(int arity) { '''<«(1 .. arity).map["A" + it].join(", ")»>''' }

	private def static Generator generator(int arity) {
		new ClassGenerator {
			private val shortName = shortName(arity)

			override className() { fullName(arity) }

			override sourceCode() { '''
				package «Constants.JCATS»;

				import java.io.Serializable;
				import «Constants.F»;
				import «Constants.F»«arity»;

				import static java.util.Objects.requireNonNull;

				public final class «shortName»«parameters(arity)» implements Equatable<«shortName»«parameters(arity)»>, Serializable {
					«FOR i : 1 .. arity»
						private final A«i» a«i»;
					«ENDFOR»

					private «shortName»(«(1 .. arity).map["final A" + it + " a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
					}

					«FOR i : 1 .. arity»
						public A«i» get«i»() {
							return a«i»;
						}

					«ENDFOR»
					«FOR i : 1 .. arity»
						public <B> «shortName»<«(1 .. arity).map[if (it == i) "B" else "A" + it].join(", ")»> set«i»(final B value) {
							return new «shortName»<>(«(1 .. arity).map[if (it == i) '''requireNonNull(value)''' else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public <B> B match(final F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> f) {
						final B b = f.apply(«(1 .. arity).map["a" + it].join(", ")»);
						return requireNonNull(b);
					}

					«FOR i : 1 .. arity»
						public <B> «shortName»<«(1 .. arity).map[if (it == i) "B" else "A" + it].join(", ")»> map«i»(final F<A«i», B> f) {
							final B b = f.apply(a«i»);
							return new «shortName»<>(«(1 .. arity).map[if (it == i) "requireNonNull(b)" else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public «shortName»<«(arity .. 1).map["A" + it].join(", ")»> reverse() {
						return new «shortName»<>(«(arity .. 1).map["a" + it].join(", ")»);
					}

					public static «parameters(arity)» «shortName»«parameters(arity)» «shortName.toLowerCase»(«(1 .. arity).map["final A" + it + " a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							requireNonNull(a«i»);
						«ENDFOR»
						return new «shortName»<>(«(1 .. arity).map["a" + it].join(", ")»);
					}

					/**
					 * Synonym for {@link #«shortName.toLowerCase»}
					 */
					public static «parameters(arity)» «shortName»«parameters(arity)» of(«(1 .. arity).map["final A" + it + " a" + it].join(", ")») {
						return «shortName.toLowerCase»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					@Override
					public int hashCode() {
						int result = 1;
						«FOR index : 1 .. arity»
							result = 31 * result + a«index».hashCode();
						«ENDFOR»
						return result;
					}

					@Override
					public boolean equals(final Object obj) {
						if (obj == this) {
							return true;
						} else if (obj instanceof «shortName»<«Collections.nCopies(arity, "?").join(", ")»>) {
							final «shortName»<«Collections.nCopies(arity, "?").join(", ")»> «shortName.toLowerCase» = («shortName»<«Collections.nCopies(arity, "?").join(", ")»>) obj;
							return a1.equals(«shortName.toLowerCase».a1)
								«FOR index : 2 .. arity»
									&& a«index».equals(«shortName.toLowerCase».a«index»)«IF index == arity»;«ENDIF»
								«ENDFOR»
						} else {
							return false;
						}
					}

					@Override
					public String toString() {
						return "(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";
					}

					«cast((1 .. arity).map["A" + it], #[], (1 .. arity).map["A" + it])»
				}
			''' }		
		}
	}
}