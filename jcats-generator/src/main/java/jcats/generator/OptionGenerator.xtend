package jcats.generator

final class OptionGenerator implements ClassGenerator {
	override className() { Constants.OPTION }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.Objects;
		import java.util.Optional;
		import java.util.function.Predicate;

		import «Constants.F»;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		public final class Option<A> implements Equatable<Option<A>>, Iterable<A>, Sized, Serializable {
			private static final Option NONE = new Option(null);

			private final A value;

			private Option(final A value) {
				this.value = value;
			}

			@Override
			public int size() {
				return (value == null) ? 0 : 1;
			}

			public A get() {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return value;
				}
			}

			public <B> Option<B> set(final B value) {
				requireNonNull(value);
				return isEmpty() ? none() : some(value);
			}

			public A getOr(final A other) {
				requireNonNull(other);
				return isEmpty() ? other : value;
			}

			public Option<A> or(final Option<A> other) {
				requireNonNull(other);
				return isEmpty() ? other : this;
			}

			public <B> Option<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return none();
				} else if (f == F.id()) {
					return (Option) this;
				} else {
					return some(f.apply(value));
				}
			}

			public <B> Option<B> flatMap(final F<A, Option<B>> f) {
				requireNonNull(f);
				return isEmpty() ? none() : f.apply(value);
			}

			public Option<A> filter(final Predicate<A> predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return none();
				} else if (predicate.test(value)) {
					return this;
				} else {
					return none();
				}
			}

			public Optional<A> toOptional() {
				return Optional.ofNullable(value);
			}

			@Override
			public int hashCode() {
				return Objects.hashCode(value);
			}

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof Option<?>) {
					return Objects.equals(value, ((Option<?>) obj).value);
				} else {
					return false;
				}
			}

			@Override
			public Iterator<A> iterator() {
				return isEmpty() ? emptyIterator() : new SingletonIterator<>(value);
			}

			@Override
			public String toString() {
				return isEmpty() ? "None" : "Some(" + value + ")";
			}

			public static <A> Option<A> none() {
				return NONE;
			}

			public static <A> Option<A> some(final A value) {
				requireNonNull(value);
				return new Option<>(value);
			}

			public static <A> Option<A> nullableToOption(final A value) {
				return (value == null) ? none() : new Option<>(value);
			}

			public static <A> Option<A> optionalToOption(final Optional<A> optional) {
				return optional.isPresent() ? some(optional.get()) : none();
			}

			«productN»
			«productWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["option" + it + ".isEmpty()"].join(" || ")») {
					return none();
				} else {
					return some(f.apply(«(1 .. arity).map['''option«it».value'''].join(", ")»));
				}
			''']»
			«join»

			«cast(#["A"], #[], #["A"])»
		}
	''' }
}