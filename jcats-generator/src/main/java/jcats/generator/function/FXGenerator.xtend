package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class FXGenerator implements InterfaceGenerator {

	override className() {
		Constants.FUNCTION + ".FX"
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Function;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		/**
		 * Represents a function A -> B which can throw a checked exception
		 */
		@FunctionalInterface
		public interface FX<@Contravariant A, @Covariant B, @Covariant X extends Throwable> {

			B apply(A value) throws X;

			default <C> FX<A, C, X> map(final F<B, C> f) {
				requireNonNull(f);
				return (final A a) -> {
					requireNonNull(a);
					final B b = requireNonNull(apply(a));
					return requireNonNull(f.apply(b));
				};
			}

			default <C> FX<C, B, X> contraMap(final F<C, A> f) {
				requireNonNull(f);
				return (final C c) -> {
					requireNonNull(c);
					final A a = requireNonNull(f.apply(c));
					return requireNonNull(apply(a));
				};
			}

			default <C, D> FX<C, D, X> diMap(final F<C, A> f, final F<B, D> g) {
				requireNonNull(f);
				requireNonNull(g);
				return (final C c) -> {
					requireNonNull(c);
					final A a = requireNonNull(f.apply(c));
					final B b = requireNonNull(apply(a));
					return requireNonNull(g.apply(b));
				};
			}

			default <C> FX<A, C, X> flatMap(final F<B, FX<A, C, X>> f) {
				requireNonNull(f);
				return (final A a) -> {
					requireNonNull(a);
					final B b = requireNonNull(apply(a));
					return requireNonNull(f.apply(b).apply(a));
				};
			}

			default F0X<B, X> toF0X(final A value) {
				requireNonNull(value);
				return () -> requireNonNull(apply(value));
			}

			default EffX<A, X> toEffX() {
				return (final A a) -> apply(requireNonNull(a));
			}

			static <A, X extends Throwable> FX<A, A, X> id() {
				return (FX<A, A, X>) Fs.IDX;
			}

			static <A, B, C, X extends Throwable> FX<A, C, X> andThenX(final FX<A, B, X> f, final FX<B, C, X> g) {
				requireNonNull(f);
				requireNonNull(g);
				return (final A a) -> {
					requireNonNull(a);
					final B b = requireNonNull(f.apply(a));
					return requireNonNull(g.apply(b));
				};
			}

			static <A, B, C, X extends Throwable> FX<A, C, X> composeX(final FX<B, C, X> f, final FX<A, B, X> g) {
				requireNonNull(f);
				requireNonNull(g);
				return (final A a) -> {
					requireNonNull(a);
					final B b = requireNonNull(g.apply(a));
					return requireNonNull(f.apply(b));
				};
			}

			static <A, B, X extends Throwable> FX<A, B, X> alwaysX(final B value) {
				requireNonNull(value);
				return (final A a) -> {
					requireNonNull(a);
					return value;
				};
			}

			/**
			 * Alias for {@link #alwaysX}
			 */
			static <A, B, X extends Throwable> FX<A, B, X> of(final B value) {
				return alwaysX(value);
			}

			static <A, B, X extends Throwable> FX<A, B, X> fX(final FX<A, B, X> f) {
				return requireNonNull(f);
			}

			static <A, B, X extends Throwable> FX<A, B, X> failX(final F0<X> f) {
				requireNonNull(f);
				return (final A value) -> {
					requireNonNull(value);
					throw f.apply();
				};
			}

			static <A, B, C, X extends Throwable> FX<A, B, X> failWithArgX(final F<C, X> f, final C arg) {
				requireNonNull(f);
				requireNonNull(arg);
				return (final A value) -> {
					requireNonNull(value);
					throw f.apply(arg);
				};
			}

			static <A, B, X extends Throwable> FX<A, B, X> join(final FX<A, FX<A, B, X>, X> f) {
				return f.flatMap(F.id());
			}

			static <A, B, X extends Throwable> FX<A, B, X> fromFunction(final Function<A, B> f) {
				requireNonNull(f);
				return (final A a) -> {
					requireNonNull(a);
					return requireNonNull(f.apply(a));
				};
			}

			static <A, AX extends A, BX, B extends BX, XX extends Throwable, X extends XX> FX<AX, BX, XX> cast(final FX<A, B, X> f) {
				return (FX<AX, BX, XX>) requireNonNull(f);
			}
		}
	''' }
}