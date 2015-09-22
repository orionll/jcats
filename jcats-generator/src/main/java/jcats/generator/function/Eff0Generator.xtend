package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class Eff0Generator implements InterfaceGenerator {
	override className() { Constants.EFF0 }

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		@FunctionalInterface
		public interface Eff0 {
			void apply();
		}
	''' }
}
