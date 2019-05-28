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

	def shortName() { type.containerViewShortName }
	def genericName() { type.containerViewGenericName }
	def paramGenericName() { type.paramGenericName("ContainerView") }
	def baseContainerViewShortName() { type.shortName("BaseContainerView") }
	def mappedContainerViewShortName() { type.shortName("MappedContainerView") }
	def mapTargetType() { if (type == Type.OBJECT) "B" else "A" }
	def filteredContainerViewShortName() { type.shortName("FilteredContainerView") }
	def limitedContainerViewShortName() { type.shortName("LimitedContainerView") }
	def skippedContainerViewShortName() { type.shortName("SkippedContainerView") }
	def generatedShortName() { type.shortName("GeneratedContainerView") }
	def concatenatedShortName() { type.shortName("ConcatenatedContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.HashSet;
		import java.util.List;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.Spliterator;
		import java.util.function.Consumer;
		import java.util.stream.«type.streamName»;
		import java.io.Serializable;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.JCATS».«type.ordShortName».*;
		import static «Constants.FUNCTION».«type.shortName("BooleanF")».*;
		import static «Constants.COMMON».*;
		import static «Constants.COLLECTION».«type.arrayShortName».*;
		import static «Constants.COLLECTION».«shortName».*;

		public interface «type.covariantName("ContainerView")» extends «type.containerGenericName» {

			@Override
			@Deprecated
			default «genericName» view() {
				return this;
			}

			default «type.containerGenericName» unview() {
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
			default int size() throws SizeOverflowException {
				return foldToInt(0, (final int size, final «type.genericName» __) -> {
					final int newSize = size + 1;
					if (newSize < 0) {
						throw new SizeOverflowException();
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
				return new «mappedContainerViewShortName»<>(unview(), f);
			}

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					default «toType.containerViewGenericName» mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
				«ELSE»
					default «toType.containerViewGenericName» mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView<>(unview(), f);
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <B> ContainerView<B> flatMap(final F<A, Iterable<B>> f) {
					requireNonNull(f);
					return new FlatMappedContainerView<>(unview(), f);
				}
			«ELSE»
				default <A> ContainerView<A> flatMap(final «type.typeName»ObjectF<Iterable<A>> f) {
					requireNonNull(f);
					return new «type.typeName»FlatMappedContainerView<>(unview(), f);
				}
			«ENDIF»

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					default «toType.containerViewGenericName» flatMapTo«toType.typeName»(final F<A, Iterable<«toType.genericBoxedName»>> f) {
				«ELSE»
					default «toType.containerViewGenericName» flatMapTo«toType.typeName»(final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»FlatMappedTo«toType.typeName»ContainerView<>(unview(), f);
				}

			«ENDFOR»
			default «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return new «filteredContainerViewShortName»<>(unview(), predicate);
			}

			«IF type == Type.OBJECT»
				default <B extends A> ContainerView<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (ContainerView<B>) filter(clazz::isInstance);
				}

			«ENDIF»
			default «genericName» limit(final int limit) {
				if (limit < 0) {
					throw new IllegalArgumentException(Integer.toString(limit));
				} else if (limit == 0) {
					return empty«shortName»();
				} else if (hasKnownFixedSize() && limit >= size()) {
					return this;
				} else {
					return new «limitedContainerViewShortName»<>(unview(), limit);
				}
			}

			default «genericName» skip(final int skip) {
				if (skip < 0) {
					throw new IllegalArgumentException(Integer.toString(skip));
				} else if (skip == 0) {
					return this;
				} else if (hasKnownFixedSize() && skip >= size()) {
					return empty«shortName»();
				} else {
					return new «skippedContainerViewShortName»<>(unview(), skip);
				}
			}

			«IF type == Type.OBJECT»
				default «type.indexedContainerViewGenericName» sort(final Ord<A> ord) {
					requireNonNull(ord);
					return new SortedContainerView<>(unview(), ord, false);
				}
			«ELSE»
				default «type.indexedContainerViewGenericName» sortAsc() {
					return new «type.shortName("SortedContainerView")»(unview(), true, false);
				}

				default «type.indexedContainerViewGenericName» sortDesc() {
					return new «type.shortName("SortedContainerView")»(unview(), false, false);
				}
			«ENDIF»

			static «paramGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«type.containerViewGenericName») «ENDIF»«baseContainerViewShortName».EMPTY;
			}

			static «paramGenericName» «type.shortName("CollectionView").firstToLowerCase»(final Collection<«type.genericBoxedName»> collection) {
				return «type.shortName("CollectionView").firstToLowerCase»(collection, true);
			}

			static «paramGenericName» «type.shortName("CollectionView").firstToLowerCase»(final Collection<«type.genericBoxedName»> collection, final boolean hasKnownFixedSize) {
				requireNonNull(collection);
				return new «type.shortName("Collection")»As«type.containerShortName»<>(collection, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		class «baseContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.containerGenericName»> implements «genericName» {
			static final «baseContainerViewShortName»<«IF type == Type.OBJECT»?, «ENDIF»?> EMPTY = new «baseContainerViewShortName»<>(«type.arrayShortName».EMPTY);

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
			public boolean hasKnownFixedSize() {
				return this.container.hasKnownFixedSize();
			}

			@Override
			public «type.genericName» first() {
				return this.container.first();
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return this.container.firstOption();
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				return this.container.contains(value);
			}

			@Override
			public «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
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
			«IF type.primitive»
				public <A> A fold(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
			«ELSE»
				public <B> B fold(final B start, final F2<B, A, B> f2) {
			«ENDIF»
				return this.container.fold(start, f2);
			}

			«FOR returnType : Type.primitives»
				@Override
				«IF type.primitive»
					public «returnType.javaName» foldTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
				«ELSE»
					public «returnType.javaName» foldTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<A> f2) {
				«ENDIF»
					return this.container.foldTo«returnType.typeName»(start, f2);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public «type.optionGenericName» reduce(final F2<A, A, A> f2) {
			«ELSE»
				public «type.optionGenericName» reduce(final «type.typeName»«type.typeName»«type.typeName»F2 f2) {
			«ENDIF»
				return this.container.reduce(f2);
			}

			«IF type.javaUnboxedType»
				@Override
				public «type.javaName» sum() {
					return this.container.sum();
				}

			«ENDIF»
			@Override
			public «type.iteratorGenericName» iterator() {
				return this.container.iterator();
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				this.container.foreach(eff);
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				this.container.foreachWithIndex(eff);
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				return this.container.foreachUntil(eff);
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.container.forEach(action);
			}

			@Override
			public void printAll() {
				this.container.printAll();
			}

			@Override
			public String joinToString() {
				return this.container.joinToString();
			}

			@Override
			public String joinToString(final String separator) {
				return this.container.joinToString(separator);
			}

			@Override
			public String joinToString(final String separator, final String prefix, final String suffix) {
				return this.container.joinToString(separator, prefix, suffix);
			}

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
			public int spliteratorCharacteristics() {
				return this.container.spliteratorCharacteristics();
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				return this.container.spliterator();
			}

			@Override
			public «type.arrayGenericName» to«type.arrayShortName»() {
				return this.container.to«type.arrayShortName»();
			}

			@Override
			public «type.seqGenericName» to«type.seqShortName»() {
				return this.container.to«type.seqShortName»();
			}

			«IF type == Type.OBJECT»
				@Override
				public Unique<A> toUnique() {
					return this.container.toUnique();
				}

			«ENDIF»
			@Override
			public «type.javaName»[] «type.toArrayName»() {
				return this.container.«type.toArrayName»();
			}

			«IF type == Type.OBJECT»
				@Override
				public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					return this.container.toPreciseArray(supplier);
				}

			«ENDIF»
			«IF type.primitive»
				@Override
				public ContainerView<«type.boxedName»> boxed() {
					return this.container.boxed();
				}

			«ENDIF»
			@Override
			public Collection<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			@Override
			public ArrayList<«type.genericBoxedName»> toArrayList() {
				return this.container.toArrayList();
			}

			@Override
			public HashSet<«type.genericBoxedName»> toHashSet() {
				return this.container.toHashSet();
			}

			@Override
			public «type.stream2GenericName» stream() {
				return this.container.stream();
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return this.container.parallelStream();
			}

			@Override
			public String toString() {
				return this.container.toString();
			}

			@Override
			public «type.containerGenericName» unview() {
				return this.container;
			}
		}

		class «mappedContainerViewShortName»<A, «IF type == Type.OBJECT»B, «ENDIF»C extends «type.containerGenericName»> implements ContainerView<«mapTargetType»> {
			final C container;
			«IF type == Type.OBJECT»
				final F<A, B> f;
			«ELSE»
				final «type.typeName»ObjectF<A> f;
			«ENDIF»

			«mappedContainerViewShortName»(final C container, final «IF type == Type.OBJECT»F<A, B>«ELSE»«type.typeName»ObjectF<A>«ENDIF» f) {
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
				return requireNonNull(this.f.apply(this.container.first()));
			}

			@Override
			public Option<«mapTargetType»> firstOption() {
				return this.container.firstOption().map(this.f);
			}

			@Override
			public Iterator<«mapTargetType»> iterator() {
				«IF type == Type.OBJECT»
					return new MappedIterator<>(this.container.iterator(), this.f);
				«ELSE»
					return new Mapped«type.typeName»ObjectIterator<>(this.container.iterator(), this.f);
				«ENDIF»
			}

			@Override
			public void foreach(final Eff<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.container.foreach((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final «mapTargetType» result = requireNonNull(this.f.apply(value));
					eff.apply(result);
				});
			}

			@Override
			public boolean foreachUntil(final BooleanF<«mapTargetType»> eff) {
				requireNonNull(eff);
				return this.container.foreachUntil((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final «mapTargetType» result = requireNonNull(this.f.apply(value));
					return eff.apply(result);
				});
			}

			@Override
			public void foreachWithIndex(final IntObjectEff2<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.container.foreachWithIndex((final int index, final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final «mapTargetType» result = requireNonNull(this.f.apply(value));
					eff.apply(index, result);
				});
			}

			@Override
			«IF type == Type.OBJECT»
				public <D> ContainerView<D> map(final F<B, D> g) {
			«ELSE»
				public <B> ContainerView<B> map(final F<A, B> g) {
			«ENDIF»
				return new «mappedContainerViewShortName»<>(this.container, this.f.map(g));
			}

			«FOR t : Type.primitives»
				@Override
				public «t.containerViewGenericName» mapTo«t.typeName»(final «t.typeName»F<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> g) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»ContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
				}

			«ENDFOR»
			@Override
			public ContainerView<«mapTargetType»> limit(final int n) {
				return new «mappedContainerViewShortName»<>(this.container.view().limit(n), this.f);
			}

			@Override
			public ContainerView<«mapTargetType»> skip(final int n) {
				return new «mappedContainerViewShortName»<>(this.container.view().skip(n), this.f);
			}

			@Override
			public int spliteratorCharacteristics() {
				return Common.clearBit(this.container.spliteratorCharacteristics(), Spliterator.DISTINCT | Spliterator.SORTED);
			}

			«toStr(Type.OBJECT)»
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				class MappedTo«toType.typeName»ContainerView<A, C extends «type.containerGenericName»> implements «toType.containerViewGenericName» {
			«ELSE»
				class «type.typeName»MappedTo«toType.typeName»ContainerView<C extends «type.containerGenericName»> implements «toType.containerViewGenericName» {
			«ENDIF»
				final C container;
				«IF type == Type.OBJECT»
					final «toType.typeName»F<A> f;
				«ELSE»
					final «type.typeName»«toType.typeName»F f;
				«ENDIF»

				«IF type == Type.OBJECT»
					MappedTo«toType.typeName»ContainerView(final C container, final «toType.typeName»F<A> f) {
				«ELSE»
					«type.typeName»MappedTo«toType.typeName»ContainerView(final C container, final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
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
				public «toType.genericName» first() {
					return this.f.apply(this.container.first());
				}

				@Override
				public «toType.optionGenericName» firstOption() {
					return this.container.firstOption().mapTo«toType.typeName»(this.f);
				}

				@Override
				public «toType.iteratorGenericName» iterator() {
					«IF type == Type.OBJECT»
						return new MappedObject«toType.typeName»Iterator<>(this.container.iterator(), this.f);
					«ELSE»
						return new Mapped«type.typeName»«toType.typeName»Iterator(this.container.iterator(), this.f);
					«ENDIF»
				}

				@Override
				public void foreach(final «toType.typeName»Eff eff) {
					requireNonNull(eff);
					this.container.foreach((final «type.genericName» value) -> {
						«IF type == Type.OBJECT»
							requireNonNull(value);
						«ENDIF»
						final «toType.genericName» result = this.f.apply(value);
						eff.apply(result);
					});
				}

				@Override
				public boolean foreachUntil(final «toType.typeName»BooleanF eff) {
					requireNonNull(eff);
					return this.container.foreachUntil((final «type.genericName» value) -> {
						«IF type == Type.OBJECT»
							requireNonNull(value);
						«ENDIF»
						final «toType.genericName» result = this.f.apply(value);
						return eff.apply(result);
					});
				}

				@Override
				public void foreachWithIndex(final Int«toType.typeName»Eff2 eff) {
					requireNonNull(eff);
					this.container.foreachWithIndex((final int index, final «type.genericName» value) -> {
						«IF type == Type.OBJECT»
							requireNonNull(value);
						«ENDIF»
						final «toType.genericName» result = this.f.apply(value);
						eff.apply(index, result);
					});
				}

				@Override
				public <B> ContainerView<B> map(final «toType.typeName»ObjectF<B> g) {
					return new «mappedContainerViewShortName»<>(this.container, this.f.map(g));
				}

				«FOR t : Type.primitives»
					@Override
					public «t.containerViewGenericName» mapTo«t.typeName»(final «toType.typeName»«t.typeName»F g) {
						return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»ContainerView<>(this.container, this.f.mapTo«t.typeName»(g));
					}

				«ENDFOR»
				@Override
				public «toType.containerViewGenericName» limit(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView<>(this.container.view().limit(n), this.f);
				}

				@Override
				public «toType.containerViewGenericName» skip(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView<>(this.container.view().skip(n), this.f);
				}

				@Override
				public int spliteratorCharacteristics() {
					return Common.clearBit(this.container.spliteratorCharacteristics(), Spliterator.DISTINCT | Spliterator.SORTED);
				}

				«toStr(toType)»
			}

		«ENDFOR»
		«IF type == Type.OBJECT»
			class FlatMappedContainerView<A, B, C extends «type.containerGenericName»> implements ContainerView<B> {
				final C container;
				final F<A, Iterable<B>> f;

				FlatMappedContainerView(final C container, final F<A, Iterable<B>> f) {
		«ELSE»
			class «type.typeName»FlatMappedContainerView<A, C extends «type.containerGenericName»> implements ContainerView<A> {
				final C container;
				final «type.typeName»ObjectF<Iterable<A>> f;

				«type.typeName»FlatMappedContainerView(final C container, final «type.typeName»ObjectF<Iterable<A>> f) {
		«ENDIF»
				this.container = container;
				this.f = f;
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public Iterator<«mapTargetType»> iterator() {
				return new FlatMapped«IF type != Type.OBJECT»«type.typeName»Object«ENDIF»Iterator<>(this.container.iterator(), this.f);
			}

			@Override
			public void foreach(final Eff<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.container.foreach((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final Iterable<«mapTargetType»> result = requireNonNull(this.f.apply(value));
					if (result instanceof Container<?>) {
						((Container<«mapTargetType»>) result).foreach(eff);
					} else {
						result.forEach(eff.toConsumer());
					}
				});
			}

			@Override
			public boolean foreachUntil(final BooleanF<«mapTargetType»> eff) {
				requireNonNull(eff);
				return this.container.foreachUntil((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					final Iterable<«mapTargetType»> result = requireNonNull(this.f.apply(value));
					if (result instanceof Container<?>) {
						return ((Container<«mapTargetType»>) result).foreachUntil(eff);
					} else {
						for (final «mapTargetType» resultValue : result) {
							if (!eff.apply(resultValue)) {
								return false;
							}
						}
						return true;
					}
				});
			}

			@Override
			public int spliteratorCharacteristics() {
				return Common.clearBit(this.container.spliteratorCharacteristics(), Spliterator.DISTINCT | Spliterator.SORTED);
			}

			«toStr»
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				class FlatMappedTo«toType.typeName»ContainerView<A, C extends «type.containerGenericName»> implements «toType.containerViewGenericName» {
					final C container;
					final F<A, Iterable<«toType.genericBoxedName»>> f;

					FlatMappedTo«toType.typeName»ContainerView(final C container, final F<A, Iterable<«toType.genericBoxedName»>> f) {
			«ELSE»
				class «type.typeName»FlatMappedTo«toType.typeName»ContainerView<C extends «type.containerGenericName»> implements «toType.containerViewGenericName» {
					final C container;
					final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f;

					«type.typeName»FlatMappedTo«toType.typeName»ContainerView(final C container, final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
			«ENDIF»
					this.container = container;
					this.f = f;
				}

				@Override
				public boolean hasKnownFixedSize() {
					return false;
				}

				@Override
				public «toType.iteratorGenericName» iterator() {
					«IF type == Type.OBJECT»
						return new FlatMappedObject«toType.typeName»Iterator<>(this.container.iterator(), this.f);
					«ELSE»
						return new FlatMapped«type.typeName»«toType.typeName»Iterator(this.container.iterator(), this.f);
					«ENDIF»
				}

				@Override
				public void foreach(final «toType.typeName»Eff eff) {
					requireNonNull(eff);
					this.container.foreach((final «type.genericName» value) -> {
						«IF type == Type.OBJECT»
							requireNonNull(value);
						«ENDIF»
						final Iterable<«toType.genericBoxedName»> result = requireNonNull(this.f.apply(value));
						if (result instanceof «toType.containerWildcardName») {
							((«toType.containerGenericName») result).foreach(eff);
						} else if (result instanceof Container<?>) {
							((Container<«toType.genericBoxedName»>) result).foreach(eff.toEff());
						} else {
							result.forEach(eff::apply);
						}
					});
				}

				@Override
				public boolean foreachUntil(final «toType.typeName»BooleanF eff) {
					requireNonNull(eff);
					return this.container.foreachUntil((final «type.genericName» value) -> {
						«IF type == Type.OBJECT»
							requireNonNull(value);
						«ENDIF»
						final Iterable<«toType.genericBoxedName»> result = requireNonNull(this.f.apply(value));
						if (result instanceof «toType.containerWildcardName») {
							return ((«toType.containerGenericName») result).foreachUntil(eff);
						} else if (result instanceof Container<?>) {
							return ((Container<«toType.genericBoxedName»>) result).foreachUntil(eff.toBooleanF());
						} else {
							for (final «toType.genericBoxedName» resultValue : result) {
								if (!eff.apply(resultValue)) {
									return false;
								}
							}
							return true;
						}
					});
				}

				@Override
				public int spliteratorCharacteristics() {
					return Common.clearBit(this.container.spliteratorCharacteristics(), Spliterator.DISTINCT | Spliterator.SORTED);
				}

				«toStr(toType)»
			}

		«ENDFOR»
		class «filteredContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.containerGenericName»> implements «genericName» {
			final C container;
			final «type.boolFName» predicate;

			«filteredContainerViewShortName»(final C container, final «type.boolFName» predicate) {
				this.container = container;
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
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type == Type.OBJECT || type.javaUnboxedType»
					return new «type.diamondName("FilteredIterator")»(this.container.iterator(), this.predicate);
				«ELSE»
					return new FilteredIterator<>(this.container.iterator(), this.predicate.to«type.typeName»F());
				«ENDIF»
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				this.container.foreach((final «type.genericName» value) -> {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					if (this.predicate.apply(value)) {
						eff.apply(value);
					}
				});
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				«IF type == Type.OBJECT»
					return this.container.foreachUntil((final «type.genericName» value) -> {
						requireNonNull(value);
						return !this.predicate.apply(value) || eff.apply(value);
					});
				«ELSE»
					return this.container.foreachUntil((final «type.genericName» value) ->
						!this.predicate.apply(value) || eff.apply(value));
				«ENDIF»
			}

			@Override
			public «genericName» filter(final «type.boolFName» p) {
				return new «filteredContainerViewShortName»<>(this.container, and(this.predicate, p));
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.container.spliteratorCharacteristics();
			}

			«toStr(type)»
		}

		class «limitedContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.containerGenericName»> implements «genericName» {
			final C container;
			final int limit;

			«limitedContainerViewShortName»(final C container, final int limit) {
				this.container = container;
				this.limit = limit;
			}

			@Override
			public int size() {
				if (this.limit == 0) {
					return 0;
				} else if (this.container.hasKnownFixedSize()) {
					return Math.min(this.limit, this.container.size());
				} else {
					return «shortName».super.size();
				}
			}

			@Override
			public boolean isEmpty() {
				return (this.limit == 0) || this.container.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return (this.limit > 0) && this.container.isNotEmpty();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return (this.limit == 0) || this.container.hasKnownFixedSize();
			}

			@Override
			public «type.genericName» first() {
				if (this.limit == 0) {
					throw new NoSuchElementException();
				} else {
					return this.container.first();
				}
			}

			@Override
			public «type.optionGenericName» firstOption() {
				if (this.limit == 0) {
					return «type.noneName»();
				} else {
					return this.container.firstOption();
				}
			}

			@Override
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return empty«shortName»();
				} else if (n < this.limit) {
					return new «type.shortName("LimitedContainerView")»<>(this.container, n);
				} else {
					return this;
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("LimitedIterator")»(this.container.iterator(), this.limit);
				«ELSE»
					return new LimitedIterator<>(this.container.iterator(), this.limit);
				«ENDIF»
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.container.spliteratorCharacteristics();
			}

			«toStr(type)»
		}

		class «skippedContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.containerGenericName»> implements «genericName» {
			final C container;
			final int skip;

			«skippedContainerViewShortName»(final C container, final int skip) {
				this.container = container;
				this.skip = skip;
			}

			@Override
			public int size() {
				if (this.container.hasKnownFixedSize()) {
					return Math.max(this.container.size() - this.skip, 0);
				} else {
					return «shortName».super.size();
				}
			}

			@Override
			public boolean isEmpty() {
				if (this.container.hasKnownFixedSize()) {
					return (this.skip >= this.container.size());
				} else {
					return «shortName».super.isEmpty();
				}
			}

			@Override
			public boolean isNotEmpty() {
				if (this.container.hasKnownFixedSize()) {
					return (this.skip < this.container.size());
				} else {
					return «shortName».super.isNotEmpty();
				}
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.container.hasKnownFixedSize();
			}

			@Override
			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n > 0) {
					final int sum = this.skip + n;
					if (sum < 0) {
						// Overflow
						if (this.container.hasKnownFixedSize()) {
							return empty«shortName»();
						} else {
							return new «type.shortName("SkippedContainerView")»<>(this, n);
						}
					} else {
						if (this.container.hasKnownFixedSize() && sum >= this.container.size()) {
							return empty«shortName»();
						} else {
							return new «type.shortName("SkippedContainerView")»<>(this.container, sum);
						}
					}
				} else {
					return this;
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("SkippedIterator")»(this.container.iterator(), this.skip);
				«ELSE»
					return new SkippedIterator<>(this.container.iterator(), this.skip);
				«ENDIF»
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.container.spliteratorCharacteristics();
			}

			«toStr(type)»
		}

		final class «type.genericName("SortedContainerView")» implements «type.indexedContainerViewGenericName» {
			final «type.containerGenericName» container;
			«IF type == Type.OBJECT»
				final Ord<A> ord;
			«ELSE»
				final boolean asc;
			«ENDIF»
			final F0<«type.arrayGenericName»> sorted;

			«type.shortName("SortedContainerView")»(final «type.containerGenericName» container, final «IF type == Type.OBJECT»Ord<A> ord«ELSE»boolean asc«ENDIF», final boolean alreadySorted) {
				this.container = container;
				«IF type == Type.OBJECT»
					this.ord = ord;
				«ELSE»
					this.asc = asc;
				«ENDIF»
				this.sorted = F0.lazy(() -> {
					«IF type == Type.OBJECT»
						final Object[] array = this.container.toObjectArray();
						if (array.length == 0) {
							return emptyArray();
						} else {
							if (!alreadySorted) {
								Arrays.sort(array, (Ord<Object>) this.ord);
							}
							return new Array<>(array);
						}
					«ELSE»
						final «type.javaName»[] array = this.container.toPrimitiveArray();
						if (array.length == 0) {
							return empty«type.arrayShortName»();
						} else {
							if (!alreadySorted) {
								«IF type == Type.BOOLEAN»
									if (this.asc) {
										Common.sortBooleanArrayAsc(array);
									} else {
										Common.sortBooleanArrayDesc(array);
									}
								«ELSE»
									Arrays.sort(array);
									if (!this.asc) {
										Common.reverse«type.arrayShortName»(array);
									}
								«ENDIF»
							}
							return new «type.arrayShortName»(array);
						}
					«ENDIF»
				});
			}

			@Override
			public int size() {
				if (this.container.hasKnownFixedSize()) {
					return this.container.size();
				} else {
					return this.sorted.apply().size();
				}
			}

			@Override
			public boolean isEmpty() {
				if (this.container.hasKnownFixedSize()) {
					return this.container.isEmpty();
				} else {
					return this.sorted.apply().isEmpty();
				}
			}

			@Override
			public boolean isNotEmpty() {
				if (this.container.hasKnownFixedSize()) {
					return this.container.isNotEmpty();
				} else {
					return this.sorted.apply().isNotEmpty();
				}
			}

			@Override
			public boolean hasKnownFixedSize() {
				return true;
			}

			@Override
			public «type.genericName» get(final int index) {
				return this.sorted.apply().get(index);
			}

			@Override
			public «type.genericName» first() {
				return this.sorted.apply().first();
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return this.sorted.apply().firstOption();
			}

			@Override
			public «type.genericName» last() {
				return this.sorted.apply().last();
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return this.sorted.apply().lastOption();
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				return this.container.contains(value);
			}

			@Override
			public «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				return this.sorted.apply().firstMatch(predicate);
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
			public IntOption indexOf(final «type.genericName» value) {
				return this.sorted.apply().indexOf(value);
			}

			@Override
			public IntOption indexWhere(final «type.boolFName» predicate) {
				return this.sorted.apply().indexWhere(predicate);
			}

			@Override
			public IntOption lastIndexOf(final «type.genericName» value) {
				return this.sorted.apply().lastIndexOf(value);
			}

			@Override
			public IntOption lastIndexWhere(final «type.boolFName» predicate) {
				return this.sorted.apply().lastIndexWhere(predicate);
			}

			@Override
			«IF type.primitive»
				public <A> A fold(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
			«ELSE»
				public <B> B fold(final B start, final F2<B, A, B> f2) {
			«ENDIF»
				return this.sorted.apply().fold(start, f2);
			}

			«FOR returnType : Type.primitives»
				@Override
				«IF type.primitive»
					public «returnType.javaName» foldTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
				«ELSE»
					public «returnType.javaName» foldTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<A> f2) {
				«ENDIF»
					return this.sorted.apply().foldTo«returnType.typeName»(start, f2);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public «type.optionGenericName» reduce(final F2<A, A, A> f2) {
			«ELSE»
				public «type.optionGenericName» reduce(final «type.typeName»«type.typeName»«type.typeName»F2 f2) {
			«ENDIF»
				return this.sorted.apply().reduce(f2);
			}

			@Override
			«IF type.primitive»
				public <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSE»
				public <B> B foldRight(final B start, final F2<A, B, B> f2) {
			«ENDIF»
				return this.sorted.apply().foldRight(start, f2);
			}

			«FOR returnType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<A> f2) {
				«ELSE»
					public «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final «type.typeName»«returnType.typeName»«returnType.typeName»F2 f2) {
				«ENDIF»
					return this.sorted.apply().foldRightTo«returnType.typeName»(start, f2);
				}

			«ENDFOR»
			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return this.sorted.apply().reverseIterator();
			}

			@Override
			public boolean isReverseQuick() {
				return true;
			}

			«IF type.javaUnboxedType»
				@Override
				public «type.javaName» sum() {
					return this.sorted.apply().sum();
				}

			«ENDIF»
			@Override
			public void foreach(final «type.effGenericName» eff) {
				this.sorted.apply().foreach(eff);
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.sorted.apply().forEach(action);
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				this.sorted.apply().foreachWithIndex(eff);
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				return this.sorted.apply().foreachUntil(eff);
			}

			@Override
			public void printAll() {
				this.sorted.apply().printAll();
			}

			@Override
			public String joinToString() {
				return this.sorted.apply().joinToString();
			}

			@Override
			public String joinToString(final String separator) {
				return this.sorted.apply().joinToString(separator);
			}

			@Override
			public String joinToString(final String separator, final String prefix, final String suffix) {
				return this.sorted.apply().joinToString(separator, prefix, suffix);
			}

			«IF type == Type.OBJECT»
				@Override
				public «type.optionGenericName» min(final «type.ordGenericName» ord) {
					if (this.ord == ord) {
						return this.sorted.apply().firstOption();
					} else {
						return this.sorted.apply().min(ord);
					}
				}

				@Override
				public «type.optionGenericName» max(final «type.ordGenericName» ord) {
					if (this.ord == ord) {
						return this.sorted.apply().lastOption();
					} else {
						return this.sorted.apply().max(ord);
					}
				}
			«ELSE»
				@Override
				public «type.optionGenericName» min() {
					if (this.asc) {
						return this.sorted.apply().firstOption();
					} else {
						return this.sorted.apply().lastOption();
					}
				}

				@Override
				public «type.optionGenericName» max() {
					if (this.asc) {
						return this.sorted.apply().lastOption();
					} else {
						return this.sorted.apply().firstOption();
					}
				}

				@Override
				public «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
					if (ord == «type.asc»()) {
						return min();
					} else if (ord == «type.desc»()) {
						return max();
					} else {
						return this.sorted.apply().minByOrd(ord);
					}
				}

				@Override
				public «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
					if (ord == «type.asc»()) {
						return max();
					} else if (ord == «type.desc»()) {
						return min();
					} else {
						return this.sorted.apply().maxByOrd(ord);
					}
				}
			«ENDIF»

			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» minBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» minBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				return this.sorted.apply().minBy(f);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» minBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» minBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					return this.sorted.apply().minBy«to.typeName»(f);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» maxBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» maxBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				return this.sorted.apply().maxBy(f);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» maxBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» maxBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					return this.sorted.apply().maxBy«to.typeName»(f);
				}

			«ENDFOR»
			@Override
			public «type.iteratorGenericName» iterator() {
				return this.sorted.apply().iterator();
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				return this.sorted.apply().spliterator();
			}

			@Override
			public int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			@Override
			public «type.arrayGenericName» to«type.arrayShortName»() {
				return this.sorted.apply();
			}

			@Override
			public «type.seqGenericName» to«type.seqShortName»() {
				return this.sorted.apply().to«type.seqShortName»();
			}

			«IF type == Type.OBJECT»
				@Override
				public Unique<A> toUnique() {
					return this.container.toUnique();
				}

			«ENDIF»
			@Override
			public «type.javaName»[] «type.toArrayName»() {
				return this.sorted.apply().«type.toArrayName»();
			}

			«IF type == Type.OBJECT»
				@Override
				public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					return this.sorted.apply().toPreciseArray(supplier);
				}

			«ENDIF»
			«IF type.primitive»
				@Override
				public IndexedContainerView<«type.boxedName»> boxed() {
					return this.sorted.apply().boxed();
				}

			«ENDIF»
			@Override
			public List<«type.genericBoxedName»> asCollection() {
				return this.sorted.apply().asCollection();
			}

			@Override
			public ArrayList<«type.genericBoxedName»> toArrayList() {
				return this.sorted.apply().toArrayList();
			}

			@Override
			public HashSet<«type.genericBoxedName»> toHashSet() {
				return this.container.toHashSet();
			}

			@Override
			public «type.stream2GenericName» stream() {
				return this.sorted.apply().stream();
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return this.sorted.apply().parallelStream();
			}

			«IF type == Type.OBJECT»
				@Override
				public «type.indexedContainerViewGenericName» sort(final Ord<A> ord) {
					requireNonNull(ord);
					if (this.ord == ord) {
						return this;
					} else {
						return new SortedContainerView<>(this.container, ord, false);
					}
				}
			«ELSE»
				@Override
				public «type.indexedContainerViewGenericName» sortAsc() {
					if (this.asc) {
						return this;
					} else {
						return new «type.shortName("SortedContainerView")»(this.container, true, false);
					}
				}

				@Override
				public «type.indexedContainerViewGenericName» sortDesc() {
					if (this.asc) {
						return new «type.shortName("SortedContainerView")»(this.container, false, false);
					} else {
						return this;
					}
				}
			«ENDIF»

			@Override
			public int hashCode() {
				return this.sorted.apply().hashCode();
			}

			@Override
			@SuppressWarnings("deprecation")
			public boolean equals(final Object obj) {
				return this.sorted.apply().equals(obj);
			}

			«toStr(type, "this.sorted.apply()")»
		}

		«IF type == Type.OBJECT»
			class «generatedShortName»<A, C extends «type.containerGenericName»> implements ContainerView<A> {
		«ELSE»
			class «generatedShortName»<C extends «type.containerGenericName»> implements «type.containerViewGenericName» {
		«ENDIF»
			private final «type.f0GenericName» f;

			«generatedShortName»(final «type.f0GenericName» f) {
				this.f = f;
			}

			@Override
			public int size() {
				throw new SizeOverflowException();
			}

			@Override
			public boolean isEmpty() {
				return false;
			}

			@Override
			public boolean isNotEmpty() {
				return true;
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				throw new UnsupportedOperationException();
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				«type.genericName» value = «type.requireNonNull("this.f.apply()")»;
				while (eff.apply(value)) {
					value = «type.requireNonNull("this.f.apply()")»;
				}
				return false;
			}

			@Override
			public «type.genericName» first() {
				return «type.requireNonNull("this.f.apply()")»;
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return «type.someName»(this.f.apply());
			}

			@Override
			public String joinToString(final String separator, final String prefix, final String suffix) {
				requireNonNull(separator);
				requireNonNull(prefix);
				requireNonNull(suffix);
				throw new UnsupportedOperationException();
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type == Type.OBJECT || type.javaUnboxedType»
					return new «type.iteratorDiamondName("Generating")»(this.f);
				«ELSE»
					return new GeneratingIterator<>(this.f.toF0());
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				@Override
				public «type.indexedContainerViewGenericName» sort(final Ord<A> ord) {
					requireNonNull(ord);
					throw new UnsupportedOperationException();
				}
			«ELSE»
				@Override
				public «type.indexedContainerViewGenericName» sortAsc() {
					throw new UnsupportedOperationException();
				}

				@Override
				public «type.indexedContainerViewGenericName» sortDesc() {
					throw new UnsupportedOperationException();
				}
			«ENDIF»

			@Override
			public String toString() {
				return "(Infinite «type.containerShortName»)";
			}
		}

		class «concatenatedShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «type.containerGenericName»> implements «genericName» {
			final C prefix;
			final C suffix;

			«concatenatedShortName»(final C prefix, final C suffix) {
				this.prefix = prefix;
				this.suffix = suffix;
			}

			@Override
			public int size() {
				final int size = this.prefix.size() + this.suffix.size();
				if (size < 0) {
					throw new SizeOverflowException();
				} else {
					return size;
				}
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.prefix.hasKnownFixedSize()
						&& this.suffix.hasKnownFixedSize()
						&& this.prefix.size() + this.suffix.size() >= 0;
			}

			@Override
			public boolean isEmpty() {
				return this.prefix.isEmpty() && this.suffix.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return this.prefix.isNotEmpty() || this.suffix.isNotEmpty();
			}

			@Override
			public «type.genericName» first() {
				if (this.prefix.hasKnownFixedSize()) {
					if (this.prefix.isEmpty()) {
						return this.suffix.first();
					} else {
						return this.prefix.first();
					}
				} else {
					return «shortName».super.first();
				}
			}

			@Override
			public «type.optionGenericName» firstOption() {
				final «type.optionGenericName» first = this.prefix.firstOption();
				if (first.isEmpty()) {
					return this.suffix.firstOption();
				} else {
					return first;
				}
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return this.prefix.contains(value) || this.suffix.contains(value);
			}

			@Override
			public «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				final «type.optionGenericName» first = this.prefix.firstMatch(predicate);
				if (first.isEmpty()) {
					return this.suffix.firstMatch(predicate);
				} else {
					return first;
				}
			}
		
			@Override
			public boolean anyMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return this.prefix.anyMatch(predicate) || this.suffix.anyMatch(predicate);
			}
		
			@Override
			public boolean allMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return this.prefix.allMatch(predicate) && this.suffix.allMatch(predicate);
			}
		
			@Override
			public boolean noneMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return this.prefix.noneMatch(predicate) && this.suffix.noneMatch(predicate);
			}

			«IF type.javaUnboxedType»
				@Override
				public «type.javaName» sum() {
					return this.prefix.sum() + this.suffix.sum();
				}

			«ENDIF»
			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.iteratorDiamondName("Concatenated")»(this.prefix.iterator(), this.suffix.iterator());
				«ELSE»
					return new ConcatenatedIterator<>(this.prefix.iterator(), this.suffix.iterator());
				«ENDIF»
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				this.prefix.foreach(eff);
				this.suffix.foreach(eff);
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				return this.prefix.foreachUntil(eff) && this.suffix.foreachUntil(eff);
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				requireNonNull(action);
				this.prefix.forEach(action);
				this.suffix.forEach(action);
			}

			@Override
			public void printAll() {
				this.prefix.printAll();
				this.suffix.printAll();
			}

			@Override
			public «type.arrayGenericName» to«type.arrayShortName»() {
				if (this.prefix.hasKnownFixedSize() && this.prefix.isEmpty()) {
					return this.suffix.to«type.arrayShortName»();
				} else if (this.suffix.hasKnownFixedSize() && this.suffix.isEmpty()) {
					return this.prefix.to«type.arrayShortName»();
				} else {
					return «shortName».super.to«type.arrayShortName»();
				}
			}

			@Override
			public «type.seqGenericName» to«type.seqShortName»() {
				if (this.prefix.hasKnownFixedSize() && this.prefix.isEmpty()) {
					return this.suffix.to«type.seqShortName»();
				} else if (this.suffix.hasKnownFixedSize() && this.suffix.isEmpty()) {
					return this.prefix.to«type.seqShortName»();
				} else {
					return «shortName».super.to«type.seqShortName»();
				}
			}

			«IF type != Type.BOOLEAN»
				@Override
				public «type.uniqueGenericName» to«type.uniqueShortName»() {
					if (this.prefix.hasKnownFixedSize() && this.prefix.isEmpty()) {
						return this.suffix.to«type.uniqueShortName»();
					} else if (this.suffix.hasKnownFixedSize() && this.suffix.isEmpty()) {
						return this.prefix.to«type.uniqueShortName»();
					} else {
						return «shortName».super.to«type.uniqueShortName»();
					}
				}

			«ENDIF»
			@Override
			public «type.stream2GenericName» stream() {
				return new «type.stream2DiamondName»(«type.streamName».concat(this.prefix.stream(), this.suffix.stream()));
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return new «type.stream2DiamondName»(«type.streamName».concat(this.prefix.parallelStream(), this.suffix.parallelStream()));
			}

			@Override
			public <«mapTargetType»> ContainerView<«mapTargetType»> map(final «type.fGenericName» f) {
				requireNonNull(f);
				return new ConcatenatedContainerView<>(this.prefix.view().map(f), this.suffix.view().map(f));
			}

			«FOR toType : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «toType.containerViewGenericName» mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
				«ELSE»
					public «toType.containerViewGenericName» mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return new «toType.shortName("ConcatenatedContainerView")»<>(this.prefix.view().mapTo«toType.typeName»(f), this.suffix.view().mapTo«toType.typeName»(f));
				}

			«ENDFOR»
			@Override
			public «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return new «concatenatedShortName»<>(this.prefix.view().filter(predicate), this.suffix.view().filter(predicate));
			}

			«toStr(type)»
		}

		«IF type == Type.OBJECT»
			class CollectionAsContainer<C extends Collection<A>, A> implements ContainerView<A>, Serializable {
		«ELSE»
			class «type.typeName»CollectionAs«type.typeName»Container<C extends Collection<«type.boxedName»>> implements «type.containerViewGenericName», Serializable {
		«ENDIF»
			final C collection;
			final boolean fixedSize;

			«type.shortName("Collection")»As«type.shortName("Container")»(final C collection, final boolean fixedSize) {
				this.collection = collection;
				this.fixedSize = fixedSize;
			}

			@Override
			public boolean isEmpty() {
				return this.collection.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return !this.collection.isEmpty();
			}

			@Override
			public int size() {
				return this.collection.size();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.fixedSize;
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return this.collection.contains(value);
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.collection.forEach(action);
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				«IF type == Type.OBJECT»
					this.collection.forEach(eff.toConsumer());
				«ELSE»
					this.collection.forEach(eff::apply);
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return «type.typeName»Iterator.getIterator(this.collection.iterator());
				«ELSE»
					return this.collection.iterator();
				«ENDIF»
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				«IF type.javaUnboxedType»
					return «type.typeName»Spliterator.getSpliterator(this.collection.spliterator());
				«ELSE»
					return this.collection.spliterator();
				«ENDIF»
			}

			@Override
			public «type.stream2GenericName» stream() {
				return «type.stream2Name».from«IF type.javaUnboxedType»Stream«ENDIF»(this.collection.stream());
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return «type.stream2Name».from«IF type.javaUnboxedType»Stream«ENDIF»(this.collection.parallelStream());
			}

			@Override
			«IF type == Type.OBJECT»
				public Object[] toObjectArray() {
					return this.collection.toArray();
				}

				@Override
				public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] array = supplier.apply(this.collection.size());
					return this.collection.toArray(array);
				}
			«ELSE»
				public «type.javaName»[] toPrimitiveArray() {
					return new Array<>(this.collection.toArray()).mapTo«type.typeName»(i -> («type.javaName») i).array;
				}
			«ENDIF»

			@Override
			public ArrayList<«type.genericBoxedName»> toArrayList() {
				return new ArrayList<>(this.collection);
			}

			@Override
			public HashSet<«type.genericBoxedName»> toHashSet() {
				return new HashSet<>(this.collection);
			}

			@Override
			public Collection<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableCollection(this.collection);
			}

			@Override
			public String toString() {
				return this.collection.toString();
			}
		}
	'''
}