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
	def reversedContainerViewShortName() { type.shortName("ReversedContainerView") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.HashSet;
		import java.util.LinkedHashSet;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.Spliterator;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.FUNCTION».«type.shortName("BooleanF")».*;
		import static «Constants.JCATS».«type.optionShortName».*;

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
			default int size() throws SizeOverflowException {
				return foldLeftToInt(0, (final int size, final «type.genericName» __) -> {
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
				return new «mappedContainerViewShortName»<>(this, f);
			}

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					default «toType.containerViewGenericName» mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
				«ELSE»
					default «toType.containerViewGenericName» mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView<>(this, f);
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <B> ContainerView<B> flatMap(final F<A, Iterable<B>> f) {
					requireNonNull(f);
					return new FlatMappedContainerView<>(this, f);
				}
			«ELSE»
				default <A> ContainerView<A> flatMap(final «type.typeName»ObjectF<Iterable<A>> f) {
					requireNonNull(f);
					return new «type.typeName»FlatMappedContainerView<>(this, f);
				}
			«ENDIF»
			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					default «toType.containerViewGenericName» flatMapTo«toType.typeName»(final F<A, Iterable<«toType.genericBoxedName»>> f) {
				«ELSE»
					default «toType.containerViewGenericName» flatMapTo«toType.typeName»(final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
				«ENDIF»
					requireNonNull(f);
					return new «IF type.primitive»«type.typeName»«ENDIF»FlatMappedTo«toType.typeName»ContainerView<>(this, f);
				}

			«ENDFOR»
			default «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return new «filteredContainerViewShortName»<>(this, predicate);
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
				}
				return new «limitedContainerViewShortName»<>(this, limit);
			}

			default «genericName» skip(final int skip) {
				if (skip < 0) {
					throw new IllegalArgumentException(Integer.toString(skip));
				} else if (skip == 0) {
					return this;
				} else {
					return new «skippedContainerViewShortName»<>(this, skip);
				}
			}

			default «genericName» reverse() {
				return new «reversedContainerViewShortName»<>(this);
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
			public boolean hasFixedSize() {
				return this.container.hasFixedSize();
			}

			@Override
			public «type.genericName» head() {
				return this.container.head();
			}

			@Override
			public «type.optionGenericName» headOption() {
				return this.container.headOption();
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
			public «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				return this.container.lastMatch(predicate);
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
				public <A> A foldLeft(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
			«ELSE»
				public <B> B foldLeft(final B start, final F2<B, A, B> f2) {
			«ENDIF»
				return this.container.foldLeft(start, f2);
			}

			«FOR returnType : Type.primitives»
				@Override
				«IF type.primitive»
					public «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
				«ELSE»
					public «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<A> f2) {
				«ENDIF»
					return this.container.foldLeftTo«returnType.typeName»(start, f2);
				}

			«ENDFOR»
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
			«IF type == Type.OBJECT»
				public «type.optionGenericName» reduceLeft(final F2<A, A, A> f2) {
			«ELSE»
				public «type.optionGenericName» reduceLeft(final «type.typeName»«type.typeName»«type.typeName»F2 f2) {
			«ENDIF»
				return this.container.reduceLeft(f2);
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
			public «type.iteratorGenericName» reverseIterator() {
				return this.container.reverseIterator();
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
			public String joinToStringWithSeparator(final String separator) {
				return this.container.joinToStringWithSeparator(separator);
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
			public «type.spliteratorGenericName» spliterator() {
				return this.container.spliterator();
			}

			@Override
			public «type.arrayGenericName» to«type.arrayShortName»() {
				return this.container.to«type.arrayShortName»();
			}

			«IF type.primitive»
				@Override
				public Array<«type.boxedName»> toArray() {
					return this.container.toArray();
				}

			«ENDIF»
			@Override
			public «type.seqGenericName» to«type.seqShortName»() {
				return this.container.to«type.seqShortName»();
			}

			«IF type.primitive»
				@Override
				public Seq<«type.boxedName»> toSeq() {
					return this.container.toSeq();
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
				public ContainerView<«type.boxedName»> asContainer() {
					return this.container.asContainer();
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
			public LinkedHashSet<«type.genericBoxedName»> toLinkedHashSet() {
				return this.container.toLinkedHashSet();
			}

			@Override
			public «type.stream2GenericName» stream() {
				return this.container.stream();
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return this.container.parallelStream();
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
			public «mapTargetType» head() {
				return requireNonNull(this.f.apply(this.view.head()));
			}

			@Override
			public Option<«mapTargetType»> headOption() {
				return this.view.headOption().map(this.f);
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
			public Iterator<«mapTargetType»> reverseIterator() {
				if (this.view.hasFixedSize() || this.view instanceof «type.indexedContainerViewWildcardName») {
					«IF type == Type.OBJECT»
						return new MappedIterator<>(this.view.reverseIterator(), this.f);
					«ELSE»
						return new Mapped«type.typeName»ObjectIterator<>(this.view.reverseIterator(), this.f);
					«ENDIF»
				} else {
					return ContainerView.super.reverseIterator();
				}
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
			public boolean foreachUntil(final BooleanF<«mapTargetType»> eff) {
				requireNonNull(eff);
				return this.view.foreachUntil((final «type.genericName» value) -> {
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
				this.view.foreachWithIndex((final int index, final «type.genericName» value) -> {
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
				return new «mappedContainerViewShortName»<>(this.view, this.f.map(g));
			}

			«FOR t : Type.primitives»
				@Override
				public «t.containerViewGenericName» mapTo«t.typeName»(final «t.typeName»F<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> g) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»ContainerView<>(this.view, this.f.mapTo«t.typeName»(g));
				}

			«ENDFOR»
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

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				class MappedTo«toType.typeName»ContainerView<A, C extends «genericName»> implements «toType.containerViewGenericName» {
			«ELSE»
				class «type.typeName»MappedTo«toType.typeName»ContainerView<C extends «genericName»> implements «toType.containerViewGenericName» {
			«ENDIF»
				final C view;
				«IF type == Type.OBJECT»
					final «toType.typeName»F<A> f;
				«ELSE»
					final «type.typeName»«toType.typeName»F f;
				«ENDIF»

				«IF type == Type.OBJECT»
					MappedTo«toType.typeName»ContainerView(final C view, final «toType.typeName»F<A> f) {
				«ELSE»
					«type.typeName»MappedTo«toType.typeName»ContainerView(final C view, final «type.typeName»«toType.typeName»F f) {
				«ENDIF»
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
				public «toType.genericName» head() {
					return this.f.apply(this.view.head());
				}

				@Override
				public «toType.optionGenericName» headOption() {
					return this.view.headOption().mapTo«toType.typeName»(this.f);
				}

				@Override
				public «toType.iteratorGenericName» iterator() {
					«IF type == Type.OBJECT»
						return new MappedObject«toType.typeName»Iterator<>(this.view.iterator(), this.f);
					«ELSE»
						return new Mapped«type.typeName»«toType.typeName»Iterator(this.view.iterator(), this.f);
					«ENDIF»
				}

				@Override
				public «toType.iteratorGenericName» reverseIterator() {
					if (this.view.hasFixedSize() || this.view instanceof «type.indexedContainerViewWildcardName») {
						«IF type == Type.OBJECT»
							return new MappedObject«toType.typeName»Iterator<>(this.view.reverseIterator(), this.f);
						«ELSE»
							return new Mapped«type.typeName»«toType.typeName»Iterator(this.view.reverseIterator(), this.f);
						«ENDIF»
					} else {
						return «toType.containerViewGenericName».super.reverseIterator();
					}
				}

				@Override
				public void foreach(final «toType.typeName»Eff eff) {
					requireNonNull(eff);
					this.view.foreach((final «type.genericName» value) -> {
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
					return this.view.foreachUntil((final «type.genericName» value) -> {
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
					this.view.foreachWithIndex((final int index, final «type.genericName» value) -> {
						«IF type == Type.OBJECT»
							requireNonNull(value);
						«ENDIF»
						final «toType.genericName» result = this.f.apply(value);
						eff.apply(index, result);
					});
				}

				@Override
				public <B> ContainerView<B> map(final «toType.typeName»ObjectF<B> g) {
					return new «mappedContainerViewShortName»<>(this.view, this.f.map(g));
				}

				«FOR t : Type.primitives»
					@Override
					public «t.containerViewGenericName» mapTo«t.typeName»(final «toType.typeName»«t.typeName»F g) {
						return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«t.typeName»ContainerView<>(this.view, this.f.mapTo«t.typeName»(g));
					}

				«ENDFOR»
				@Override
				public «toType.containerViewGenericName» limit(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView<>(this.view.limit(n), this.f);
				}

				@Override
				public «toType.containerViewGenericName» skip(final int n) {
					return new «IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView<>(this.view.skip(n), this.f);
				}

				«toStr(toType, '''«IF type.primitive»«type.typeName»«ENDIF»MappedTo«toType.typeName»ContainerView''', false)»
			}

		«ENDFOR»
		«IF type == Type.OBJECT»
			final class FlatMappedContainerView<A, B, C extends ContainerView<A>> implements ContainerView<B> {
				final C view;
				final F<A, Iterable<B>> f;

				FlatMappedContainerView(final C view, final F<A, Iterable<B>> f) {
		«ELSE»
			final class «type.typeName»FlatMappedContainerView<A, C extends «genericName»> implements ContainerView<A> {
				final C view;
				final «type.typeName»ObjectF<Iterable<A>> f;

				«type.typeName»FlatMappedContainerView(final C view, final «type.typeName»ObjectF<Iterable<A>> f) {
		«ENDIF»
				this.view = view;
				this.f = f;
			}

			@Override
			public boolean hasFixedSize() {
				return false;
			}

			@Override
			public Iterator<«mapTargetType»> iterator() {
				return new FlatMapped«IF type != Type.OBJECT»«type.typeName»Object«ENDIF»Iterator<>(this.view.iterator(), this.f);
			}

			@Override
			public Iterator<«mapTargetType»> reverseIterator() {
				if (this.view.hasFixedSize() || this.view instanceof «type.indexedContainerViewWildcardName») {
					return new FlatMapped«IF type != Type.OBJECT»«type.typeName»Object«ENDIF»ReverseIterator<>(this.view.reverseIterator(), this.f);
				} else {
					return ContainerView.super.reverseIterator();
				}
			}

			@Override
			public void foreach(final Eff<«mapTargetType»> eff) {
				requireNonNull(eff);
				this.view.foreach((final «type.genericName» value) -> {
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
				return this.view.foreachUntil((final «type.genericName» value) -> {
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

			«toStr(Type.OBJECT, type.shortName("FlatMappedContainerView"), false)»
		}

		«FOR toType : Type.primitives»
			«IF type == Type.OBJECT»
				final class FlatMappedTo«toType.typeName»ContainerView<A, C extends «genericName»> implements «toType.containerViewGenericName» {
					final C view;
					final F<A, Iterable<«toType.genericBoxedName»>> f;

					FlatMappedTo«toType.typeName»ContainerView(final C view, final F<A, Iterable<«toType.genericBoxedName»>> f) {
			«ELSE»
				final class «type.typeName»FlatMappedTo«toType.typeName»ContainerView<C extends «genericName»> implements «toType.containerViewGenericName» {
					final C view;
					final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f;

					«type.typeName»FlatMappedTo«toType.typeName»ContainerView(final C view, final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
			«ENDIF»
					this.view = view;
					this.f = f;
				}

				@Override
				public boolean hasFixedSize() {
					return false;
				}

				@Override
				public «toType.iteratorGenericName» iterator() {
					«IF type == Type.OBJECT»
						return new FlatMappedObject«toType.typeName»Iterator<>(this.view.iterator(), this.f);
					«ELSE»
						return new FlatMapped«type.typeName»«toType.typeName»Iterator(this.view.iterator(), this.f);
					«ENDIF»
				}

				@Override
				public «toType.iteratorGenericName» reverseIterator() {
					if (this.view.hasFixedSize() || this.view instanceof «type.indexedContainerViewWildcardName») {
						«IF type == Type.OBJECT»
							return new FlatMappedObject«toType.typeName»ReverseIterator<>(this.view.reverseIterator(), this.f);
						«ELSE»
							return new FlatMapped«type.typeName»«toType.typeName»ReverseIterator(this.view.reverseIterator(), this.f);
						«ENDIF»
					} else {
						return «toType.containerViewGenericName».super.reverseIterator();
					}
				}

				@Override
				public void foreach(final «toType.typeName»Eff eff) {
					requireNonNull(eff);
					this.view.foreach((final «type.genericName» value) -> {
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
					return this.view.foreachUntil((final «type.genericName» value) -> {
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

				«toStr(toType, '''«IF type.primitive»«type.typeName»«ENDIF»FlatMappedTo«toType.typeName»ContainerView''', false)»
			}

		«ENDFOR»
		final class «filteredContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «genericName»> implements «genericName» {
			final C view;
			final «type.boolFName» predicate;

			«filteredContainerViewShortName»(final C view, final «type.boolFName» predicate) {
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
				«IF type == Type.OBJECT || type.javaUnboxedType»
					return new «type.diamondName("FilteredIterator")»(this.view.iterator(), this.predicate);
				«ELSE»
					return new FilteredIterator<>(this.view.iterator(), this.predicate::apply);
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				if (this.view.hasFixedSize() || this.view instanceof «type.indexedContainerViewWildcardName») {
					«IF type == Type.OBJECT || type.javaUnboxedType»
						return new «type.diamondName("FilteredIterator")»(this.view.reverseIterator(), this.predicate);
					«ELSE»
						return new FilteredIterator<>(this.view.reverseIterator(), this.predicate::apply);
					«ENDIF»
				} else {
					return «shortName».super.reverseIterator();
				}
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

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				«IF type == Type.OBJECT»
					return this.view.foreachUntil((final «type.genericName» value) -> {
						requireNonNull(value);
						return !this.predicate.apply(value) || eff.apply(value);
					});
				«ELSE»
					return this.view.foreachUntil((final «type.genericName» value) ->
						!this.predicate.apply(value) || eff.apply(value));
				«ENDIF»
			}

			@Override
			public «genericName» filter(final «type.boolFName» p) {
				return new «filteredContainerViewShortName»<>(this.view, and(this.predicate, p));
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
				return (this.limit == 0) || this.view.hasFixedSize();
			}

			@Override
			public «type.genericName» head() {
				if (this.limit == 0) {
					throw new NoSuchElementException();
				} else {
					return this.view.head();
				}
			}

			@Override
			public «type.optionGenericName» headOption() {
				if (this.limit == 0) {
					return «type.noneName»();
				} else {
					return this.view.headOption();
				}
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
				if (this.view.hasFixedSize()) {
					return (this.skip >= this.view.size());
				} else {
					return «shortName».super.isEmpty();
				}
			}

			@Override
			public boolean isNotEmpty() {
				if (this.view.hasFixedSize()) {
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

		class «reversedContainerViewShortName»<«IF type == Type.OBJECT»A, «ENDIF»C extends «genericName»> implements «genericName» {
			final C view;

			«reversedContainerViewShortName»(final C view) {
				this.view = view;
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
			public boolean contains(final «type.genericName» value) {
				return this.view.contains(value);
			}

			@Override
			public «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				return this.view.lastMatch(predicate);
			}

			@Override
			public «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				return this.view.firstMatch(predicate);
			}

			@Override
			public boolean anyMatch(final «type.boolFName» predicate) {
				return this.view.anyMatch(predicate);
			}

			@Override
			public boolean allMatch(final «type.boolFName» predicate) {
				return this.view.allMatch(predicate);
			}

			@Override
			public boolean noneMatch(final «type.boolFName» predicate) {
				return this.view.noneMatch(predicate);
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return this.view.reverseIterator();
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return this.view.iterator();
			}

			«IF type.javaUnboxedType»
				@Override
				public «type.javaName» sum() {
					return this.view.sum();
				}

			«ENDIF»
			«IF type == Type.INT»
				@Override
				public long sumToLong() {
					return this.view.sumToLong();
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				@Override
				public «type.optionGenericName» max(final «type.ordGenericName» ord) {
					return this.view.max(ord);
				}

				@Override
				public «type.optionGenericName» min(final «type.ordGenericName» ord) {
					return this.view.min(ord);
				}
			«ELSE»
				@Override
				public «type.optionGenericName» max() {
					return this.view.max();
				}

				@Override
				public «type.optionGenericName» min() {
					return this.view.min();
				}

				@Override
				public «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
					return this.view.maxByOrd(ord);
				}

				@Override
				public «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
					return this.view.minByOrd(ord);
				}
			«ENDIF»

			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» maxBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» maxBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				return this.view.maxBy(f);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» maxBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» maxBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					return this.view.maxBy«to.typeName»(f);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» minBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» minBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				return this.view.minBy(f);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» minBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» minBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					return this.view.minBy«to.typeName»(f);
				}

			«ENDFOR»
			@Override
			public «genericName» reverse() {
				return this.view;
			}

			@Override
			public HashSet<«type.genericBoxedName»> toHashSet() {
				return this.view.toHashSet();
			}

			«toStr(type, reversedContainerViewShortName, false)»
		}
	''' }
}