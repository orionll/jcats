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

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.Set;
		import java.util.Spliterator;
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
				default UniqueContainerView<«type.boxedName»> boxed() {
					return new «type.typeName»BoxedUniqueContainer<>(this);
				}

			«ENDIF»
			@Override
			default Set<«type.genericBoxedName»> asCollection() {
				return new «type.shortName("UniqueContainerAsSet")»<>(this);
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
			boolean equals(Object other);
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type.primitive»
			class «type.typeName»BoxedUniqueContainer<C extends «shortName»> extends «type.typeName»BoxedContainer<C> implements UniqueContainerView<«type.boxedName»> {

				«type.typeName»BoxedUniqueContainer(final C container) {
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

			@Override
			public Object[] toArray() {
				«IF type == Type.OBJECT»
					return this.container.toObjectArray();
				«ELSE»
					return «type.containerShortName.firstToLowerCase»ToArray(this.container);
				«ENDIF»
			}

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
	'''
}