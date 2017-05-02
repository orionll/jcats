package jcats.generator

final class OrdGenerator implements ClassGenerator {
	override className() { Constants.ORD }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Comparator;

		import «Constants.F»;
		import «Constants.F2»;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface Ord<A> {

			Order compare(final A x, final A y);

			default boolean less(final A x, final A y) {
				requireNonNull(x);
				requireNonNull(y);
				return compare(x, y).equals(Order.LT);
			}

			default boolean greater(final A x, final A y) {
				requireNonNull(x);
				requireNonNull(y);
				return compare(x, y).equals(Order.GT);
			}

			default boolean eq(final A x, final A y) {
				requireNonNull(x);
				requireNonNull(y);
				return compare(x, y).equals(Order.EQ);
			}

			default A min(final A x, final A y) {
				return less(x, y) ? x : y;
			}

			default A max(final A x, final A y) {
				return greater(x, y) ? x : y;
			}

			default Ord<A> reverse() {
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return compare(x, y).reverse();
				};
			}

			default <B> Ord<B> contraMap(final F<B, A> f) {
				requireNonNull(f);
				return (b1, b2) -> {
					requireNonNull(b1);
					requireNonNull(b2);
					final A a1 = f.apply(b1);
					final A a2 = f.apply(b2);
					return requireNonNull(compare(a1, a2));
				};
			}

			default Ord<A> then(final Ord<A> ord) {
				requireNonNull(ord);
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					final Order order = compare(x, y);
					return (order == Order.EQ) ? ord.compare(x, y) : order;
				};
			}

			default <B extends Comparable<B>> Ord<A> thenBy(final F<A, B> f) {
				return then(Ord.<B>ord().contraMap(f));
			}

			default F2<A, A, Order> toF() {
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return requireNonNull(compare(x, y));
				};
			}

			default Comparator<A> toComparator() {
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return compare(x, y).toInt();
				};
			}

			static <A> Ord<A> fromF(final F2<A, A, Order> f2) {
				requireNonNull(f2);
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return requireNonNull(f2.apply(x, y));
				};
			}

			static <A> Ord<A> fromComparator(final Comparator<A> comparator) {
				requireNonNull(comparator);
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return Order.fromInt(comparator.compare(x, y));
				};
			}

			static <A extends Comparable<A>> Ord<A> ord() {
				return (Ord) NaturalOrd.INSTANCE;
			}

			static <A extends Comparable<A>> Ord<A> reverseOrd() {
				return (Ord) ReverseOrd.INSTANCE;
			}

			static <A, B extends Comparable<B>> Ord<A> by(final F<A, B> f) {
				return Ord.<B>ord().contraMap(f);
			}

			«cast(#["A"], #["A"], #[])»
		}

		final class NaturalOrd implements Ord<Comparable>, Serializable {
			static final NaturalOrd INSTANCE = new NaturalOrd();

			@Override
			public Order compare(Comparable x, Comparable y) {
				requireNonNull(x);
				requireNonNull(y);
				return Order.fromInt(x.compareTo(y));
			}

			@Override
			public Comparator<Comparable> toComparator() {
				return Comparator.naturalOrder();
			}

			@Override
			public Ord<Comparable> reverse() {
				return ReverseOrd.INSTANCE;
			}
		}

		final class ReverseOrd implements Ord<Comparable>, Serializable {
			static final ReverseOrd INSTANCE = new ReverseOrd();

			@Override
			public Order compare(Comparable x, Comparable y) {
				requireNonNull(x);
				requireNonNull(y);
				return Order.fromInt(y.compareTo(x));
			}

			@Override
			public Comparator<Comparable> toComparator() {
				return Comparator.reverseOrder();
			}

			@Override
			public Ord<Comparable> reverse() {
				return NaturalOrd.INSTANCE;
			}
		}
	''' }
}