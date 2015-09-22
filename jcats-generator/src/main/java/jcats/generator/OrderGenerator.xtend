package jcats.generator

final class OrderGenerator implements ClassGenerator {
	override className() { Constants.ORDER }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import static java.util.Objects.requireNonNull;

		public enum Order {
			/**
			 * Less than
			 */
			LT,

			/**
			 * Equal
			 */
			EQ,

			/**
			 * Greater than
			 */
			GT;

			public Order reverse() {
				switch (this) {
					case LT: return GT;
					case GT: return LT;
					default: return EQ;
				}
			}

			public int toInt() {
				return ordinal() - 1 ;
			}

			public static Order intToOrder(final int cmp) {
				return (cmp == 0) ? EQ : (cmp > 0) ? GT : LT;
			}

			static final Ord ORD = (Ord<Comparable>) (Comparable x, Comparable y) -> {
				requireNonNull(x);
				requireNonNull(y);
				return intToOrder(x.compareTo(y));
			};
		}
	''' }
}