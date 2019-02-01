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
	def baseIndexedContainerViewShortName() { type.shortName("BaseIndexedContainerView") }
	def mappedIndexedContainerViewShortName() { type.shortName("MappedIndexedContainerView") }
	def mapTargetType() { if (type == Type.OBJECT) "B" else "A" }
	def limitedIndexedContainerViewShortName() { type.shortName("LimitedIndexedContainerView") }
	def skippedIndexedContainerViewShortName() { type.shortName("SkippedIndexedContainerView") }
	def reverseIndexedContainerViewShortName() { type.shortName("ReverseIndexedContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		«IF !type.javaUnboxedType»
			import java.util.Iterator;
		«ENDIF»
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
					return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
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
				return new «mappedIndexedContainerViewShortName»<>(unview(), f);
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
			@Override
			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				} else if (hasKnownFixedSize() && limit >= size()) {
					return this;
				} else {
					return new «limitedIndexedContainerViewShortName»<>(unview(), limit);
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
					return new «skippedIndexedContainerViewShortName»<>(unview(), skip);
				}
			}

			@Override
			default «genericName» reverse() {
				return new «reverseIndexedContainerViewShortName»<>(unview());
			}

			static «type.paramGenericName("IndexedContainerView")» «type.shortName("ListView").firstToLowerCase»(final List<«type.genericBoxedName»> list) {
				return «type.shortName("ListView").firstToLowerCase»(list, true);
			}

			static «type.paramGenericName("IndexedContainerView")» «type.shortName("ListView").firstToLowerCase»(final List<«type.genericBoxedName»> list, final boolean hasKnownFixedSize) {
				requireNonNull(list);
				return new «type.shortName("List")»As«type.indexedContainerDiamondName»(list, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			class «baseIndexedContainerViewShortName»<A, C extends IndexedContainer<A>> extends BaseOrderedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			class «baseIndexedContainerViewShortName»<C extends «type.indexedContainerShortName»> extends «type.typeName»BaseOrderedContainerView<C> implements «type.indexedContainerViewShortName» {
		«ENDIF»

			«baseIndexedContainerViewShortName»(final C container) {
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
			public boolean equals(final Object obj) {
				return this.container.equals(obj);
			}

			@Override
			public «type.indexedContainerGenericName» unview() {
				return this.container;
			}
		}

		final class «mappedIndexedContainerViewShortName»<A, «IF type == Type.OBJECT»B, «ENDIF»C extends «type.indexedContainerGenericName»> extends «type.shortName("MappedOrderedContainerView")»<A, «IF type == Type.OBJECT»B, «ENDIF»C> implements IndexedContainerView<«mapTargetType»> {

			«mappedIndexedContainerViewShortName»(final C container, final «IF type == Type.OBJECT»F<A, B>«ELSE»«type.typeName»ObjectF<A>«ENDIF» f) {
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
				return new «mappedIndexedContainerViewShortName»<>(this.container, this.f.map(g));
			}

			«FOR t : Type.primitives»
				@Override
				public «t.indexedContainerViewGenericName» mapTo«t.typeName»(final «t.typeName»F<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> g) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»IndexedContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
				}

			«ENDFOR»
			@Override
			public IndexedContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedIndexedContainerViewShortName»<>(this.container.view().limit(n), this.f);
			}

			@Override
			public IndexedContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedIndexedContainerViewShortName»<>(this.container.view().skip(n), this.f);
			}

			«hashcode(Type.OBJECT)»

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
				public «toType.optionGenericName» lastOption() {
					return this.container.lastOption().mapTo«toType.typeName»(this.f);
				}

				@Override
				public <B> IndexedContainerView<B> map(final «toType.typeName»ObjectF<B> g) {
					return new «mappedIndexedContainerViewShortName»<>(this.container, this.f.map(g));
				}

				«FOR t : Type.primitives»
					@Override
					public «t.indexedContainerViewGenericName» mapTo«t.typeName»(final «toType.typeName»«t.typeName»F g) {
						return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»IndexedContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
					}

				«ENDFOR»
				@Override
				public «toType.indexedContainerViewGenericName» limit(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.container.view().limit(n), this.f);
				}

				@Override
				public «toType.indexedContainerViewGenericName» skip(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.container.view().skip(n), this.f);
				}

				«hashcode(toType)»

				«indexedEquals(toType)»
			}

		«ENDFOR»
		«IF type == Type.OBJECT»
			final class «limitedIndexedContainerViewShortName»<A, C extends «type.indexedContainerGenericName»> extends LimitedOrderedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «limitedIndexedContainerViewShortName»<C extends «type.indexedContainerGenericName»> extends «type.typeName»LimitedOrderedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«limitedIndexedContainerViewShortName»(final C container, final int limit) {
				super(container, limit);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index < 0 || index >= this.limit) {
					throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«limitedIndexedContainerViewShortName»"));
				} else {
					try {
						return this.container.get(index);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«limitedIndexedContainerViewShortName»"));
					}
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n < this.limit) {
					return new «limitedIndexedContainerViewShortName»<>(this.container, n);
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

			«hashcode(type)»

			«indexedEquals(type)»
		}

		«IF type == Type.OBJECT»
			final class «skippedIndexedContainerViewShortName»<A, C extends «type.indexedContainerGenericName»> extends SkippedOrderedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «skippedIndexedContainerViewShortName»<C extends «type.indexedContainerGenericName»> extends «type.typeName»SkippedOrderedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«skippedIndexedContainerViewShortName»(final C container, final int skip) {
				super(container, skip);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index < 0) {
					throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«skippedIndexedContainerViewShortName»"));
				} else {
					final int newIndex = this.skip + index;
					if (newIndex < 0) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«skippedIndexedContainerViewShortName»"));
					}
					try {
						return this.container.get(newIndex);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«skippedIndexedContainerViewShortName»"));
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
							return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
						} else {
							return new «skippedIndexedContainerViewShortName»<>(this, n);
						}
					} else {
						if (this.container.hasKnownFixedSize() && sum >= this.container.size()) {
							return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
						} else {
							return new «skippedIndexedContainerViewShortName»<>(this.container, sum);
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

			«hashcode(type)»

			«indexedEquals(type)»
		}

		«IF type == Type.OBJECT»
			final class «reverseIndexedContainerViewShortName»<A, C extends «type.indexedContainerGenericName»> extends ReverseOrderedContainerView<A, C> implements «genericName» {
		«ELSE»
			final class «reverseIndexedContainerViewShortName»<C extends «type.indexedContainerGenericName»> extends «type.typeName»ReverseOrderedContainerView<C> implements «genericName» {
		«ENDIF»

			«reverseIndexedContainerViewShortName»(final C container) {
				super(container);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (hasKnownFixedSize()) {
					try {
						return this.container.get(size() - index - 1);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«reverseIndexedContainerViewShortName»"));
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

			«hashcode(type)»

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
			public List<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableList(this.collection);
			}

			«hashcode(type)»

			«equals(type, type.indexedContainerWildcardName, false)»
		}
	'''
}