package jcats.generator.collection

import jcats.generator.Generator
import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import jcats.generator.Type
import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

@FinalFieldsConstructor
class ContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Container" else type.typeName + "Container" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.stream.«type.streamName»;
		import java.util.stream.StreamSupport;

		import «Constants.SIZED»;
		import «Constants.FUNCTION».«type.effShortName»;

		import static java.util.Objects.requireNonNull;


		public interface «genericName» extends Iterable<«type.genericBoxedName»>, Sized {

			default boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				for (final «type.genericName» a : this) {
					«IF type == Type.OBJECT»
						if (a.equals(value)) {
					«ELSE»
						if (a == value) {
					«ENDIF»
						return true;
					}
				}
				return false;
			}

			default void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				«IF Type.javaUnboxedTypes.contains(type)»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						eff.apply(iterator.«type.iteratorNext»());
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						eff.apply(value);
					}
				«ENDIF»
			}

			«IF Type.javaUnboxedTypes.contains(type)»
				@Override
				«type.iteratorGenericName» iterator();

				@Override
				«type.spliteratorGenericName» spliterator();

			«ENDIF»
			default «type.streamGenericName» stream() {
				return StreamSupport.«type.streamFunction»(spliterator(), false);
			}

			default «type.streamGenericName» parallelStream() {
				return StreamSupport.«type.streamFunction»(spliterator(), true);
			}
		}
	''' }
}