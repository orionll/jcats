package jcats.generator

final class UnitGenerator implements ClassGenerator {
	override className() { "jcats.Unit" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;

		public final class Unit implements Equatable<Unit>, Serializable {

			private static final Unit UNIT = new Unit();

			private Unit() {}

			public static Unit unit() {
				return UNIT;
			}

			@Override
			public int hashCode() {
				return 0;
			}

			@Override
			public boolean equals(final Object obj) {
				return (obj == this);
			}

			@Override
			public String toString() {
				return "()";
			}

			«transform("Unit")»
		}
	''' }
}