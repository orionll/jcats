package jcats.generator

final class OrdGenerator implements ClassGenerator {
	override className() { Constants.ORD }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.util.Comparator;

		import «Constants.F»;
		import «Constants.F2»;

		import static java.util.Objects.requireNonNull;
		import static «Constants.ORDER».intToOrder;

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

			static <A> Ord<A> fToOrd(final F2<A, A, Order> f2) {
				requireNonNull(f2);
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return requireNonNull(f2.apply(x, y));
				};
			}

			/**
			 * Synonym for {@link #fToOrd}
			 */
			static <A> Ord<A> fromF(final F2<A, A, Order> f2) {
				return fToOrd(f2);
			}

			static <A> Ord<A> comparatorToOrd(final Comparator<A> comparator) {
				requireNonNull(comparator);
				return (x, y) -> {
					requireNonNull(x);
					requireNonNull(y);
					return intToOrder(comparator.compare(x, y));
				};
			}

			/**
			 * Synonym for {@link #comparatorToOrd}
			 */
			static <A> Ord<A> fromComparator(final Comparator<A> comparator) {
				return comparatorToOrd(comparator);
			}

			static <A extends Comparable<A>> Ord<A> ord() {
				return Order.ORD;
			}

			«cast(#["A"], #["A"], #[])»
		}
	''' }
}