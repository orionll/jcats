package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class EffGenerator implements InterfaceGenerator {
	override className() { Constants.EFF }
	
	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Consumer;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface Eff<A> {
			void apply(final A value);

			default <B> Eff<B> contraMap(final F<B, A> f) {
				requireNonNull(f);
				return (B b) -> {
					requireNonNull(b);
					final A a = requireNonNull(f.apply(b));
					apply(a);
				};
			}

			default Consumer<A> toConsumer() {
				return (A a) -> apply(requireNonNull(a));
			}

			static <A> Eff<A> consumerToEff(final Consumer<A> c) {
				requireNonNull(c);
				return (A a) -> c.accept(requireNonNull(a));
			}

			«cast(#["A"], #["A"], #[])»
		}
	''' }
}