package jcats.generator

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.List

@FinalFieldsConstructor
final class IndexedGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new IndexedGenerator(it) as Generator]
	}

	override className() { Constants.JCATS + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Indexed" else type.typeName + "Indexed" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import static java.util.Objects.requireNonNull;

		public interface «type.covariantName("Indexed")» {

			«type.genericName» get(int index) throws IndexOutOfBoundsException;
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}