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
		import java.util.NavigableSet;
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
			«type.sortedUniqueContainerViewGenericName» view();

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

			static «type.paramGenericName("SortedUniqueContainerView")» as«type.sortedUniqueContainerShortName»(final SortedSet<«type.genericBoxedName»> set) {
				requireNonNull(set);
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(set, false);
			}

			static «type.paramGenericName("SortedUniqueContainerView")» asFixedSize«type.sortedUniqueContainerShortName»(final SortedSet<«type.genericBoxedName»> set) {
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
					return this.container.ord().toOrd();
				}

				@Override
				public SortedUniqueContainerView<«type.boxedName»> slice(final «type.boxedName» from, final boolean fromInclusive, final «type.boxedName» to, final boolean toInclusive) {
					return new «shortName»AsSortedUniqueContainer(this.container.view().slice(from, fromInclusive, to, toInclusive));
				}

				@Override
				public SortedUniqueContainerView<«type.boxedName»> sliceFrom(final «type.boxedName» from, final boolean inclusive) {
					return new «shortName»AsSortedUniqueContainer(this.container.view().sliceFrom(from, inclusive));
				}

				@Override
				public SortedUniqueContainerView<«type.boxedName»> sliceTo(final «type.boxedName» to, final boolean inclusive) {
					return new «shortName»AsSortedUniqueContainer(this.container.view().sliceTo(to, inclusive));
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
				return new «type.diamondName("SortedUniqueContainerAsSortedSet")»(this.container.view().slice(fromElement, true, toElement, false));
			}

			@Override
			public SortedSet<«type.genericBoxedName»> headSet(final «type.genericBoxedName» toElement) {
				return new «type.diamondName("SortedUniqueContainerAsSortedSet")»(this.container.view().sliceTo(toElement, false));
			}

			@Override
			public SortedSet<«type.genericBoxedName»> tailSet(final «type.genericBoxedName» fromElement) {
				return new «type.diamondName("SortedUniqueContainerAsSortedSet")»(this.container.view().sliceFrom(fromElement, true));
			}

			@Override
			public «type.genericBoxedName» first() {
				return this.container.first();
			}

			@Override
			public «type.genericBoxedName» last() {
				return this.container.last();
			}
		}

		«IF type == Type.OBJECT»
			final class SortedSetAsSortedUniqueContainer<A> extends SetAsUniqueContainer<SortedSet<A>, A> implements SortedUniqueContainerView<A> {
		«ELSE»
			final class «type.shortName("SortedSet")»As«type.sortedUniqueContainerShortName» extends «type.shortName("Set")»As«type.uniqueContainerShortName»<SortedSet<«type.boxedName»>> implements «type.sortedUniqueContainerViewGenericName» {
		«ENDIF»

			«type.shortName("SortedSet")»As«type.sortedUniqueContainerShortName»(final SortedSet<«type.genericBoxedName»> set, final boolean fixedSize) {
				super(set, fixedSize);
			}

			@Override
			public «type.ordGenericName» ord() {
				return «type.ordShortName».fromComparator((Comparator<«type.genericBoxedName»>) this.collection.comparator());
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» slice(final «type.genericName» from, final boolean fromInclusive, final «type.genericName» to, final boolean toInclusive) {
				«IF type == Type.OBJECT»
					requireNonNull(from);
					requireNonNull(to);
				«ENDIF»
				final SortedSet<«type.genericBoxedName»> subSet;
				if (fromInclusive && !toInclusive) {
					subSet = this.collection.subSet(from, to);
				} else {
					subSet = ((NavigableSet<«type.genericBoxedName»>) this.collection).subSet(from, fromInclusive, to, toInclusive);
				}
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(subSet, hasFixedSize());
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» sliceFrom(final «type.genericName» from, final boolean inclusive) {
				«IF type == Type.OBJECT»
					requireNonNull(from);
				«ENDIF»
				final SortedSet<«type.genericBoxedName»> tailSet;
				if (inclusive) {
					tailSet = this.collection.tailSet(from);
				} else {
					tailSet = ((NavigableSet<«type.genericBoxedName»>) this.collection).tailSet(from, inclusive);
				}
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(tailSet, hasFixedSize());
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» sliceTo(final «type.genericName» to, final boolean inclusive) {
				«IF type == Type.OBJECT»
					requireNonNull(to);
				«ENDIF»
				final SortedSet<«type.genericBoxedName»> headSet;
				if (inclusive) {
					headSet = ((NavigableSet<«type.genericBoxedName»>) this.collection).headSet(to, inclusive);
				} else {
					headSet = this.collection.headSet(to);
				}
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(headSet, hasFixedSize());
			}

			@Override
			public SortedSet<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableSortedSet(this.collection);
			}
		}
	''' }
}