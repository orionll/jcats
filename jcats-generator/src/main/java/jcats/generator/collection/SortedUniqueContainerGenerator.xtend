package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SortedUniqueContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].map[new SortedUniqueContainerGenerator(it) as Generator].toList
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.sortedUniqueContainerShortName }
	def genericName() { type.genericName("SortedUniqueContainer") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Comparator;
		import java.util.«IF type.javaUnboxedType»Primitive«ENDIF»Iterator;
		import java.util.NoSuchElementException;
		import java.util.SortedSet;
		import java.util.Spliterator;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.optionShortName».*;

		public interface «type.covariantName("SortedUniqueContainer")» extends «type.uniqueContainerGenericName» {

			«type.ordGenericName» ord();

			default «type.genericName» last() throws NoSuchElementException {
				return reverseIterator().«type.iteratorNext»();
			}

			default «type.optionGenericName» lastOption() {
				final «type.iteratorGenericName» iterator = reverseIterator();
				if (iterator.hasNext()) {
					return «type.someName»(iterator.«type.iteratorNext»());
				} else {
					return «type.noneName»();
				}
			}

			@Override
			default «type.sortedUniqueContainerViewGenericName» view() {
				return new «type.shortName("BaseSortedUniqueContainerView")»<>(this);
			}

			«IF type.primitive»
				@Override
				default SortedUniqueContainerView<«type.boxedName»> asContainer() {
					return new «shortName»AsSortedUniqueContainer(this);
				}

			«ENDIF»
			@Override
			default SortedSet<«type.genericBoxedName»> asCollection() {
				return new «type.diamondName("SortedUniqueContainerAsSortedSet")»(this);
			}

			@Override
			default int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			static «IF type == Type.OBJECT»<A> «ENDIF»«type.sortedUniqueContainerGenericName» as«type.sortedUniqueContainerShortName»(final SortedSet<«type.genericBoxedName»> set) {
				requireNonNull(set);
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(set, false);
			}

			static «IF type == Type.OBJECT»<A> «ENDIF»«type.sortedUniqueContainerGenericName» asFixedSize«type.sortedUniqueContainerShortName»(final SortedSet<«type.genericBoxedName»> set) {
				requireNonNull(set);
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(set, true);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type.primitive»
			final class «shortName»AsSortedUniqueContainer extends «type.typeName»UniqueContainerAsUniqueContainer<«shortName»> implements SortedUniqueContainerView<«type.boxedName»> {

				«shortName»AsSortedUniqueContainer(final «shortName» container) {
					super(container);
				}

				@Override
				public Ord<«type.boxedName»> ord() {
					throw new UnsupportedOperationException("Not implemented");
				}

				@Override
				public SortedSet<«type.boxedName»> asCollection() {
					return this.container.asCollection();
				}
			}

		«ENDIF»
		final class «type.genericName("SortedUniqueContainerAsSortedSet")» extends «type.shortName("UniqueContainerAsSet")»<«IF type == Type.OBJECT»A, «ENDIF»«genericName»> implements SortedSet<«type.genericBoxedName»> {

			«shortName»AsSortedSet(final «genericName» container) {
				super(container);
			}

			@Override
			public Comparator<? super «type.genericBoxedName»> comparator() {
				return this.container.ord();
			}

			@Override
			public SortedSet<«type.genericBoxedName»> subSet(final «type.genericBoxedName» fromElement, final «type.genericBoxedName» toElement) {
				throw new UnsupportedOperationException("Not implemented");
			}

			@Override
			public SortedSet<«type.genericBoxedName»> headSet(final «type.genericBoxedName» toElement) {
				throw new UnsupportedOperationException("Not implemented");
			}

			@Override
			public SortedSet<«type.genericBoxedName»> tailSet(final «type.genericBoxedName» fromElement) {
				throw new UnsupportedOperationException("Not implemented");
			}

			@Override
			public «type.genericBoxedName» first() {
				return this.container.head();
			}

			@Override
			public «type.genericBoxedName» last() {
				return this.container.last();
			}
		}

		«IF type == Type.OBJECT»
			final class SortedSetAsSortedUniqueContainer<A> extends SetAsUniqueContainer<SortedSet<A>, A> implements SortedUniqueContainer<A> {
		«ELSE»
			final class «type.shortName("SortedSet")»As«type.sortedUniqueContainerShortName» extends «type.shortName("Set")»As«type.uniqueContainerShortName»<SortedSet<«type.boxedName»>> implements «type.sortedUniqueContainerGenericName» {
		«ENDIF»

			«type.shortName("SortedSet")»As«type.sortedUniqueContainerShortName»(final SortedSet<«type.genericBoxedName»> set, final boolean fixedSize) {
				super(set, fixedSize);
			}

			@Override
			public «type.ordGenericName» ord() {
				return «type.ordShortName».fromComparator((Comparator<«type.genericBoxedName»>) this.collection.comparator());
			}

			@Override
			public SortedSet<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableSortedSet(this.collection);
			}
		}
	''' }
}