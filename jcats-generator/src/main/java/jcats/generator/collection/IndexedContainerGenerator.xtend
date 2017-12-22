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
		«IF type == Type.OBJECT»
			import java.util.Collections;
		«ENDIF»
		import java.util.Iterator;
		import java.util.List;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("IndexedContainer")» extends «type.containerGenericName», «type.indexedGenericName», Equatable<«genericName»> {

			@Override
			default List<«type.genericBoxedName»> asCollection() {
				return new «shortName»AsList«IF type == Type.OBJECT»<>«ENDIF»(this);
			}
			«IF type == Type.OBJECT»

				static <A> IndexedContainer<A> asIndexedContainer(final List<A> list) {
					requireNonNull(list);
					return new ListAsIndexedContainer<>(list);
				}

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

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				container.forEach(action);
			}
		}
		«IF type == Type.OBJECT»

			final class ListAsIndexedContainer<A> extends CollectionAsContainer<A> implements IndexedContainer<A> {

				ListAsIndexedContainer(final List<A> collection) {
					super(collection);
				}

				@Override
				public A get(final int index) {
					return ((List<A>) collection).get(index);
				}

				@Override
				public IntOption indexOf(final A value) {
					final int index = ((List<A>) collection).indexOf(value);
					return (index >= 0) ? intSome(index) : intNone();
				}

				@Override
				public IntOption lastIndexOf(final A value) {
					final int index = ((List<A>) collection).lastIndexOf(value);
					return (index >= 0) ? intSome(index) : intNone();
				}

				@Override
				public Iterator<A> reverseIterator() {
					if (collection instanceof RandomAccess) {
						final List<A> list = (List<A>) collection;
						final int size = list.size();
						if (size == 0) {
							return Collections.emptyIterator();
						} else {
							return new ListReverseIterator<>(list, size);
						}
					} else {
						return toArray().reverseIterator();
					}
				}

				@Override
				public List<A> asCollection() {
					return (List<A>) collection;
				}

				@Override
				public int hashCode() {
					return iterableHashCode(this);
				}

				@Override
				public boolean equals(final Object obj) {
					if (obj == this) {
						return true;
					} else if (obj instanceof IndexedContainer) {
						return indexedContainersEqual(this, (IndexedContainer<?>) obj);
					} else {
						return false;
					}
				}
			}
		«ENDIF»
	''' }
}