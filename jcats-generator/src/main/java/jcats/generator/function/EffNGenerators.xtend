package jcats.generator.function

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator

final class EffNGenerators {
	def static List<Generator> generators() {
		(3 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	private def static Generator generator(int arity) {
		new InterfaceGenerator {
			override className() { Constants.EFF + arity }

			def params() { '''<«(1 .. arity).map["A" + it].join(", ")»>''' }

			override sourceCode() { '''
				package «Constants.FUNCTION»;

				import «Constants.JCATS».*;

				import static java.util.Objects.requireNonNull;

				@FunctionalInterface
				public interface Eff«arity»<«(1 .. arity).map["@Contravariant A" + it].join(", ")»> {
					void apply(«(1 .. arity).map["final A" + it + " a" + it].join(", ")»);

					«FOR i : 1 .. arity»
						default <B> Eff«arity»<«(1 .. arity).map[(if (it == i) "B" else "A" + it)].join(", ")»> contraMap«i»(final F<B, A«i»> f) {
							requireNonNull(f);
							return («(1 .. arity).map[if (it == i) "final B b" else '''final A«it» a«it»'''].join(", ")») -> {
								«FOR j : 1 .. arity»
									requireNonNull(«if (i == j) "b" else "a" + j»);
								«ENDFOR»
								final A«i» a«i» = requireNonNull(f.apply(b));
								apply(«(1 .. arity).map["a" + it].join(", ")»);
							};
						}

					«ENDFOR»
					default Eff«arity»<«(arity .. 1).map["A" + it].join(", ")»> reverse() {
						return («(arity .. 1).map['''final A«it» value«it»'''].join(", ")») -> {
							«FOR i : arity .. 1»
								requireNonNull(value«i»);
							«ENDFOR»
							apply(«(1 .. arity).map["value" + it].join(", ")»);
						};
					}

					«FOR i : 1 .. arity»
						default Eff«arity-1»<«(1 .. arity).filter[it != i].map['''A«it»'''].join(", ")»> apply«i»(final A«i» value«i») {
							requireNonNull(value«i»);
							return («(1 .. arity).filter[it != i].map['''final A«it» value«it»'''].join(", ")») -> {
								«FOR j : 1 .. arity»
									«IF j != i»
										requireNonNull(value«j»);
									«ENDIF»
								«ENDFOR»
								apply(«(1 .. arity).map['''value«it»'''].join(", ")»);
							};
						}

					«ENDFOR»
					static «params» Eff«arity»«params» eff«arity»(final Eff«arity»«params» eff) {
						return requireNonNull(eff);
					}

					static «params» Eff«arity»«params» doNothing() {
						return («(1 .. arity).map['''final A«it» value«it»'''].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(value«i»);
							«ENDFOR»
						};
					}

					«cast((1 .. arity).map["A" + it], (1 .. arity).map["A" + it], #[])»
				}

			''' }		
		}
	}
}