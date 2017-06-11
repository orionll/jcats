package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class IndexedContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new IndexedContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "IndexedContainer" else type.typeName + "IndexedContainer" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;
		
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.List;
		import java.util.RandomAccess;
		import java.util.Spliterator;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		public interface «genericName» extends «type.containerGenericName», «type.indexedGenericName», Equatable<«genericName»> {

			@Override
			default Collection<«type.genericBoxedName»> asCollection() {
				return asList();
			}

			default List<«type.genericBoxedName»> asList() {
				return new «shortName»AsList«IF type == Type.OBJECT»<>«ENDIF»(this);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class «type.genericName("IndexedContainerAsList")» extends AbstractImmutableList<«type.genericBoxedName»> implements RandomAccess {
			final «genericName» container;

			«shortName»AsList(final «genericName» container) {
				this.container = container;
			}

			@Override
			public «type.genericBoxedName» get(final int index) {
				return container.get(index);
			}

			@Override
			public int size() {
				return container.size();
			}

			«IF type == Type.OBJECT»
				@Override
				public Object[] toArray() {
					return container.toObjectArray();
				}

			«ENDIF»
			@Override
			public Iterator<«type.genericBoxedName»> iterator() {
				return container.iterator();
			}

			@Override
			public Spliterator<«type.genericBoxedName»> spliterator() {
				return container.spliterator();
			}
		}
	''' }
}