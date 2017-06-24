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
		import java.util.Collection;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		«IF type == Type.OBJECT»
			import static java.lang.Math.min;
		«ENDIF»
		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static jcats.collection.Seq.*;
		«ENDIF»
		«IF type == Type.OBJECT»
			import static «Constants.F».id;
			import static «Constants.P».p;
		«ENDIF»
		import static «Constants.COMMON».*;


		public abstract class «genericName» implements «type.indexedContainerGenericName», Serializable {
			private static final «shortName» EMPTY = new «shortName»0();

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
			public abstract «type.genericName» head();

			/**
			 * O(1)
			 */
			public abstract «type.genericName» last();

			/**
			 * O(1)
			 */
			public abstract «genericName» init();

			/**
			 * O(1)
			 */
			public abstract «genericName» tail();

			/**
			 * O(log(size))
			 */
			@Override
			public abstract «type.genericName» get(final int index);

			/**
			 * O(log(size))
			 */
			public final «genericName» set(final int index, final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return update(index, (final «type.genericName» __) -> value);
				«ELSE»
					return update(index, «type.typeName»«type.typeName»F.constant(value));
				«ENDIF»
			}

			/**
			 * O(log(size))
			 */
			public abstract «genericName» update(final int index, final «type.updateFunction» f);

			public abstract «genericName» take(final int n);

			public abstract «genericName» drop(final int n);

			«takeWhile(true, type)»

			/**
			 * O(1)
			 */
			public abstract «genericName» prepend(final «type.genericName» value);

			/**
			 * O(1)
			 */
			public abstract «genericName» append(final «type.genericName» value);

			public final «genericName» removeAt(final int index) {
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
				final «genericName» prefix = take(index);
				final «genericName» suffix = drop(index + 1);
				return prefix.concat(suffix);
			}

			/**
			 * O(min(this.size, suffix.size))
			 */
			public final «genericName» concat(final «genericName» suffix) {
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					final int prefixSize = size();
					final int suffixSize = suffix.size();
					if (prefixSize >= suffixSize) {
						return appendSized(suffix.iterator(), suffixSize);
					} else {
						return suffix.prependSized(iterator(), prefixSize);
					}
				}
			}

			// Assume suffixSize > 0
			abstract «genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize);

			// Assume prefixSize > 0
			abstract «genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize);

			public final «genericName» appendAll(final Iterable<«type.genericBoxedName»> suffix) {
				if (isEmpty()) {
					return ofAll(suffix);
				} else if (suffix instanceof «shortName») {
					return concat((«genericName») suffix);
				} else if (suffix instanceof Sized) {
					final int suffixSize = ((Sized) suffix).size();
					if (suffixSize == 0) {
						return this;
					} else {
						return appendSized(«type.getIterator("suffix.iterator()")», suffixSize);
					}
				} else if (suffix instanceof Collection && ((Collection<?>) suffix).isEmpty()) {
					return this;
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»(this);
					builder.appendAll(suffix);
					return builder.build();
				}
			}

			public final «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) {
				if (isEmpty()) {
					return ofAll(prefix);
				} else if (prefix instanceof «shortName») {
					return ((«genericName») prefix).concat(this);
				} else if (prefix instanceof Sized) {
					final int prefixSize = ((Sized) prefix).size();
					if (prefixSize == 0) {
						return this;
					} else {
						return prependSized(«type.getIterator("prefix.iterator()")», prefixSize);
					}
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»();
					prefix.forEach(builder::append);
					return builder.build().concat(this);
				}
			}

			public final «genericName» slice(final int fromIndex, final int toIndex) {
				sliceRangeCheck(fromIndex, toIndex, size());
				return drop(fromIndex).take(toIndex - fromIndex);
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
						if (f == «type.typeName»«type.typeName»F.id()) {
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
				public final <B> Seq<B> flatMap(final F<A, Seq<B>> f) {
			«ELSE»
				public final <A> Seq<A> flatMap(final «type.typeName»ObjectF<Seq<A>> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptySeq();
				} else {
					final SeqBuilder<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> builder = new SeqBuilder<>();
					for (final «type.genericName» value : this) {
						builder.appendAll(f.apply(value));
					}
					return builder.build();
				}
			}

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
				public final <B> Seq<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (Seq<B>) filter(clazz::isInstance);
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

				abstract void copyToArray(final Object[] array);

			«ENDIF»
			@Override
			@Deprecated
			public final «type.seqGenericName» to«type.seqShortName»() {
				return this;
			}

			public static «paramGenericName» empty«shortName»() {
				return EMPTY;
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

			«repeat(type, paramGenericName)»

			«fill(type, paramGenericName)»

			«fillUntil(type, paramGenericName, seqBuilderName)»

			public static «paramGenericName» tabulate(final int size, final Int«type.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
				requireNonNull(f);
				if (size <= 0) {
					return empty«shortName»();
				} else {
					«IF type == Type.OBJECT»
						return sizedToSeq(new TableIterator<>(size, f), size);
					«ELSEIF type == Type.BOOLEAN»
						return sizedToSeq(new TableIterator<>(size, f.toIntObjectF()), size);
					«ELSE»
						return sizedToSeq(new Table«type.typeName»Iterator(size, f), size);
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
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
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
				if (iterable instanceof «wildcardName») {
					return («genericName») iterable;
				} else if (iterable instanceof Sized) {
					return sizedToSeq(«type.getIterator("iterable.iterator()")», ((Sized) iterable).size());
				} else {
					final «seqBuilderName» builder = new «seqBuilderDiamondName»();
					builder.appendAll(iterable);
					return builder.build();
				}
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
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
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

			abstract void initSeqBuilder(final «seqBuilderName» builder);

			«IF type == Type.OBJECT /* TODO */»
				«join»

			«ENDIF»
			«IF Type.javaUnboxedTypes.contains(type)»
				@Override
				public abstract «type.iteratorGenericName» iterator();

			«ENDIF»
			«hashcode(type, true)»

			«equals(type, type.indexedContainerWildcardName, true)»

			public final boolean isStrictlyEqualTo(final «genericName» other) {
				if (other == this) {
					return true;
				} else {
					return «type.indexedContainerShortName.firstToLowerCase»sEqual(this, other);
				}
			}

			«toStr(type, true)»

			«IF type == Type.OBJECT»
				«zip(true, true)»

				«zipWith(true, true)»

				/**
				 * O(size)
				 */
				public final Seq<P<A, Integer>> zipWithIndex() {
					if (isEmpty()) {
						return emptySeq();
					} else {
						final Iterator<A> iterator = iterator();
						return tabulate(size(), (final int i) -> p(iterator.next(), i));
					}
				}

				«zipN»
				«zipWithN[arity | '''
					requireNonNull(f);
					if («(1 .. arity).map["seq" + it + ".isEmpty()"].join(" || ")») {
						return emptySeq();
					} else {
						final int size = «(1 ..< arity).map['''min(seq«it».size()'''].join(", ")», seq«arity».size()«(1 ..< arity).map[")"].join»;
						«FOR i : 1 .. arity»
							final Iterator<A«i»> iterator«i» = seq«i».iterator();
						«ENDFOR»
						return fill(size, () -> requireNonNull(f.apply(«(1 .. arity).map['''iterator«it».next()'''].join(", ")»)));
					}
				''']»
				«productN»
				«productWithN[arity | '''
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
				''']»
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
				«cast(#["A"], #[], #["A"])»

			«ENDIF»
			«IF type == Type.OBJECT»
				public static <A> SeqBuilder<A> builder() {
			«ELSE»
				public static «seqBuilderName» builder() {
			«ENDIF»
				return new «seqBuilderDiamondName»();
			}
		}
	''' }
}
