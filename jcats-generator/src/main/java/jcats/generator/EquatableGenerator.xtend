package jcats.generator

final class EquatableGenerator implements InterfaceGenerator {
	override className() { Constants.EQUATABLE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface Equatable<A> {
			boolean isEqualTo(final A other);

			default boolean isNotEqualTo(final A other) {
				return !isEqualTo(other);
			}
		}
	''' }
}