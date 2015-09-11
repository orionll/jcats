package jcats.generator.function

import jcats.generator.Generator
import jcats.generator.Constants

final class F0Generator implements Generator {
	override className() { Constants.F0 }
	
	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Supplier;

		import static java.util.Objects.requireNonNull;

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

			static <A> F0<A> supplierToF0(final Supplier<A> s) {
				requireNonNull(s);
				return () -> requireNonNull(s.get());
			}

			«cast("F0", #["A"], #[], #["A"])»
		}
	''' }
}