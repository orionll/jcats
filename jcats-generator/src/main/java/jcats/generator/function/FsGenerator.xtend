package jcats.generator.function

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class FsGenerator implements ClassGenerator {
	override className() { Constants.F + "s" }
	
	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.Objects;

		final class Fs {
			static final F ID = Objects::requireNonNull;
			«FOR type : Type.values.filter[t | t != Type.OBJECT]»
				static final «type.typeName»«type.typeName»F «type.typeName.toUpperCase»_ID = value -> value;
			«ENDFOR»
		}
	''' }
}