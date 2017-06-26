package jcats.generator

final class EitherGenerator implements ClassGenerator {
	override className() { Constants.EITHER }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.NoSuchElementException;
		import java.util.Objects;

		import «Constants.F»;

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		public final class Either<X, A> implements Maybe<A>, Equatable<Either<X, A>>, Serializable {
			private final X left;
			private final A right;

			private Either(final X left, final A right) {
				this.left = left;
				this.right = right;
			}

			public boolean isLeft() {
				return (left != null);
			}

			public boolean isRight() {
				return (right != null);
			}

			public X getLeft() {
				if (isLeft()) {
					return left;
				} else {
					throw new NoSuchElementException();
				}
			}

			@Override
			public A getOrNull() {
				if (isRight()) {
					return right;
				} else {
					return null;
				}
			}

			public X getLeftOrNull() {
				if (isLeft()) {
					return left;
				} else {
					return null;
				}
			}

			public A getOr(final A other) {
				requireNonNull(other);
				return isRight() ? right : other;
			}

			public X getLeftOr(final X other) {
				requireNonNull(other);
				return isLeft() ? left : other;
			}

			public <B> Either<X, B> map(final F<A, B> f) {
				requireNonNull(f);
				if (isRight()) {
					final B newRight = requireNonNull(f.apply(right));
					return new Either<>(null, newRight);
				} else {
					return (Either)this;
				}
			}

			public <Y> Either<Y, A> mapLeft(final F<X, Y> f) {
				requireNonNull(f);
				if (isLeft()) {
					final Y newLeft = requireNonNull(f.apply(left));
					return new Either<>(newLeft, null);
				} else {
					return (Either)this;
				}
			}

			public <B> Either<X, B> flatMap(final F<A, Either<X, B>> f) {
				requireNonNull(f);
				if (isRight()) {
					return requireNonNull(f.apply(right));
				} else {
					return (Either)this;
				}
			}

			public <Y> Either<Y, A> flatMapLeft(final F<X, Either<Y, A>> f) {
				requireNonNull(f);
				if (isLeft()) {
					return requireNonNull(f.apply(left));
				} else {
					return (Either)this;
				}
			}

			public <Y, B> Either<Y, B> biMap(final F<X, Y> f, final F<A, B> g) {
				if (isLeft()) {
					final Y newLeft = requireNonNull(f.apply(left));
					return new Either<>(newLeft, null);
				} else {
					final B newRight = requireNonNull(g.apply(right));
					return new Either<>(null, newRight);
				}
			}

			public Either<A, X> flip() {
				return new Either<>(right, left);
			}

			public Option<A> toOption() {
				return Option.fromNullable(right);
			}

			@Override
			public int hashCode() {
				return isRight() ? right.hashCode() : ~left.hashCode();
			}

			@Override
			public boolean equals(Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof Either<?, ?>) {
					final Either<?, ?> either = (Either<?, ?>) obj;
					return Objects.equals(left, either.left) && Objects.equals(right, either.right);
				} else {
					return false;
				}
			}

			@Override
			public String toString() {
				return isLeft() ? "Left(" + left + ")" : "Right(" + right + ")";
			}

			public static <X, A> Either<X, A> left(final X left) {
				requireNonNull(left);
				return new Either<>(left, null);
			}

			public static <X, A> Either<X, A> right(final A right) {
				requireNonNull(right);
				return new Either<>(null, right);
			}

			«joinMultiple(#["X"], "A")»

			«cast(#["X", "A"], #[], #["X", "A"])»
		}

	'''}
}