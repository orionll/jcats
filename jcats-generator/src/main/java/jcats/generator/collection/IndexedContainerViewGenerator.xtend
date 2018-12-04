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

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.List;
		import java.util.PrimitiveIterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.FUNCTION».«type.shortName("BooleanF")».*;

		public interface «type.covariantName("IndexedContainerView")» extends «type.containerViewGenericName», «type.indexedContainerGenericName» {

			@Override
			@Deprecated
			default «type.indexedContainerViewGenericName» view() {
				return this;
			}

			@Override
			«IF type == Type.OBJECT»
				default <B> IndexedContainerView<B> map(final F<A, B> f) {
			«ELSE»
				default <A> IndexedContainerView<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return new «mappedIndexedContainerViewShortName»<>(this, f);
			}

			«FOR toType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					default «toType.indexedContainerViewGenericName» mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
				«ELSE»
					default «toType.indexedContainerViewGenericName» mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this, f);
				}

			«ENDFOR»
			@Override
			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				}
				return new «limitedIndexedContainerViewShortName»<>(this, limit);
			}

			@Override
			default «genericName» skip(final int skip) {
				if (skip < 0) {
					throw new IllegalArgumentException(Integer.toString(skip));
				} else if (skip == 0) {
					return this;
				} else {
					return new «skippedIndexedContainerViewShortName»<>(this, skip);
				}
			}

			@Override
			default «genericName» reverse() {
				return new «reverseIndexedContainerViewShortName»<>(this);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			class «baseIndexedContainerViewShortName»<A, C extends IndexedContainer<A>> extends BaseContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			class «baseIndexedContainerViewShortName»<C extends «type.indexedContainerShortName»> extends «type.typeName»BaseContainerView<C> implements «type.indexedContainerViewShortName» {
		«ENDIF»

			«baseIndexedContainerViewShortName»(final C container) {
				super(container);
			}

			@Override
			public «type.genericName» get(final int index) throws IndexOutOfBoundsException {
				return this.container.get(index);
			}

			@Override
			public «type.genericName» last() {
				return this.container.first();
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return this.container.lastOption();
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
				public IndexedContainerView<«type.boxedName»> asContainer() {
					return this.container.asContainer();
				}

			«ENDIF»
			@Override
			public List<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«hashcode(type)»

			«indexedEquals(type)»

			@Override
			public String toString() {
				return iterableToString(this, "«baseIndexedContainerViewShortName»");
			}
		}

		«IF type == Type.OBJECT»
			final class «mappedIndexedContainerViewShortName»<A, B, C extends IndexedContainerView<A>> extends MappedContainerView<A, B, C> implements IndexedContainerView<B> {
		«ELSE»
			final class «mappedIndexedContainerViewShortName»<A, C extends «type.indexedContainerViewShortName»> extends «type.typeName»MappedContainerView<A, C> implements IndexedContainerView<A> {
		«ENDIF»

			«mappedIndexedContainerViewShortName»(final C view, final «IF type == Type.OBJECT»F<A, B>«ELSE»«type.typeName»ObjectF<A>«ENDIF» f) {
				super(view, f);
			}

			@Override
			public «mapTargetType» get(final int index) throws IndexOutOfBoundsException {
				return requireNonNull(this.f.apply(this.view.get(index)));
			}

			@Override
			public «mapTargetType» last() {
				return requireNonNull(this.f.apply(this.view.last()));
			}

			@Override
			public Option<«mapTargetType»> lastOption() {
				return this.view.lastOption().map(this.f);
			}

			@Override
			«IF type == Type.OBJECT»
				public <D> IndexedContainerView<D> map(final F<B, D> g) {
			«ELSE»
				public <B> IndexedContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedIndexedContainerViewShortName»<>(this.view, this.f.map(g));
			}

			«FOR t : Type.primitives»
				@Override
				public «t.indexedContainerViewGenericName» mapTo«t.typeName»(final «t.typeName»F<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> g) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»IndexedContainerView<>(this.view, this.f.mapTo«t.typeName»(g));
				}

			«ENDFOR»
			@Override
			public IndexedContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedIndexedContainerViewShortName»<>(this.view.limit(n), this.f);
			}

			@Override
			public IndexedContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedIndexedContainerViewShortName»<>(this.view.skip(n), this.f);
			}

			«hashcode(Type.OBJECT)»

			«indexedEquals(Type.OBJECT)»

			«toStr(Type.OBJECT, mappedIndexedContainerViewShortName, false)»
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				class MappedTo«toType.typeName»IndexedContainerView<A, C extends «genericName»> extends MappedTo«toType.typeName»ContainerView<A, C> implements «toType.indexedContainerViewGenericName» {
			«ELSE»
				class «type.typeName»MappedTo«toType.typeName»IndexedContainerView<C extends «genericName»> extends «type.typeName»MappedTo«toType.typeName»ContainerView<C> implements «toType.indexedContainerViewGenericName» {
			«ENDIF»
				«IF type == Type.OBJECT»
					MappedTo«toType.typeName»IndexedContainerView(final C view, final «toType.typeName»F<A> f) {
				«ELSE»
					«type.typeName»MappedTo«toType.typeName»IndexedContainerView(final C view, final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					super(view, f);
				}

				@Override
				public «toType.genericName» get(final int index) throws IndexOutOfBoundsException {
					return this.f.apply(this.view.get(index));
				}

				@Override
				public «toType.genericName» last() {
					return this.f.apply(this.view.last());
				}

				@Override
				public «toType.optionGenericName» lastOption() {
					return this.view.lastOption().mapTo«toType.typeName»(this.f);
				}

				@Override
				public <B> IndexedContainerView<B> map(final «toType.typeName»ObjectF<B> g) {
					return new «mappedIndexedContainerViewShortName»<>(this.view, this.f.map(g));
				}

				«FOR t : Type.primitives»
					@Override
					public «t.indexedContainerViewGenericName» mapTo«t.typeName»(final «toType.typeName»«t.typeName»F g) {
						return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»IndexedContainerView<>(this.view, this.f.mapTo«t.typeName»(g));
					}

				«ENDFOR»
				@Override
				public «toType.indexedContainerViewGenericName» limit(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.view.limit(n), this.f);
				}

				@Override
				public «toType.indexedContainerViewGenericName» skip(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView<>(this.view.skip(n), this.f);
				}

				«hashcode(toType)»

				«indexedEquals(toType)»

				«toStr(toType, '''«IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»IndexedContainerView''', false)»
			}

		«ENDFOR»
		«IF type == Type.OBJECT»
			final class «limitedIndexedContainerViewShortName»<A, C extends IndexedContainerView<A>> extends LimitedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «limitedIndexedContainerViewShortName»<C extends «type.indexedContainerViewGenericName»> extends «type.typeName»LimitedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«limitedIndexedContainerViewShortName»(final C view, final int limit) {
				super(view, limit);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index < 0 || index >= this.limit) {
					throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«limitedIndexedContainerViewShortName»"));
				} else {
					try {
						return this.view.get(index);
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
					return new «limitedIndexedContainerViewShortName»<>(this.view, n);
				} else {
					return this;
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (this.view.hasFixedSize()) {
					final int size = Math.min(this.limit, this.view.size());
					for (int i = 0; i < size; i++) {
						eff.apply(this.view.get(i));
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
				if (this.view.hasFixedSize()) {
					final int size = Math.min(this.limit, this.view.size());
					for (int i = 0; i < size; i++) {
						eff.apply(i, this.view.get(i));
					}
				} else {
					super.foreachWithIndex(eff);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				if (this.view.hasFixedSize()) {
					final int size = Math.min(this.limit, this.view.size());
					for (int i = 0; i < size; i++) {
						if (!eff.apply(this.view.get(i))) {
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

			«toStr(type, limitedIndexedContainerViewShortName, false)»
		}

		«IF type == Type.OBJECT»
			final class «skippedIndexedContainerViewShortName»<A, C extends IndexedContainerView<A>> extends SkippedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «skippedIndexedContainerViewShortName»<C extends «type.indexedContainerViewGenericName»> extends «type.typeName»SkippedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«skippedIndexedContainerViewShortName»(final C view, final int skip) {
				super(view, skip);
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
						return this.view.get(newIndex);
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
						return new «skippedIndexedContainerViewShortName»<>(this, n);
					} else {
						return new «skippedIndexedContainerViewShortName»<>(this.view, sum);
					}
				} else {
					return this;
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (this.view.hasFixedSize()) {
					final int size = this.view.size();
					for (int i = this.skip; i < size; i++) {
						eff.apply(this.view.get(i));
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
				if (this.view.hasFixedSize()) {
					final int size = this.view.size();
					for (int i = this.skip; i < size; i++) {
						eff.apply(i - this.skip, this.view.get(i));
					}
				} else {
					super.foreachWithIndex(eff);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				if (this.view.hasFixedSize()) {
					final int size = this.view.size();
					for (int i = this.skip; i < size; i++) {
						if (!eff.apply(this.view.get(i))) {
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
				if (this.view.hasFixedSize()) {
					return «type.indexedContainerViewShortName».super.iterator();
				} else {
					return super.iterator();
				}
			}

			«hashcode(type)»

			«indexedEquals(type)»

			«toStr(type, skippedIndexedContainerViewShortName, false)»
		}

		«IF type == Type.OBJECT»
			final class «reverseIndexedContainerViewShortName»<A, C extends «genericName»> extends ReverseContainerView<A, C> implements «genericName» {
		«ELSE»
			final class «reverseIndexedContainerViewShortName»<C extends «genericName»> extends «type.typeName»ReverseContainerView<C> implements «genericName» {
		«ENDIF»

			«reverseIndexedContainerViewShortName»(final C view) {
				super(view);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (hasFixedSize()) {
					try {
						return this.view.get(size() - index - 1);
					} catch (final IndexOutOfBoundsException __) {
						throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this, "«reverseIndexedContainerViewShortName»"));
					}
				} else {
					throw new UnsupportedOperationException("get() is unsupported if hasFixedSize() == false");
				}
			}

			@Override
			public «type.genericName» first() {
				return this.view.last();
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return this.view.lastOption();
			}

			@Override
			public «type.genericName» last() {
				return this.view.first();
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return this.view.firstOption();
			}

			@Override
			public «genericName» reverse() {
				return this.view;
			}

			«hashcode(type)»

			«indexedEquals(type)»

			«toStr(type, reverseIndexedContainerViewShortName, false)»
		}
	''' }
}