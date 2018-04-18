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
				requireNonNull(other);
				return !equals(other);
			}

			«FOR i : 2 .. Constants.MAX_ARITY»
				default boolean isEqualToAny(«(1..i).map['''final A value«it»'''].join(", ")») {
					«FOR j : 1 .. i»
						requireNonNull(value«j»);
					«ENDFOR»
					return equals(value1)
						«FOR j : 2 .. i»
							|| equals(value«j»)«IF j == i»;«ENDIF»
						«ENDFOR»
				}

			«ENDFOR»
			default boolean isEqualToAny(«(1..Constants.MAX_ARITY+1).map['''final A value«it»'''].join(", ")», final A... values) {
				«FOR j : 1 .. Constants.MAX_ARITY+1»
					requireNonNull(value«j»);
				«ENDFOR»
				requireNonNull(values);
				«FOR j : 1 .. Constants.MAX_ARITY+1»
					if (equals(value«j»)) {
						return true;
					}
				«ENDFOR»
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