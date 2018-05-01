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

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.PrimitiveIterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("IndexedContainerView")» extends «type.containerViewGenericName», «type.indexedContainerGenericName» {

			@Override
			@Deprecated
			default «type.indexedContainerViewGenericName» view() {
				return this;
			}

			«IF type == Type.OBJECT»
				default <B> IndexedContainerView<B> map(final F<A, B> f) {
			«ELSE»
				default <A> IndexedContainerView<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return new «mappedIndexedContainerViewShortName»<>(this, f);
			}

			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				}
				return new «limitedIndexedContainerViewShortName»<>(this, limit);
			}

			default «genericName» skip(final int skip) {
				if (skip < 0) {
					throw new IllegalArgumentException(Integer.toString(skip));
				}
				return new «skippedIndexedContainerViewShortName»<>(this, skip);
			}
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
			«IF type == Type.OBJECT»
				public <D> IndexedContainerView<D> map(final F<B, D> g) {
			«ELSE»
				public <B> IndexedContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedIndexedContainerViewShortName»<>(this.view, this.f.map(g));
			}

			@Override
			public IndexedContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedIndexedContainerViewShortName»<>(this.view.limit(n), this.f);
			}

			@Override
			public IndexedContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedIndexedContainerViewShortName»<>(this.view.skip(n), this.f);
			}

			@Override
			public String toString() {
				return iterableToString(this, "«mappedIndexedContainerViewShortName»");
			}
		}

		«IF type == Type.OBJECT»
			final class «limitedIndexedContainerViewShortName»<A, C extends IndexedContainerView<A>> extends LimitedContainerView<A, C> implements IndexedContainerView<A> {
		«ELSE»
			final class «limitedIndexedContainerViewShortName»<C extends «type.indexedContainerViewGenericName»> extends «type.typeName»LimitedContainerView<C> implements «type.indexedContainerViewGenericName» {
		«ENDIF»

			«limitedIndexedContainerViewShortName»(final C view, final int limit) {
				super(view, limit);
			}

			@Override
			public «type.genericName» get(final int index) throws IndexOutOfBoundsException {
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
			public «type.genericName» get(final int index) throws IndexOutOfBoundsException {
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

			«toStr(type, skippedIndexedContainerViewShortName, false)»
		}
	''' }
}