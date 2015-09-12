package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class F0Generator implements InterfaceGenerator {
	override className() { Constants.F0 }
	
	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Supplier;

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

			«cast(#["A"], #[], #["A"], true)»
		}
	''' }
}