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
		Type.values.filter[it != Type.BOOLEAN].map[new UniqueContainerGenerator(it) as Generator].toList
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.uniqueContainerShortName }
	def genericName() { type.genericName("UniqueContainer") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Collection;
		«IF type == Type.OBJECT»
			import java.util.Collections;
		«ENDIF»
		import java.util.Iterator;
		import java.util.Set;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("UniqueContainer")» extends «type.containerGenericName», Equatable<«genericName»> {

			@Override
			default Set<«type.genericBoxedName»> asCollection() {
				return new «type.diamondName("UniqueContainerAsSet")»(this);
			}

			@Override
			default «type.spliteratorGenericName» spliterator() {
				if (isEmpty()) {
					return Spliterators.«type.emptySpliteratorName»();
				} else {
					return Spliterators.spliterator(iterator(), size(), Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE);
				}
			}
			«IF type == Type.OBJECT»

				static <A> UniqueContainer<A> asUniqueContainer(final Set<A> set) {
					requireNonNull(set);
					return new SetAsUniqueContainer<>(set);
				}

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
				return this.container.size();
			}

			@Override
			public boolean contains(final Object obj) {
				«IF type == Type.OBJECT»
					if (obj == null) {
						return false;
					} else {
						return this.container.contains((A) obj);
					}
				«ELSE»
					if (obj instanceof «type.boxedName») {
						return this.container.contains((«type.javaName») obj);
					} else {
						return false;
					}
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				@Override
				public Object[] toArray() {
					return this.container.toObjectArray();
				}

			«ENDIF»
			@Override
			public Iterator<«type.genericBoxedName»> iterator() {
				return this.container.iterator();
			}

			@Override
			public Spliterator<«type.genericBoxedName»> spliterator() {
				return this.container.spliterator();
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.container.forEach(action);
			}
		}
		«IF type == Type.OBJECT»

			final class SetAsUniqueContainer<A> extends CollectionAsContainer<A> implements UniqueContainer<A> {

				SetAsUniqueContainer(final Set<A> collection) {
					super(collection);
				}

				@Override
				public Set<A> asCollection() {
					return Collections.unmodifiableSet((Set<A>) this.collection);
				}

				@Override
				public int hashCode() {
					return uniqueContainerHashCode(this);
				}

				@Override
				public boolean equals(final Object obj) {
					if (obj == this) {
						return true;
					} else if (obj instanceof UniqueContainer) {
						return uniqueContainersEqual(this, (UniqueContainer<?>) obj);
					} else {
						return false;
					}
				}
			}
		«ENDIF»
	''' }
}