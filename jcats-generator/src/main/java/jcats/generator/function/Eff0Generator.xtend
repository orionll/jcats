package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator
import jcats.generator.Type

final class Eff0Generator implements InterfaceGenerator {
	override className() { Constants.EFF0 }

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface Eff0 {
			void apply();

			default <A> Eff<A> toEff() {
				return (final A value) -> {
					requireNonNull(value);
					apply();
				};
			}

			«FOR type : Type.primitives»
				default «type.effShortName» to«type.effShortName»() {
					return (final «type.javaName» __) -> apply();
				}

			«ENDFOR»
			default <X extends Throwable> Eff0X<X> toEff0X() {
				return this::apply;
			}

			static Eff0 eff0(final Eff0 eff) {
				return requireNonNull(eff);
			}

			static Eff0 doNothing() {
				return () -> {};
			}

			static <X extends RuntimeException> Eff0 fail(final F0<X> f) {
				requireNonNull(f);
				return () -> {
					throw f.apply();
				};
			}
		}
	''' }
}
