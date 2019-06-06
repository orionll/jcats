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

	def shortName() { type.sortedUniqueContainerViewShortName }
	def genericName() { type.sortedUniqueContainerViewGenericName }
	def paramComparableGenericName() { type.paramComparableGenericName("SortedUniqueContainerView") }
	def baseShortName() { type.shortName("BaseSortedUniqueContainerView") }
	def reverseShortName() { type.shortName("ReverseSortedUniqueContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Comparator;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.NavigableSet;
		import java.util.SortedSet;
		import java.util.TreeSet;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.JCATS».«type.ordShortName».*;

		public interface «type.covariantName("SortedUniqueContainerView")» extends «type.uniqueContainerViewGenericName», «type.sortedUniqueContainerGenericName», «type.orderedContainerViewGenericName» {

			@Override
			@Deprecated
			default «genericName» view() {
				return this;
			}

			@Override
			default «type.sortedUniqueContainerGenericName» unview() {
				return this;
			}

			«IF type == Type.OBJECT»
				@Override
				default «type.indexedContainerViewGenericName» sort(final Ord<A> ord) {
					requireNonNull(ord);
					return new SortedContainerView<>(this, ord, ord() == ord);
				}
			«ELSE»
				@Override
				default «type.indexedContainerViewGenericName» sortAsc() {
					return new «type.shortName("SortedContainerView")»(this, true, ord() == «type.asc»());
				}

				@Override
				default «type.indexedContainerViewGenericName» sortDesc() {
					return new «type.shortName("SortedContainerView")»(this, false, ord() == «type.desc»());
				}
			«ENDIF»

			«genericName» slice(«type.genericName» from, boolean fromInclusive, «type.genericName» to, boolean toInclusive);

			«genericName» sliceFrom(«type.genericName» from, boolean inclusive);

			«genericName» sliceTo(«type.genericName» to, boolean inclusive);

			@Override
			default «genericName» reverse() {
				return new «type.diamondName("ReverseSortedUniqueContainerView")»(unview());
			}

			static «paramComparableGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«type.sortedUniqueContainerViewGenericName») «ENDIF»«type.shortName("SortedUniqueView")».EMPTY;
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
			abstract class «baseShortName»<A, C extends SortedUniqueContainer<A>> extends BaseUniqueContainerView<A, C> implements SortedUniqueContainerView<A> {
		«ELSE»
			abstract class «baseShortName»<C extends «type.sortedUniqueContainerShortName»> extends «type.typeName»BaseUniqueContainerView<C> implements «type.sortedUniqueContainerViewShortName» {
		«ENDIF»

			«baseShortName»(final C container) {
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
			public «type.optionGenericName» findLast() {
				return this.container.findLast();
			}

			@Override
			public «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				return this.container.lastMatch(predicate);
			}

			@Override
			«IF type.primitive»
				public <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSE»
				public <B> B foldRight(final B start, final F2<A, B, B> f2) {
			«ENDIF»
				return this.container.foldRight(start, f2);
			}

			«FOR returnType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<A> f2) {
				«ELSE»
					public «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final «type.typeName»«returnType.typeName»«returnType.typeName»F2 f2) {
				«ENDIF»
					return this.container.foldRightTo«returnType.typeName»(start, f2);
				}

			«ENDFOR»
			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return this.container.reverseIterator();
			}

			@Override
			public «type.sortedUniqueGenericName» to«type.sortedUniqueShortName»() {
				return this.container.to«type.sortedUniqueShortName»();
			}

			@Override
			public TreeSet<«type.genericBoxedName»> toTreeSet() {
				return this.container.toTreeSet();
			}

			@Override
			public SortedSet<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«IF type.primitive»
				@Override
				public SortedUniqueContainerView<«type.boxedName»> boxed() {
					return this.container.boxed();
				}

			«ENDIF»
			@Override
			public «type.sortedUniqueContainerGenericName» unview() {
				return this.container;
			}
		}

		final class «type.genericName("ReverseSortedUniqueContainerView")» extends «type.shortName("ReverseOrderedContainerView")»<«IF type == Type.OBJECT»A, «ENDIF»«type.sortedUniqueContainerGenericName»> implements «genericName» {

			«reverseShortName»(final «type.sortedUniqueContainerGenericName» container) {
				super(container);
			}

			@Override
			public «type.ordGenericName» ord() {
				return this.container.ord().reversed();
			}

			@Override
			public «genericName» slice(final «type.genericName» from, final boolean fromInclusive, final «type.genericName» to, final boolean toInclusive) {
				return new «type.diamondName("ReverseSortedUniqueContainerView")»(this.container.view().slice(to, toInclusive, from, fromInclusive));
			}

			@Override
			public «genericName» sliceFrom(final «type.genericName» from, final boolean inclusive) {
				return new «type.diamondName("ReverseSortedUniqueContainerView")»(this.container.view().sliceTo(from, inclusive));
			}

			@Override
			public «genericName» sliceTo(final «type.genericName» to, final boolean inclusive) {
				return new «type.diamondName("ReverseSortedUniqueContainerView")»(this.container.view().sliceFrom(to, inclusive));
			}

			@Override
			public «genericName» reverse() {
				return this.container.view();
			}

			@Override
			public int hashCode() {
				return this.container.hashCode();
			}

			@Override
			@SuppressWarnings("deprecation")
			public boolean equals(final Object obj) {
				return this.container.equals(obj);
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
			public «type.genericName» first() {
				return this.collection.first();
			}

			@Override
			public «type.genericName» last() {
				return this.collection.last();
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