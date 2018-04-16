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
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.Set;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("UniqueContainer")» extends «type.containerGenericName», Equatable<«genericName»> {

			«IF type.primitive»
				default UniqueContainer<«type.boxedName»> asContainer() {
					return new «shortName»AsUniqueContainer(this);
				}

			«ENDIF»
			@Override
			default Set<«type.genericBoxedName»> asCollection() {
				return new «type.diamondName("UniqueContainerAsSet")»(this);
			}

			@Override
			default int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE;
			}

			«IF type == Type.OBJECT»
				static <A> UniqueContainer<A> asUniqueContainer(final Set<A> set) {
					requireNonNull(set);
					return new SetAsUniqueContainer<>(set);
				}
			«ELSE»
				static «type.uniqueContainerGenericName» as«type.typeName»UniqueContainer(final Set<«type.boxedName»> set) {
					requireNonNull(set);
					return new «type.typeName»SetAs«type.typeName»UniqueContainer(set);
				}
			«ENDIF»
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type.primitive»
			final class «shortName»AsUniqueContainer extends «type.typeName»ContainerAsContainer<«shortName»> implements UniqueContainer<«type.boxedName»> {

				«shortName»AsUniqueContainer(final «shortName» container) {
					super(container);
				}

				@Override
				public Set<«type.boxedName»> asCollection() {
					return this.container.asCollection();
				}

				«uniqueHashCode(Type.OBJECT)»

				«uniqueEquals(Type.OBJECT)»
			}

		«ENDIF»
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
			public boolean isEmpty() {
				return this.container.isEmpty();
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
			final class SetAsUniqueContainer<A> extends CollectionAsContainer<Set<A>, A> implements UniqueContainer<A> {
		«ELSE»
			final class «type.typeName»SetAs«type.typeName»UniqueContainer extends «type.typeName»CollectionAs«type.typeName»Container<Set<«type.boxedName»>> implements «type.typeName»UniqueContainer {
		«ENDIF»
			
			«IF type == Type.OBJECT»
				SetAsUniqueContainer(final Set<A> set) {
			«ELSE»
				«type.typeName»SetAs«type.typeName»UniqueContainer(final Set<«type.boxedName»> set) {
			«ENDIF»
				super(set);
			}

			@Override
			public Set<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableSet(this.collection);
			}

			«uniqueHashCode(type)»

			«uniqueEquals(type)»
		}
	''' }
}