package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class ContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("ContainerView") }
	def genericName() { type.genericName("ContainerView") }
	def baseContainerViewShortName() { type.shortName("BaseContainerView") }
	def mappedContainerViewShortName() { type.shortName("MappedContainerView") }
	def mapTargetType() { if (type == Type.OBJECT) "B" else "A" }
	def filteredContainerViewShortName() { type.shortName("FilteredContainerView") }
	def limitedContainerViewShortName() { type.shortName("LimitedContainerView") }
	def skippedContainerViewShortName() { type.shortName("SkippedContainerView") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.PrimitiveIterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("ContainerView")» extends «type.containerGenericName» {

			@Override
			@Deprecated
			default «type.containerViewGenericName» view() {
				return this;
			}

			@Override
			default boolean isEmpty() {
				return !iterator().hasNext();
			}

			@Override
			default boolean isNotEmpty() {
				return iterator().hasNext();
			}

			@Override
			default int size() throws ArithmeticException {
				return foldLeftToInt(0, (final int size, final «type.genericName» __) -> {
					final int newSize = size + 1;
					if (newSize < 0) {
						throw new ArithmeticException("Integer overflow");
					} else {
						return newSize;
					}
				});
			}

			«IF type == Type.OBJECT»
				default <B> ContainerView<B> map(final F<A, B> f) {
			«ELSE»
				default <A> ContainerView<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return new «mappedContainerViewShortName»<>(this, f);
			}

			default «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return new «type.diamondName("FilteredContainerView")»(this, predicate);
			}

			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				}
				return new «type.shortName("LimitedContainerView")»<>(this, limit);
			}

			default «genericName» skip(final int skip) {
				if (skip < 0) {
					throw new IllegalArgumentException(Integer.toString(skip));
				}
				return new «type.shortName("SkippedContainerView")»<>(this, skip);
			}
		}

		class «baseContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.containerGenericName»> implements «genericName» {
			final C container;

			«baseContainerViewShortName»(final C container) {
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
			public boolean hasFixedSize() {
				return this.container.hasFixedSize();
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return this.container.iterator();
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				this.container.foreach(eff);
			}

			«toStr(type, baseContainerViewShortName, false)»
		}

		class «mappedContainerViewShortName»<A, «IF type == Type.OBJECT»B, «ENDIF»C extends «genericName»> implements ContainerView<«mapTargetType»> {
			final C view;
			«IF type == Type.OBJECT»
				final F<A, B> f;
			«ELSE»
				final «type.typeName»ObjectF<A> f;
			«ENDIF»

			«mappedContainerViewShortName»(final C view, final «IF type == Type.OBJECT»F<A, B>«ELSE»«type.typeName»ObjectF<A>«ENDIF» f) {
				this.view = view;
				this.f = f;
			}

			@Override
			public int size() {
				return this.view.size();
			}

			@Override
			public boolean isEmpty() {
				return this.view.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return this.view.isNotEmpty();
			}

			@Override
			public boolean hasFixedSize() {
				return this.view.hasFixedSize();
			}

			@Override
			public Iterator<«mapTargetType»> iterator() {
				«IF type == Type.OBJECT»
					return new MappedIterator<>(this.view.iterator(), this.f);
				«ELSE»
					return new Mapped«type.typeName»ObjectIterator<>(this.view.iterator(), this.f);
				«ENDIF»
			}

			@Override
			public void foreach(final Eff<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.view.foreach((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final «mapTargetType» result = requireNonNull(this.f.apply(value));
					eff.apply(result);
				});
			}

			@Override
			«IF type == Type.OBJECT»
				public <D> ContainerView<D> map(final F<B, D> g) {
			«ELSE»
				public <B> ContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedContainerViewShortName»<>(this.view, this.f.map(g));
			}

			@Override
			public ContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedContainerViewShortName»<>(this.view.limit(n), this.f);
			}

			@Override
			public ContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedContainerViewShortName»<>(this.view.skip(n), this.f);
			}

			«toStr(Type.OBJECT, mappedContainerViewShortName, false)»
		}

		class «type.genericName("FilteredContainerView")» implements «genericName» {
			private final «genericName» view;
			private final «type.boolFName» predicate;

			«filteredContainerViewShortName»(final «genericName» view, final «type.boolFName» predicate) {
				this.view = view;
				this.predicate = predicate;
			}

			@Override
			public boolean isEmpty() {
				return noneMatch(this.predicate);
			}

			@Override
			public boolean isNotEmpty() {
				return anyMatch(this.predicate);
			}

			@Override
			public boolean hasFixedSize() {
				return false;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("FilteredIterator")»(this.view.iterator(), this.predicate);
				«ELSEIF type == Type.OBJECT»
					return new FilteredIterator<>(this.view.iterator(), this.predicate);
				«ELSE»
					return new FilteredIterator<>(this.view.iterator(), this.predicate::apply);
				«ENDIF»
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				this.view.foreach((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					if (this.predicate.apply(value)) {
						eff.apply(value);
					}
				});
			}

			«toStr(type, filteredContainerViewShortName, false)»
		}

		class «limitedContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «genericName»> implements «genericName» {
			final C view;
			final int limit;

			«limitedContainerViewShortName»(final C view, final int limit) {
				this.view = view;
				this.limit = limit;
			}

			@Override
			public int size() {
				if (this.limit == 0) {
					return 0;
				} else if (this.view.hasFixedSize()) {
					return Math.min(this.limit, this.view.size());
				} else {
					return «shortName».super.size();
				}
			}

			@Override
			public boolean isEmpty() {
				return (this.limit == 0) || this.view.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return (this.limit > 0) && this.view.isNotEmpty();
			}

			@Override
			public boolean hasFixedSize() {
				return this.view.hasFixedSize();
			}

			@Override
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n < this.limit) {
					return new «type.shortName("LimitedContainerView")»<>(this.view, n);
				} else {
					return this;
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("LimitedIterator")»(this.view.iterator(), this.limit);
				«ELSE»
					return new LimitedIterator<>(this.view.iterator(), this.limit);
				«ENDIF»
			}

			«toStr(type, limitedContainerViewShortName, false)»
		}

		class «skippedContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «genericName»> implements «genericName» {
			final C view;
			final int skip;

			«skippedContainerViewShortName»(final C view, final int skip) {
				this.view = view;
				this.skip = skip;
			}

			@Override
			public int size() {
				if (this.view.hasFixedSize()) {
					return Math.max(this.view.size() - this.skip, 0);
				} else {
					return «shortName».super.size();
				}
			}

			@Override
			public boolean isEmpty() {
				if (this.view.isEmpty()) {
					return true;
				} else if (this.view.hasFixedSize()) {
					return (this.skip >= this.view.size());
				} else {
					return «shortName».super.isEmpty();
				}
			}

			@Override
			public boolean isNotEmpty() {
				if (this.view.isEmpty()) {
					return false;
				} else if (this.view.hasFixedSize()) {
					return (this.skip < this.view.size());
				} else {
					return «shortName».super.isNotEmpty();
				}
			}

			@Override
			public boolean hasFixedSize() {
				return this.view.hasFixedSize();
			}

			@Override
			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n > 0) {
					final int sum = this.skip + n;
					if (sum < 0) {
						// Overflow
						return new «type.shortName("SkippedContainerView")»<>(this, n);
					} else {
						return new «type.shortName("SkippedContainerView")»<>(this.view, sum);
					}
				} else {
					return this;
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("SkippedIterator")»(this.view.iterator(), this.skip);
				«ELSE»
					return new SkippedIterator<>(this.view.iterator(), this.skip);
				«ENDIF»
			}

			«toStr(type, skippedContainerViewShortName, false)»
		}
	''' }
}