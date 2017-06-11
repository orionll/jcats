package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class UniqueContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new UniqueContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.uniqueContainerShortName }
	def genericName() { type.genericName("UniqueContainer") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;
		
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.Set;
		import java.util.Spliterator;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		public interface «genericName» extends «type.containerGenericName», Equatable<«genericName»> {

			@Override
			default Collection<«type.genericBoxedName»> asCollection() {
				return asSet();
			}

			default Set<«type.genericBoxedName»> asSet() {
				return new «type.diamondName("UniqueContainerAsSet")»(this);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class «type.genericName("UniqueContainerAsSet")» extends AbstractImmutableSet<«type.genericBoxedName»> {
			final «genericName» container;

			«shortName»AsSet(final «genericName» container) {
				this.container = container;
			}

			@Override
			public int size() {
				return container.size();
			}

			@Override
			public boolean contains(final Object obj) {
				«IF type == Type.OBJECT»
					if (obj == null) {
						return false;
					} else {
						return container.contains((A) obj);
					}
				«ELSE»
					if (obj instanceof «type.boxedName») {
						return container.contains((«type.javaName») obj);
					} else {
						return false;
					}
				«ENDIF»
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