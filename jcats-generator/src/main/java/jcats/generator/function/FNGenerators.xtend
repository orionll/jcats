package jcats.generator.function

import com.google.common.collect.Iterables
import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator

final class FNGenerators {
	def static List<Generator> generators() {
		(2 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	private def static Generator generator(int arity) {
		new InterfaceGenerator {
			override className() { Constants.F + arity }

			override sourceCode() { '''
				package «Constants.FUNCTION»;

				«IF arity == 2»
				import java.util.function.BiFunction;

				«ENDIF»
				import static java.util.Objects.requireNonNull;
				import static «Constants.F».id;

				@FunctionalInterface
				public interface F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> {
					B apply(«(1 .. arity).map["final A" + it + " a" + it].join(", ")»);

					default <C> F«arity»<«(1 .. arity).map["A" + it + ", "].join»C> map(final F<B, C> f) {
						requireNonNull(f);
						return («(1 .. arity).map["a" + it].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
							final B b = requireNonNull(apply(«(1 .. arity).map["a" + it].join(", ")»));
							return requireNonNull(f.apply(b));
						};
					}

					«FOR i : 1 .. arity»
						default <C> F«arity»<«(1 .. arity).map[(if (it == i) "C" else "A" + it) + ", "].join»B> contraMap«i»(final F<C, A«i»> f) {
							requireNonNull(f);
							return («(1 .. arity).map[if (it == i) "c" else "a" + it].join(", ")») -> {
								«FOR j : 1 .. arity»
									requireNonNull(«if (i == j) "c" else "a" + j»);
								«ENDFOR»
								final A«i» a«i» = requireNonNull(f.apply(c));
								return requireNonNull(apply(«(1 .. arity).map["a" + it].join(", ")»));
							};
						}

					«ENDFOR»
					«IF arity == 2»
						default F2<A2, A1, B> flip() {
							return (a2, a1) -> {
								requireNonNull(a1);
								requireNonNull(a2);
								return requireNonNull(apply(a1, a2));
							};
						}
					«ENDIF»

					«FOR i : 1 ..< arity»
						default «curryReturnType(i, arity)» curry«if (i == 1) "" else i»() {
							return a1 -> {
							«FOR j : 1 ..< i»
								«(1 .. j).map["\t"].join»requireNonNull(a«j»);
								«(1 .. j).map["\t"].join»return a«j + 1» -> {
							«ENDFOR»
							«(1 .. i).map["\t"].join»requireNonNull(a«i»);
							«(1 .. i).map["\t"].join»return («(i + 1 .. arity).map['''a«it»'''].join(", ")») -> {
								«FOR j : i + 1 .. arity»
									«(1 .. i).map["\t"].join»requireNonNull(a«j»);
								«ENDFOR»
								«(1 .. i).map["\t"].join»return requireNonNull(apply(«(1 .. arity).map['''a«it»'''].join(", ")»));
							«(1 .. i).map["\t"].join»};
							«FOR j : 1 .. i»
								«(1 ..< i - j + 1).map["\t"].join»};
							«ENDFOR»
						}

					«ENDFOR»
					default <C> F«arity»<«(1 .. arity).map["A" + it + ", "].join»C> flatMap(final F<B, F«arity»<«(1 .. arity).map["A" + it + ", "].join»C>> f) {
						requireNonNull(f);
						return («(1 .. arity).map["a" + it].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
							final B b = requireNonNull(apply(«(1 .. arity).map["a" + it].join(", ")»));
							return requireNonNull(f.apply(b).apply(«(1 .. arity).map["a" + it].join(", ")»));
						};
					}

					default Eff«arity»<«(1 .. arity).map["A" + it].join(", ")»> toEff() {
						return («(1 .. arity).map["a" + it].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
							apply(«(1 .. arity).map["a" + it].join(", ")»);
						};
					}
					«IF arity == 2»

						default BiFunction<A1, A2, B> toBiFunction() {
							return (a1, a2) -> {
								requireNonNull(a1);
								requireNonNull(a2);
								return requireNonNull(apply(a1, a2));
							};
						}
					«ENDIF»

					«joinMultiple((1 .. arity).map["A" + it], "B")»
					«IF arity == 2»

						static <A1, A2, B> F2<A1, A2, B> biFunctionToF2(final BiFunction<A1, A2, B> f) {
							requireNonNull(f);
							return (a1, a2) -> {
								requireNonNull(a1);
								requireNonNull(a2);
								return requireNonNull(f.apply(a1, a2));
							};
						}
					«ENDIF»

					«cast(Iterables.concat((1 .. arity).map["A" + it], #["B"]), (1 .. arity).map["A" + it], #["B"])»
				}
			''' }

			private def String curryReturnType(int index, int arity) {
				val lastFunctionArity = arity - index
				val lastFunctionType = if (lastFunctionArity == 1) "F" else ("F" + lastFunctionArity)
				val aTail = (1 .. arity).map["A" + it].toList.subList(index, arity)
				var retType = lastFunctionType + "<" + aTail.map[it + ", "].join + "B>"
				for (i : index >.. 0) {
					retType = "F<A" + (i + 1) + ", " + retType + ">"
				}
				retType
			}
		}
	}
}