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
	def baseContainerViewShortName() { type.shortName("BaseContainerView") }
	def mappedContainerViewShortName() { type.shortName("MappedContainerView") }
	def mapTargetType() { if (type == Type.OBJECT) "B" else "A" }
	def filteredContainerViewShortName() { type.shortName("FilteredContainerView") }
	def limitedContainerViewShortName() { type.shortName("LimitedContainerView") }
	def skippedContainerViewShortName() { type.shortName("SkippedContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.HashSet;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.Spliterator;
		import java.util.function.Consumer;
		import java.io.Serializable;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.FUNCTION».«type.shortName("BooleanF")».*;
		import static «Constants.COMMON».*;
		«IF type.primitive»
			import static «Constants.COLLECTION».«type.arrayShortName».*;
		«ENDIF»

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
					return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
				} else {
					return new «skippedContainerViewShortName»<>(unview(), skip);
				}
			}

			static «type.paramGenericName("ContainerView")» «type.shortName("CollectionView").firstToLowerCase»(final Collection<«type.genericBoxedName»> collection) {
				return «type.shortName("CollectionView").firstToLowerCase»(collection, true);
			}

			static «type.paramGenericName("ContainerView")» «type.shortName("CollectionView").firstToLowerCase»(final Collection<«type.genericBoxedName»> collection, final boolean hasKnownFixedSize) {
				requireNonNull(collection);
				return new «type.shortName("Collection")»As«type.containerShortName»<>(collection, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
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
			«IF type == Type.INT»
				@Override
				public long sumToLong() {
					return this.container.sumToLong();
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
					return new FilteredIterator<>(this.container.iterator(), this.predicate::apply);
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
							return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
						} else {
							return new «type.shortName("SkippedContainerView")»<>(this, n);
						}
					} else {
						if (this.container.hasKnownFixedSize() && sum >= this.container.size()) {
							return «IF type == Type.OBJECT»Array.<A> «ENDIF»empty«type.arrayShortName»().view();
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