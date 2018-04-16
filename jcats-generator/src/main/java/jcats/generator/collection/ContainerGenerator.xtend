package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class ContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Container" else type.typeName + "Container" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Collections;
		import java.util.HashSet;
		import java.util.Iterator;
		import java.util.LinkedHashSet;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.NavigableSet;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;
		import java.util.stream.«type.streamName»;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;
		«IF type != Type.INT»
			import static «Constants.JCATS».«type.optionShortName».*;
		«ENDIF»
		import static «Constants.COLLECTION».Common.*;
		import static «Constants.JCATS».«type.ordShortName».*;
		«IF type.primitive»
			import static «Constants.ARRAY».*;
		«ENDIF»

		public interface «type.covariantName("Container")» extends Iterable<«type.genericBoxedName»>, Sized {

			default boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (iterator.«type.iteratorNext»() == value) {
							return true;
						}
					}
				«ELSE»
					for (final «type.genericName» a : this) {
						«IF type == Type.OBJECT»
							if (a.equals(value)) {
						«ELSE»
							if (a == value) {
						«ENDIF»
							return true;
						}
					}
				«ENDIF»
				return false;
			}

			default «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						final «type.genericName» value = iterator.«type.iteratorNext»();
						if (predicate.apply(value)) {
							return «type.someName»(value);
						}
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (predicate.apply(value)) {
							return «type.someName»(value);
						}
					}
				«ENDIF»
				return «type.noneName»();
			}

			default «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					final «type.genericName» value = iterator.«type.iteratorNext»();
					if (predicate.apply(value)) {
						return «type.someName»(value);
					}
				}
				return «type.noneName»();
			}

			default boolean anyMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (predicate.apply(iterator.«type.iteratorNext»())) {
							return true;
						}
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (predicate.apply(value)) {
							return true;
						}
					}
				«ENDIF»
				return false;
			}

			default boolean allMatch(final «type.boolFName» predicate) {
				return !anyMatch(predicate.negate());
			}

			default boolean noneMatch(final «type.boolFName» predicate) {
				return !anyMatch(predicate);
			}

			«IF type.primitive»
				default <A> A foldLeft(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					final «type.typeName»Folder<A> folder = new «type.typeName»Folder<>(start, f2);
					foreach(folder);
					return folder.acc;
				}
			«ELSE»
				default <B> B foldLeft(final B start, final F2<B, A, B> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					final Folder<A, B> folder = new Folder<>(start, f2);
					foreach(folder);
					return folder.acc;
				}
			«ENDIF»

			«IF type.primitive»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
						requireNonNull(f2);
						final «type.typeName»FolderTo«returnType.typeName» folder = new «type.typeName»FolderTo«returnType.typeName»(start, f2);
						foreach(folder);
						return folder.acc;
					}

				«ENDFOR»
			«ELSE»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<A> f2) {
						requireNonNull(f2);
						final FolderTo«returnType.typeName»<A> folder = new FolderTo«returnType.typeName»<>(start, f2);
						foreach(folder);
						return folder.acc;
					}

				«ENDFOR»
			«ENDIF»
			«IF type.javaUnboxedType»
				default <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSEIF type == Type.BOOLEAN»
				default <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSE»
				default <B> B foldRight(final B start, final F2<A, B, B> f2) {
			«ENDIF»
				requireNonNull(start);
				requireNonNull(f2);
				«IF type == Type.OBJECT»B«ELSE»A«ENDIF» result = start;
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					final «type.genericName» value = iterator.«type.iteratorNext»();
					result = requireNonNull(f2.apply(value, result));
				}
				return result;
			}

			«FOR returnType : Type.primitives»
				«IF type == Type.OBJECT»
					default «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<A> f2) {
				«ELSE»
					default «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final «type.typeName»«returnType.typeName»«returnType.typeName»F2 f2) {
				«ENDIF»
					requireNonNull(f2);
					«returnType.javaName» result = start;
					final «type.iteratorGenericName» iterator = reverseIterator();
					while (iterator.hasNext()) {
						final «type.genericName» value = iterator.«type.iteratorNext»();
						result = f2.apply(value, result);
					}
					return result;
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				default Option<A> reduceLeft(final F2<A, A, A> f2) {
					requireNonNull(f2);
					final Reducer<A> reducer = new Reducer<>(f2);
					foreach(reducer);
					return Option.fromNullable(reducer.acc);
				}
			«ELSE»
				default «type.optionGenericName» reduceLeft(final «type.typeName»«type.typeName»«type.typeName»F2 f2) {
					requireNonNull(f2);
					final «type.typeName»Reducer reducer = new «type.typeName»Reducer(f2);
					foreach(reducer);
					if (reducer.nonEmpty) {
						return «type.someName»(reducer.acc);
					} else {
						return «type.noneName»();
					}
				}
			«ENDIF»

			«IF type.javaUnboxedType»
				default «type.javaName» sum() {
					return foldLeftTo«type.typeName»(0, Common.SUM_«type.typeName.toUpperCase»);
				}

			«ENDIF»
			«IF type == Type.INT»
				default long sumToLong() {
					return foldLeftToLong(0L, (final long sum, final int i) -> sum + i);
				}

			«ENDIF»
			default void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						eff.apply(iterator.«type.iteratorNext»());
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						eff.apply(value);
					}
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				default void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				default void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				int i = 0;
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (i < 0) {
							throw new IndexOutOfBoundsException("Integer overflow");
						}
						eff.apply(i++, iterator.«type.iteratorNext»());
				«ELSE»
					for (final «type.genericName» value : this) {
						if (i < 0) {
							throw new IndexOutOfBoundsException("Integer overflow");
						}
						eff.apply(i++, value);
				«ENDIF»
				}
			}

			default void foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (!eff.apply(iterator.«type.iteratorNext»())) {
							return;
						}
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (!eff.apply(value)) {
							return;
						}
					}
				«ENDIF»
			}

			@Override
			default void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				requireNonNull(action);
				foreach(action::accept);
			}

			default void printAll() {
				foreach(System.out::println);
			}

			«IF type.javaUnboxedType»
				@Override
				«type.iteratorGenericName» iterator();

			«ENDIF»
			default «type.iteratorGenericName» reverseIterator() {
				return to«type.arrayShortName»().reverseIterator();
			}

			default String joinToString() {
				if (isEmpty()) {
					return "";
				} else {
					final StringBuilder builder = new StringBuilder();
					foreach(builder::append);
					return builder.toString();
				}
			}

			default String joinToStringWithSeparator(final String separator) {
				if (isEmpty()) {
					return "";
				} else {
					final StringBuilder builder = new StringBuilder();
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						builder.append(iterator.«type.iteratorNext»());
						if (iterator.hasNext()) {
							builder.append(separator);
						}
					}
					return builder.toString();
				}
			}

			«IF type == Type.OBJECT»
				default «type.optionGenericName» max(final «type.ordGenericName» ord) {
					return reduceLeft(ord::max);
				}

				default «type.optionGenericName» min(final «type.ordGenericName» ord) {
					return reduceLeft(ord::min);
				}
			«ELSE»
				default «type.optionGenericName» max() {
					«IF type.javaUnboxedType»
						return reduceLeft(«type.boxedName»::max);
					«ELSE»
						return maxByOrd(«type.ordShortName.firstToLowerCase»());
					«ENDIF»
				}

				default «type.optionGenericName» min() {
					«IF type.javaUnboxedType»
						return reduceLeft(«type.boxedName»::min);
					«ELSE»
						return minByOrd(«type.ordShortName.firstToLowerCase»());
					«ENDIF»
				}

				default «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
					return reduceLeft(ord::max);
				}

				default «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
					return reduceLeft(ord::min);
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				default <B extends Comparable<B>> «type.optionGenericName» maxBy(final F<A, B> f) {
					return max(by(f));
			«ELSE»
				default <A extends Comparable<A>> «type.optionGenericName» maxBy(final «type.typeName»ObjectF<A> f) {
					return maxByOrd(by(f));
			«ENDIF»
			}

			«FOR to : Type.primitives»
				«IF type == Type.OBJECT»
					default «type.optionGenericName» maxBy«to.typeName»(final «to.typeName»F<A> f) {
						return max(by«to.typeName»(f));
				«ELSE»
					default «type.optionGenericName» maxBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
						return maxByOrd(by«to.typeName»(f));
				«ENDIF»
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <B extends Comparable<B>> «type.optionGenericName» minBy(final F<A, B> f) {
					return min(by(f));
			«ELSE»
				default <A extends Comparable<A>> «type.optionGenericName» minBy(final «type.typeName»ObjectF<A> f) {
					return minByOrd(by(f));
			«ENDIF»
			}
			
			«FOR to : Type.primitives»
				«IF type == Type.OBJECT»
					default «type.optionGenericName» minBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					default «type.optionGenericName» minBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					«IF to == Type.DOUBLE»
						return reduceLeft((final «type.genericName» min, final «type.genericName» value) -> {
							final double minResult = f.apply(min);
							final double valueResult = f.apply(value);
							if (Double.isNaN(minResult)) {
								return min;
							} else if (Double.isNaN(valueResult)) {
								return value;
							} else {
								return Double.compare(minResult, valueResult) < 0 ? min : value;
							}
						});
					«ELSEIF type == Type.OBJECT»
						return min(by«to.typeName»(f));
					«ELSE»
						return minByOrd(by«to.typeName»(f));
					«ENDIF»
				}

			«ENDFOR»
			default int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE;
			}

			@Override
			default «type.spliteratorGenericName» spliterator() {
				if (isEmpty()) {
					return Spliterators.«type.emptySpliteratorName»();
				} else if (hasFixedSize()) {
					return Spliterators.spliterator(iterator(), size(), spliteratorCharacteristics());
				} else {
					return Spliterators.spliteratorUnknownSize(iterator(), spliteratorCharacteristics());
				}
			}

			default «type.arrayGenericName» to«type.arrayShortName»() {
				if (isEmpty()) {
					return «type.arrayShortName».empty«type.arrayShortName»();
				} else {
					return new «type.diamondName("Array")»(«type.toArrayName»());
				}
			}

			«IF type.primitive»
				default Array<«type.boxedName»> toArray() {
					if (isEmpty()) {
						return emptyArray();
					} else if (hasFixedSize()) {
						final Object[] array = new Object[size()];
						foreachWithIndex((final int index, final «type.javaName» value) -> array[index] = value);
						return new Array<>(array);
					} else {
						final ArrayBuilder<«type.boxedName»> builder = Array.builder();
						foreach(builder::append);
						return builder.build();
					}
				}

			«ENDIF»
			default «type.seqGenericName» to«type.seqShortName»() {
				if (hasFixedSize()) {
					return «type.seqShortName».sizedToSeq(iterator(), size());
				} else {
					final «type.seqBuilderGenericName» builder = new «type.seqBuilderDiamondName»();
					foreach(builder::append);
					return builder.build();
				}
			}

			«IF type.primitive»
				default Seq<«type.boxedName»> toSeq() {
					if (hasFixedSize()) {
						return Seq.sizedToSeq(iterator(), size());
					} else {
						final SeqBuilder<«type.boxedName»> builder = new SeqBuilder<>();
						foreach(builder::append);
						return builder.build();
					}
				}

			«ENDIF»
			default «type.javaName»[] «type.toArrayName»() {
				if (isEmpty()) {
					return «type.emptyArrayName»;
				} else if (hasFixedSize()) {
					final «type.javaName»[] array = new «type.javaName»[size()];
					foreachWithIndex((final int index, final «type.genericName» value) -> array[index] = value);
					return array;
				} else {
					final «type.arrayBuilderGenericName» builder = «type.arrayShortName».builder();
					foreach(builder::append);
					return builder.buildArray();
				}
			}

			«IF type == Type.OBJECT»
				default A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					if (hasFixedSize()) {
						final A[] array = supplier.apply(size());
						requireNonNull(array);
						foreachWithIndex((final int index, final A value) -> array[index] = value);
						return array;
					} else {
						final ArrayBuilder<A> builder = Array.builder();
						foreach(builder::append);
						return builder.buildPreciseArray(supplier);
					}
				}

			«ENDIF»
			«IF type.primitive»
				default Container<«type.boxedName»> asContainer() {
					return new «shortName»AsContainer(this);
				}

			«ENDIF»
			default Collection<«type.genericBoxedName»> asCollection() {
				return new «shortName»AsCollection«IF type == Type.OBJECT»<>«ENDIF»(this);
			}

			default ArrayList<«type.genericBoxedName»> toArrayList() {
				return new ArrayList<>(asCollection());
			}

			default HashSet<«type.genericBoxedName»> toHashSet() {
				return new HashSet<>(asCollection());
			}

			default LinkedHashSet<«type.genericBoxedName»> toLinkedHashSet() {
				return new LinkedHashSet<>(asCollection());
			}

			default «type.stream2GenericName» stream() {
				return new «type.stream2DiamondName»(StreamSupport.«type.streamFunction»(spliterator(), false));
			}

			default «type.stream2GenericName» parallelStream() {
				return new «type.stream2DiamondName»(StreamSupport.«type.streamFunction»(spliterator(), true));
			}

			«IF type == Type.OBJECT»
				static <A> Container<A> asContainer(final Collection<A> collection) {
					requireNonNull(collection);
					return new CollectionAsContainer<>(collection);
				}
			«ELSE»
				static «type.containerGenericName» as«type.typeName»Container(final Collection<«type.boxedName»> collection) {
					requireNonNull(collection);
					return new «type.typeName»CollectionAs«type.typeName»Container(collection);
				}
			«ENDIF»
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type.primitive»
			final class «type.genericName("ContainerAsContainer")» implements Container<«type.boxedName»> {
				final «shortName» container;

				«shortName»AsContainer(final «shortName» container) {
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
				public boolean contains(final «type.boxedName» value) {
					return this.container.contains(value);
				}

				@Override
				public Option<«type.boxedName»> firstMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.firstMatch(predicate::apply).toOption();
				}

				@Override
				public Option<«type.boxedName»> lastMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.lastMatch(predicate::apply).toOption();
				}

				@Override
				public boolean anyMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.anyMatch(predicate::apply);
				}

				@Override
				public boolean allMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.allMatch(predicate::apply);
				}

				@Override
				public boolean noneMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.noneMatch(predicate::apply);
				}

				@Override
				public <A> A foldLeft(final A start, final F2<A, «type.boxedName», A> f2) {
					return this.container.foldLeft(start, f2::apply);
				}

				«FOR returnType : Type.primitives»
					@Override
					public «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<«type.boxedName»> f2) {
						return this.container.foldLeftTo«returnType.typeName»(start, f2::apply);
					}

				«ENDFOR»
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
				public Option<«type.boxedName»> reduceLeft(final F2<«type.boxedName», «type.boxedName», «type.boxedName»> f2) {
					return this.container.reduceLeft(f2::apply).toOption();
				}

				@Override
				public void forEach(final Consumer<? super «type.boxedName»> action) {
					this.container.forEach(action);
				}

				@Override
				public void foreach(final Eff<«type.boxedName»> eff) {
					this.container.foreach(eff::apply);
				}

				@Override
				public void foreachWithIndex(final IntObjectEff2<«type.boxedName»> eff) {
					this.container.foreachWithIndex(eff::apply);
				}

				@Override
				public void foreachUntil(final BooleanF<«type.boxedName»> eff) {
					this.container.foreachUntil(eff::apply);
				}

				@Override
				public void printAll() {
					this.container.printAll();
				}

				@Override
				public «type.iteratorGenericName» iterator() {
					return this.container.iterator();
				}

				@Override
				public «type.spliteratorGenericName» spliterator() {
					return this.container.spliterator();
				}

				@Override
				public «type.iteratorGenericName» reverseIterator() {
					return this.container.reverseIterator();
				}

				@Override
				public String joinToString() {
					return this.container.joinToString();
				}

				@Override
				public String joinToStringWithSeparator(final String separator) {
					return this.container.joinToStringWithSeparator(separator);
				}

				@Override
				public Option<«type.boxedName»> max(final Ord<«type.boxedName»> ord) {
					return this.container.maxByOrd(ord::compare).toOption();
				}

				@Override
				public Option<«type.boxedName»> min(final Ord<«type.boxedName»> ord) {
					return this.container.minByOrd(ord::compare).toOption();
				}

				@Override
				public <B extends Comparable<B>> Option<«type.boxedName»> maxBy(final F<«type.boxedName», B> f) {
					return this.container.maxBy(f::apply).toOption();
				}

				«FOR to : Type.primitives»
					@Override
					public Option<«type.boxedName»> maxBy«to.typeName»(final «to.typeName»F<«type.boxedName»> f) {
						return this.container.maxBy«to.typeName»(f::apply).toOption();
					}

				«ENDFOR»
				@Override
				public <B extends Comparable<B>> Option<«type.boxedName»> minBy(final F<«type.boxedName», B> f) {
					return this.container.minBy(f::apply).toOption();
				}

				«FOR to : Type.primitives»
					@Override
					public Option<«type.boxedName»> minBy«to.typeName»(final «to.typeName»F<«type.boxedName»> f) {
						return this.container.minBy«to.typeName»(f::apply).toOption();
					}

				«ENDFOR»
				@Override
				public Array<«type.boxedName»> toArray() {
					return this.container.toArray();
				}

				@Override
				public Seq<«type.boxedName»> toSeq() {
					return this.container.toSeq();
				}

				@Override
				public Object[] toObjectArray() {
					return this.container.toArray().array;
				}

				@Override
				public Collection<«type.boxedName»> asCollection() {
					return this.container.asCollection();
				}

				@Override
				public ArrayList<«type.boxedName»> toArrayList() {
					return this.container.toArrayList();
				}

				@Override
				public HashSet<«type.boxedName»> toHashSet() {
					return this.container.toHashSet();
				}

				@Override
				public LinkedHashSet<«type.boxedName»> toLinkedHashSet() {
					return this.container.toLinkedHashSet();
				}

				@Override
				public Stream2<«type.boxedName»> stream() {
					return this.container.stream()«IF type.javaUnboxedType».boxed()«ENDIF»;
				}

				@Override
				public Stream2<«type.boxedName»> parallelStream() {
					return this.container.parallelStream()«IF type.javaUnboxedType».boxed()«ENDIF»;
				}

				@Override
				public String toString() {
					return this.container.toString();
				}
			}

		«ENDIF»
		final class «type.genericName("ContainerAsCollection")» extends AbstractImmutableCollection<«type.genericBoxedName»> {
			final «genericName» container;

			«shortName»AsCollection(final «genericName» container) {
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

			«IF type == Type.OBJECT»
				@Override
				public Object[] toArray() {
					return this.container.toObjectArray();
				}

			«ENDIF»
			@Override
			public Iterator<«type.genericBoxedName»> iterator() {
				return this.container.iterator();
			}

			@Override
			public Spliterator<«type.genericBoxedName»> spliterator() {
				return this.container.spliterator();
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.container.forEach(action);
			}
		}

		«IF type == Type.OBJECT»
			class CollectionAsContainer<C extends Collection<A>, A> implements Container<A> {
		«ELSE»
			class «type.typeName»CollectionAs«type.typeName»Container<C extends Collection<«type.boxedName»>> implements «type.typeName»Container {
		«ENDIF»
			final C collection;

			«IF type == Type.OBJECT»
				CollectionAsContainer(final C collection) {
			«ELSE»
				«type.typeName»CollectionAs«type.typeName»Container(final C collection) {
			«ENDIF»
				this.collection = collection;
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
			public boolean hasFixedSize() {
				return false;
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
			public «type.iteratorGenericName» reverseIterator() {
				if (this.collection instanceof NavigableSet) {
					«IF type.javaUnboxedType»
						return «type.typeName»Iterator.getIterator(((NavigableSet<«type.boxedName»>) this.collection).descendingIterator());
					«ELSE»
						return ((NavigableSet<«type.genericBoxedName»>) this.collection).descendingIterator();
					«ENDIF»
				} else {
					return «type.containerShortName».super.reverseIterator();
				}
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
			«ELSE»
				public «type.javaName»[] toPrimitiveArray() {
					return new Array<>(this.collection.toArray()).mapTo«type.typeName»(i -> («type.javaName») i).array;
				}
			«ENDIF»

			@Override
			public Collection<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableCollection(this.collection);
			}

			@Override
			public String toString() {
				return this.collection.toString();
			}
		}

		«IF type == Type.OBJECT»
			final class Folder<A, B> implements Eff<A> {
				B acc;
				final F2<B, A, B> f2;

				Folder(final B start, final F2<B, A, B> f2) {
					this.acc = start;
					this.f2 = f2;
				}

				public void apply(final A value) {
					requireNonNull(value);
					this.acc = requireNonNull(this.f2.apply(this.acc, value));
				}
			}

			«FOR returnType : Type.primitives»
				final class FolderTo«returnType.typeName»<A> implements Eff<A> {
					«returnType.javaName» acc;
					final «returnType.typeName»«type.typeName»«returnType.typeName»F2<A> f2;

					FolderTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2<A> f2) {
						this.acc = start;
						this.f2 = f2;
					}

					public void apply(final A value) {
						this.acc = this.f2.apply(this.acc, value);
					}
				}

			«ENDFOR»
			final class Reducer<A> implements Eff<A> {
				A acc;
				final F2<A, A, A> f2;

				Reducer(final F2<A, A, A> f2) {
					this.f2 = f2;
				}

				public void apply(final A value) {
					requireNonNull(value);
					if (this.acc == null) {
						this.acc = value;
					} else {
						this.acc = requireNonNull(this.f2.apply(this.acc, value));
					}
				}
			}
		«ELSE»
			final class «type.typeName»Folder<A> implements «type.effGenericName» {
				A acc;
				final Object«type.typeName»ObjectF2<A, A> f2;

				«type.typeName»Folder(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
					this.acc = start;
					this.f2 = f2;
				}

				public void apply(final «type.javaName» value) {
					this.acc = requireNonNull(this.f2.apply(this.acc, value));
				}
			}

			«FOR returnType : Type.primitives»
				final class «type.typeName»FolderTo«returnType.typeName» implements «type.effGenericName» {
					«returnType.javaName» acc;
					final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2;

					«type.typeName»FolderTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
						this.acc = start;
						this.f2 = f2;
					}

					public void apply(final «type.javaName» value) {
						this.acc = this.f2.apply(this.acc, value);
					}
				}

			«ENDFOR»
			final class «type.typeName»Reducer implements «type.typeName»Eff {
				«type.javaName» acc;
				boolean nonEmpty;
				final «type.typeName»«type.typeName»«type.typeName»F2 f2;

				«type.typeName»Reducer(final «type.typeName»«type.typeName»«type.typeName»F2 f2) {
					this.f2 = f2;
				}

				public void apply(final «type.javaName» value) {
					if (this.nonEmpty) {
						this.acc = this.f2.apply(this.acc, value);
					} else {
						this.acc = value;
						this.nonEmpty = true;
					}
				}
			}
		«ENDIF»
	''' }
}