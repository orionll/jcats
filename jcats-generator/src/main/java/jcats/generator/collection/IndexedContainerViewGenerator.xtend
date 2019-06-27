package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class IndexedContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new IndexedContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("IndexedContainerView") }
	def genericName() { type.genericName("IndexedContainerView") }
	def paramGenericName() { type.paramGenericName("IndexedContainerView") }
	def baseShortName() { type.shortName("BaseIndexedContainerView") }
	def mappedShortName() { type.shortName("MappedIndexedContainerView") }
	def mappedWithIndexShortName() { type.shortName("MappedWithIndexIndexedContainerView") }
	def mapTargetType() { if (type == Type.OBJECT) "B" else "A" }
	def limitedShortName() { type.shortName("LimitedIndexedContainerView") }
	def filteredShortName() { type.shortName("FilteredIndexedContainerView") }
	def skippedShortName() { type.shortName("SkippedIndexedContainerView") }
	def reverseShortName() { type.shortName("ReverseIndexedContainerView") }
	def concatenatedShortName() { type.shortName("ConcatenatedIndexedContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Iterator;
		import java.util.List;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;
		import static «Constants.COMMON».*;
		«IF type.primitive»
			import static «Constants.COLLECTION».«type.arrayShortName».*;
		«ENDIF»
		import static «Constants.COLLECTION».«shortName».*;

		public interface «type.covariantName("IndexedContainerView")» extends «type.orderedContainerViewGenericName», «type.indexedContainerGenericName» {

			@Override
			@Deprecated
			default «genericName» view() {
				return this;
			}

			@Override
			default «type.indexedContainerGenericName» unview() {
				return this;
			}

			default «genericName» slice(final int fromIndexInclusive, final int toIndexExclusive) throws IndexOutOfBoundsException {
				final int size = size();
				sliceRangeCheck(fromIndexInclusive, toIndexExclusive, size);
				if (fromIndexInclusive == 0 && toIndexExclusive == size) {
					return this;
				} else if (fromIndexInclusive == toIndexExclusive) {
					return empty«shortName»();
				} else {
					return skip(fromIndexInclusive).limit(toIndexExclusive - fromIndexInclusive);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				default <B> IndexedContainerView<B> map(final F<A, B> f) {
			«ELSE»
				default <A> IndexedContainerView<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return new «mappedShortName»<>(unview(), f);
			}

			«FOR toType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					default «toType.indexedContainerViewGenericName» mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
				«ELSE»
					default «toType.indexedContainerViewGenericName» mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(unview(), f);
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <B> IndexedContainerView<B> mapWithIndex(final IntObjectObjectF2<A, B> f) {
			«ELSE»
				default <A> IndexedContainerView<A> mapWithIndex(final Int«type.typeName»ObjectF2<A> f) {
			«ENDIF»
				requireNonNull(f);
				return new «mappedWithIndexShortName»<>(unview(), f);
			}

			@Override
			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				} else if (limit == 0) {
					return empty«shortName»();
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
					return empty«shortName»();
				} else {
					return new «skippedShortName»<>(unview(), skip);
				}
			}

			@Override
			default «genericName» reverse() {
				return new «reverseShortName»<>(unview());
			}

			static «paramGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«type.indexedContainerViewGenericName») «ENDIF»«baseShortName».EMPTY;
			}

			static «paramGenericName» «type.shortName("ListView").firstToLowerCase»(final List<«type.genericBoxedName»> list) {
				return «type.shortName("ListView").firstToLowerCase»(list, true);
			}

			static «paramGenericName» «type.shortName("ListView").firstToLowerCase»(final List<«type.genericBoxedName»> list, final boolean hasKnownFixedSize) {
				requireNonNull(list);
				return new «type.shortName("List")»As«type.indexedContainerDiamondName»(list, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			class «baseShortName»<A, C extends IndexedContainer<A>> extends BaseOrderedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			class «baseShortName»<C extends «type.indexedContainerShortName»> extends «type.typeName»BaseOrderedContainerView<C> implements «type.indexedContainerViewShortName» {
		«ENDIF»
			static final «baseShortName»<«IF type == Type.OBJECT»?, «ENDIF»?> EMPTY = new «baseShortName»<>(«type.arrayShortName».EMPTY);

			«baseShortName»(final C container) {
				super(container);
			}

			@Override
			public «type.genericName» get(final int index) throws IndexOutOfBoundsException {
				return this.container.get(index);
			}

			@Override
			public IntOption indexOf(final «type.genericName» value) {
				return this.container.indexOf(value);
			}

			@Override
			public IntOption indexWhere(final «type.boolFName» predicate) {
				return this.container.indexWhere(predicate);
			}

			@Override
			public IntOption lastIndexOf(final «type.genericName» value) {
				return this.container.lastIndexOf(value);
			}

			@Override
			public IntOption lastIndexWhere(final «type.boolFName» predicate) {
				return this.container.lastIndexWhere(predicate);
			}

			@Override
			public IntIndexedContainer indices() {
				return this.container.indices();
			}

			«IF type.primitive»
				@Override
				public IndexedContainerView<«type.boxedName»> boxed() {
					return this.container.boxed();
				}

			«ENDIF»
			@Override
			public List<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
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

			@Override
			public «type.indexedContainerGenericName» unview() {
				return this.container;
			}
		}

		final class «mappedShortName»<A, «IF type == Type.OBJECT»B, «ENDIF»C extends «type.indexedContainerGenericName»> extends «type.shortName("MappedOrderedContainerView")»<A, «IF type == Type.OBJECT»B, «ENDIF»C> implements IndexedContainerView<«mapTargetType»> {

			«mappedShortName»(final C container, final «IF type == Type.OBJECT»F<A, B>«ELSE»«type.typeName»ObjectF<A>«ENDIF» f) {
				super(container, f);
			}

			@Override
			public «mapTargetType» get(final int index) throws IndexOutOfBoundsException {
				return requireNonNull(this.f.apply(this.container.get(index)));
			}

			@Override
			«IF type == Type.OBJECT»
				public <D> IndexedContainerView<D> map(final F<B, D> g) {
			«ELSE»
				public <B> IndexedContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedShortName»<>(this.container, this.f.map(g));
			}

			«FOR t : Type.primitives»
				@Override
				public «t.indexedContainerViewGenericName» mapTo«t.typeName»(final «t.typeName»F<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> g) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»IndexedContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public <D> IndexedContainerView<D> mapWithIndex(final IntObjectObjectF2<B, D> g) {
			«ELSE»
				public <B> IndexedContainerView<B> mapWithIndex(final IntObjectObjectF2<A, B> g) {
			«ENDIF»
				return new «mappedWithIndexShortName»<>(this.container, g.contraMap«IF type.primitive»From«type.typeName»«ENDIF»2(this.f));
			}

			@Override
			public IndexedContainerView<«mapTargetType»> slice(final int fromIndexInclusive, final int toIndexExclusive) {
				return new «mappedShortName»<>(this.container.view().slice(fromIndexInclusive, toIndexExclusive), this.f);
			}

			@Override
			public IndexedContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedShortName»<>(this.container.view().limit(n), this.f);
			}

			@Override
			public IndexedContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedShortName»<>(this.container.view().skip(n), this.f);
			}

			@Override
			public IndexedContainerView<«mapTargetType»> reverse() {
				return new «mappedShortName»<>(this.container.view().reverse().unview(), this.f);
			}

			«orderedHashCode(Type.OBJECT)»

			«indexedEquals(Type.OBJECT)»
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				class MappedTo«toType.typeName»IndexedContainerView<A, C extends «type.indexedContainerGenericName»> extends MappedTo«toType.typeName»OrderedContainerView<A, C> implements «toType.indexedContainerViewGenericName» {
			«ELSE»
				class «type.typeName»MappedTo«toType.typeName»IndexedContainerView<C extends «type.indexedContainerGenericName»> extends «type.typeName»MappedTo«toType.typeName»OrderedContainerView<C> implements «toType.indexedContainerViewGenericName» {
			«ENDIF»
				«IF type == Type.OBJECT»
					MappedTo«toType.typeName»IndexedContainerView(final C container, final «toType.typeName»F<A> f) {
				«ELSE»
					«type.typeName»MappedTo«toType.typeName»IndexedContainerView(final C container, final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					super(container, f);
				}

				@Override
				public «toType.genericName» get(final int index) throws IndexOutOfBoundsException {
					return this.f.apply(this.container.get(index));
				}

				@Override
				public «toType.genericName» last() {
					return this.f.apply(this.container.last());
				}

				@Override
				public «toType.optionGenericName» findLast() {
					return this.container.findLast().mapTo«toType.typeName»(this.f);
				}

				@Override
				public <B> IndexedContainerView<B> map(final «toType.typeName»ObjectF<B> g) {
					return new «mappedShortName»<>(this.container, this.f.map(g));
				}

				«FOR t : Type.primitives»
					@Override
					public «t.indexedContainerViewGenericName» mapTo«t.typeName»(final «toType.typeName»«t.typeName»F g) {
						return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»IndexedContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
					}

				«ENDFOR»
				@Override
				«IF type == Type.OBJECT»
					public <B> IndexedContainerView<B> mapWithIndex(final Int«toType.typeName»ObjectF2<B> g) {
				«ELSE»
					public <A> IndexedContainerView<A> mapWithIndex(final Int«toType.typeName»ObjectF2<A> g) {
				«ENDIF»
					return new «mappedWithIndexShortName»<>(this.container, g.contraMap«IF type.primitive»From«type.typeName»«ENDIF»2(this.f));
				}

				@Override
				public «toType.indexedContainerViewGenericName» slice(final int fromIndexInclusive, final int toIndexExclusive) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.container.view().slice(fromIndexInclusive, toIndexExclusive), this.f);
				}

				@Override
				public «toType.indexedContainerViewGenericName» limit(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.container.view().limit(n), this.f);
				}

				@Override
				public «toType.indexedContainerViewGenericName» skip(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.container.view().skip(n), this.f);
				}

				@Override
				public «toType.indexedContainerViewGenericName» reverse() {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.container.view().reverse().unview(), this.f);
				}

				«orderedHashCode(toType)»

				«indexedEquals(toType)»
			}

		«ENDFOR»
		final class «mappedWithIndexShortName»<A«IF type == Type.OBJECT», B«ENDIF»> implements IndexedContainerView<«mapTargetType»> {
			private final «type.indexedContainerGenericName» container;
			private final «IF type == Type.OBJECT»IntObjectObjectF2<A, B>«ELSE»Int«type.typeName»ObjectF2<A>«ENDIF» f;
		
			«mappedWithIndexShortName»(final «type.indexedContainerGenericName» container, final «IF type == Type.OBJECT»IntObjectObjectF2<A, B>«ELSE»Int«type.typeName»ObjectF2<A>«ENDIF» f) {
				this.container = container;
				this.f = f;
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
			public «mapTargetType» first() {
				return requireNonNull(this.f.apply(0, this.container.first()));
			}

			@Override
			public Option<«mapTargetType»> findFirst() {
				return this.container.findFirst().map(value -> this.f.apply(0, value));
			}

			@Override
			public Iterator<«mapTargetType»> iterator() {
				«IF type == Type.OBJECT»
					return new MappedWithIndexIterator<>(this.container.iterator(), this.f);
				«ELSE»
					return new «type.typeName»MappedWithIndexIterator<>(this.container.iterator(), this.f);
				«ENDIF»
			}

			@Override
			public void foreach(final Eff<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.container.foreachWithIndex((final int index, final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final «mapTargetType» result = requireNonNull(this.f.apply(index, value));
					eff.apply(result);
				});
			}

			@Override
			public void foreachWithIndex(final IntObjectEff2<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.container.foreachWithIndex((final int index, final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final «mapTargetType» result = requireNonNull(this.f.apply(index, value));
					eff.apply(index, result);
				});
			}

			@Override
			public «mapTargetType» get(final int index) {
				return this.f.apply(index, this.container.get(index));
			}
		
			@Override
			«IF type == Type.OBJECT»
				public <C> IndexedContainerView<C> map(final F<B, C> g) {
			«ELSE»
				public <B> IndexedContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedWithIndexShortName»<>(this.container, this.f.map(g));
			}

			@Override
			«IF type == Type.OBJECT»
				public <C> IndexedContainerView<C> mapWithIndex(final IntObjectObjectF2<B, C> g) {
			«ELSE»
				public <B> IndexedContainerView<B> mapWithIndex(final IntObjectObjectF2<A, B> g) {
			«ENDIF»
				return new «mappedWithIndexShortName»<>(this.container, (final int i, final «type.genericName» value) -> {
					final «mapTargetType» result = requireNonNull(this.f.apply(i, value));
					return g.apply(i, result);
				});
			}

			@Override
			public IndexedContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedWithIndexShortName»<>(this.container.view().limit(n), this.f);
			}

			@Override
			public boolean isReverseQuick() {
				return this.container.isReverseQuick();
			}

			«orderedHashCode(Type.OBJECT)»

			«indexedEquals(Type.OBJECT)»

			«toStr(Type.OBJECT)»
		}

		«IF type == Type.OBJECT»
			final class «limitedShortName»<A, C extends «type.indexedContainerGenericName»> extends LimitedOrderedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «limitedShortName»<C extends «type.indexedContainerGenericName»> extends «type.typeName»LimitedOrderedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«limitedShortName»(final C container, final int limit) {
				super(container, limit);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index < 0 || index >= this.limit) {
					throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«limitedShortName»"));
				} else {
					try {
						return this.container.get(index);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«limitedShortName»"));
					}
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return empty«shortName»();
				} else if (n < this.limit) {
					return new «limitedShortName»<>(this.container, n);
				} else {
					return this;
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = Math.min(this.limit, this.container.size());
					for (int i = 0; i < size; i++) {
						eff.apply(this.container.get(i));
					}
				} else {
					super.foreach(eff);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = Math.min(this.limit, this.container.size());
					for (int i = 0; i < size; i++) {
						eff.apply(i, this.container.get(i));
					}
				} else {
					super.foreachWithIndex(eff);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = Math.min(this.limit, this.container.size());
					for (int i = 0; i < size; i++) {
						if (!eff.apply(this.container.get(i))) {
							return false;
						}
					}
					return true;
				} else {
					return super.foreachUntil(eff);
				}
			}

			«orderedHashCode(type)»

			«indexedEquals(type)»
		}

		«IF type == Type.OBJECT»
			final class «skippedShortName»<A, C extends «type.indexedContainerGenericName»> extends SkippedOrderedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «skippedShortName»<C extends «type.indexedContainerGenericName»> extends «type.typeName»SkippedOrderedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«skippedShortName»(final C container, final int skip) {
				super(container, skip);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index < 0) {
					throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«skippedShortName»"));
				} else {
					final int newIndex = this.skip + index;
					if (newIndex < 0) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«skippedShortName»"));
					}
					try {
						return this.container.get(newIndex);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«skippedShortName»"));
					}
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n > 0) {
					final int sum = this.skip + n;
					if (sum < 0) {
						// Overflow
						if (this.container.hasKnownFixedSize()) {
							return empty«shortName»();
						} else {
							return new «skippedShortName»<>(this, n);
						}
					} else {
						if (this.container.hasKnownFixedSize() && sum >= this.container.size()) {
							return empty«shortName»();
						} else {
							return new «skippedShortName»<>(this.container, sum);
						}
					}
				} else {
					return this;
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = this.container.size();
					for (int i = this.skip; i < size; i++) {
						eff.apply(this.container.get(i));
					}
				} else {
					super.foreach(eff);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = this.container.size();
					for (int i = this.skip; i < size; i++) {
						eff.apply(i - this.skip, this.container.get(i));
					}
				} else {
					super.foreachWithIndex(eff);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = this.container.size();
					for (int i = this.skip; i < size; i++) {
						if (!eff.apply(this.container.get(i))) {
							return false;
						}
					}
					return true;
				} else {
					return super.foreachUntil(eff);
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				if (this.container.hasKnownFixedSize()) {
					return «type.indexedContainerViewShortName».super.iterator();
				} else {
					return super.iterator();
				}
			}

			«orderedHashCode(type)»

			«indexedEquals(type)»
		}

		«IF type == Type.OBJECT»
			final class «reverseShortName»<A, C extends «type.indexedContainerGenericName»> extends ReverseOrderedContainerView<A, C> implements «genericName» {
		«ELSE»
			final class «reverseShortName»<C extends «type.indexedContainerGenericName»> extends «type.typeName»ReverseOrderedContainerView<C> implements «genericName» {
		«ENDIF»

			«reverseShortName»(final C container) {
				super(container);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (hasKnownFixedSize()) {
					try {
						return this.container.get(size() - index - 1);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«reverseShortName»"));
					}
				} else {
					throw new UnsupportedOperationException("get() is unsupported if hasKnownFixedSize() == false");
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					for (int i = this.container.size() - 1; i >= 0; i--) {
						eff.apply(this.container.get(i));
					}
				} else {
					super.foreach(eff);
				}
			}

			@Override
			public void foreachWithIndex(final Int«type.typeName»Eff2«IF type == Type.OBJECT»<A>«ENDIF» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					final int size = this.container.size();
					for (int i = 0; i < size; i++) {
						eff.apply(i, this.container.get(size - i - 1));
					}
				} else {
					super.foreachWithIndex(eff);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				if (this.container.hasKnownFixedSize()) {
					for (int i = this.container.size() - 1; i >= 0; i--) {
						if (!eff.apply(this.container.get(i))) {
							return false;
						}
					}
					return true;
				} else {
					return super.foreachUntil(eff);
				}
			}

			@Override
			public «genericName» reverse() {
				return this.container.view();
			}

			«orderedHashCode(type)»

			«indexedEquals(type)»
		}

		«IF type == Type.OBJECT»
			final class «concatenatedShortName»<A> extends ConcatenatedOrderedContainerView<A, IndexedContainer<A>> implements IndexedContainerView<A> {
		«ELSE»
			final class «concatenatedShortName» extends «type.typeName»ConcatenatedOrderedContainerView<«type.indexedContainerGenericName»> implements «type.indexedContainerViewGenericName» {
		«ENDIF»
			«concatenatedShortName»(final «type.indexedContainerGenericName»[] containers) {
				super(containers);
			}

			@Override
			public «type.genericName» get(final int index)  {
				if (index < 0) {
					throw new IllegalArgumentException(Integer.toString(index));
				}
				int size = 0;
				for (final «type.indexedContainerGenericName» container : this.containers) {
					final int nextSize = size + container.size();
					if (index < nextSize || nextSize < 0) {
						return container.get(index - size);
					}
					size = nextSize;
				}
				«indexOutOfBounds(shortName)»
			}

			@Override
			public «genericName» reverse() {
				final «type.indexedContainerGenericName»[] reverse = new «type.indexedContainerShortName»[this.containers.length];
				for (int i = 0; i < this.containers.length; i++) {
					reverse[i] = this.containers[this.containers.length - i - 1].view().reverse().unview();
				}
				return new «type.diamondName("ConcatenatedIndexedContainerView")»(reverse);
			}

			«orderedHashCode(type)»

			«indexedEquals(type)»
		}

		«IF type == Type.OBJECT»
			final class ListAsIndexedContainer<A> extends CollectionAsOrderedContainer<List<A>, A> implements IndexedContainerView<A> {
		«ELSE»
			final class «type.typeName»ListAs«type.typeName»IndexedContainer extends «type.typeName»CollectionAs«type.typeName»OrderedContainer<List<«type.boxedName»>> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«type.shortName("List")»As«type.shortName("IndexedContainer")»(final List<«type.genericBoxedName»> list, final boolean fixedSize) {
				super(list, fixedSize);
			}

			@Override
			public «type.genericName» get(final int index) {
				return this.collection.get(index);
			}

			@Override
			public IntOption indexOf(final «type.genericName» value) {
				final int index = this.collection.indexOf(value);
				return (index >= 0) ? intSome(index) : intNone();
			}

			@Override
			public IntOption lastIndexOf(final «type.genericName» value) {
				final int index = this.collection.lastIndexOf(value);
				return (index >= 0) ? intSome(index) : intNone();
			}

			@Override
			public «genericName» slice(final int fromIndexInclusive, final int toIndexExclusive) {
				return new «type.shortName("List")»As«type.diamondName("IndexedContainer")»(this.collection.subList(fromIndexInclusive, toIndexExclusive), this.fixedSize);
			}

			@Override
			public List<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableList(this.collection);
			}

			«orderedHashCode(type)»

			«equals(type, type.indexedContainerWildcardName, false)»
		}
	'''
}