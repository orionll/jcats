package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class Eff0XGenerator implements InterfaceGenerator {
	override className() { Constants.FUNCTION + ".Eff0X" }

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		/**
		 * Represents a side-effect of zero arguments which can throw a checked exception
		 */
		@FunctionalInterface
		public interface Eff0X<@Covariant X extends Throwable> {

			void apply() throws X;

			default <A> EffX<A, X> toEff() {
				return (final A value) -> {
					requireNonNull(value);
					apply();
				};
			}

			static <X extends Throwable> Eff0X<X> eff0X(final Eff0X<X> eff) {
				return requireNonNull(eff);
			}

			static <X extends Throwable> Eff0X<X> doNothingX() {
				return () -> {};
			}

			static <X extends Throwable> Eff0X<X> failX(final F0<X> f) {
				requireNonNull(f);
				return () -> {
					throw f.apply();
				};
			}

			static <XX extends Throwable, X extends XX> Eff0X<XX> cast(final Eff0X<X> eff0X) {
				return (Eff0X<XX>) requireNonNull(eff0X);
			}
		}
	''' }
}
