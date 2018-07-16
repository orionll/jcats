package jcats.generator

final class ControlGenerator implements ClassGenerator {
	override className() { "jcats.Control" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import jcats.function.Eff;
		import jcats.function.Eff0;
		import jcats.function.F;
		import jcats.function.F0;

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

			public static <A, B> B ifNonNull(final A value, final F<A, B> f) {
				requireNonNull(f);
				return (value == null) ? null : f.apply(value);
			}

			public static <A, B> B ifNonNullOr(final A value, final F<A, B> f, final B defaultValue) {
				requireNonNull(f);
				return (value == null) ? defaultValue : f.apply(value);
			}

			public static <A, B> B ifNonNullOrElse(final A value, final F<A, B> f, final F0<B> defaultValue) {
				requireNonNull(f);
				requireNonNull(defaultValue);
				return (value == null) ? defaultValue.apply() : f.apply(value);
			}

			public static <A, B> B whenNonNull(final A value, final F0<B> f) {
				requireNonNull(f);
				return (value == null) ? null : f.apply();
			}

			public static <A, B> B whenNonNullOr(final A value, final F0<B> f, final B defaultValue) {
				requireNonNull(f);
				return (value == null) ? defaultValue : f.apply();
			}

			public static <A, B> B whenNonNullOrElse(final A value, final F0<B> f, final F0<B> defaultValue) {
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

			public static <A> void doIfNonNullOrElse(final A value, final Eff<A> ifNonNull, final Eff0 ifNull) {
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

			public static <A> void doWhenNonNullOrElse(final A value, final Eff0 ifNonNull, final Eff0 ifNull) {
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

			public static <A> Matcher<A> matcher(final A value) {
				requireNonNull(value);
				return new Matcher<>(value);
			}

			public static class Matcher<A> {
				final A value;

				Matcher(final A value) {
					this.value = value;
				}
				«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»

					public <B> B match(
							«FOR j : 1 .. i»
								final A case«j», final F0<B> f«j»,
							«ENDFOR»
							final F0<B> defaultValue) {
						«FOR j : 1 .. i»
							requireNonNull(case«j»);
							requireNonNull(f«j»);
						«ENDFOR»
						requireNonNull(defaultValue);
						if (this.value.equals(case1)) {
							return requireNonNull(f1.apply());
						«FOR j : 1 ..< i»
							} else if (this.value.equals(case«j+1»)) {
								return requireNonNull(f«j+1».apply());
						«ENDFOR»
						} else {
							return requireNonNull(defaultValue.apply());
						}
					}
				«ENDFOR»
			}
		}

	''' }
}