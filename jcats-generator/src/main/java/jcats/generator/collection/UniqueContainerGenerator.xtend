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
	def genericName() { type.uniqueContainerGenericName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Collection;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.Set;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;
		import java.io.Serializable;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("UniqueContainer")» extends «type.containerGenericName», Equatable<«genericName»> {

			@Override
			default «type.uniqueContainerViewGenericName» view() {
				return new «type.shortName("BaseUniqueContainerView")»<>(this);
			}

			«IF type.primitive»
				@Override
				default UniqueContainerView<«type.boxedName»> asContainer() {
					return new «shortName»AsUniqueContainer<>(this);
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

			/**
			 * «equalsDeprecatedJavaDoc»
			 */
			@Override
			@Deprecated
			boolean equals(final Object other);

			static «IF type == Type.OBJECT»<A> «ENDIF»«type.uniqueContainerGenericName» as«type.uniqueContainerShortName»(final Set<«type.genericBoxedName»> set) {
				requireNonNull(set);
				return new «type.shortName("Set")»As«type.uniqueContainerShortName»<>(set, false);
			}

			static «IF type == Type.OBJECT»<A> «ENDIF»«type.uniqueContainerGenericName» asFixedSize«type.uniqueContainerShortName»(final Set<«type.genericBoxedName»> set) {
				requireNonNull(set);
				return new «type.shortName("Set")»As«type.uniqueContainerShortName»<>(set, true);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type.primitive»
			class «shortName»AsUniqueContainer<C extends «shortName»> extends «type.typeName»ContainerAsContainer<C> implements UniqueContainerView<«type.boxedName»> {

				«shortName»AsUniqueContainer(final C container) {
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
		«IF type == Type.OBJECT»
			class UniqueContainerAsSet<A, C extends UniqueContainer<A>> extends AbstractImmutableSet<A> implements Serializable {
		«ELSE»
			class «type.typeName»UniqueContainerAsSet<C extends «type.uniqueContainerGenericName»> extends AbstractImmutableSet<«type.genericBoxedName»> implements Serializable {
		«ENDIF»
			final C container;

			«shortName»AsSet(final C container) {
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
			class SetAsUniqueContainer<C extends Set<A>, A> extends CollectionAsContainer<C, A> implements UniqueContainer<A> {
		«ELSE»
			class «type.typeName»SetAs«type.typeName»UniqueContainer<C extends Set<«type.boxedName»>> extends «type.typeName»CollectionAs«type.typeName»Container<C> implements «type.typeName»UniqueContainer {
		«ENDIF»

			«type.shortName("Set")»As«type.uniqueContainerShortName»(final C set, final boolean fixedSize) {
				super(set, fixedSize);
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