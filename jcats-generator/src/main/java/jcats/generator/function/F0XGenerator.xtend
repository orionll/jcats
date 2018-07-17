package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class F0XGenerator implements InterfaceGenerator {

	override className() {
		Constants.FUNCTION + ".F0X"
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Supplier;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		@FunctionalInterface
		public interface F0X<@Covariant A, @Covariant X extends Throwable> {

			A apply() throws X;

			default <B> F0X<B, X> map(final F<A, B> f) {
				requireNonNull(f);
				return () -> {
					final A a = requireNonNull(apply());
					return requireNonNull(f.apply(a));
				};
			}

			default <B> F0X<B, X> flatMap(final F<A, F0X<B, X>> f) {
				requireNonNull(f);
				return () -> {
					final A a = requireNonNull(apply());
					return requireNonNull(f.apply(a).apply());
				};
			}

			default <B> FX<B, A, X> toFX() {
				return (final B b) -> {
					requireNonNull(b);
					return requireNonNull(apply());
				};
			}

			default Eff0X<X> toEff0X() {
				return this::apply;
			}

			static <A, X extends Throwable> F0X<A, X> valueX(final A value) {
				requireNonNull(value);
				return () -> value;
			}

			«javadocSynonym("valueX")»
			static <A, X extends Throwable> F0X<A, X> of(final A value) {
				return valueX(value);
			}

			static <A, X extends Throwable> F0X<A, X> f0X(final F0X<A, X> f) {
				return requireNonNull(f);
			}

			static <A, X extends Throwable> F0X<A, X> lazyX(final F0X<A, X> f) {
				return new LazyF0X<>(f);
			}

			static <A, X extends Throwable> F0X<A, X> failX(final F0<X> f) {
				requireNonNull(f);
				return () -> {
					throw f.apply();
				};
			}

			static <A, X extends Throwable> F0X<A, X> join(final F0X<F0X<A, X>, X> f0X) {
				return f0X.flatMap(id());
			}

			static <A, X extends Throwable> F0X<A, X> fromSupplier(final Supplier<A> s) {
				return () -> requireNonNull(s.get());
			}

			«FOR i : 2 .. Constants.MAX_ARITY»
				static <«(1..i).map['''A«it», '''].join»B, X extends Throwable> F0X<B, X> map«i»(«(1..i).map['''final F0X<A«it», X> f«it», '''].join»final F«i»<«(1..i).map['''A«it», '''].join»B> f) {
					«FOR j : 1 .. i»
						requireNonNull(f«j»);
					«ENDFOR»
					requireNonNull(f);
					return () -> {
						«FOR j : 1 .. i»
							final A«j» a«j» = requireNonNull(f«j».apply());
						«ENDFOR»
						return requireNonNull(f.apply(«(1..i).map['''a«it»'''].join(", ")»));
					};
				}

			«ENDFOR»
			static <AX, XX extends Throwable, A extends AX, X extends XX> F0X<AX, XX> cast(final F0X<A, X> f0X) {
				return (F0X<AX, XX>) requireNonNull(f0X);
			}
		}

		final class LazyF0X<A, X extends Throwable> implements F0X<A, X> {
			private final F0X<A, X> f;
			private volatile A value;

			LazyF0X(final F0X<A, X> f) {
				this.f = requireNonNull(f);
			}

			@Override
			public A apply() throws X {
				if (this.value == null) {
					synchronized (this) {
						if (this.value == null) {
							final A a = requireNonNull(this.f.apply());
							this.value = a;
							return a;
						}
					}
				}
				return this.value;
			}
		}
	''' }
}