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

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Comparator;
		import java.util.Iterator;
		«IF type.primitive»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.NoSuchElementException;
		import java.util.SortedSet;
		import java.util.Spliterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		«IF type == Type.OBJECT»
			import static java.util.Objects.requireNonNull;
		«ENDIF»
		import static «Constants.JCATS».«type.optionShortName».*;

		public interface «type.covariantName("SortedUniqueContainer")» extends «type.uniqueContainerGenericName», «type.orderedContainerGenericName» {

			«type.ordGenericName» ord();

			@Override
			default «type.genericName» last() throws NoSuchElementException {
				return reverseIterator().«type.iteratorNext»();
			}

			@Override
			default «type.optionGenericName» lastOption() {
				final «type.iteratorGenericName» iterator = reverseIterator();
				if (iterator.hasNext()) {
					return «type.someName»(iterator.«type.iteratorNext»());
				} else {
					return «type.noneName»();
				}
			}

			«IF type == Type.OBJECT»
				@Override
				default «type.optionGenericName» max(final «type.ordGenericName» ord) {
					if (ord == ord()) {
						return lastOption();
					} else {
						return «type.uniqueContainerShortName».super.max(ord);
					}
				}

				@Override
				default «type.optionGenericName» min(final «type.ordGenericName» ord) {
					if (ord == ord()) {
						return firstOption();
					} else {
						return «type.uniqueContainerShortName».super.min(ord);
					}
				}
			«ELSE»
				@Override
				default «type.optionGenericName» max() {
					return lastOption();
				}

				@Override
				default «type.optionGenericName» min() {
					return firstOption();
				}

				@Override
				default «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
					if (ord == ord()) {
						return lastOption();
					} else {
						return «type.uniqueContainerShortName».super.maxByOrd(ord);
					}
				}

				@Override
				default «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
					if (ord == ord()) {
						return firstOption();
					} else {
						return «type.uniqueContainerShortName».super.minByOrd(ord);
					}
				}
			«ENDIF»

			@Override
			«type.sortedUniqueContainerViewGenericName» view();

			«IF type.primitive»
				@Override
				default SortedUniqueContainerView<«type.boxedName»> boxed() {
					return new «type.typeName»BoxedSortedUniqueContainer(this);
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
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type.primitive»
			final class «type.typeName»BoxedSortedUniqueContainer extends «type.typeName»BoxedUniqueContainer<«shortName»> implements SortedUniqueContainerView<«type.boxedName»> {

				«type.typeName»BoxedSortedUniqueContainer(final «shortName» container) {
					super(container);
				}

				@Override
				public «type.boxedName» last() {
					return this.container.last();
				}

				@Override
				public Option<«type.boxedName»> lastOption() {
					return this.container.lastOption().toOption();
				}

				@Override
				public Option<«type.boxedName»> lastMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.lastMatch(predicate::apply).toOption();
				}

				@Override
				public <A> A foldRight(final A start, final F2<«type.boxedName», A, A> f2) {
					return this.container.foldRight(start, f2::apply);
				}

				«FOR returnType : Type.primitives»
					@Override
					public «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<«type.boxedName»> f2) {
						return this.container.foldRightTo«returnType.typeName»(start, f2::apply);
					}

				«ENDFOR»
				@Override
				public Iterator<«type.genericBoxedName»> reverseIterator() {
					return this.container.reverseIterator();
				}

				@Override
				public Ord<«type.boxedName»> ord() {
					return this.container.ord().toOrd();
				}

				@Override
				public SortedUniqueContainerView<«type.boxedName»> slice(final «type.boxedName» from, final boolean fromInclusive, final «type.boxedName» to, final boolean toInclusive) {
					return new «type.typeName»BoxedSortedUniqueContainer(this.container.view().slice(from, fromInclusive, to, toInclusive));
				}

				@Override
				public SortedUniqueContainerView<«type.boxedName»> sliceFrom(final «type.boxedName» from, final boolean inclusive) {
					return new «type.typeName»BoxedSortedUniqueContainer(this.container.view().sliceFrom(from, inclusive));
				}

				@Override
				public SortedUniqueContainerView<«type.boxedName»> sliceTo(final «type.boxedName» to, final boolean inclusive) {
					return new «type.typeName»BoxedSortedUniqueContainer(this.container.view().sliceTo(to, inclusive));
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
	'''
}