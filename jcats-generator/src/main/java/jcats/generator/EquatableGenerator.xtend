package jcats.generator

final class EquatableGenerator implements InterfaceGenerator {
	override className() { Constants.EQUATABLE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import static java.util.Objects.requireNonNull;

		public interface Equatable<A> {

			default boolean isEqualTo(final A other) {
				requireNonNull(other);
				return equals(other);
			}

			default boolean isNotEqualTo(final A other) {
				return !isEqualTo(other);
			}

			default boolean isEqualToAny(final A value, final A... values) {
				requireNonNull(value);
				if (equals(value)) {
					return true;
				}
				for (final A val : values) {
					requireNonNull(val);
					if (equals(val)) {
						return true;
					}
				}
				return false;
			}
		}
	''' }
}