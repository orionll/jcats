package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OrderedContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new OrderedContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.orderedContainerViewShortName }
	def genericName() { type.orderedContainerViewGenericName }
	def baseShortName() { type.shortName("BaseOrderedContainerView") }
	def mappedShortName() { type.shortName("MappedOrderedContainerView") }
	def mapTargetType() { if (type == Type.OBJECT) "B" else "A" }
	def filteredShortName() { type.shortName("FilteredOrderedContainerView") }
	def limitedShortName() { type.shortName("LimitedOrderedContainerView") }
	def skippedShortName() { type.shortName("SkippedOrderedContainerView") }
	def reverseShortName() { type.shortName("ReverseOrderedContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collection;
		«IF !type.javaUnboxedType»
			import java.util.Collections;
		«ENDIF»
		import java.util.Deque;
		import java.util.Iterator;
		import java.util.List;
		import java.util.NavigableSet;
		import java.util.HashSet;
		import java.util.PrimitiveIterator;
		import java.util.RandomAccess;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF type.javaUnboxedType»
			import static «Constants.JCATS».«type.optionShortName».*;
		«ENDIF»
		import static «Constants.FUNCTION».«type.shortName("BooleanF")».*;
		import static «Constants.COMMON».*;
		«IF type.primitive»
			import static «Constants.COLLECTION».«type.arrayShortName».*;
		«ENDIF»

		public interface «type.covariantName("OrderedContainerView")» extends «type.containerViewGenericName», «type.orderedContainerGenericName» {

			@Override
			@Deprecated
			default «genericName» view() {
				return this;
			}

			@Override
			default «type.orderedContainerGenericName» unview() {
				return this;
			}

			@Override
			«IF type == Type.OBJECT»
				default <B> OrderedContainerView<B> map(final F<A, B> f) {
			«ELSE»
				default <A> OrderedContainerView<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return new «mappedShortName»<>(unview(), f);
			}

			«FOR toType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					default «toType.orderedContainerViewGenericName» mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
				«ELSE»
					default «toType.orderedContainerViewGenericName» mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»OrderedContainerView<>(unview(), f);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				default <B> OrderedContainerView<B> flatMap(final F<A, Iterable<B>> f) {
					requireNonNull(f);
					return new FlatMappedOrderedContainerView<>(unview(), f);
				}
			«ELSE»
				default <A> OrderedContainerView<A> flatMap(final «type.typeName»ObjectF<Iterable<A>> f) {
					requireNonNull(f);
					return new «type.typeName»FlatMappedOrderedContainerView<>(unview(), f);
				}
			«ENDIF»
			«FOR toType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					default «toType.orderedContainerViewGenericName» flatMapTo«toType.typeName»(final F<A, Iterable<«toType.genericBoxedName»>> f) {
				«ELSE»
					default «toType.orderedContainerViewGenericName» flatMapTo«toType.typeName»(final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
				«ENDIF»
					requireNonNull(f);
					return new «type.diamondName('''FlatMappedTo«toType.typeName»OrderedContainerView''')»(unview(), f);
				}

			«ENDFOR»
			@Override
			default «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return new «type.diamondName("FilteredOrderedContainerView")»(unview(), predicate);
			}

			«IF type == Type.OBJECT»
				@Override
				default <B extends A> OrderedContainerView<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (OrderedContainerView<B>) filter(clazz::isInstance);
				}

			«ENDIF»
			@Override
			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				} else if (hasKnownFixedSize() && limit >= size()) {
					return this;
				} else {
					return new «limitedShortName»<>(unview(), limit);
				}
			}

			@Override
			default «genericName» skip(final int skip) {
				if (skip < 0) {
					throw new IllegalArgumentException(Integer.toString(skip));
				} else if (skip == 0) {
					return this;
				} else if (hasKnownFixedSize() && skip >= size()) {
					return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view(); 
				} else {
					return new «skippedShortName»<>(unview(), skip);
				}
			}

			default «genericName» reverse() {
				return new «reverseShortName»<>(unview());
			}

			static «type.paramGenericName("OrderedContainerView")» «type.shortName("CollectionView").firstToLowerCase»(final Collection<«type.genericBoxedName»> collection) {
				return «type.shortName("CollectionView").firstToLowerCase»(collection, true);
			}

			static «type.paramGenericName("OrderedContainerView")» «type.shortName("CollectionView").firstToLowerCase»(final Collection<«type.genericBoxedName»> collection, final boolean hasKnownFixedSize) {
				requireNonNull(collection);
				return new «type.shortName("Collection")»As«type.orderedContainerShortName»<>(collection, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			class «baseShortName»<A, C extends OrderedContainer<A>> extends BaseContainerView<A, C> implements OrderedContainerView<A> {
		«ELSE»
			class «baseShortName»<C extends «type.orderedContainerShortName»> extends «type.typeName»BaseContainerView<C> implements «type.orderedContainerViewShortName» {
		«ENDIF»

			«baseShortName»(final C container) {
				super(container);
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

			«IF type.primitive»
				@Override
				public OrderedContainerView<«type.boxedName»> boxed() {
					return this.container.boxed();
				}

			«ENDIF»
			@Override
			public «type.orderedContainerGenericName» unview() {
				return this.container;
			}
		}

		class «mappedShortName»<A, «IF type == Type.OBJECT»B, «ENDIF»C extends «type.orderedContainerGenericName»> extends «type.shortName("MappedContainerView")»<A, «IF type == Type.OBJECT»B, «ENDIF»C> implements OrderedContainerView<«mapTargetType»> {

			«mappedShortName»(final C container, final «IF type == Type.OBJECT»F<A, B>«ELSE»«type.typeName»ObjectF<A>«ENDIF» f) {
				super(container, f);
			}

			@Override
			public «mapTargetType» last() {
				return requireNonNull(this.f.apply(this.container.last()));
			}

			@Override
			public Option<«mapTargetType»> lastOption() {
				return this.container.lastOption().map(this.f);
			}

			@Override
			public Iterator<«mapTargetType»> reverseIterator() {
				«IF type == Type.OBJECT»
					return new MappedIterator<>(this.container.reverseIterator(), this.f);
				«ELSE»
					return new Mapped«type.typeName»ObjectIterator<>(this.container.reverseIterator(), this.f);
				«ENDIF»
			}

			@Override
			«IF type == Type.OBJECT»
				public <D> OrderedContainerView<D> map(final F<B, D> g) {
			«ELSE»
				public <B> OrderedContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedShortName»<>(this.container, this.f.map(g));
			}

			«FOR t : Type.primitives»
				@Override
				public «t.orderedContainerViewGenericName» mapTo«t.typeName»(final «t.typeName»F<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> g) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»OrderedContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
				}

			«ENDFOR»
			@Override
			public OrderedContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedShortName»<>(this.container.view().limit(n), this.f);
			}

			@Override
			public OrderedContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedShortName»<>(this.container.view().skip(n), this.f);
			}
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				class MappedTo«toType.typeName»OrderedContainerView<A, C extends «type.orderedContainerGenericName»> extends MappedTo«toType.typeName»ContainerView<A, C> implements «toType.orderedContainerViewGenericName» {
			«ELSE»
				class «type.typeName»MappedTo«toType.typeName»OrderedContainerView<C extends «type.orderedContainerGenericName»> extends «type.typeName»MappedTo«toType.typeName»ContainerView<C> implements «toType.orderedContainerViewGenericName» {
			«ENDIF»
				«IF type == Type.OBJECT»
					MappedTo«toType.typeName»OrderedContainerView(final C container, final «toType.typeName»F<A> f) {
				«ELSE»
					«type.typeName»MappedTo«toType.typeName»OrderedContainerView(final C container, final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					super(container, f);
				}

				@Override
				public «toType.genericName» last() {
					return this.f.apply(this.container.last());
				}

				@Override
				public «toType.optionGenericName» lastOption() {
					return this.container.lastOption().mapTo«toType.typeName»(this.f);
				}

				@Override
				public «toType.iteratorGenericName» reverseIterator() {
					«IF type == Type.OBJECT»
						return new MappedObject«toType.typeName»Iterator<>(this.container.reverseIterator(), this.f);
					«ELSE»
						return new Mapped«type.typeName»«toType.typeName»Iterator(this.container.reverseIterator(), this.f);
					«ENDIF»
				}

				@Override
				public <B> OrderedContainerView<B> map(final «toType.typeName»ObjectF<B> g) {
					return new «mappedShortName»<>(this.container, this.f.map(g));
				}

				«FOR t : Type.primitives»
					@Override
					public «t.orderedContainerViewGenericName» mapTo«t.typeName»(final «toType.typeName»«t.typeName»F g) {
						return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»OrderedContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
					}

				«ENDFOR»
				@Override
				public «toType.orderedContainerViewGenericName» limit(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»OrderedContainerView<>(this.container.view().limit(n), this.f);
				}

				@Override
				public «toType.orderedContainerViewGenericName» skip(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»OrderedContainerView<>(this.container.view().skip(n), this.f);
				}
			}

		«ENDFOR»
		«IF type == Type.OBJECT»
			final class FlatMappedOrderedContainerView<A, B> extends FlatMappedContainerView<A, B, «type.orderedContainerGenericName»> implements OrderedContainerView<B> {
				FlatMappedOrderedContainerView(final «type.orderedContainerGenericName» container, final F<A, Iterable<B>> f) {
		«ELSE»
			final class «type.typeName»FlatMappedOrderedContainerView<A> extends «type.typeName»FlatMappedContainerView<A, «type.orderedContainerGenericName»> implements OrderedContainerView<A> {
				«type.typeName»FlatMappedOrderedContainerView(final «type.orderedContainerGenericName» container, final «type.typeName»ObjectF<Iterable<A>> f) {
		«ENDIF»
				super(container, f);
			}

			@Override
			public Iterator<«mapTargetType»> reverseIterator() {
				if (this.container.hasKnownFixedSize() || this.container instanceof «type.indexedContainerViewWildcardName») {
					return new FlatMapped«IF type != Type.OBJECT»«type.typeName»Object«ENDIF»ReverseIterator<>(this.container.reverseIterator(), this.f);
				} else {
					return OrderedContainerView.super.reverseIterator();
				}
			}
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				final class FlatMappedTo«toType.typeName»OrderedContainerView<A> extends FlatMappedTo«toType.typeName»ContainerView<A, «type.orderedContainerGenericName»> implements «toType.orderedContainerViewGenericName» {
					FlatMappedTo«toType.typeName»OrderedContainerView(final «type.orderedContainerGenericName» container, final F<A, Iterable<«toType.genericBoxedName»>> f) {
			«ELSE»
				final class «type.typeName»FlatMappedTo«toType.typeName»OrderedContainerView extends «type.typeName»FlatMappedTo«toType.typeName»ContainerView<«type.orderedContainerGenericName»> implements «toType.orderedContainerViewGenericName» {
					«type.typeName»FlatMappedTo«toType.typeName»OrderedContainerView(final «type.orderedContainerGenericName» container, final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
			«ENDIF»
					super(container, f);
				}

				@Override
				public «toType.iteratorGenericName» reverseIterator() {
					if (this.container.hasKnownFixedSize() || this.container instanceof «type.indexedContainerViewWildcardName») {
						«IF type == Type.OBJECT»
							return new FlatMappedObject«toType.typeName»ReverseIterator<>(this.container.reverseIterator(), this.f);
						«ELSE»
							return new FlatMapped«type.typeName»«toType.typeName»ReverseIterator(this.container.reverseIterator(), this.f);
						«ENDIF»
					} else {
						return «toType.orderedContainerViewGenericName».super.reverseIterator();
					}
				}
			}

		«ENDFOR»
		final class «type.genericName("FilteredOrderedContainerView")» extends «type.shortName("FilteredContainerView")»<«IF type == Type.OBJECT»A, «ENDIF»«type.orderedContainerGenericName»> implements «genericName» {

			«filteredShortName»(final «type.orderedContainerGenericName» container, final «type.boolFName» predicate) {
				super(container, predicate);
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				if (this.container.hasKnownFixedSize() || this.container instanceof «type.indexedContainerViewWildcardName») {
					«IF type == Type.OBJECT || type.javaUnboxedType»
						return new «type.diamondName("FilteredIterator")»(this.container.reverseIterator(), this.predicate);
					«ELSE»
						return new FilteredIterator<>(this.container.reverseIterator(), this.predicate::apply);
					«ENDIF»
				} else {
					return «shortName».super.reverseIterator();
				}
			}

			@Override
			public «genericName» filter(final «type.boolFName» p) {
				return new «type.diamondName("FilteredOrderedContainerView")»(this.container, and(this.predicate, p));
			}
		}

		«IF type == Type.OBJECT»
			class «limitedShortName»<A, C extends «type.orderedContainerGenericName»> extends LimitedContainerView<A, C> implements OrderedContainerView<A> {
		«ELSE»
			class «limitedShortName»<C extends «type.orderedContainerGenericName»> extends «type.typeName»LimitedContainerView<C> implements «type.orderedContainerViewGenericName» {
		«ENDIF»

			«limitedShortName»(final C container, final int limit) {
				super(container, limit);
			}

			@Override
			public «type.orderedContainerViewGenericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n < this.limit) {
					return new «limitedShortName»<>(this.container, n);
				} else {
					return this;
				}
			}
		}

		«IF type == Type.OBJECT»
			class «skippedShortName»<A, C extends «type.orderedContainerGenericName»> extends SkippedContainerView<A, C> implements OrderedContainerView<A> {
		«ELSE»
			class «skippedShortName»<C extends «type.orderedContainerGenericName»> extends «type.typeName»SkippedContainerView<C> implements «type.orderedContainerViewGenericName» {
		«ENDIF»

			«skippedShortName»(final C container, final int skip) {
				super(container, skip);
			}

			@Override
			public «type.orderedContainerViewGenericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n > 0) {
					final int sum = this.skip + n;
					if (sum < 0) {
						// Overflow
						if (this.container.hasKnownFixedSize()) {
							return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
						} else {
							return new «skippedShortName»<>(this, n);
						}
					} else {
						if (this.container.hasKnownFixedSize() && sum >= this.container.size()) {
							return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
						} else {
							return new «skippedShortName»<>(this.container, sum);
						}
					}
				} else {
					return this;
				}
			}
		}

		class «reverseShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.orderedContainerGenericName»> implements «genericName» {
			final C container;

			«reverseShortName»(final C container) {
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
			public boolean isNotEmpty() {
				return this.container.isNotEmpty();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.container.hasKnownFixedSize();
			}

			@Override
			public «type.genericName» first() {
				return this.container.last();
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return this.container.lastOption();
			}

			@Override
			public «type.genericName» last() {
				return this.container.first();
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return this.container.firstOption();
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				return this.container.contains(value);
			}

			@Override
			public «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				return this.container.lastMatch(predicate);
			}

			@Override
			public «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				return this.container.firstMatch(predicate);
			}

			@Override
			public boolean anyMatch(final «type.boolFName» predicate) {
				return this.container.anyMatch(predicate);
			}

			@Override
			public boolean allMatch(final «type.boolFName» predicate) {
				return this.container.allMatch(predicate);
			}

			@Override
			public boolean noneMatch(final «type.boolFName» predicate) {
				return this.container.noneMatch(predicate);
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return this.container.reverseIterator();
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return this.container.iterator();
			}

			«IF type.javaUnboxedType»
				@Override
				public «type.javaName» sum() {
					return this.container.sum();
				}

			«ENDIF»
			«IF type == Type.INT»
				@Override
				public long sumToLong() {
					return this.container.sumToLong();
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				@Override
				public «type.optionGenericName» max(final «type.ordGenericName» ord) {
					return this.container.max(ord);
				}

				@Override
				public «type.optionGenericName» min(final «type.ordGenericName» ord) {
					return this.container.min(ord);
				}
			«ELSE»
				@Override
				public «type.optionGenericName» max() {
					return this.container.max();
				}

				@Override
				public «type.optionGenericName» min() {
					return this.container.min();
				}

				@Override
				public «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
					return this.container.maxByOrd(ord);
				}

				@Override
				public «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
					return this.container.minByOrd(ord);
				}
			«ENDIF»

			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» maxBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» maxBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				return this.container.maxBy(f);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» maxBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» maxBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					return this.container.maxBy«to.typeName»(f);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» minBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» minBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				return this.container.minBy(f);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» minBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» minBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					return this.container.minBy«to.typeName»(f);
				}

			«ENDFOR»
			@Override
			public «genericName» reverse() {
				return this.container.view();
			}

			«IF type == Type.OBJECT»
				@Override
				public Unique<A> toUnique() {
					return this.container.toUnique();
				}

			«ENDIF»
			@Override
			public HashSet<«type.genericBoxedName»> toHashSet() {
				return this.container.toHashSet();
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.container.spliteratorCharacteristics();
			}

			«toStr(type)»
		}

		«IF type == Type.OBJECT»
			class CollectionAsOrderedContainer<C extends Collection<A>, A> extends CollectionAsContainer<C, A> implements OrderedContainerView<A> {
		«ELSE»
			class «type.typeName»CollectionAs«type.typeName»OrderedContainer<C extends Collection<«type.boxedName»>> extends «type.typeName»CollectionAs«type.typeName»Container<C> implements «type.orderedContainerViewGenericName» {
		«ENDIF»
			«type.shortName("Collection")»As«type.shortName("OrderedContainer")»(final C collection, final boolean fixedSize) {
				super(collection, fixedSize);
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				if (this.collection instanceof List<?> && this.collection instanceof RandomAccess) {
					final int size = this.collection.size();
					if (size == 0) {
						«IF type.javaUnboxedType»
							return «type.noneName»().iterator();
						«ELSE»
							return Collections.emptyIterator();
						«ENDIF»
					} else {
						«IF type.javaUnboxedType»
							return new «type.typeName»ListReverseIterator((List<«type.genericBoxedName»>) this.collection, size);
						«ELSE»
							return new ListReverseIterator<>((List<«type.genericBoxedName»>) this.collection, size);
						«ENDIF»
					}
				} else if (this.collection instanceof Deque<?>) {
					«IF type.javaUnboxedType»
						return «type.typeName»Iterator.getIterator(((Deque<«type.boxedName»>) this.collection).descendingIterator());
					«ELSE»
						return ((Deque<«type.genericBoxedName»>) this.collection).descendingIterator();
					«ENDIF»
				} else if (this.collection instanceof NavigableSet<?>) {
					«IF type.javaUnboxedType»
						return «type.typeName»Iterator.getIterator(((NavigableSet<«type.boxedName»>) this.collection).descendingIterator());
					«ELSE»
						return ((NavigableSet<«type.genericBoxedName»>) this.collection).descendingIterator();
					«ENDIF»
				} else {
					return «type.orderedContainerViewShortName».super.reverseIterator();
				}
			}
		}
	'''
}