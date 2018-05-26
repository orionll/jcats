package jcats.generator

final class OrderGenerator implements ClassGenerator {
	override className() { Constants.ORDER }

	override sourceCode() { '''
		package «Constants.JCATS»;

		public enum Order implements Ordered<Order>, Equatable<Order> {
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

			@Override
			public Order order(final Order other) {
				if (this == other) {
					return EQ;
				} else if (ordinal() < other.ordinal()) {
					return LT;
				} else {
					return GT;
				}
			}

			public Order reverse() {
				if (this == LT) {
					return GT;
				} else if (this == GT) {
					return LT;
				} else {
					return EQ;
				}
			}

			public int toInt() {
				return ordinal() - 1 ;
			}

			public static Order fromInt(final int cmp) {
				return (cmp == 0) ? EQ : (cmp > 0) ? GT : LT;
			}
		}
	''' }
}