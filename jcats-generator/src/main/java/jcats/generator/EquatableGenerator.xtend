package jcats.generator

final class EquatableGenerator implements InterfaceGenerator {
	override className() { Constants.EQUATABLE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.util.Objects;

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

			static <A extends Equatable<A>> boolean equal(final A value1, final A value2) {
				requireNonNull(value2);
				return value1.equals(value2);
			}

			static <A extends Equatable<A>> boolean nullableEqual(final A value1, final A value2) {
				return Objects.equals(value1, value2);
			}

			@SafeVarargs
			static <A extends Equatable<A>> boolean allEqual(final A... values) {
				if (values.length == 0) {
					return true;
				}
				for (final A value : values) {
					requireNonNull(value);
				}
				final Equatable<A> first = values[0];
				for (int i = 1; i < values.length; i++) {
					if (!first.equals(values[i])) {
						return false;
					}
				}
				return true;
			}
		}
	''' }
}