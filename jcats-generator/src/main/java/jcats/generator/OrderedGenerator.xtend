package jcats.generator

final class OrderedGenerator implements ClassGenerator {
	override className() { Constants.ORDERED }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import static java.util.Objects.requireNonNull;
		import static jcats.Order.*;

		public interface Ordered<A> extends Comparable<A> {

			Order compare(final A other);

			@Override
			default int compareTo(final A other) {
				requireNonNull(other);
				return compare(other).toInt();
			}

			default boolean isLessThan(final A other) {
				requireNonNull(other);
				return compare(other).equals(LT);
			}

			default boolean isLessThanOrEqualTo(final A other) {
				requireNonNull(other);
				return !compare(other).equals(GT);
			}

			default boolean isGreaterThan(final A other) {
				requireNonNull(other);
				return compare(other).equals(GT);
			}

			default boolean isGreaterThanOrEqualTo(final A other) {
				requireNonNull(other);
				return !compare(other).equals(LT);
			}
		}
	''' }
}