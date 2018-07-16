package jcats.generator

final class ControlGenerator implements ClassGenerator {
	override className() { "jcats.Control" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;

		public final class Control {
			private Control() {
			}

			public static <A> A nonNullOr(final A value, final A defaultValue) {
				requireNonNull(defaultValue);
				return (value == null) ? defaultValue : value;
			}

			public static <A> A nonNullOrElse(final A value, final F0<A> defaultValue) {
				requireNonNull(defaultValue);
				return (value == null) ? requireNonNull(defaultValue.apply()) : value;
			}

			public static <A, X extends Throwable> A nonNullOrElseX(final A value, final F0X<A, X> defaultValue) throws X {
				requireNonNull(defaultValue);
				return (value == null) ? requireNonNull(defaultValue.apply()) : value;
			}

			public static <A, B> B ifNonNull(final A value, final F<A, B> f) {
				requireNonNull(f);
				return (value == null) ? null : f.apply(value);
			}

			public static <A, B, X extends Throwable> B ifNonNullX(final A value, final FX<A, B, X> f) throws X {
				requireNonNull(f);
				return (value == null) ? null : f.apply(value);
			}

			public static <A, B> B ifNonNullOr(final A value, final F<A, B> f, final B defaultValue) {
				requireNonNull(f);
				return (value == null) ? defaultValue : f.apply(value);
			}

			public static <A, B, X extends Throwable> B ifNonNullOrX(final A value, final FX<A, B, X> f, final B defaultValue) throws X {
				requireNonNull(f);
				return (value == null) ? defaultValue : f.apply(value);
			}

			public static <A, B> B ifNonNullOrElse(final A value, final F<A, B> f, final F0<B> defaultValue) {
				requireNonNull(f);
				requireNonNull(defaultValue);
				return (value == null) ? defaultValue.apply() : f.apply(value);
			}

			public static <A, B, X extends Throwable> B ifNonNullOrElseX(final A value, final FX<A, B, X> f, final F0X<B, X> defaultValue) throws X {
				requireNonNull(f);
				requireNonNull(defaultValue);
				return (value == null) ? defaultValue.apply() : f.apply(value);
			}

			public static <A, B> B whenNonNull(final A value, final F0<B> f) {
				requireNonNull(f);
				return (value == null) ? null : f.apply();
			}

			public static <A, B, X extends Throwable> B whenNonNullX(final A value, final F0X<B, X> f) throws X {
				requireNonNull(f);
				return (value == null) ? null : f.apply();
			}

			public static <A, B> B whenNonNullOr(final A value, final F0<B> f, final B defaultValue) {
				requireNonNull(f);
				return (value == null) ? defaultValue : f.apply();
			}

			public static <A, B, X extends Throwable> B whenNonNullOrX(final A value, final F0X<B, X> f, final B defaultValue) throws X {
				requireNonNull(f);
				return (value == null) ? defaultValue : f.apply();
			}

			public static <A, B> B whenNonNullOrElse(final A value, final F0<B> f, final F0<B> defaultValue) {
				requireNonNull(f);
				requireNonNull(defaultValue);
				return (value == null) ? defaultValue.apply() : f.apply();
			}

			public static <A, B, X extends Throwable> B whenNonNullOrElseX(final A value, final F0X<B, X> f, final F0X<B, X> defaultValue) throws X {
				requireNonNull(f);
				requireNonNull(defaultValue);
				return (value == null) ? defaultValue.apply() : f.apply();
			}

			public static <A> void doIfNonNull(final A value, final Eff<A> eff) {
				requireNonNull(eff);
				if (value != null) {
					eff.apply(value);
				}
			}

			public static <A, X extends Throwable> void doIfNonNullX(final A value, final EffX<A, X> eff) throws X {
				requireNonNull(eff);
				if (value != null) {
					eff.apply(value);
				}
			}

			public static <A> void doIfNonNullOrElse(final A value, final Eff<A> ifNonNull, final Eff0 ifNull) {
				requireNonNull(ifNonNull);
				requireNonNull(ifNull);
				if (value != null) {
					ifNonNull.apply(value);
				} else {
					ifNull.apply();
				}
			}

			public static <A, X extends Throwable> void doIfNonNullOrElseX(final A value, final EffX<A, X> ifNonNull, final Eff0X<X> ifNull) throws X {
				requireNonNull(ifNonNull);
				requireNonNull(ifNull);
				if (value != null) {
					ifNonNull.apply(value);
				} else {
					ifNull.apply();
				}
			}

			public static <A> void doWhenNonNull(final A value, final Eff0 eff) {
				requireNonNull(eff);
				if (value != null) {
					eff.apply();
				}
			}

			public static <A, X extends Throwable> void doWhenNonNullX(final A value, final Eff0X<X> eff) throws X {
				requireNonNull(eff);
				if (value != null) {
					eff.apply();
				}
			}

			public static <A> void doWhenNonNullOrElse(final A value, final Eff0 ifNonNull, final Eff0 ifNull) {
				requireNonNull(ifNonNull);
				requireNonNull(ifNull);
				if (value != null) {
					ifNonNull.apply();
				} else {
					ifNull.apply();
				}
			}

			public static <A, X extends Throwable> void doWhenNonNullOrElseX(final A value, final Eff0X<X> ifNonNull, final Eff0X<X> ifNull) throws X {
				requireNonNull(ifNonNull);
				requireNonNull(ifNull);
				if (value != null) {
					ifNonNull.apply();
				} else {
					ifNull.apply();
				}
			}

			public static <A> void doIfNull(final A value, final Eff0 eff) {
				requireNonNull(eff);
				if (value == null) {
					eff.apply();
				}
			}

			public static <A, X extends Throwable> void doIfNullX(final A value, final Eff0X<X> eff) throws X {
				requireNonNull(eff);
				if (value == null) {
					eff.apply();
				}
			}
		}

	''' }
}