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

			override sourceCode() { '''
				package «Constants.FUNCTION»;

				import static java.util.Objects.requireNonNull;

				@FunctionalInterface
				public interface Eff«arity»<«(1 .. arity).map["A" + it].join(", ")»> {
					void apply(«(1 .. arity).map["final A" + it + " a" + it].join(", ")»);

					«FOR i : 1 .. arity»
						default <B> Eff«arity»<«(1 .. arity).map[(if (it == i) "B" else "A" + it)].join(", ")»> contraMap«i»(final F<B, A«i»> f) {
							requireNonNull(f);
							return («(1 .. arity).map[if (it == i) "b" else "a" + it].join(", ")») -> {
								«FOR j : 1 .. arity»
									requireNonNull(«if (i == j) "b" else "a" + j»);
								«ENDFOR»
								final A«i» a«i» = requireNonNull(f.apply(b));
								apply(«(1 .. arity).map["a" + it].join(", ")»);
							};
						}

					«ENDFOR»
					«IF arity == 2»
						default Eff2<A2, A1> flip() {
							return (a2, a1) -> {
								requireNonNull(a1);
								requireNonNull(a2);
								apply(a1, a2);
							};
						}

					«ENDIF»
					«cast((1 .. arity).map["A" + it], (1 .. arity).map["A" + it], #[])»
				}

			''' }		
		}
	}
}