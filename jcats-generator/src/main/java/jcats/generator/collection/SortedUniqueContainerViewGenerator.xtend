package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SortedUniqueContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].toList.map[new SortedUniqueContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("SortedUniqueContainerView") }
	def genericName() { type.genericName("SortedUniqueContainerView") }
	def baseSortedUniqueContainerViewShortName() { type.shortName("BaseSortedUniqueContainerView") }
	
	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Comparator;
		import java.util.NavigableSet;
		import java.util.SortedSet;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.JCATS».«type.ordShortName».*;

		public interface «type.covariantName("SortedUniqueContainerView")» extends «type.uniqueContainerViewGenericName», «type.sortedUniqueContainerGenericName» {

			«genericName» slice(final «type.genericName» from, final boolean fromInclusive, final «type.genericName» to, final boolean toInclusive);

			«genericName» sliceFrom(final «type.genericName» from, final boolean inclusive);

			«genericName» sliceTo(final «type.genericName» to, final boolean inclusive);

			@Override
			@Deprecated
			default «type.sortedUniqueContainerViewGenericName» view() {
				return this;
			}

			static «type.paramGenericName("SortedUniqueContainerView")» «type.shortName("SortedSetView").firstToLowerCase»(final SortedSet<«type.genericBoxedName»> sortedSet) {
				return «type.shortName("SortedSetView").firstToLowerCase»(sortedSet, true);
			}

			static «type.paramGenericName("SortedUniqueContainerView")» «type.shortName("SortedSetView").firstToLowerCase»(final SortedSet<«type.genericBoxedName»> sortedSet, final boolean hasKnownFixedSize) {
				requireNonNull(sortedSet);
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(sortedSet, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			abstract class «baseSortedUniqueContainerViewShortName»<A, C extends SortedUniqueContainer<A>> extends BaseUniqueContainerView<A, C> implements SortedUniqueContainerView<A> {
		«ELSE»
			abstract class «baseSortedUniqueContainerViewShortName»<C extends «type.sortedUniqueContainerShortName»> extends «type.typeName»BaseUniqueContainerView<C> implements «type.sortedUniqueContainerViewShortName» {
		«ENDIF»

			«baseSortedUniqueContainerViewShortName»(final C container) {
				super(container);
			}

			@Override
			public «type.ordGenericName» ord() {
				return this.container.ord();
			}

			@Override
			public «type.genericName» last() {
				return this.container.last();
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return this.container.lastOption();
			}

			@Override
			public SortedSet<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«IF type.primitive»
				@Override
				public SortedUniqueContainerView<«type.boxedName»> asContainer() {
					return this.container.asContainer();
				}

			«ENDIF»
			«toStr(type)»
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
				final Comparator<«type.genericBoxedName»> comparator = (Comparator<«type.genericBoxedName»>) this.collection.comparator();
				if (comparator == null) {
					return «IF type == Type.OBJECT»(Ord<A>) «ENDIF»«type.asc»();
				} else {
					return «type.ordShortName».fromComparator(comparator);
				}
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
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(subSet, hasKnownFixedSize());
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
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(tailSet, hasKnownFixedSize());
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
				return new «type.shortName("SortedSet")»As«type.sortedUniqueContainerDiamondName»(headSet, hasKnownFixedSize());
			}

			@Override
			public SortedSet<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableSortedSet(this.collection);
			}
		}
	'''
}