package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class EffXGenerator implements InterfaceGenerator {

	override className() {
		Constants.FUNCTION + ".EffX"
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.Objects;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		/**
		 * Represents a side-effect of one argument which can throw a checked exception
		 */
		@FunctionalInterface
		public interface EffX<@Contravariant A, @Covariant X extends Throwable> {

			void apply(A value) throws X;

			default <B> EffX<B, X> contraMap(final F<B, A> f) {
				requireNonNull(f);
				return (final B b) -> {
					requireNonNull(b);
					final A a = requireNonNull(f.apply(b));
					apply(a);
				};
			}

			default Eff0X<X> toEff0X(final A value) {
				requireNonNull(value);
				return () -> apply(value);
			}

			static <A, X extends Throwable> EffX<A, X> effX(final EffX<A, X> eff) {
				return requireNonNull(eff);
			}

			static <A, B, X extends Throwable> EffX<A, X> composeX(final EffX<B, X> eff, final FX<A, B, X> f) {
				requireNonNull(eff);
				requireNonNull(f);
				return (final A a) -> {
					requireNonNull(a);
					final B b = requireNonNull(f.apply(a));
					eff.apply(b);
				};
			}

			static <A, X extends Throwable> EffX<A, X> failX(final F0<X> f) {
				requireNonNull(f);
				return (final A value) -> {
					requireNonNull(value);
					throw f.apply();
				};
			}

			static <A, C, X extends Throwable> EffX<A, X> failWithArgX(final F<C, X> f, final C arg) {
				requireNonNull(f);
				requireNonNull(arg);
				return (final A value) -> {
					requireNonNull(value);
					throw f.apply(arg);
				};
			}

			static <A, X extends Throwable> EffX<A, X> doNothingX() {
				return Objects::requireNonNull;
			}

			static <A, X extends Throwable> EffX<A, X> fromConsumer(final Consumer<A> c) {
				requireNonNull(c);
				return (final A a) -> c.accept(requireNonNull(a));
			}

			static <A, AX extends A, XX extends Throwable, X extends XX> EffX<AX, XX> cast(final EffX<A, X> eff) {
				return (EffX<AX, XX>) requireNonNull(eff);
			}
		}
	''' }
}