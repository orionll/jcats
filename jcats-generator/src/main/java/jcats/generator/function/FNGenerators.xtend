package jcats.generator.function

import com.google.common.collect.Iterables
import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator

final class FNGenerators {
	def static List<Generator> generators() {
		(3 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	private def static Generator generator(int arity) {
		new InterfaceGenerator {
			override className() { Constants.F + arity }

			def typeParams() { '''<«(1 .. arity).map['''A«it», '''].join»B>''' }
			def genericName() { "F" + arity + typeParams }

			override sourceCode() { '''
				package «Constants.FUNCTION»;

				«IF arity == 2»
				import java.util.function.BiFunction;

				«ENDIF»
				import «Constants.JCATS».*;

				import static java.util.Objects.requireNonNull;
				import static «Constants.F».id;

				@FunctionalInterface
				public interface F«arity»<«(1 .. arity).map["@Contravariant A" + it + ", "].join»@Covariant B> {
					B apply(«(1 .. arity).map["final A" + it + " a" + it].join(", ")»);

					default <C> F«arity»<«(1 .. arity).map["A" + it + ", "].join»C> map(final F<B, C> f) {
						requireNonNull(f);
						return («(1 .. arity).map['''final A«it» a«it»'''].join(", ")») -> {
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
							return («(1 .. arity).map[if (it == i) "final C c" else '''final A«it» a«it»'''].join(", ")») -> {
								«FOR j : 1 .. arity»
									requireNonNull(«if (i == j) "c" else "a" + j»);
								«ENDFOR»
								final A«i» a«i» = requireNonNull(f.apply(c));
								return requireNonNull(apply(«(1 .. arity).map["a" + it].join(", ")»));
							};
						}

					«ENDFOR»
					«FOR i : 1 ..< arity»
						default «curryReturnType(i, arity)» curry«if (i == 1) "" else i»() {
							return (final A1 a1) -> {
							«FOR j : 1 ..< i»
								«(1 .. j).map["\t"].join»requireNonNull(a«j»);
								«(1 .. j).map["\t"].join»return (final A«j+1» a«j+1») -> {
							«ENDFOR»
							«(1 .. i).map["\t"].join»requireNonNull(a«i»);
							«(1 .. i).map["\t"].join»return («(i + 1 .. arity).map['''final A«it» a«it»'''].join(", ")») -> {
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
						return («(1 .. arity).map['''final A«it» a«it»'''].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
							final B b = requireNonNull(apply(«(1 .. arity).map["a" + it].join(", ")»));
							return requireNonNull(f.apply(b).apply(«(1 .. arity).map["a" + it].join(", ")»));
						};
					}

					default Eff«arity»<«(1 .. arity).map["A" + it].join(", ")»> toEff«arity»() {
						return («(1 .. arity).map['''final A«it» a«it»'''].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
							apply(«(1 .. arity).map["a" + it].join(", ")»);
						};
					}

					«FOR i : 1 .. arity»
						default F«arity-1»<«(1 .. arity).filter[it != i].map['''A«it», '''].join»B> apply«i»(final A«i» value«i») {
							requireNonNull(value«i»);
							return («(1 .. arity).filter[it != i].map['''final A«it» value«it»'''].join(", ")») -> {
								«FOR j : 1 .. arity»
									«IF j != i»
										requireNonNull(value«j»);
									«ENDIF»
								«ENDFOR»
								return requireNonNull(apply(«(1 .. arity).map['''value«it»'''].join(", ")»));
							};
						}

					«ENDFOR»
					static «typeParams» «genericName» always(final B value) {
						requireNonNull(value);
						return («(1 .. arity).map['''final A«it» a«it»'''].join(", ")») -> {
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
							return value;
						};
					}

					«javadocSynonym("always")»
					static «typeParams» «genericName» of(final B value) {
						return always(value);
					}

					static «typeParams» «genericName» f«arity»(final «genericName» f) {
						return requireNonNull(f);
					}

					«joinMultiple((1 .. arity).map["A" + it], "B")»

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