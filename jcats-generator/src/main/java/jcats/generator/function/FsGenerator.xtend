package jcats.generator.function

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class FsGenerator implements ClassGenerator {
	override className() { Constants.F + "s" }
	
	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.Objects;

		final class Fs {
			static final F ID = Objects::requireNonNull;
		}
	''' }
}