package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class SeqGenerator implements ClassGenerator {
	package val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new SeqGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.seqShortName }
	def genericName() { type.seqGenericName }
	def genericName(int index) { type.genericName("Seq" + index) }
	def diamondName(int index) { type.diamondName("Seq" + index) }
	def wildcardName() { type.wildcardName("Seq") }
	def paramGenericName() { type.paramGenericName("Seq") }
	def paramGenericName(int index) { type.paramGenericName("Seq" + index) }
	def seqBuilderName() { type.seqBuilderGenericName }
	def seqBuilderDiamondName() { type.diamondName("SeqBuilder") }
	def iteratorName(int index) { type.genericName("Seq" + index + "Iterator") }
	def iteratorDiamondName(int index) { type.diamondName("Seq" + index + "Iterator") }
	def reverseIteratorName(int index) { type.genericName("Seq" + index + "ReverseIterator") }
	def reverseIteratorDiamondName(int index) { type.diamondName("Seq" + index + "ReverseIterator") }
	def index() { if (type == Type.OBJECT) "index" else "Seq.index" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		«IF type == Type.OBJECT || type.javaUnboxedType»
			import java.util.Arrays;
		«ENDIF»
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.stream.Collector;
		import java.util.stream.«type.streamName»;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«FOR t : Type.values»
			«IF t != type»
				import static «Constants.COLLECTION».«t.seqShortName».*;
			«ENDIF»
		«ENDFOR»
		«IF type == Type.OBJECT»
			import static «Constants.ORD».*;
			import static «Constants.F».*;
			import static «Constants.FUNCTION».IntObjectF.*;
		«ELSEIF type == Type.INT»
			import static «Constants.FUNCTION».IntIntF.*;
		«ELSE»
			import static «Constants.FUNCTION».Int«type.typeName»F.*;
			import static «Constants.FUNCTION».«type.typeName»«type.typeName»F.*;
		«ENDIF»
		import static «Constants.JCATS».IntOption.*;
		import static «Constants.COMMON».*;


		public abstract class «type.covariantName("Seq")» implements «type.indexedContainerGenericName», Serializable {

			static final «type.javaName»[][] EMPTY_NODE2 = new «type.javaName»[0][];

			«shortName»() {
			}

			/**
			 * O(1)
			 */
			@Override
			public abstract int size();

			/**
			 * O(1)
			 */
			public abstract «genericName» init() throws NoSuchElementException;

			/**
			 * O(1)
			 */
			public abstract «genericName» tail() throws NoSuchElementException;

			/**
			 * O(log(size))
			 */
			@Override
			public abstract «type.genericName» get(int index) throws IndexOutOfBoundsException;

			/**
			 * O(log(size))
			 */
			public final «genericName» set(final int index, final «type.genericName» value) throws IndexOutOfBoundsException {
				«IF type == Type.OBJECT»
					return update(index, always(value));
				«ELSE»
					return update(index, «type.typeName.firstToLowerCase»«type.typeName»Always(value));
				«ENDIF»
			}

			/**
			 * O(log(size))
			 */
			public abstract «genericName» update(int index, «type.updateFunction» f) throws IndexOutOfBoundsException;

			@Override
			public IntOption lastIndexWhere(final «type.boolFName» predicate) {
				int index = size() - 1;
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					if (predicate.apply(iterator.«type.iteratorNext»())) {
						return intSome(index);
					}
					index--;
				}
				return intNone();
			}

			public abstract «genericName» limit(int n);

			public abstract «genericName» skip(int n);

			«takeWhile(true, type)»

			/**
			 * O(1)
			 */
			public abstract «genericName» prepend(«type.genericName» value);

			/**
			 * O(1)
			 */
			public abstract «genericName» append(«type.genericName» value);

			public final «genericName» removeAt(final int index) throws IndexOutOfBoundsException {
				final int size = size();
				if (index < 0 || index >= size) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				} else {
					return remove(index);
				}
			}

			public final «genericName» removeFirstWhere(final «type.boolFName» predicate) {
				final IntOption index = indexWhere(predicate);
				if (index.isEmpty()) {
					return this;
				} else {
					return remove(index.get());
				}
			}

			public final «genericName» removeFirst(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return removeFirstWhere(value::equals);
				«ELSE»
					return removeFirstWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			public final «genericName» removeLastWhere(final «type.boolFName» predicate) {
				final IntOption index = lastIndexWhere(predicate);
				if (index.isEmpty()) {
					return this;
				} else {
					return remove(index.get());
				}
			}

			public final «genericName» removeLast(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return removeLastWhere(value::equals);
				«ELSE»
					return removeLastWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			private «genericName» remove(final int index) {
				final «genericName» prefix = limit(index);
				final «genericName» suffix = skip(index + 1);
				return concat(prefix, suffix);
			}

			// Assume suffixSize > 0
			abstract «genericName» appendSized(«type.iteratorGenericName» suffix, int suffixSize);

			// Assume prefixSize > 0
			abstract «genericName» prependSized(«type.iteratorGenericName» prefix, int prefixSize);

			public final «genericName» appendAll(final Iterable<«type.genericBoxedName»> suffix) throws SizeOverflowException {
				if (isEmpty()) {
					return ofAll(suffix);
				} else if (suffix instanceof «type.seqWildcardName») {
					return concat(this, («genericName») suffix);
				} else if (suffix instanceof Sized && ((Sized) suffix).hasKnownFixedSize()) {
					final int suffixSize = ((Sized) suffix).size();
					if (suffixSize == 0) {
						return this;
					} else if (size() + suffixSize < 0) {
						throw new SizeOverflowException();
					} else {
						return appendSized(«type.getIterator("suffix.iterator()")», suffixSize);
					}
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»(this);
					builder.appendAll(suffix);
					return builder.build();
				}
			}

			public final «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) throws SizeOverflowException {
				if (isEmpty()) {
					return ofAll(prefix);
				} else if (prefix instanceof «type.seqWildcardName») {
					return concat((«genericName») prefix, this);
				} else if (prefix instanceof Sized && ((Sized) prefix).hasKnownFixedSize()) {
					final int prefixSize = ((Sized) prefix).size();
					if (prefixSize == 0) {
						return this;
					} else if (prefixSize + size() < 0) {
						throw new SizeOverflowException();
					} else {
						return prependSized(«type.getIterator("prefix.iterator()")», prefixSize);
					}
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»();
					prefix.forEach(builder::append);
					return concat(builder.build(), this);
				}
			}

			public final «genericName» slice(final int fromIndexInclusive, final int toIndexExclusive) {
				sliceRangeCheck(fromIndexInclusive, toIndexExclusive, size());
				return skip(fromIndexInclusive).limit(toIndexExclusive - fromIndexInclusive);
			}

			public final «genericName» reverse() {
				return sizedToSeq(reverseIterator(), size());
			}

			«IF type == Type.OBJECT»
				public final <B> Seq<B> map(final F<A, B> f) {
					requireNonNull(f);
					if (f == F.id()) {
						return (Seq<B>) this;
					} else {
						return sizedToSeq(new MappedIterator<>(iterator(), f), size());
					}
				}
			«ELSE»
				public final <A> Seq<A> map(final «type.typeName»ObjectF<A> f) {
					requireNonNull(f);
					return Seq.sizedToSeq(new Mapped«type.typeName»ObjectIterator<>(iterator(), f), size());
				}
			«ENDIF»

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					public final «toType.typeName»Seq mapTo«toType.typeName»(final «toType.typeName»F<A> f) {
						requireNonNull(f);
						return «toType.typeName»Seq.sizedToSeq(new MappedObject«toType.typeName»Iterator<>(iterator(), f), size());
					}
				«ELSE»
					public final «toType.typeName»Seq mapTo«toType.typeName»(final «type.typeName»«toType.typeName»F f) {
						requireNonNull(f);
						«IF type == toType»
						if (f == «type.javaName»Id()) {
							return this;
						} else {
						«ENDIF»
						«IF type == toType»	«ENDIF»return «toType.typeName»Seq.sizedToSeq(new Mapped«type.typeName»«toType.typeName»Iterator(iterator(), f), size());
						«IF type == toType»
						}
						«ENDIF»
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				public final <B> Seq<B> mapWithIndex(final IntObjectObjectF2<A, B> f) {
			«ELSE»
				public final <A> Seq<A> mapWithIndex(final Int«type.typeName»ObjectF2<A> f) {
			«ENDIF»
				if (isEmpty()) {
					return emptySeq();
				} else {
					final «type.iteratorGenericName» iterator = iterator();
					return Seq.tabulate(size(), (final int i) -> f.apply(i, iterator.«type.iteratorNext»()));
				}
			}

			«IF type == Type.OBJECT»
				public final <B> Seq<B> flatMap(final F<A, Iterable<B>> f) {
			«ELSE»
				public final <A> Seq<A> flatMap(final «type.typeName»ObjectF<Iterable<A>> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptySeq();
				} else {
					final SeqBuilder<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> builder = new SeqBuilder<>();
					foreach((final «type.genericName» value) -> builder.appendAll(f.apply(value)));
					return builder.build();
				}
			}

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					public final «toType.seqGenericName» flatMapTo«toType.typeName»(final F<A, Iterable<«toType.genericBoxedName»>> f) {
				«ELSE»
					public final «toType.seqGenericName» flatMapTo«toType.typeName»(final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
				«ENDIF»
					requireNonNull(f);
					if (isEmpty()) {
						return empty«toType.seqShortName»();
					} else {
						final «toType.seqBuilderGenericName» builder = new «toType.seqBuilderDiamondName»();
						foreach((final «type.genericName» value) -> builder.appendAll(f.apply(value)));
						return builder.build();
					}
				}

			«ENDFOR»
			public final «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return empty«shortName»();
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»();
					for (final «type.genericName» value : this) {
						if (predicate.apply(value)) {
							builder.append(value);
						}
					}
					if (builder.size() == size()) {
						return this;
					} else {
						return builder.build();
					}
				}
			}

			«IF type == Type.OBJECT»
				public final <B extends A> Seq<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (Seq<B>) filter(clazz::isInstance);
				}

				@Override
				public final Array<A> toArray() {
					return Array.create(toSharedObjectArray());
				}

				@Override
				public final Object[] toObjectArray() {
					if (isEmpty()) {
						return EMPTY_OBJECT_ARRAY;
					} else {
						final Object[] array = new Object[size()];
						copyToArray(array);
						return array;
					}
				}

				@Override
				public final A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] array = supplier.apply(size());
					requireNonNull(array);
					copyToArray(array);
					return array;
				}

				abstract void copyToArray(Object[] array);

				Object[] toSharedObjectArray() {
					return toObjectArray();
				}
			«ELSE»
				@Override
				public final «type.arrayGenericName» to«type.arrayShortName»() {
					return «type.arrayShortName».create(toSharedPrimitiveArray());
				}

				«type.javaName»[] toSharedPrimitiveArray() {
					return toPrimitiveArray();
				}
			«ENDIF»

			@Override
			@Deprecated
			public final «type.seqGenericName» to«type.seqShortName»() {
				return this;
			}

			«IF type == Type.OBJECT»
				public Seq<A> sort(final Ord<A> ord) {
					requireNonNull(ord);
					if (size() <= 1) {
						return this;
					} else {
						final Object[] sorted = toObjectArray();
						Arrays.sort(sorted, (Ord<Object>) ord);
						return seqFromSharedArray(sorted);
					}
				}
			«ELSEIF type == Type.BOOLEAN»
				public «genericName» sortAsc() {
					final int size = size();
					if (size <= 1) {
						return this;
					} else {
						final int countFalse = foldToInt(0, (int i, boolean value) -> value ? i : i + 1);
						return tabulate(size, i -> i >= countFalse);
					}
				}

				public «genericName» sortDesc() {
					final int size = size();
					if (size <= 1) {
						return this;
					} else {
						final int countTrue = foldToInt(0, (int i, boolean value) -> value ? i + 1 : i);
						return tabulate(size, i -> i < countTrue);
					}
				}
			«ELSE»
				public «genericName» sortAsc() {
					if (size() <= 1) {
						return this;
					} else {
						final «type.javaName»[] sorted = toPrimitiveArray();
						Arrays.sort(sorted);
						return seqFromSharedArray(sorted);
					}
				}

				public «genericName» sortDesc() {
					if (size() <= 1) {
						return this;
					} else {
						final «type.javaName»[] sorted = toPrimitiveArray();
						Arrays.sort(sorted);
						Common.reverse«type.arrayShortName»(sorted);
						return seqFromSharedArray(sorted);
					}
				}
			«ENDIF»

			public static «paramGenericName» empty«shortName»() {
				«IF type == Type.OBJECT»
					return («genericName») «shortName»0.EMPTY;
				«ELSE»
					return «shortName»0.EMPTY;
				«ENDIF»
			}

			public static «paramGenericName» single«shortName»(final «type.genericName» value) {
				final «type.javaName»[] node1 = { «IF type == Type.OBJECT»requireNonNull(value)«ELSE»value«ENDIF» };
				return new «diamondName(1)»(node1);
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» «shortName.firstToLowerCase»(final «type.genericName»... values) {
				if (values.length == 0) {
					return empty«shortName»();
				} else {
					«IF type == Type.OBJECT»
						for (final Object value : values) {
							requireNonNull(value);
						}
					«ENDIF»
					return seqFromArray(values);
				}
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			«IF type == Type.OBJECT»
				public static <A extends Comparable<A>> Seq<A> sortAsc(final Seq<A> seq) {
					return seq.sort(asc());
				}

				public static <A extends Comparable<A>> Seq<A> sortDesc(final Seq<A> seq) {
					return seq.sort(desc());
				}

			«ENDIF»
			«repeat(type, paramGenericName)»

			«fill(type, paramGenericName)»

			«fillUntil(type, paramGenericName, seqBuilderName, "append")»

			public static «paramGenericName» tabulate(final int size, final Int«type.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
				requireNonNull(f);
				if (size < 0) {
					throw new IllegalArgumentException(Integer.toString(size));
				} else if (size == 0) {
					return empty«shortName»();
				} else {
					«IF type == Type.OBJECT || type.javaUnboxedType»
						return sizedToSeq(new «type.diamondName("TableIterator")»(size, f), size);
					«ELSE»
						return sizedToSeq(new TableIterator<>(size, f.toIntObjectF()), size);
					«ENDIF»
				}
			}

			«iterate(type, paramGenericName, seqBuilderName)»

			static «IF type == Type.OBJECT»<A> «ENDIF»void fillArray(final «type.javaName»[] array, final int startIndex, final «type.iteratorGenericName» iterator) {
				for (int i = startIndex; i < array.length; i++) {
					«IF type == Type.OBJECT»
						array[i] = requireNonNull(iterator.next());
					«ELSE»
						array[i] = iterator.«type.iteratorNext»();
					«ENDIF»
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillNode2(final «type.javaName»[][] node2, final int startIndex2, final int endIndex2, final «type.iteratorGenericName» iterator) {
				for (int i = startIndex2; i < endIndex2; i++) {
					fillArray(node2[i], 0, iterator);
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillNode3(final «type.javaName»[][][] node3, final int startIndex3, final int endIndex3, final «type.iteratorGenericName» iterator) {
				for (int i = startIndex3; i < endIndex3; i++) {
					fillNode2(node3[i], 0, node3[i].length, iterator);
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillNode4(final «type.javaName»[][][][] node4, final int startIndex4, final int endIndex4, final «type.iteratorGenericName» iterator) {
				for (int i = startIndex4; i < endIndex4; i++) {
					fillNode3(node4[i], 0, node4[i].length, iterator);
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillNode5(final «type.javaName»[][][][][] node5, final int startIndex5, final int endIndex5, final «type.iteratorGenericName» iterator) {
				for (int i = startIndex5; i < endIndex5; i++) {
					fillNode4(node5[i], 0, node5[i].length, iterator);
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillNode6(final «type.javaName»[][][][][][] node6, final int startIndex6, final int endIndex6, final «type.iteratorGenericName» iterator) {
				for (int i = startIndex6; i < endIndex6; i++) {
					fillNode5(node6[i], 0, node6[i].length, iterator);
				}
			}

			static «paramGenericName(1)» fillSeq1(final «type.javaName»[] node1, final int startIndex1, final «type.iteratorGenericName» iterator) {
				fillArray(node1, startIndex1, iterator);
				return new «diamondName(1)»(node1);
			}

			static «paramGenericName(2)» fillSeq2(final «type.javaName»[][] node2, final int startIndex2, final «type.javaName»[] node1, final int startIndex1,
					final «type.javaName»[] init, final «type.javaName»[] tail, final int size, final «type.iteratorGenericName» iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillArray(tail, 0, iterator);
				return new «diamondName(2)»(node2, init, tail, size);
			}

			static «paramGenericName(3)» fillSeq3(final «type.javaName»[][][] node3, final int startIndex3, final «type.javaName»[][] node2, final int startIndex2,
					final «type.javaName»[] node1, final int startIndex1, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex,
					final int size, final «type.iteratorGenericName» iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillArray(tail, 0, iterator);
				return new «diamondName(3)»(node3, init, tail, startIndex, size);
			}

			static «paramGenericName(4)» fillSeq4(final «type.javaName»[][][][] node4, final int startIndex4, final «type.javaName»[][][] node3, final int startIndex3,
					final «type.javaName»[][] node2, final int startIndex2,  final «type.javaName»[] node1, final int startIndex1, final «type.javaName»[] init,
					final «type.javaName»[] tail, final int startIndex,  final int size, final «type.iteratorGenericName» iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillNode4(node4, startIndex4, node4.length, iterator);
				fillArray(tail, 0, iterator);
				return new «diamondName(4)»(node4, init, tail, startIndex, size);
			}

			static «paramGenericName(5)» fillSeq5(final «type.javaName»[][][][][] node5, final int startIndex5, final «type.javaName»[][][][] node4, final int startIndex4,
					final «type.javaName»[][][] node3, final int startIndex3, final «type.javaName»[][] node2, final int startIndex2,
					final «type.javaName»[] node1, final int startIndex1, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex,
					final int size, final «type.iteratorGenericName» iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillNode4(node4, startIndex4, node4.length, iterator);
				fillNode5(node5, startIndex5, node5.length, iterator);
				fillArray(tail, 0, iterator);
				return new «diamondName(5)»(node5, init, tail, startIndex, size);
			}

			static «paramGenericName(6)» fillSeq6(final «type.javaName»[][][][][][] node6, final int startIndex6, final «type.javaName»[][][][][] node5, final int startIndex5,
					final «type.javaName»[][][][] node4, final int startIndex4, final «type.javaName»[][][] node3, final int startIndex3,
					final «type.javaName»[][] node2, final int startIndex2, final «type.javaName»[] node1, final int startIndex1,
					final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size, final «type.iteratorGenericName» iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillNode4(node4, startIndex4, node4.length, iterator);
				fillNode5(node5, startIndex5, node5.length, iterator);
				fillNode6(node6, startIndex6, node6.length, iterator);
				fillArray(tail, 0, iterator);
				return new «diamondName(6)»(node6, init, tail, startIndex, size);
			}

			static <A> void fillArrayFromStart(final «type.javaName»[] array, final int endIndex, final «type.iteratorGenericName» iterator) {
				for (int i = 0; i < endIndex; i++) {
					«IF type == Type.OBJECT»
						array[i] = requireNonNull(iterator.next());
					«ELSE»
						array[i] = iterator.«type.iteratorNext»();
					«ENDIF»
				}
			}

			static «paramGenericName(1)» fillSeq1FromStart(final «type.javaName»[] node1, final int endIndex1, final «type.iteratorGenericName» iterator) {
				fillArrayFromStart(node1, endIndex1, iterator);
				return new «diamondName(1)»(node1);
			}

			static «paramGenericName(2)» fillSeq2FromStart(final «type.javaName»[][] node2, final int fromEndIndex2, final «type.javaName»[] node1,
					final int fromEndIndex1, final «type.javaName»[] init, final «type.javaName»[] tail, final int size, final «type.iteratorGenericName» iterator) {
				fillArray(init, 0, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new «diamondName(2)»(node2, init, tail, size);
			}

			static «paramGenericName(3)» fillSeq3FromStart(final «type.javaName»[][][] node3, final int fromEndIndex3, final «type.javaName»[][] node2,
					final int fromEndIndex2, final «type.javaName»[] node1, final int fromEndIndex1, final «type.javaName»[] init,
					final «type.javaName»[] tail, final int startIndex, final int size, final «type.iteratorGenericName» iterator) {
				fillArray(init, 0, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new «diamondName(3)»(node3, init, tail, startIndex, size);
			}

			static «paramGenericName(4)» fillSeq4FromStart(final «type.javaName»[][][][] node4, final int fromEndIndex4, final «type.javaName»[][][] node3,
					final int fromEndIndex3, final «type.javaName»[][] node2, final int fromEndIndex2, final «type.javaName»[] node1,
					final int fromEndIndex1, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size,
					final «type.iteratorGenericName» iterator) {
				fillArray(init, 0, iterator);
				fillNode4(node4, 0, node4.length - fromEndIndex4, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new «diamondName(4)»(node4, init, tail, startIndex, size);
			}

			static «paramGenericName(5)» fillSeq5FromStart(final «type.javaName»[][][][][] node5, final int fromEndIndex5, final «type.javaName»[][][][] node4,
					final int fromEndIndex4, final «type.javaName»[][][] node3, final int fromEndIndex3, final «type.javaName»[][] node2,
					final int fromEndIndex2, final «type.javaName»[] node1, final int fromEndIndex1, final «type.javaName»[] init, final «type.javaName»[] tail,
					final int startIndex, final int size, final «type.iteratorGenericName» iterator) {
				fillArray(init, 0, iterator);
				fillNode5(node5, 0, node5.length - fromEndIndex5, iterator);
				fillNode4(node4, 0, node4.length - fromEndIndex4, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new «diamondName(5)»(node5, init, tail, startIndex, size);
			}

			static «paramGenericName(6)» fillSeq6FromStart(final «type.javaName»[][][][][][] node6, final int fromEndIndex6, final «type.javaName»[][][][][] node5,
					final int fromEndIndex5, final «type.javaName»[][][][] node4, final int fromEndIndex4, final «type.javaName»[][][] node3,
					final int fromEndIndex3, final «type.javaName»[][] node2, final int fromEndIndex2, final «type.javaName»[] node1, final int fromEndIndex1,
					final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size, final «type.iteratorGenericName» iterator) {
				fillArray(init, 0, iterator);
				fillNode6(node6, 0, node6.length - fromEndIndex6, iterator);
				fillNode5(node5, 0, node5.length - fromEndIndex5, iterator);
				fillNode4(node4, 0, node4.length - fromEndIndex4, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new «diamondName(6)»(node6, init, tail, startIndex, size);
			}

			static «paramGenericName» seqFromSharedArray(final «type.javaName»[] values) {
				// Assume values.length != 0
				if (values.length <= 32) {
					return new «diamondName(1)»(values);
				} else {
					return seqFromArray(values);
				}
			}

			static «paramGenericName» seqFromArray(final «type.javaName»[] values) {
				// Assume values.length != 0
				if (values.length <= 32) {
					return seq1FromArray(values);
				} else if (values.length <= (1 << 10)) {
					return seq2FromArray(values);
				} else if (values.length <= (1 << 15)) {
					return seq3FromArray(values);
				} else if (values.length <= (1 << 20)) {
					return seq4FromArray(values);
				} else if (values.length <= (1 << 25)) {
					return seq5FromArray(values);
				} else if (values.length <= (1 << 30)) {
					return seq6FromArray(values);
				} else {
					throw new SizeOverflowException();
				}
			}

			private static «paramGenericName(1)» seq1FromArray(final «type.javaName»[] values) {
				final «type.javaName»[] node1 = new «type.javaName»[values.length];
				System.arraycopy(values, 0, node1, 0, values.length);
				return new «diamondName(1)»(node1);
			}

			private static «paramGenericName(2)» seq2FromArray(final «type.javaName»[] values) {
				final «type.javaName»[] init = initFromArray(values);
				if (values.length <= 64) {
					final «type.javaName»[] tail = new «type.javaName»[values.length - 32];
					System.arraycopy(values, 32, tail, 0, values.length - 32);
					return new «diamondName(2)»(EMPTY_NODE2, init, tail, values.length);
				} else {
					final «type.javaName»[] tail = tailFromArray(values);
					final «type.javaName»[][] node2 = new «type.javaName»[(values.length - 32 - tail.length) / 32][32];
					int index = 32;
					for (final «type.javaName»[] node1 : node2) {
						System.arraycopy(values, index, node1, 0, 32);
						index += 32;
					}
					return new «diamondName(2)»(node2, init, tail, values.length);
				}
			}

			private static «paramGenericName(3)» seq3FromArray(final «type.javaName»[] values) {
				final «type.javaName»[] init = initFromArray(values);
				final «type.javaName»[] tail = tailFromArray(values);
				final «type.javaName»[][][] node3 = allocateNode3(0, values.length);
				int index = 32;
				for (final «type.javaName»[][] node2 : node3) {
					for (final «type.javaName»[] node1 : node2) {
						System.arraycopy(values, index, node1, 0, 32);
						index += 32;
					}
				}
				return new «diamondName(3)»(node3, init, tail, 0, values.length);
			}

			private static «paramGenericName(4)» seq4FromArray(final «type.javaName»[] values) {
				final «type.javaName»[] init = initFromArray(values);
				final «type.javaName»[] tail = tailFromArray(values);
				final «type.javaName»[][][][] node4 = allocateNode4(0, values.length);
				int index = 32;
				for (final «type.javaName»[][][] node3 : node4) {
					for (final «type.javaName»[][] node2 : node3) {
						for (final «type.javaName»[] node1 : node2) {
							System.arraycopy(values, index, node1, 0, 32);
							index += 32;
						}
					}
				}
				return new «diamondName(4)»(node4, init, tail, 0, values.length);
			}

			private static «paramGenericName(5)» seq5FromArray(final «type.javaName»[] values) {
				final «type.javaName»[] init = initFromArray(values);
				final «type.javaName»[] tail = tailFromArray(values);
				final «type.javaName»[][][][][] node5 = allocateNode5(0, values.length);

				int index = 32;
				for (final «type.javaName»[][][][] node4 : node5) {
					for (final «type.javaName»[][][] node3 : node4) {
						for (final «type.javaName»[][] node2 : node3) {
							for (final «type.javaName»[] node1 : node2) {
								System.arraycopy(values, index, node1, 0, 32);
								index += 32;
							}
						}
					}
				}
				return new «diamondName(5)»(node5, init, tail, 0, values.length);
			}

			private static «paramGenericName(6)» seq6FromArray(final «type.javaName»[] values) {
				final «type.javaName»[] init = initFromArray(values);
				final «type.javaName»[] tail = tailFromArray(values);
				final «type.javaName»[][][][][][] node6 = allocateNode6(0, values.length);

				int index = 32;
				for (final «type.javaName»[][][][][] node5 : node6) {
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									System.arraycopy(values, index, node1, 0, 32);
									index += 32;
								}
							}
						}
					}
				}
				return new «diamondName(6)»(node6, init, tail, 0, values.length);
			}

			static «type.javaName»[] allocateTail(final int size) {
				return new «type.javaName»[((size % 32) == 0) ? 32 : size % 32];
			}

			private static «type.javaName»[] initFromArray(final «type.javaName»[] values) {
				final «type.javaName»[] init = new «type.javaName»[32];
				System.arraycopy(values, 0, init, 0, 32);
				return init;
			}

			private static «type.javaName»[] tailFromArray(final «type.javaName»[] values) {
				final «type.javaName»[] tail = allocateTail(values.length);
				System.arraycopy(values, values.length - tail.length, tail, 0, tail.length);
				return tail;
			}

			public static «paramGenericName» ofAll(final Iterable<«type.genericBoxedName»> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof «type.containerWildcardName») {
					return ((«type.containerGenericName») iterable).to«shortName»();
				} else if (iterable instanceof Sized && ((Sized) iterable).hasKnownFixedSize()) {
					return sizedToSeq(«type.getIterator("iterable.iterator()")», ((Sized) iterable).size());
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»();
					builder.appendAll(iterable);
					return builder.build();
				}
			}

			public static «paramGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				requireNonNull(iterator);
				final «seqBuilderName» builder = builder();
				builder.appendIterator(iterator);
				return builder.build();
			}

			public static «paramGenericName» from«type.streamName»(final «type.streamGenericName» stream) {
				final «seqBuilderName» builder = builder();
				builder.append«type.streamName»(stream);
				return builder.build();
			}

			static «paramGenericName» sizedToSeq(final «type.iteratorGenericName» iterator, final int size) {
				if (size == 0) {
					return empty«shortName»();
				} else if (size <= 32) {
					return fillSeq1(new «type.javaName»[size], 0, iterator);
				} else if (size <= (1 << 10)) {
					return sizedToSeq2(iterator, size);
				} else if (size <= (1 << 15)) {
					return sizedToSeq3(iterator, size);
				} else if (size <= (1 << 20)) {
					return sizedToSeq4(iterator, size);
				} else if (size <= (1 << 25)) {
					return sizedToSeq5(iterator, size);
				} else if (size <= (1 << 30)) {
					return sizedToSeq6(iterator, size);
				} else {
					throw new SizeOverflowException();
				}
			}

			private static «paramGenericName» sizedToSeq2(final «type.iteratorGenericName» iterator, final int size) {
				final «type.javaName»[] init = new «type.javaName»[32];
				fillArray(init, 0, iterator);
				final «type.javaName»[] tail = allocateTail(size);
				final int size2 = (size - 32 - tail.length) / 32;
				if (size2 == 0) {
					fillArray(tail, 0, iterator);
					return new «diamondName(2)»(EMPTY_NODE2, init, tail, size);
				} else {
					final «type.javaName»[][] node2 = new «type.javaName»[size2][32];
					return fillSeq2(node2, 1, node2[0], 0, init, tail, size, iterator);
				}
			}

			private static «paramGenericName» sizedToSeq3(final «type.iteratorGenericName» iterator, final int size) {
				final «type.javaName»[] init = new «type.javaName»[32];
				fillArray(init, 0, iterator);
				final «type.javaName»[] tail = allocateTail(size);
				final «type.javaName»[][][] node3 = allocateNode3(0, size);
				return fillSeq3(node3, 1, node3[0], 1, node3[0][0], 0, init, tail, 0, size, iterator);
			}

			private static «paramGenericName» sizedToSeq4(final «type.iteratorGenericName» iterator, final int size) {
				final «type.javaName»[] init = new «type.javaName»[32];
				fillArray(init, 0, iterator);
				final «type.javaName»[] tail = allocateTail(size);
				final «type.javaName»[][][][] node4 = allocateNode4(0, size);
				return fillSeq4(node4, 1, node4[0], 1, node4[0][0], 1, node4[0][0][0], 0, init, tail, 0, size, iterator);
			}

			private static «paramGenericName» sizedToSeq5(final «type.iteratorGenericName» iterator, final int size) {
				final «type.javaName»[] init = new «type.javaName»[32];
				fillArray(init, 0, iterator);
				final «type.javaName»[] tail = allocateTail(size);
				final «type.javaName»[][][][][] node5 = allocateNode5(0, size);
				return fillSeq5(node5, 1, node5[0], 1, node5[0][0], 1, node5[0][0][0], 1, node5[0][0][0][0], 0,
						init, tail, 0, size, iterator);
			}

			private static «paramGenericName» sizedToSeq6(final «type.iteratorGenericName» iterator, final int size) {
				final «type.javaName»[] init = new «type.javaName»[32];
				fillArray(init, 0, iterator);
				final «type.javaName»[] tail = allocateTail(size);
				final «type.javaName»[][][][][][] node6 = allocateNode6(0, size);
				return fillSeq6(node6, 1, node6[0], 1, node6[0][0], 1, node6[0][0][0], 1, node6[0][0][0][0], 1,
						node6[0][0][0][0][0], 0, init, tail, 0, size, iterator);
			}

			static «type.javaName»[][][] allocateNode3(final int startIndex3, final int size) {
				final «type.javaName»[][][] node3 = new «type.javaName»[(size % (1 << 10) == 0) ? size / (1 << 10) : size / (1 << 10) + 1][][];
				for (int index3 = startIndex3; index3 < node3.length; index3++) {
					final int size2;
					if (index3 == 0) {
						size2 = 31;
					} else if (index3 < node3.length - 1) {
						size2 = 32;
					} else {
						final int totalSize2 = (size % (1 << 10) == 0) ? (1 << 10) : size % (1 << 10);
						size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
					}
					node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
				}
				return node3;
			}

			static «type.javaName»[][][][] allocateNode4(final int startIndex4, final int size) {
				final «type.javaName»[][][][] node4 = new «type.javaName»[(size % (1 << 15) == 0) ? size / (1 << 15) : size / (1 << 15) + 1][][][];
				for (int index4 = startIndex4; index4 < node4.length; index4++) {
					final int size3;
					if (index4 == node4.length - 1) {
						final int totalSize3 = (size % (1 << 15) == 0) ? (1 << 15) : size % (1 << 15);
						size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
					} else {
						size3 = 32;
					}
					final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
					node4[index4] = node3;
					for (int index3 = 0; index3 < size3; index3++) {
						final int size2;
						if (index4 == 0 && index3 == 0) {
							size2 = 31;
						} else if (index4 < node4.length - 1 || index3 < size3 - 1) {
							size2 = 32;
						} else {
							final int totalSize3 = (size % (1 << 15) == 0) ? (1 << 15) : size % (1 << 15);
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
						}
						node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
					}
				}
				return node4;
			}

			static «type.javaName»[][][][][] allocateNode5(final int startIndex5, final int size) {
				final «type.javaName»[][][][][] node5 = new «type.javaName»[(size % (1 << 20) == 0) ? size / (1 << 20) : size / (1 << 20) + 1][][][][];
				for (int index5 = startIndex5; index5 < node5.length; index5++) {
					final int size4;
					if (index5 == node5.length - 1) {
						final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
						size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
					} else {
						size4 = 32;
					}

					final «type.javaName»[][][][] node4 = new «type.javaName»[size4][][][];
					node5[index5] = node4;

					for (int index4 = 0; index4 < size4; index4++) {
						final int size3;
						if (index5 == node5.length - 1 && index4 == size4 - 1) {
							final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
						} else {
							size3 = 32;
						}

						final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
						node4[index4] = node3;

						for (int index3 = 0; index3 < size3; index3++) {
							final int size2;
							if (index5 == 0 && index4 == 0 && index3 == 0) {
								size2 = 31;
							} else if (index5 < node5.length - 1 || index4 < size4 - 1 || index3 < size3 - 1) {
								size2 = 32;
							} else {
								final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
								final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
							}
							node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
						}
					}
				}
				return node5;
			}

			static «type.javaName»[][][][][][] allocateNode6(final int startIndex6, final int size) {
				final «type.javaName»[][][][][][] node6 = new «type.javaName»[(size % (1 << 25) == 0) ? size / (1 << 25) : size / (1 << 25) + 1][][][][][];
				for (int index6 = startIndex6; index6 < node6.length; index6++) {
					final int size5;
					if (index6 == node6.length - 1) {
						final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
						size5 = (totalSize5 % (1 << 20) == 0) ? totalSize5 / (1 << 20) : totalSize5 / (1 << 20) + 1;
					} else {
						size5 = 32;
					}

					final «type.javaName»[][][][][] node5 = new «type.javaName»[size5][][][][];
					node6[index6] = node5;

					for (int index5 = 0; index5 < node5.length; index5++) {
						final int size4;
						if (index6 == node6.length - 1 && index5 == node5.length - 1) {
							final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
							final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
							size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
						} else {
							size4 = 32;
						}

						final «type.javaName»[][][][] node4 = new «type.javaName»[size4][][][];
						node5[index5] = node4;

						for (int index4 = 0; index4 < node4.length; index4++) {
							final int size3;
							if (index6 == node6.length - 1 && index5 == node5.length - 1 && index4 == node4.length - 1) {
								final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
								final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
								final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
								size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
							} else {
								size3 = 32;
							}

							final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
							node4[index4] = node3;

							for (int index3 = 0; index3 < node3.length; index3++) {
								final int size2;
								if (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) {
									size2 = 31;
								} else if (index6 < node6.length - 1 || index5 < node5.length - 1 || index4 < node4.length - 1 || index3 < node3.length - 1) {
									size2 = 32;
								} else {
									final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
									final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
									final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
									final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
									size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
								}
								final «type.javaName»[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
								node3[index3] = node2;
							}
						}
					}
				}
				return node6;
			}

			static «type.javaName»[][][] allocateNode3FromStart(final int fromEndIndex3, final int size) {
				final int size3 = (size % (1 << 10) == 0) ? size / (1 << 10) : size / (1 << 10) + 1;
				final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
				for (int index3 = 0; index3 < size3 - fromEndIndex3; index3++) {
					final int size2;
					if (index3 == node3.length - 1) {
						size2 = 31;
					} else if (index3 > 0) {
						size2 = 32;
					} else {
						final int totalSize2 = (size % (1 << 10) == 0) ? (1 << 10) : size % (1 << 10);
						size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
					}
					node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
				}
				return node3;
			}

			static «type.javaName»[][][][] allocateNode4FromStart(final int fromEndIndex4, final int size) {
				final int size4 = (size % (1 << 15) == 0) ? size / (1 << 15) : size / (1 << 15) + 1;
				final «type.javaName»[][][][] node4 = new «type.javaName»[size4][][][];
				for (int index4 = 0; index4 < size4 - fromEndIndex4; index4++) {
					final int size3;
					if (index4 == 0) {
						final int totalSize3 = (size % (1 << 15) == 0) ? (1 << 15) : size % (1 << 15);
						size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
					} else {
						size3 = 32;
					}
					final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
					node4[index4] = node3;
					for (int index3 = 0; index3 < size3; index3++) {
						final int size2;
						if (index4 == node4.length - 1 && index3 == size3 - 1) {
							size2 = 31;
						} else if (index4 > 0 || index3 > 0) {
							size2 = 32;
						} else {
							final int totalSize3 = (size % (1 << 15) == 0) ? (1 << 15) : size % (1 << 15);
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
						}
						node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
					}
				}
				return node4;
			}

			static «type.javaName»[][][][][] allocateNode5FromStart(final int fromEndIndex5, final int size) {
				final int size5 = (size % (1 << 20) == 0) ? size / (1 << 20) : size / (1 << 20) + 1;
				final «type.javaName»[][][][][] node5 = new «type.javaName»[size5][][][][];
				for (int index5 = 0; index5 < size5 - fromEndIndex5; index5++) {
					final int size4;
					if (index5 == 0) {
						final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
						size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
					} else {
						size4 = 32;
					}

					final «type.javaName»[][][][] node4 = new «type.javaName»[size4][][][];
					node5[index5] = node4;

					for (int index4 = 0; index4 < size4; index4++) {
						final int size3;
						if (index5 == 0 && index4 == 0) {
							final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
						} else {
							size3 = 32;
						}

						final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
						node4[index4] = node3;

						for (int index3 = 0; index3 < size3; index3++) {
							final int size2;
							if (index5 == node5.length - 1 && index4 == size4 - 1 && index3 == size3 - 1) {
								size2 = 31;
							} else if (index5 > 0 || index4 > 0 || index3 > 0) {
								size2 = 32;
							} else {
								final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
								final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
							}
							node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
						}
					}
				}
				return node5;
			}

			static «type.javaName»[][][][][][] allocateNode6FromStart(final int fromEndIndex6, final int size) {
				final int size6 = (size % (1 << 25) == 0) ? size / (1 << 25) : size / (1 << 25) + 1;
				final «type.javaName»[][][][][][] node6 = new «type.javaName»[size6][][][][][];
				for (int index6 = 0; index6 < size6 - fromEndIndex6; index6++) {
					final int size5;
					if (index6 == 0) {
						final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
						size5 = (totalSize5 % (1 << 20) == 0) ? totalSize5 / (1 << 20) : totalSize5 / (1 << 20) + 1;
					} else {
						size5 = 32;
					}

					final «type.javaName»[][][][][] node5 = new «type.javaName»[size5][][][][];
					node6[index6] = node5;

					for (int index5 = 0; index5 < node5.length; index5++) {
						final int size4;
						if (index6 == 0 && index5 == 0) {
							final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
							final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
							size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
						} else {
							size4 = 32;
						}

						final «type.javaName»[][][][] node4 = new «type.javaName»[size4][][][];
						node5[index5] = node4;

						for (int index4 = 0; index4 < node4.length; index4++) {
							final int size3;
							if (index6 == 0 && index5 == 0 && index4 == 0) {
								final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
								final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
								final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
								size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
							} else {
								size3 = 32;
							}

							final «type.javaName»[][][] node3 = new «type.javaName»[size3][][];
							node4[index4] = node3;

							for (int index3 = 0; index3 < node3.length; index3++) {
								final int size2;
								if (index6 == node6.length - 1 && index5 == size5 - 1 && index4 == size4 - 1 && index3 == size3 - 1) {
									size2 = 31;
								} else if (index6 > 0 || index5 > 0 || index4 > 0 || index3 > 0) {
									size2 = 32;
								} else {
									final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
									final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
									final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
									final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
									size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
								}
								final «type.javaName»[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new «type.javaName»[size2][32];
								node3[index3] = node2;
							}
						}
					}
				}
				return node6;
			}

			static int calculateSeq3StartIndex(final «type.javaName»[][][] node3, final «type.javaName»[] init) {
				return (1 << 10) - 32*node3[0].length - init.length;
			}

			static int calculateSeq4StartIndex(final «type.javaName»[][][][] node4, final «type.javaName»[] init) {
				return (1 << 15) - 32*node4[0][0].length - (1 << 10)*(node4[0].length - 1) - init.length;
			}

			static int calculateSeq5StartIndex(final «type.javaName»[][][][][] node5, final «type.javaName»[] init) {
				return (1 << 20) - 32*node5[0][0][0].length - (1 << 10)*(node5[0][0].length - 1) - (1 << 15)*(node5[0].length - 1)
						- init.length;
			}

			static int calculateSeq6StartIndex(final «type.javaName»[][][][][][] node6, final «type.javaName»[] init) {
				return (1 << 25) - 32*node6[0][0][0][0].length - (1 << 10)*(node6[0][0][0].length - 1) -
						(1 << 15)*(node6[0][0].length - 1) - (1 << 20)*(node6[0].length - 1) - init.length;
			}

			static int calculateSeq3EndIndex(final «type.javaName»[][][] lastNode3, final «type.javaName»[] tail) {
				return (1 << 10) - 32*lastNode3[lastNode3.length - 1].length - tail.length;
			}

			static int calculateSeq4EndIndex(final «type.javaName»[][][] lastNode3, final «type.javaName»[] tail) {
				return (1 << 15) - 32*lastNode3[lastNode3.length - 1].length - (1 << 10)*(lastNode3.length - 1) - tail.length;
			}

			static int calculateSeq5EndIndex(final «type.javaName»[][][][] lastNode4, final «type.javaName»[][][] lastNode3, final «type.javaName»[] init) {
				return (1 << 20) - 32*lastNode3[lastNode3.length - 1].length - (1 << 10)*(lastNode3.length - 1)
						- (1 << 15)*(lastNode4.length - 1) - init.length;
			}

			abstract void initSeqBuilder(«seqBuilderName» builder);

			«flattenCollection(type, genericName, type.seqBuilderGenericName)»

			/**
			 * O(min(prefix.size, suffix.size))
			 */
			public static «paramGenericName» concat(final «genericName» prefix, final «genericName» suffix) throws SizeOverflowException {
				requireNonNull(prefix);
				requireNonNull(suffix);
				if (prefix.isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return prefix;
				} else {
					final int prefixSize = prefix.size();
					final int suffixSize = suffix.size();
					final int size = prefixSize + suffixSize;
					if (size < 0) {
						throw new SizeOverflowException();
					} else if (size <= 32) {
						final «type.javaName»[] prefixArray = ((«genericName(1)») prefix).node1;
						final «type.javaName»[] suffixArray = ((«genericName(1)») suffix).node1;
						final «type.javaName»[] array = new «type.javaName»[size];
						System.arraycopy(prefixArray, 0, array, 0, prefixSize);
						System.arraycopy(suffixArray, 0, array, prefixSize, suffixSize);
						return new «diamondName(1)»(array);
					} else if (prefixSize >= suffixSize) {
						return prefix.appendSized(suffix.iterator(), suffixSize);
					} else {
						return suffix.prependSized(prefix.iterator(), prefixSize);
					}
				}
			}

			«IF type.javaUnboxedType»
				@Override
				public abstract «type.iteratorGenericName» iterator();

			«ENDIF»
			@Override
			public «type.indexedContainerViewGenericName» view() {
				if (isEmpty()) {
					return «IF type == Type.OBJECT»(«type.indexedContainerViewGenericName») «ENDIF»«type.shortName("BaseIndexedContainerView")».EMPTY;
				} else {
					return new «type.diamondName("SeqView")»(this);
				}
			}

			«orderedHashCode(type, true)»

			«equals(type, type.indexedContainerWildcardName, true)»

			public final boolean isStrictlyEqualTo(final «genericName» other) {
				if (other == this) {
					return true;
				} else {
					return «type.indexedContainerShortName.firstToLowerCase»sEqual(this, other);
				}
			}

			«toStr(type)»

			«IF type == Type.OBJECT»
				static int index1(final int index) {
					return (index & 0x1F);
				}

				static int index2(final int index) {
					return ((index >> 5) & 0x1F);
				}

				static int index3(final int index) {
					return ((index >> 10) & 0x1F);
				}

				static int index4(final int index) {
					return ((index >> 15) & 0x1F);
				}

				static int index5(final int index) {
					return ((index >> 20) & 0x1F);
				}

				static int index6(final int index) {
					return ((index >> 25) & 0x1F);
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				«FOR arity : 2 .. Constants.MAX_PRODUCT_ARITY»
					public static <«(1..arity).map['''A«it», '''].join»B> Seq<B> map«arity»(«(1..arity).map['''final Seq<A«it»> seq«it», '''].join»final F«arity»<«(1..arity).map['''A«it», '''].join»B> f) {
						requireNonNull(f);
						if («(1 .. arity).map["seq" + it + ".isEmpty()"].join(" || ")») {
							return emptySeq();
						} else {
							final long size1 = seq1.size();
							«FOR i : 2 .. arity»
								final long size«i» = size«i-1» * seq«i».size();
								if (size«i» != (int) size«i») {
									throw new IndexOutOfBoundsException("Size overflow");
								}
							«ENDFOR»
							return sizedToSeq(new Product«arity»Iterator<>(«(1 .. arity).map['''seq«it»'''].join(", ")», f), (int) size«arity»);
						}
					}

				«ENDFOR»
			«ENDIF»
			«IF type == Type.OBJECT»
				public static <A> SeqBuilder<A> builder() {
			«ELSE»
				public static «seqBuilderName» builder() {
			«ENDIF»
				return new «seqBuilderDiamondName»();
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»Collector<«type.genericBoxedName», ?, «genericName»> collector() {
				«IF type == Type.OBJECT»
					return Collector.<«type.genericBoxedName», «type.seqBuilderGenericName», «genericName»> of(
				«ELSE»
					return Collector.of(
				«ENDIF»
					«shortName»::builder, «type.seqBuilderShortName»::append, «type.seqBuilderShortName»::appendSeqBuilder, «type.seqBuilderShortName»::build);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			final class SeqView<A> extends BaseIndexedContainerView<A, Seq<A>> {
		«ELSE»
			final class «shortName»View extends «type.typeName»BaseIndexedContainerView<«shortName»> {
		«ENDIF»

			«shortName»View(final «genericName» seq) {
				super(seq);
			}

			@Override
			public «type.indexedContainerViewGenericName» slice(final int fromIndexInclusive, final int toIndexExclusive) {
				return new «type.diamondName("SeqView")»(this.container.slice(fromIndexInclusive, toIndexExclusive));
			}

			@Override
			public «type.indexedContainerViewGenericName» limit(final int n) {
				return new «type.diamondName("SeqView")»(this.container.limit(n));
			}

			@Override
			public «type.indexedContainerViewGenericName» skip(final int n) {
				return new «type.diamondName("SeqView")»(this.container.skip(n));
			}
		}
	''' }
}
