package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class F0Generator implements InterfaceGenerator {
	override className() { Constants.F0 }
	
	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Supplier;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		@FunctionalInterface
		public interface F0<A> {
			A apply();

			default <B> F0<B> map(final F<A, B> f) {
				requireNonNull(f);
				return () -> {
					final A a = requireNonNull(apply());
					return requireNonNull(f.apply(a));
				};
			}

			default <B> F0<B> flatMap(final F<A, F0<B>> f) {
				requireNonNull(f);
				return () -> {
					final A a = requireNonNull(apply());
					return requireNonNull(f.apply(a).apply());
				};
			}

			default <B> F<B, A> toConstF() {
				return __ -> requireNonNull(apply());
			}

			default Supplier<A> toSupplier() {
				return () -> requireNonNull(apply());
			}

			static <A> F0<A> value(final A a) {
				requireNonNull(a);
				return () -> a;
			}

			«join»

			static <A> F0<A> supplierToF0(final Supplier<A> s) {
				requireNonNull(s);
				return () -> requireNonNull(s.get());
			}

			«applyN»
			«applyWithN[arity | '''
				requireNonNull(f);
				return () -> {
					«FOR i : 1 .. arity»
						final A«i» a«i» = requireNonNull(f«i».apply());
					«ENDFOR»
					return requireNonNull(f.apply(«(1 .. arity).map["a" + it].join(", ")»));
				};
			''']»
			«cast(#["A"], #[], #["A"])»
		}
	''' }
}