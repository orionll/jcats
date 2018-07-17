package jcats.generator

final class MatcherGenerator implements ClassGenerator {
	override className() { "jcats.Matcher" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;

		public final class Matcher<A> {
			final A value;

			private Matcher(final A value) {
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
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public <B, X extends Throwable> B matchX(
						«FOR j : 1 .. i»
							final A case«j», final F0X<B, X> f«j»,
						«ENDFOR»
						final F0X<B, X> defaultValue) throws X {
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
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public void doMatch(
						«FOR j : 1 .. i»
							final A case«j», final Eff0 eff«j»,
						«ENDFOR»
						final Eff0 defaultEff) {
					«FOR j : 1 .. i»
						requireNonNull(case«j»);
						requireNonNull(eff«j»);
					«ENDFOR»
					requireNonNull(defaultEff);
					if (this.value.equals(case1)) {
						eff1.apply();
					«FOR j : 1 ..< i»
						} else if (this.value.equals(case«j+1»)) {
							eff«j+1».apply();
					«ENDFOR»
					} else {
						defaultEff.apply();
					}
				}

			«ENDFOR»
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public <X extends Throwable> void doMatchX(
						«FOR j : 1 .. i»
							final A case«j», final Eff0X<X> eff«j»,
						«ENDFOR»
						final Eff0X<X> defaultEff) throws X {
					«FOR j : 1 .. i»
						requireNonNull(case«j»);
						requireNonNull(eff«j»);
					«ENDFOR»
					requireNonNull(defaultEff);
					if (this.value.equals(case1)) {
						eff1.apply();
					«FOR j : 1 ..< i»
						} else if (this.value.equals(case«j+1»)) {
							eff«j+1».apply();
					«ENDFOR»
					} else {
						defaultEff.apply();
					}
				}

			«ENDFOR»
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public <«(1..i).map["C" + it].join(", ")», B> B matchClass(
						«FOR j : 1 .. i»
							final Class<C«j»> class«j», final F<C«j», B> f«j»,
						«ENDFOR»
						final F0<B> defaultValue) {
					«FOR j : 1 .. i»
						requireNonNull(class«j»);
						requireNonNull(f«j»);
					«ENDFOR»
					requireNonNull(defaultValue);
					if (class1.isInstance(this.value)) {
						return requireNonNull(f1.apply((C1) this.value));
					«FOR j : 1 ..< i»
						} else if (class«j+1».isInstance(this.value)) {
							return requireNonNull(f«j+1».apply((C«j+1») this.value));
					«ENDFOR»
					} else {
						return requireNonNull(defaultValue.apply());
					}
				}

			«ENDFOR»
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public <«(1..i).map["C" + it].join(", ")», B, X extends Throwable> B matchClassX(
						«FOR j : 1 .. i»
							final Class<C«j»> class«j», final FX<C«j», B, X> f«j»,
						«ENDFOR»
						final F0X<B, X> defaultValue) throws X {
					«FOR j : 1 .. i»
						requireNonNull(class«j»);
						requireNonNull(f«j»);
					«ENDFOR»
					requireNonNull(defaultValue);
					if (class1.isInstance(this.value)) {
						return requireNonNull(f1.apply((C1) this.value));
					«FOR j : 1 ..< i»
						} else if (class«j+1».isInstance(this.value)) {
							return requireNonNull(f«j+1».apply((C«j+1») this.value));
					«ENDFOR»
					} else {
						return requireNonNull(defaultValue.apply());
					}
				}

			«ENDFOR»
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public <«(1..i).map["C" + it].join(", ")»> void doMatchClass(
						«FOR j : 1 .. i»
							final Class<C«j»> class«j», final Eff<C«j»> eff«j»,
						«ENDFOR»
						final Eff0 defaultEff) {
					«FOR j : 1 .. i»
						requireNonNull(class«j»);
						requireNonNull(eff«j»);
					«ENDFOR»
					requireNonNull(defaultEff);
					if (class1.isInstance(this.value)) {
						eff1.apply((C1) this.value);
					«FOR j : 1 ..< i»
						} else if (class«j+1».isInstance(this.value)) {
							eff«j+1».apply((C«j+1») this.value);
					«ENDFOR»
					} else {
						defaultEff.apply();
					}
				}

			«ENDFOR»
			«FOR i : 1 .. Constants.MATCHER_METHODS_COUNT»
				public <«(1..i).map["C" + it].join(", ")», X extends Throwable> void doMatchClassX(
						«FOR j : 1 .. i»
							final Class<C«j»> class«j», final EffX<C«j», X> eff«j»,
						«ENDFOR»
						final Eff0X<X> defaultEff) throws X {
					«FOR j : 1 .. i»
						requireNonNull(class«j»);
						requireNonNull(eff«j»);
					«ENDFOR»
					requireNonNull(defaultEff);
					if (class1.isInstance(this.value)) {
						eff1.apply((C1) this.value);
					«FOR j : 1 ..< i»
						} else if (class«j+1».isInstance(this.value)) {
							eff«j+1».apply((C«j+1») this.value);
					«ENDFOR»
					} else {
						defaultEff.apply();
					}
				}

			«ENDFOR»
			public static <A> Matcher<A> matcher(final A value) {
				requireNonNull(value);
				return new Matcher<>(value);
			}
		}

	''' }
}