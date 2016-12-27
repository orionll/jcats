package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type
import java.util.List
import jcats.generator.Generator
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SeqGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new SeqGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Seq" else type.typeName + "Seq" }
	def genericName() { if (type == Type.OBJECT) "Seq<A>" else shortName }
	def genericName(int index) { if (type == Type.OBJECT) "Seq" + index + "<A>" else shortName + index }
	def diamondName(int index) { if (type == Type.OBJECT) "Seq" + index + "<>" else shortName + index }
	def wildcardName() { if (type == Type.OBJECT) "Seq<?>" else shortName }
	def paramGenericName() { if (type == Type.OBJECT) "<A> Seq<A>" else shortName }
	def paramGenericName(int index) { if (type == Type.OBJECT) "<A> Seq" + index + "<A>" else shortName + index }
	def updateFunction() { if (type == Type.OBJECT) "F<A, A>" else type.typeName + type.typeName + "F" }
	def seqBuilderName() { if (type == Type.OBJECT) "SeqBuilder<A>" else shortName + "Builder" }
	def seqBuilderDiamondName() { if (type == Type.OBJECT) "SeqBuilder<>" else shortName + "Builder" }
	def iteratorName(int index) { shortName + index + "Iterator" + (if (type == Type.OBJECT) "<A>" else "") }
	def iteratorDiamondName(int index) { shortName + index + "Iterator" + (if (type == Type.OBJECT) "<>" else "") }
	def iteratorReturnType() { if (type == Type.OBJECT) "A" else if (type == Type.BOOL) "Boolean" else type.javaName }
	def bufferedListName() { if (type == Type.OBJECT) "BufferedList<A>" else if (type == Type.BOOL) "BufferedList<Boolean>" else "Buffered" + type.typeName + "List" }
	def bufferedListDiamondName() { if (type == Type.OBJECT) "BufferedList<>" else if (type == Type.BOOL) "BufferedList<>" else "Buffered" + type.typeName + "List" }
	def index() { if (type == Type.OBJECT) "index" else "Seq.index" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Collection;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.HashSet;
		import java.util.List;
		import java.util.NoSuchElementException;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.stream.«type.javaPrefix»Stream;
		«ELSE»
			import java.util.stream.Stream;
		«ENDIF»
		import java.util.stream.StreamSupport;

		import «Constants.F»;
		«IF type == Type.OBJECT»
			import «Constants.F0»;
		«ELSE»
			import «Constants.FUNCTION».«type.typeName»F0;
		«ENDIF»
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		«IF type == Type.OBJECT»
			«FOR toType : Type.primitives»
				import «Constants.FUNCTION».«toType.typeName»F;
			«ENDFOR»
			import «Constants.FUNCTION».IntObjectF;
		«ELSE»
			«FOR toType : Type.primitives»
				import «Constants.FUNCTION».«type.typeName»«toType.typeName»F;
			«ENDFOR»
			import «Constants.FUNCTION».«type.typeName»ObjectF;
			«IF type != Type.INT»
				import «Constants.FUNCTION».Int«type.typeName»F;
			«ENDIF»
		«ENDIF»
		import «Constants.EQUATABLE»;
		import «Constants.JCATS».«IF type != Type.OBJECT»«type.typeName»«ENDIF»Indexed;
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»
		import «Constants.SIZED»;

		import static java.lang.Math.min;
		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static jcats.collection.Seq.*;
		«ENDIF»
		import static «Constants.F».id;
		import static «Constants.P».p;
		import static «Constants.COMMON».iterableToString;
		import static «Constants.COMMON».iterableHashCode;


		public abstract class «genericName» implements Iterable<«type.genericBoxedName»>, Equatable<«genericName»>, Sized, «IF type == Type.OBJECT»Indexed<A>«ELSE»«type.typeName»Indexed«ENDIF», Serializable {
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
				return update(index, «IF type == Type.OBJECT»F«ELSE»«type.typeName»«type.typeName»F«ENDIF».constant(value));
			}

			/**
			 * O(log(size))
			 */
			public abstract «genericName» update(final int index, final «updateFunction» f);

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

			/**
			 * O(min(this.size, suffix.size))
			 */
			public «genericName» concat(final «genericName» suffix) {
				if (suffix.isEmpty()) {
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

			abstract «genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize);

			abstract «genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize);

			public final «genericName» appendAll(final Iterable<«type.genericBoxedName»> suffix) {
				requireNonNull(suffix);
				if (suffix instanceof «wildcardName») {
					return concat((«genericName») suffix);
				} else if (suffix instanceof Collection<?> && suffix instanceof RandomAccess) {
					final int suffixSize = ((Collection<«type.genericBoxedName»>) suffix).size();
					if (suffixSize == 0) {
						return this;
					} else {
						return appendSized(«type.getIterator("suffix.iterator()")», suffixSize);
					}
				} else if (suffix instanceof Sized) {
					final int suffixSize = ((Sized) suffix).size();
					if (suffixSize == 0) {
						return this;
					} else {
						return appendSized(«type.getIterator("suffix.iterator()")», suffixSize);
					}
				} else {
					final «type.iteratorGenericName» iterator = «type.getIterator("suffix.iterator()")»;
					if (iterator.hasNext()) {
						final «IF (type == Type.OBJECT)»SeqBuilder<A>«ELSE»«shortName»Builder«ENDIF» builder = new «IF (type == Type.OBJECT)»SeqBuilder<>«ELSE»«shortName»Builder«ENDIF»(this);
						while (iterator.hasNext()) {
							builder.append(iterator.«type.iteratorNext»());
						}
						return builder.build();
					} else {
						return this;
					}
				}
			}

			public final «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) {
				requireNonNull(prefix);
				if (prefix instanceof «wildcardName») {
					return ((«genericName») prefix).concat(this);
				} else if (prefix instanceof Collection<?> && prefix instanceof RandomAccess) {
					final int prefixSize = ((Collection<«type.genericBoxedName»>) prefix).size();
					if (prefixSize == 0) {
						return this;
					} else {
						return prependSized(«type.getIterator("prefix.iterator()")», prefixSize);
					}
				} else if (prefix instanceof Sized) {
					final int prefixSize = ((Sized) prefix).size();
					if (prefixSize == 0) {
						return this;
					} else {
						return prependSized(«type.getIterator("prefix.iterator()")», prefixSize);
					}
				} else {
					final «type.iteratorGenericName» iterator = «type.getIterator("prefix.iterator()")»;
					if (iterator.hasNext()) {
						if (isEmpty()) {
							final «IF (type == Type.OBJECT)»SeqBuilder<A>«ELSE»«shortName»Builder«ENDIF» builder = new «IF (type == Type.OBJECT)»SeqBuilder<>«ELSE»«shortName»Builder«ENDIF»();
							while (iterator.hasNext()) {
								builder.append(iterator.«type.iteratorNext»());
							}
							return builder.build();
						} else {
							// We must know exact size, so use a temporary list
							final «bufferedListName» tempList = new «bufferedListDiamondName»();
							int size = 0;
							while (iterator.hasNext()) {
								tempList.append(iterator.«type.iteratorNext»());
								size++;
							}
							return prependSized(tempList.iterator(), size);
						}
					} else {
						return this;
					}
				}
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
					«IF type == Type.BOOL»
						return Seq.sizedToSeq(new MappedIterator<>(iterator(), f.toF()), size());
					«ELSE»
						return Seq.sizedToSeq(new Mapped«type.typeName»ObjectIterator<>(iterator(), f), size());
					«ENDIF»
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

			public final «genericName» filter(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»BoolF«IF type == Type.OBJECT»<A>«ENDIF» predicate) {
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
					return builder.build();
				}
			}

			«IF type == Type.OBJECT»
				public final List<A> asList() {
					return new SeqAsList<>(this);
				}
			«ELSE»
				public final List<«type.genericBoxedName»> asList() {
					return new «type.typeName»IndexedIterableAsList<>(this);
				}
			«ENDIF»

			«toArrayList(type, true)»

			«toHashSet(type, true)»

			«IF type == Type.OBJECT»
				public final Array<A> toArray() {
					if (isEmpty()) {
						return Array.emptyArray();
					} else {
						return new Array<>(toObjectArray());
					}
				}

			«ENDIF»
			public abstract «type.javaName»[] to«type.javaPrefix»Array();

			public static «paramGenericName» empty«shortName»() {
				return «shortName».EMPTY;
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

			«repeat(type, paramGenericName)»

			«fill(type, paramGenericName)»

			public static «paramGenericName» tabulate(final int size, final Int«type.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
				requireNonNull(f);
				if (size <= 0) {
					return empty«shortName»();
				} else {
					«IF type == Type.OBJECT»
						return sizedToSeq(new TableIterator<>(size, f), size);
					«ELSEIF type == Type.BOOL»
						return sizedToSeq(new TableIterator<>(size, f.toIntObjectF()), size);
					«ELSE»
						return sizedToSeq(new Table«type.typeName»Iterator(size, f), size);
					«ENDIF»
				}
			}

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

			public static «paramGenericName» iterableToSeq(final Iterable<«type.genericBoxedName»> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof «wildcardName») {
					return («genericName») iterable;
				} else if (iterable instanceof Collection<?> && iterable instanceof RandomAccess) {
					return sizedToSeq(«type.getIterator("iterable.iterator()")», ((Collection<«type.genericBoxedName»>) iterable).size());
				} else if (iterable instanceof Sized) {
					return sizedToSeq(«type.getIterator("iterable.iterator()")», ((Sized) iterable).size());
				} else {
					final «type.iteratorGenericName» iterator = «type.getIterator("iterable.iterator()")»;
					if (iterator.hasNext()) {
						final «seqBuilderName» builder = new «seqBuilderDiamondName»();
						while (iterator.hasNext()) {
							builder.append(iterator.«type.iteratorNext»());
						}
						return builder.build();
					} else {
						return empty«shortName»();
					}
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
			«spliterator(type)»

			«stream(type)»

			«parallelStream(type)»

			«hashcode(type.genericBoxedName)»

			«equals(type, wildcardName)»

			«toStr(type)»

			«IF type == Type.OBJECT»
				«zip»

				«zipWith»

				/**
				 * O(size)
				 */
				public Seq<P<A, Integer>> zipWithIndex() {
					if (isEmpty()) {
						return emptySeq();
					} else {
						final Iterator<A> iterator = iterator();
						return tabulate(size(), i -> p(iterator.next(), i));
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
				public static <A> SeqBuilder<A> seqBuilder() {
					return new SeqBuilder<>();
				}
			«ELSE»
				public static «seqBuilderName» «seqBuilderName.firstToLowerCase»() {
					return new «seqBuilderDiamondName»();
				}
			«ENDIF»
		}

		«seq0SourceCode»

		«seq1SourceCode»

		«seq2SourceCode»

		«seq3SourceCode»

		«seq4SourceCode»

		«seq5SourceCode»

		«seq6SourceCode»

		final class «iteratorName(2)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][] node2;
			private final «type.javaName»[] tail;

			private int index2;
			private int index1;
			private «type.javaName»[] node1;

			«shortName»2Iterator(final «type.javaName»[][] node2, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node2 = node2;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || index2 <= node2.length);
			}

			@Override
			public «iteratorReturnType» «type.iteratorNext»() {
				if (index1 < node1.length) {
					return «type.genericCast»node1[index1++];
				} else if (index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index2 == node2.length) {
					node1 = tail;
					index2++;
					index1 = 1;
					return «type.genericCast»node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class «iteratorName(3)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][] node3;
			private final «type.javaName»[] tail;

			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»3Iterator(final «type.javaName»[][][] node3, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node3 = node3;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || (node2 != null && index2 < node2.length) || index3 <= node3.length);
			}

			@Override
			public «iteratorReturnType» «type.iteratorNext»() {
				if (index1 < node1.length) {
					return «type.genericCast»node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index3 < node3.length) {
					if (node3[index3].length == 0) {
						if (index3 == 0) {
							node2 = node3[1];
							node1 = node2[0];
							index3 += 2;
							index2 = 1;
						} else {
							node2 = null;
							node1 = tail;
							index3 += 2;
						}
					} else {
						node2 = node3[index3++];
						node1 = node2[0];
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index3 == node3.length) {
					node2 = null;
					node1 = tail;
					index3++;
					index1 = 1;
					return «type.genericCast»node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class «iteratorName(4)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][][] node4;
			private final «type.javaName»[] tail;

			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][][] node3;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»4Iterator(final «type.javaName»[][][][] node4, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node4 = node4;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || (node2 != null && index2 < node2.length) ||
						(node3 != null && index3 < node3.length) || index4 <= node4.length);
			}

			@Override
			public «iteratorReturnType» «type.iteratorNext»() {
				if (index1 < node1.length) {
					return «type.genericCast»node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (node3 != null && index3 < node3.length) {
					if (node3[index3].length == 0) {
						node3 = null;
						node2 = null;
						node1 = tail;
						index4 += 2;
					} else {
						node2 = node3[index3++];
						node1 = node2[0];
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index4 < node4.length) {
					if (node4[index4][0].length == 0) {
						if (node4[index4].length == 1) {
							if (index4 == node4.length - 1) {
								node3 = null;
								node2 = null;
								node1 = tail;
								index4 += 2;
							} else {
								index4++;
								node3 = node4[index4++];
								node2 = node3[0];
								node1 = node2[0];
								index3 = 1;
								index2 = 1;
							}
						} else {
							node3 = node4[index4++];
							node2 = node3[1];
							node1 = node2[0];
							index3 = 2;
							index2 = 1;
						}
					} else {
						node3 = node4[index4++];
						node2 = node3[0];
						node1 = node2[0];
						index3 = 1;
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index4 == node4.length) {
					node3 = null;
					node2 = null;
					node1 = tail;
					index4++;
					index1 = 1;
					return «type.genericCast»node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class «iteratorName(5)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][][][] node5;
			private final «type.javaName»[] tail;

			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][][][] node4;
			private «type.javaName»[][][] node3;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»5Iterator(final «type.javaName»[][][][][] node5, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node5 = node5;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || (node2 != null && index2 < node2.length) ||
						(node3 != null && index3 < node3.length) || (node4 != null && index4 < node4.length) ||
						index5 <= node5.length);
			}

			@Override
			public «iteratorReturnType» «type.iteratorNext»() {
				if (index1 < node1.length) {
					return «type.genericCast»node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (node3 != null && index3 < node3.length) {
					if (node3[index3].length == 0) {
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = tail;
						index5 += 2;
					} else {
						node2 = node3[index3++];
						node1 = node2[0];
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (node4 != null && index4 < node4.length) {
					if (node4[index4][0].length == 0) {
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = tail;
						index5 += 2;
					} else {
						node3 = node4[index4++];
						node2 = node3[0];
						node1 = node2[0];
						index3 = 1;
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index5 < node5.length) {
					if (node5[index5][0][0].length == 0) {
						if (node5[index5][0].length == 1) {
							if (node5[index5].length == 1) {
								if (index5 == node5.length - 1) {
									node4 = null;
									node3 = null;
									node2 = null;
									node1 = tail;
									index5 += 2;
								} else {
									index5++;
									node4 = node5[index5++];
									node3 = node4[0];
									node2 = node3[0];
									node1 = node2[0];
									index4 = 1;
									index3 = 1;
									index2 = 1;
								}
							} else {
								node4 = node5[index5++];
								node3 = node4[1];
								node2 = node3[0];
								node1 = node2[0];
								index4 = 2;
								index3 = 1;
								index2 = 1;
							}
						} else {
							node4 = node5[index5++];
							node3 = node4[0];
							node2 = node3[1];
							node1 = node2[0];
							index4 = 1;
							index3 = 2;
							index2 = 1;
						}
					} else {
						node4 = node5[index5++];
						node3 = node4[0];
						node2 = node3[0];
						node1 = node2[0];
						index4 = 1;
						index3 = 1;
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index5 == node5.length) {
					node4 = null;
					node3 = null;
					node2 = null;
					node1 = tail;
					index5++;
					index1 = 1;
					return «type.genericCast»node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class «iteratorName(6)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][][][][] node6;
			private final «type.javaName»[] tail;

			private int index6;
			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][][][][] node5;
			private «type.javaName»[][][][] node4;
			private «type.javaName»[][][] node3;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»6Iterator(final «type.javaName»[][][][][][] node6, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node6 = node6;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || (node2 != null && index2 < node2.length) ||
						(node3 != null && index3 < node3.length) || (node4 != null && index4 < node4.length) ||
						(node5 != null && index5 < node5.length) || index6 <= node6.length);
			}

			@Override
			public «iteratorReturnType» «type.iteratorNext»() {
				if (index1 < node1.length) {
					return «type.genericCast»node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (node3 != null && index3 < node3.length) {
					if (node3[index3].length == 0) {
						node5 = null;
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = tail;
						index6 += 2;
					} else {
						node2 = node3[index3++];
						node1 = node2[0];
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (node4 != null && index4 < node4.length) {
					if (node4[index4][0].length == 0) {
						node5 = null;
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = tail;
						index6 += 2;
					} else {
						node3 = node4[index4++];
						node2 = node3[0];
						node1 = node2[0];
						index3 = 1;
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (node5 != null && index5 < node5.length) {
					if (node5[index5][0][0].length == 0) {
						node5 = null;
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = tail;
						index6 += 2;
					} else {
						node4 = node5[index5++];
						node3 = node4[0];
						node2 = node3[0];
						node1 = node2[0];
						index4 = 1;
						index3 = 1;
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index6 < node6.length) {
					if (node6[index6][0][0][0].length == 0) {
						if (node6[index6][0][0].length == 1) {
							if (node6[index6][0].length == 1) {
								if (node6[index6].length == 1) {
									if (index6 == node6.length - 1) {
										node5 = null;
										node4 = null;
										node3 = null;
										node2 = null;
										node1 = tail;
										index6 += 2;
									} else {
										index6++;
										node5 = node6[index6++];
										node4 = node5[0];
										node3 = node4[0];
										node2 = node3[0];
										node1 = node2[0];
										index5 = 1;
										index4 = 1;
										index3 = 1;
										index2 = 1;
									}
								} else {
									node5 = node6[index6++];
									node4 = node5[1];
									node3 = node4[0];
									node2 = node3[0];
									node1 = node2[0];
									index5 = 2;
									index4 = 1;
									index3 = 1;
									index2 = 1;
								}
							} else {
								node5 = node6[index6++];
								node4 = node5[0];
								node3 = node4[1];
								node2 = node3[0];
								node1 = node2[0];
								index5 = 1;
								index4 = 2;
								index3 = 1;
								index2 = 1;
							}
						} else {
							node5 = node6[index6++];
							node4 = node5[0];
							node3 = node4[0];
							node2 = node3[1];
							node1 = node2[0];
							index5 = 1;
							index4 = 1;
							index3 = 2;
							index2 = 1;
						}
					} else {
						node5 = node6[index6++];
						node4 = node5[0];
						node3 = node4[0];
						node2 = node3[0];
						node1 = node2[0];
						index5 = 1;
						index4 = 1;
						index3 = 1;
						index2 = 1;
					}
					index1 = 1;
					return «type.genericCast»node1[0];
				} else if (index6 == node6.length) {
					node5 = null;
					node4 = null;
					node3 = null;
					node2 = null;
					node1 = tail;
					index6++;
					index1 = 1;
					return «type.genericCast»node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}
		«IF type == Type.OBJECT»

			final class SeqAsList<A> extends IndexedIterableAsList<A, Seq<A>> {
				SeqAsList(final «shortName»«IF type == Type.OBJECT»<A>«ENDIF» seq) {
					super(seq);
				}

				@Override
				public Object[] toArray() {
					return iterable.toObjectArray();
				}
			}
		«ENDIF»
	''' }

	def seq0SourceCode() { '''
		final class «genericName(0)» extends «genericName» {
			@Override
			public int size() {
				return 0;
			}

			@Override
			public «type.genericName» head() {
				throw new NoSuchElementException();
			}

			@Override
			public «type.genericName» last() {
				throw new NoSuchElementException();
			}

			@Override
			public «genericName» init() {
				throw new NoSuchElementException();
			}

			@Override
			public «genericName» tail() {
				throw new NoSuchElementException();
			}

			@Override
			public «type.genericName» get(final int index) {
				throw new IndexOutOfBoundsException(Integer.toString(index));
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» __) {
				throw new IndexOutOfBoundsException(Integer.toString(index));
			}

			@Override
			public «genericName» take(final int n) {
				return empty«shortName»();
			}

			@Override
			public «genericName» drop(final int n) {
				return empty«shortName»();
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				return append(value);
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				final «type.javaName»[] node1 = { requireNonNull(value) };
				return new «diamondName(1)»(node1);
			}

			@Override
			public «genericName» concat(final «genericName» suffix) {
				return requireNonNull(suffix);
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				return sizedToSeq(suffix, suffixSize);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				return sizedToSeq(prefix, prefixSize);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				return «IF type != Type.OBJECT»«type.typeName»«ENDIF»Array.EMPTY.array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF !Type.javaUnboxedTypes.contains(type)»
					return emptyIterator();
				«ELSE»
					return Empty«type.typeName»Iterator.empty«type.typeName»Iterator();
				«ENDIF»
			}
		}
	''' }

	def seq1SourceCode() { '''
		final class «genericName(1)» extends «genericName» {
			final «type.javaName»[] node1;

			«shortName»1(final «type.javaName»[] node1) {
				this.node1 = node1;
				assert node1.length >= 1 && node1.length <= 32 : "node1.length = " + node1.length;
			}

			@Override
			public int size() {
				return node1.length;
			}

			@Override
			public «type.genericName» head() {
				return «type.genericCast»node1[0];
			}

			@Override
			public «type.genericName» last() {
				return «type.genericCast»node1[node1.length - 1];
			}

			@Override
			public «genericName» init() {
				if (node1.length == 1) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length - 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length - 1);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» tail() {
				if (node1.length == 1) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length - 1];
					System.arraycopy(node1, 1, newNode1, 0, node1.length - 1);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «type.genericName» get(final int index) {
				return «type.genericCast»node1[index];
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» f) {
				requireNonNull(f);
				final «type.javaName»[] newNode1 = node1.clone();
				final «type.genericName» oldValue = «type.genericCast»node1[index];
				final «type.genericName» newValue = f.apply(oldValue);
				newNode1[index] = newValue;
				return new «diamondName(1)»(newNode1);
			}

			@Override
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n >= node1.length) {
					return this;
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[n];
					System.arraycopy(node1, 0, newNode1, 0, n);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» drop(final int n) {
				if (n >= node1.length) {
					return empty«shortName»();
				} else if (n <= 0) {
					return this;
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length - n];
					System.arraycopy(node1, n, newNode1, 0, newNode1.length);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				requireNonNull(value);
				if (node1.length == 32) {
					final «type.javaName»[] init = { value };
					return new «diamondName(2)»(«shortName»2.EMPTY_NODE2, init, node1, 33);
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				requireNonNull(value);
				if (node1.length == 32) {
					final «type.javaName»[] tail = { value };
					return new «diamondName(2)»(«shortName»2.EMPTY_NODE2, node1, tail, 33);
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length);
					newNode1[node1.length] = value;
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» concat(final «genericName» suffix) {
				if (suffix.size() <= 32) {
					return appendSized(suffix.iterator(), suffix.size());
				} else {
					return suffix.prependSized(iterator(), node1.length);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				final int size = node1.length + suffixSize;
				final int maxSize = 32 + suffixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (size <= 32) {
					return appendSizedToSeq1(suffix, size);
				} else if (maxSize <= (1 << 10)) {
					return appendSizedToSeq2(suffix, suffixSize, size);
				} else if (maxSize <= (1 << 15)) {
					return appendSizedToSeq3(suffix, suffixSize, size, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return appendSizedToSeq4(suffix, suffixSize, size, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return appendSizedToSeq5(suffix, suffixSize, size, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, size, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(1)» appendSizedToSeq1(final «type.iteratorGenericName» suffix, final int size) {
				final «type.javaName»[] newNode1 = new «type.javaName»[size];
				System.arraycopy(node1, 0, newNode1, 0, node1.length);
				return fillSeq1(newNode1, node1.length, suffix);
			}

			private «genericName(2)» appendSizedToSeq2(final «type.iteratorGenericName» suffix, final int suffixSize, final int size) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final int size2 = (suffixSize - newTail.length) / 32;
				final «type.javaName»[][] newNode2;
				if (size2 == 0) {
					fillArray(newTail, 0, suffix);
					return new «diamondName(2)»(EMPTY_NODE2, node1, newTail, size);
				} else {
					newNode2 = new «type.javaName»[size2][32];
					return fillSeq2(newNode2, 1, newNode2[0], 0, node1, newTail, size, suffix);
				}
			}

			private «genericName(3)» appendSizedToSeq3(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][] newNode3 = allocateNode3(0, maxSize);
				return fillSeq3(newNode3, 1, newNode3[0], 1, newNode3[0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			private «genericName(4)» appendSizedToSeq4(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4(0, maxSize);
				return fillSeq4(newNode4, 1, newNode4[0], 1, newNode4[0][0], 1, newNode4[0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private «genericName(5)» appendSizedToSeq5(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5(0, maxSize);
				return fillSeq5(newNode5, 1, newNode5[0], 1, newNode5[0][0], 1, newNode5[0][0][0], 1, newNode5[0][0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(0, maxSize);
				return fillSeq6(newNode6, 1, newNode6[0], 1, newNode6[0][0], 1, newNode6[0][0][0], 1, newNode6[0][0][0][0], 1,
						newNode6[0][0][0][0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				final int size = prefixSize + node1.length;
				final int maxSize = prefixSize + 32;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (size <= 32) {
					return prependSizedToSeq1(prefix, size);
				} else if (maxSize <= (1 << 10)) {
					return prependSizedToSeq2(prefix, prefixSize, size);
				} else if (maxSize <= (1 << 15)) {
					return prependSizedToSeq3(prefix, prefixSize, size, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return prependSizedToSeq4(prefix, prefixSize, size, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return prependSizedToSeq5(prefix, prefixSize, size, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, size, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(1)» prependSizedToSeq1(final «type.iteratorGenericName» prefix, final int size) {
				final «type.javaName»[] newNode1 = new «type.javaName»[size];
				System.arraycopy(node1, 0, newNode1, size - node1.length, node1.length);
				return fillSeq1FromStart(newNode1, size - node1.length, prefix);
			}

			private «genericName(2)» prependSizedToSeq2(final «type.iteratorGenericName» prefix, final int prefixSize, final int size) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final int size2 = (prefixSize - newInit.length) / 32;
				final «type.javaName»[][] newNode2;
				if (size2 == 0) {
					fillArray(newInit, 0, prefix);
					return new «diamondName(2)»(EMPTY_NODE2, newInit, node1, size);
				} else {
					newNode2 = new «type.javaName»[size2][32];
					return fillSeq2FromStart(newNode2, 1, newNode2[size2 - 1], 0, newInit, node1, size, prefix);
				}
			}

			private «genericName(3)» prependSizedToSeq3(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][] newNode3 = allocateNode3FromStart(0, maxSize);
				final int startIndex = calculateSeq3StartIndex(newNode3, newInit);
				return fillSeq3FromStart(newNode3, 1, newNode3[newNode3.length - 1], 1, newNode3[newNode3.length - 1][30], 0,
						newInit, node1, startIndex, size, prefix);
			}

			private «genericName(4)» prependSizedToSeq4(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4FromStart(0, maxSize);
				final int startIndex = calculateSeq4StartIndex(newNode4, newInit);
				return fillSeq4FromStart(newNode4, 1, newNode4[newNode4.length - 1], 1, newNode4[newNode4.length - 1][31], 1,
						newNode4[newNode4.length - 1][31][30], 0, newInit, node1, startIndex, size, prefix);
			}

			private «genericName(5)» prependSizedToSeq5(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5FromStart(0, maxSize);
				final int startIndex = calculateSeq5StartIndex(newNode5, newInit);
				return fillSeq5FromStart(newNode5, 1, newNode5[newNode5.length - 1], 1, newNode5[newNode5.length - 1][31], 1,
						newNode5[newNode5.length - 1][31][31], 1, newNode5[newNode5.length - 1][31][31][30], 0, newInit, node1,
						startIndex, size, prefix);
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(0, maxSize);
				final int startIndex = calculateSeq6StartIndex(newNode6, newInit);
				return fillSeq6FromStart(newNode6, 1, newNode6[newNode6.length - 1], 1, newNode6[newNode6.length - 1][31], 1,
						newNode6[newNode6.length - 1][31][31], 1, newNode6[newNode6.length - 1][31][31][31], 1,
						newNode6[newNode6.length - 1][31][31][31][30], 0, newInit, node1, startIndex, size, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				if (node1.length == 32) {
					builder.node1 = node1;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(node1, 0, builder.node1, 0, node1.length);
				}
				builder.index1 = node1.length;
				builder.size = node1.length;
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				final «type.javaName»[] array = new «type.javaName»[node1.length];
				System.arraycopy(node1, 0, array, 0, node1.length);
				return array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type == Type.OBJECT»
					return new ArrayIterator<>(node1);
				«ELSE»
					return new «type.typeName»ArrayIterator(node1);
				«ENDIF»
			}
		}
	''' }

	def seq2SourceCode() { '''
		final class «genericName(2)» extends «genericName» {
			final «type.javaName»[][] node2;
			final «type.javaName»[] init;
			final «type.javaName»[] tail;
			final int size;

			«shortName»2(final «type.javaName»[][] node2, final «type.javaName»[] init, final «type.javaName»[] tail, final int size) {
				this.node2 = node2;
				this.init = init;
				this.tail = tail;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					assert node2.length <= 30 : "node2.length = " + node2.length;
					assert node2.length > 0 || node2 == EMPTY_NODE2;
					assert init.length >= 1 && init.length <= 32 : "init.length = " + init.length;
					assert tail.length >= 1 && tail.length <= 32 : "tail.length = " + tail.length;
					assert size >= 33 && size <= (1 << 10) : "size = " + size;
					for (final «type.javaName»[] node1 : node2) {
						assert node1.length == 32 : "node1.length = " + node1.length;
						for (final Object value : node1) {
							assert value != null;
						}
					}
					for (final Object value : init) {
						assert value != null;
					}
					for (final Object value : tail) {
						assert value != null;
					}
					assert 32*node2.length + init.length + tail.length == size;
				}
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «type.genericName» head() {
				return «type.genericCast»init[0];
			}

			@Override
			public «type.genericName» last() {
				return «type.genericCast»tail[tail.length - 1];
			}

			@Override
			public «genericName» init() {
				if (tail.length == 1) {
					if (node2.length == 0) {
						return new «diamondName(1)»(init);
					} else if (node2.length == 1) {
						return new «diamondName(2)»(EMPTY_NODE2, init, node2[0], size - 1);
					} else {
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
						return new «diamondName(2)»(newNode2, init, node2[node2.length - 1], size - 1);
					}
				} else if (node2.length == 0 && init.length + tail.length == 33) {
					final «type.javaName»[] node1 = new «type.javaName»[32];
					System.arraycopy(init, 0, node1, 0, init.length);
					System.arraycopy(tail, 0, node1, init.length, tail.length - 1);
					return new «diamondName(1)»(node1);
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new «diamondName(2)»(node2, init, newTail, size - 1);
				}
			}

			@Override
			public «genericName» tail() {
				if (init.length == 1) {
					if (node2.length == 0) {
						return new «diamondName(1)»(tail);
					} else if (node2.length == 1) {
						return new «diamondName(2)»(EMPTY_NODE2, node2[0], tail, size - 1);
					} else {
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
						System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
						return new «diamondName(2)»(newNode2, node2[0], tail, size - 1);
					}
				} else if (node2.length == 0 && init.length + tail.length == 33) {
					final «type.javaName»[] node1 = new «type.javaName»[32];
					System.arraycopy(init, 1, node1, 0, init.length - 1);
					System.arraycopy(tail, 0, node1, init.length - 1, tail.length);
					return new «diamondName(1)»(node1);
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new «diamondName(2)»(node2, newInit, tail, size - 1);
				}
			}

			@Override
			public «type.genericName» get(final int index) {
				try {
					if (index < init.length) {
						return «type.genericCast»init[index];
					} else if (index >= size - tail.length) {
						return «type.genericCast»tail[index + tail.length - size];
					} else {
						final int idx = index + 32 - init.length;
						return «type.genericCast»node2[index2(idx) - 1][index1(idx)];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = init.clone();
						final «type.genericName» oldValue = «type.genericCast»init[index];
						final «type.genericName» newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new «diamondName(2)»(node2, newInit, tail, size);
					} else if (index >= size - tail.length) {
						final «type.javaName»[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final «type.genericName» oldValue = «type.genericCast»tail[tailIndex];
						final «type.genericName» newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new «diamondName(2)»(node2, init, newTail, size);
					} else {
						final «type.javaName»[][] newNode2 = node2.clone();
						final int idx = index + 32 - init.length;
						final int index2 = index2(idx) - 1;
						final «type.javaName»[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final «type.genericName» oldValue = «type.genericCast»newNode1[index1];
						final «type.genericName» newValue = f.apply(oldValue);
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new «diamondName(2)»(newNode2, init, tail, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n < init.length) {
					final «type.javaName»[] node1 = new «type.javaName»[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new «diamondName(1)»(node1);
				} else if (n == init.length) {
					return new «diamondName(1)»(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					if (n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(tail, 0, newNode1, init.length, n - init.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newTail = new «type.javaName»[tail.length + n - size];
						System.arraycopy(tail, 0, newTail, 0, newTail.length);
						return new «diamondName(2)»(node2, init, newTail, n);
					}
				} else {
					final int idx = n + 31 - init.length;
					final int index2 = index2(idx) - 1;
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new «type.javaName»[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						final «type.javaName»[][] newNode2;
						if (index2 == 0) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[index2][];
							System.arraycopy(node2, 0, newNode2, 0, index2);
						}

						return new «diamondName(2)»(newNode2, init, newTail, n);
					}
				}
			}

			@Override
			public «genericName» drop(final int n) {
				if (n >= size) {
					return empty«shortName»();
				} else if (n > size - tail.length) {
					final «type.javaName»[] node1 = new «type.javaName»[size - n];
					System.arraycopy(tail, n - size + tail.length, node1, 0, node1.length);
					return new «diamondName(1)»(node1);
				} else if (n == size - tail.length) {
					return new «diamondName(1)»(tail);
				} else if (n <= 0) {
					return this;
				} else if (n < init.length) {
					if (size - n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[size - n];
						System.arraycopy(init, n, newNode1, 0, init.length - n);
						System.arraycopy(tail, 0, newNode1, init.length - n, tail.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newInit = new «type.javaName»[init.length - n];
						System.arraycopy(init, n, newInit, 0, newInit.length);
						return new «diamondName(2)»(node2, newInit, tail, size - n);
					}
				} else {
					final int idx = n + 32 - init.length;
					final int index2 = index2(idx) - 1;
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);
					final int newSize = size - n;

					if (newSize <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[newSize];
						System.arraycopy(node1, index1, newNode1, 0, 32 - index1);
						System.arraycopy(tail, 0, newNode1, 32 - index1, tail.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newInit;
						if (index1 == 0) {
							newInit = node1;
						} else {
							newInit = new «type.javaName»[32 - index1];
							System.arraycopy(node1, index1, newInit, 0, newInit.length);
						}

						final «type.javaName»[][] newNode2;
						if (index2 == node2.length - 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[node2.length - index2 - 1][];
							System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
						}

						return new «diamondName(2)»(newNode2, newInit, tail, newSize);
					}
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				requireNonNull(value);
				if (init.length == 32) {
					if (node2.length == 30) {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
						System.arraycopy(node2, 0, newNode2, 1, 30);
						newNode2[0] = init;
						final «type.javaName»[][][] newNode3 = { EMPTY_NODE2, newNode2 };
						return new «diamondName(3)»(newNode3, newInit, tail, (1 << 10) - 1, size + 1);
					} else {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						return new «diamondName(2)»(newNode2, newInit, tail, size + 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new «diamondName(2)»(node2, newInit, tail, size + 1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				requireNonNull(value);
				if (tail.length == 32) {
					if (node2.length == 30) {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
						System.arraycopy(node2, 0, newNode2, 0, 30);
						newNode2[30] = tail;
						final «type.javaName»[][][] newNode3 = { newNode2, EMPTY_NODE2 };
						return new «diamondName(3)»(newNode3, init, newTail, 32 - init.length, size + 1);
					} else {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						return new «diamondName(2)»(newNode2, init, newTail, size + 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new «diamondName(2)»(node2, init, newTail, size + 1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new «diamondName(2)»(node2, init, newTail, size + suffixSize);
				}

				final int maxSize = size - init.length + 32 + suffixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 10)) {
					return appendSizedToSeq2(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 15)) {
					return appendSizedToSeq3(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return appendSizedToSeq4(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return appendSizedToSeq5(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(2)» appendSizedToSeq2(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final int size2 = (maxSize - 32 - newTail.length) / 32;
				final «type.javaName»[][] newNode2 = new «type.javaName»[size2][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < size2; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					return fillSeq2(newNode2, node2.length + 1, tail, 32, init, newTail, size + suffixSize, suffix);
				} else {
					for (int index2 = node2.length; index2 < size2; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
					return fillSeq2(newNode2, node2.length + 1, newNode2[node2.length], tail.length,
							init, newTail, size + suffixSize, suffix);
				}
			}

			private «genericName(3)» appendSizedToSeq3(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][] newNode3 = allocateNode3(1, maxSize);
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;

				return fillSeq3(newNode3, 1, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			private «genericName(4)» appendSizedToSeq4(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4(1, maxSize);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;
				for (int index3 = 1; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[0] = newNode3;

				return fillSeq4(newNode4, 1, newNode3, 1, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			private «genericName(5)» appendSizedToSeq5(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5(1, maxSize);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;
				for (int index3 = 1; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[0] = newNode4;

				return fillSeq5(newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;
				for (int index3 = 1; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[0] = newNode4;
				for (int index5 = 1; index5 < 32; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new «diamondName(2)»(node2, newInit, tail, size + prefixSize);
				}

				final int maxSize = size - tail.length + 32 + prefixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 10)) {
					return prependSizedToSeq2(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 15)) {
					return prependSizedToSeq3(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return prependSizedToSeq4(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return prependSizedToSeq5(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(2)» prependSizedToSeq2(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final int size2 = (maxSize - 32 - newInit.length) / 32;
				final «type.javaName»[][] newNode2 = new «type.javaName»[size2][];
				System.arraycopy(node2, 0, newNode2, size2 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[size2 - node2.length - 1] = init;
					for (int index2 = 0; index2 < size2 - node2.length - 1; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					return fillSeq2FromStart(newNode2, node2.length + 1, init, 32, newInit, tail, size + prefixSize, prefix);
				} else {
					for (int index2 = 0; index2 < size2 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[size2 - node2.length - 1], 32 - init.length, init.length);
					return fillSeq2FromStart(newNode2, node2.length + 1, newNode2[size2 - node2.length - 1], init.length,
							newInit, tail, size + prefixSize, prefix);
				}
			}

			private «genericName(3)» prependSizedToSeq3(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][] newNode3 = allocateNode3FromStart(1, maxSize);
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - 1] = newNode2;
				final int startIndex = calculateSeq3StartIndex(newNode3, newInit);

				return fillSeq3FromStart(newNode3, 1, newNode2, node2.length + 1, newNode2[30 - node2.length], init.length,
						newInit, tail, startIndex, size + prefixSize, prefix);
			}

			private «genericName(4)» prependSizedToSeq4(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4FromStart(1, maxSize);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[31] = newNode2;
				for (int index3 = 0; index3 < 31; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[newNode4.length - 1] = newNode3;
				final int startIndex = calculateSeq4StartIndex(newNode4, newInit);

				return fillSeq4FromStart(newNode4, 1, newNode3, 1, newNode2, node2.length + 1, newNode2[30 - node2.length],
						init.length, newInit, tail, startIndex, size + prefixSize, prefix);
			}

			private «genericName(5)» prependSizedToSeq5(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5FromStart(1, maxSize);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[31] = newNode2;
				for (int index3 = 0; index3 < 31; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[newNode5.length - 1] = newNode4;
				final int startIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[30 - node2.length], init.length, newInit, tail, startIndex, size + prefixSize, prefix);
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[31] = newNode2;
				for (int index3 = 0; index3 < 31; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[31] = newNode4;
				for (int index5 = 0; index5 < 31; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int startIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[30 - node2.length], init.length, newInit, tail, startIndex, size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				builder.node2 = new «type.javaName»[31][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.startIndex = 32 - init.length;
				builder.size = size;
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				final «type.javaName»[] array = new «type.javaName»[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[] node1 : node2) {
					System.arraycopy(node1, 0, array, index, 32);
					index += 32;
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(2)»(node2, init, tail);
			}
		}
	''' }

	def seq3SourceCode() { '''
		final class «genericName(3)» extends «genericName» {
			final «type.javaName»[][][] node3;
			final int startIndex;
			final «type.javaName»[] init;
			final «type.javaName»[] tail;
			final int size;

			«shortName»3(final «type.javaName»[][][] node3, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size) {
				this.node3 = node3;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final «type.javaName»[][] lastNode2 = node3[node3.length - 1];

					assert node3.length >= 2 && node3.length <= 32 : "node3.length = " + node3.length;
					assert init.length >= 1 && init.length <= 32 : "init.length = " + init.length;
					assert tail.length >= 1 && tail.length <= 32 : "tail.length = " + tail.length;
					assert size >= 31*32 + 2 && size <= (1 << 15) : "size = " + size;

					assert node3[0].length <= 31 : "node2.length = " + node3[0].length;
					assert lastNode2.length <= 31 : "node2.length = " + lastNode2.length;
					assert node3[0].length != 0 || node3[0] == EMPTY_NODE2;
					assert lastNode2.length != 0 || lastNode2 == EMPTY_NODE2;

					for (int i = 1; i < node3.length - 1; i++) {
						assert node3[i].length == 32 : "node2.length = " + node3[i].length;
					}
					for (final «type.javaName»[][] node2 : node3) {
						for (final «type.javaName»[] node1 : node2) {
							assert node1.length == 32 : "node1.length = " + node1.length;
							for (final Object value : node1) {
								assert value != null;
							}
						}
					}
					for (final Object value : init) {
						assert value != null;
					}
					for (final Object value : tail) {
						assert value != null;
					}

					if (node3.length == 2) {
						assert node3[0].length + node3[1].length >= 31;
					}

					assert 32*node3[0].length + 32*lastNode2.length + 32*32*(node3.length - 2) +
							init.length + tail.length == size : "size = " + size;
					assert startIndex == calculateSeq3StartIndex(node3, init) : "startIndex = " + startIndex;
				}
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «type.genericName» head() {
				return «type.genericCast»init[0];
			}

			@Override
			public «type.genericName» last() {
				return «type.genericCast»tail[tail.length - 1];
			}

			@Override
			public «genericName» init() {
				if (tail.length == 1) {
					final «type.javaName»[][] lastNode2 = node3[node3.length - 1];
					if (lastNode2.length == 0) {
						if (node3.length == 2) {
							final «type.javaName»[][] node2 = node3[0];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							return new «diamondName(2)»(newNode2, init, node2[node2.length - 1], size - 1);
						} else {
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 2);
							final «type.javaName»[][] node2 = node3[node3.length - 2];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[node3.length - 2] = newNode2;
							return new «diamondName(3)»(newNode3, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						if (node3.length == 2) {
							final «type.javaName»[][] firstNode2 = node3[0];
							if (firstNode2.length + lastNode2.length == 31) {
								final «type.javaName»[][] newNode2 = new «type.javaName»[30][];
								System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
								System.arraycopy(lastNode2, 0, newNode2, firstNode2.length, lastNode2.length - 1);
								return new «diamondName(2)»(newNode2, init, lastNode2[lastNode2.length - 1], size - 1);
							}
						}

						final «type.javaName»[][][] newNode3 = node3.clone();
						final «type.javaName»[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[node3.length - 1] = newNode2;
						return new «diamondName(3)»(newNode3, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new «diamondName(3)»(node3, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public «genericName» tail() {
				if (init.length == 1) {
					final «type.javaName»[][] firstNode2 = node3[0];
					if (firstNode2.length == 0) {
						if (node3.length == 2) {
							final «type.javaName»[][] node2 = node3[1];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							return new «diamondName(2)»(newNode2, node2[0], tail, size - 1);
						} else {
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - 1][][];
							System.arraycopy(node3, 2, newNode3, 1, node3.length - 2);
							final «type.javaName»[][] node2 = node3[1];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new «diamondName(3)»(newNode3, node2[0], tail, 0, size - 1);
						}
					} else {
						if (node3.length == 2) {
							final «type.javaName»[][] lastNode2 = node3[1];
							if (firstNode2.length + lastNode2.length == 31) {
								final «type.javaName»[][] newNode2 = new «type.javaName»[30][];
								System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
								System.arraycopy(lastNode2, 0, newNode2, firstNode2.length - 1, lastNode2.length);
								return new «diamondName(2)»(newNode2, firstNode2[0], tail, size - 1);
							}
						}

						final «type.javaName»[][][] newNode3 = node3.clone();
						final «type.javaName»[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new «diamondName(3)»(newNode3, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new «diamondName(3)»(node3, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final «type.javaName»[][] node2) {
				return (index3 == 0) ? «index»2(idx) + node2.length - 32 : «index»2(idx);
			}

			@Override
			public «type.genericName» get(final int index) {
				try {
					if (index < init.length) {
						return «type.genericCast»init[index];
					} else if (index >= size - tail.length) {
						return «type.genericCast»tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index3 = index3(idx);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);
						return «type.genericCast»node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = init.clone();
						final «type.genericName» oldValue = «type.genericCast»init[index];
						final «type.genericName» newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new «diamondName(3)»(node3, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final «type.javaName»[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final «type.genericName» oldValue = «type.genericCast»tail[tailIndex];
						final «type.genericName» newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new «diamondName(3)»(node3, init, newTail, startIndex, size);
					} else {
						final «type.javaName»[][][] newNode3 = node3.clone();
						final int idx = index + startIndex;
						final int index3 = index3(idx);
						final «type.javaName»[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, newNode2);
						final «type.javaName»[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final «type.genericName» oldValue = «type.genericCast»newNode1[index1];
						final «type.genericName» newValue = f.apply(oldValue);
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new «diamondName(3)»(newNode3, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n < init.length) {
					final «type.javaName»[] node1 = new «type.javaName»[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new «diamondName(1)»(node1);
				} else if (n == init.length) {
					return new «diamondName(1)»(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new «diamondName(3)»(node3, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index3 = index3(idx);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new «type.javaName»[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final «type.javaName»[][] newNode2;
							if (index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final «type.javaName»[][] firstNode2 = node3[0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new «diamondName(2)»(newNode2, init, newTail, n);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							final «type.javaName»[][][] newNode3 = new «type.javaName»[index3 + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, index3);
							newNode3[index3] = newNode2;
							return new «diamondName(3)»(newNode3, init, newTail, startIndex, n);
						}
					}
				}
			}

			@Override
			public «genericName» drop(final int n) {
				if (n >= size) {
					return empty«shortName»();
				} else if (n > size - tail.length) {
					final «type.javaName»[] node1 = new «type.javaName»[size - n];
					System.arraycopy(tail, n - size + tail.length, node1, 0, node1.length);
					return new «diamondName(1)»(node1);
				} else if (n == size - tail.length) {
					return new «diamondName(1)»(tail);
				} else if (n <= 0) {
					return this;
				} else if (n < init.length) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - n];
					System.arraycopy(init, n, newInit, 0, newInit.length);
					return new «diamondName(3)»(node3, newInit, tail, startIndex + n, size - n);
				} else {
					final int idx = n + startIndex;
					final int index3 = index3(idx);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);
					final int newSize = size - n;

					if (newSize <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[newSize];
						System.arraycopy(node1, index1, newNode1, 0, 32 - index1);
						System.arraycopy(tail, 0, newNode1, 32 - index1, tail.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newInit;
						if (index1 == 0) {
							newInit = node1;
						} else {
							newInit = new «type.javaName»[32 - index1];
							System.arraycopy(node1, index1, newInit, 0, newInit.length);
						}

						if (newSize <= 1024 - 32 + tail.length) {
							final «type.javaName»[][] newNode2;
							if (index3 == node3.length - 1) {
								if (index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
								}
							} else {
								final «type.javaName»[][] lastNode2 = node3[node3.length - 1];
								if (lastNode2.length == 0 && index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1 + lastNode2.length][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, node2.length - index2 - 1);
									System.arraycopy(lastNode2, 0, newNode2, node2.length - index2 - 1, lastNode2.length);
								}
							}
							return new «diamondName(2)»(newNode2, newInit, tail, newSize);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == node2.length - 1) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[node2.length - index2 - 1][];
								System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
							}

							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - index3][][];
							System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
							newNode3[0] = newNode2;
							final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);
							return new «diamondName(3)»(newNode3, newInit, tail, newStartIndex, newSize);
						}
					}
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				requireNonNull(value);
				if (init.length == 32) {
					final «type.javaName»[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							final «type.javaName»[] newInit = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final «type.javaName»[][][] newNode3 = node3.clone();
							newNode3[0] = newNode2;
							final «type.javaName»[][][][] newNode4 = { { EMPTY_NODE2 }, newNode3 };
							if (startIndex != 0) {
								throw new IllegalStateException("startIndex != 0");
							}
							return new «diamondName(4)»(newNode4, newInit, tail, (1 << 15) - 1, size + 1);
						} else {
							final «type.javaName»[] newInit = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							if (startIndex != 0) {
								throw new IllegalStateException("startIndex != 0");
							}
							return new «diamondName(3)»(newNode3, newInit, tail, (1 << 10) - 1, size + 1);
						}
					} else {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						return new «diamondName(3)»(newNode3, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new «diamondName(3)»(node3, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final «type.javaName»[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							final «type.javaName»[] newTail = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final «type.javaName»[][][] newNode3 = node3.clone();
							newNode3[31] = newNode2;
							final «type.javaName»[][][][] newNode4 = { newNode3, { EMPTY_NODE2 } };
							return new «diamondName(4)»(newNode4, init, newTail, startIndex, size + 1);
						} else {
							final «type.javaName»[] newTail = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							return new «diamondName(3)»(newNode3, init, newTail, startIndex, size + 1);
						}
					} else {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						return new «diamondName(3)»(newNode3, init, newTail, startIndex, size + 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new «diamondName(3)»(node3, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new «diamondName(3)»(node3, init, newTail, startIndex, size + suffixSize);
				}

				final int maxSize = size - init.length - 32*node3[0].length + (1 << 10) + suffixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 15)) {
					return appendSizedToSeq3(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return appendSizedToSeq4(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return appendSizedToSeq5(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(3)» appendSizedToSeq3(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][] newNode3 = allocateNode3(node3.length, maxSize);
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);

				final «type.javaName»[][] newNode2;
				if (node3.length < newNode3.length) {
					newNode2 = new «type.javaName»[32][];
				} else {
					final int totalSize2 = (maxSize % (1 << 10) == 0) ? (1 << 10) : maxSize % (1 << 10);
					newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
				}
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);

				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;

				return fillSeq3(newNode3, node3.length, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, startIndex, size + suffixSize, suffix);
			}

			private «genericName(4)» appendSizedToSeq4(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4(1, maxSize);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[0] = newNode3;

				return fillSeq4(newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, startIndex, size + suffixSize, suffix);
			}

			private «genericName(5)» appendSizedToSeq5(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5(1, maxSize);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[0] = newNode4;

				return fillSeq5(newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[0] = newNode4;
				for (int index5 = 1; index5 < 32; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new «diamondName(3)»(node3, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final int maxSize = size - tail.length - 32*node3[node3.length - 1].length + (1 << 10) + prefixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 15)) {
					return prependSizedToSeq3(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return prependSizedToSeq4(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return prependSizedToSeq5(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(3)» prependSizedToSeq3(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][] newNode3 = allocateNode3FromStart(node3.length, maxSize);
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);

				final «type.javaName»[][] newNode2;
				if (node3.length < newNode3.length) {
					newNode2 = new «type.javaName»[32][];
				} else {
					final int totalSize2 = (maxSize % (1 << 10) == 0) ? (1 << 10) : maxSize % (1 << 10);
					newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
				}
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);

				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[newNode2.length - node2.length - 1], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - node3.length] = newNode2;
				final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);

				return fillSeq3FromStart(newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex,
						size + prefixSize, prefix);
			}

			private «genericName(4)» prependSizedToSeq4(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4FromStart(1, maxSize);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 1, newNode3, 33 - node3.length, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, 32 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[newNode4.length - 1] = newNode3;
				final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);

				return fillSeq4FromStart(newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[31 - node2.length], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private «genericName(5)» prependSizedToSeq5(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5FromStart(1, maxSize);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 1, newNode3, 33 - node3.length, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, 32 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[newNode5.length - 1] = newNode4;
				final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[31 - node2.length], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 1, newNode3, 33 - node3.length, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, 32 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[31] = newNode4;
				for (int index5 = 0; index5 < 31; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[31 - node2.length], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				builder.node2 = new «type.javaName»[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.index3 = node3.length;
				builder.startIndex = startIndex;
				builder.size = size;
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				final «type.javaName»[] array = new «type.javaName»[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[][] node2 : node3) {
					for (final «type.javaName»[] node1 : node2) {
						System.arraycopy(node1, 0, array, index, 32);
						index += 32;
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(3)»(node3, init, tail);
			}
		}
	''' }

	def seq4SourceCode() { '''
		final class «genericName(4)» extends «genericName» {
			final «type.javaName»[][][][] node4;
			final «type.javaName»[] init;
			final «type.javaName»[] tail;
			final int startIndex;
			final int size;

			«shortName»4(final «type.javaName»[][][][] node4, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size) {
				this.node4 = node4;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final «type.javaName»[][][] lastNode3 = node4[node4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];

					assert node4.length >= 2 && node4.length <= 32 : "node4.length = " + node4.length;
					assert init.length >= 1 && init.length <= 32 : "init.length = " + init.length;
					assert tail.length >= 1 && tail.length <= 32 : "tail.length = " + tail.length;
					assert size >= 31*32*32 + 2 && size <= (1 << 20) : "size = " + size;

					assert node4[0].length >= 1 && node4[0].length <= 32 : "node3.length = " + node4[0].length;
					assert lastNode3.length >= 1 && lastNode3.length <= 32 : "node3.length = " + lastNode3.length;

					assert node4[0][0].length <= 31 : "node2.length = " + node4[0][0].length;
					assert lastNode2.length <= 31 : "node2.length = " + lastNode2.length;
					assert node4[0][0].length != 0 || node4[0][0] == EMPTY_NODE2;
					assert lastNode2.length != 0 || lastNode2 == EMPTY_NODE2;

					for (int i = 1; i < node4.length - 1; i++) {
						assert node4[i].length == 32 : "node3.length = " + node4[i].length;
						for (final «type.javaName»[][] node2 : node4[i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 1; i < node4[0].length; i++) {
						assert node4[0][i].length == 32 : "node2.length = " + node4[0][i].length;
					}
					for (int i = 0; i < lastNode3.length - 1; i++) {
						assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
					}

					for (final «type.javaName»[][][] node3 : node4) {
						for (final «type.javaName»[][] node2 : node3) {
							for (final «type.javaName»[] node1 : node2) {
								assert node1.length == 32 : "node1.length = " + node1.length;
								for (final Object value : node1) {
									assert value != null;
								}
							}
						}
					}
					for (final Object value : init) {
						assert value != null;
					}
					for (final Object value : tail) {
						assert value != null;
					}

					if (node4.length == 2) {
						assert node4[0].length + node4[1].length >= 33;
					}

					assert 32*node4[0][0].length + 32*32*(node4[0].length - 1) + 32*lastNode2.length + 32*32*(lastNode3.length - 1) +
							32*32*32*(node4.length - 2) + init.length + tail.length == size : "size = " + size;
					assert startIndex == calculateSeq4StartIndex(node4, init) : "startIndex = " + startIndex;
				}
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «type.genericName» head() {
				return «type.genericCast»init[0];
			}

			@Override
			public «type.genericName» last() {
				return «type.genericCast»tail[tail.length - 1];
			}

			@Override
			public «genericName» init() {
				if (tail.length == 1) {
					final «type.javaName»[][][] lastNode3 = node4[node4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (node4.length == 2) {
								final «type.javaName»[][][] node3 = node4[0];
								final «type.javaName»[][][] newNode3 = node3.clone();
								final «type.javaName»[][] node2 = node3[node3.length - 1];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new «diamondName(3)»(newNode3, init, node2[node2.length - 1], startIndex, size - 1);
							} else {
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length - 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 2);
								final «type.javaName»[][][] node3 = node4[node4.length - 2];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[node4.length - 2] = newNode3;
								final «type.javaName»[][] node2 = node3[node3.length - 1];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new «diamondName(4)»(newNode4, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							if (node4.length == 2) {
								final «type.javaName»[][][] firstNode3 = node4[0];
								if (firstNode3.length + lastNode3.length == 33) {
									final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(lastNode3, 0, newNode3, firstNode3.length, lastNode3.length - 1);
									final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
									final «type.javaName»[][] node2 = lastNode3[lastNode3.length - 2];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode3[31] = newNode2;
									final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
									return new «diamondName(3)»(newNode3, init, node2[31], newStartIndex, size - 1);
								}
							}

							final «type.javaName»[][][][] newNode4 = node4.clone();
							final «type.javaName»[][][] newNode3 = new «type.javaName»[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[node4.length - 1] = newNode3;
							final «type.javaName»[][] node2 = lastNode3[lastNode3.length - 2];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new «diamondName(4)»(newNode4, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final «type.javaName»[][][][] newNode4 = node4.clone();
						final «type.javaName»[][][] newNode3 = lastNode3.clone();
						newNode4[node4.length - 1] = newNode3;
						final «type.javaName»[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new «diamondName(4)»(newNode4, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new «diamondName(4)»(node4, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public «genericName» tail() {
				if (init.length == 1) {
					final «type.javaName»[][][] firstNode3 = node4[0];
					final «type.javaName»[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (node4.length == 2) {
								final «type.javaName»[][][] node3 = node4[1];
								final «type.javaName»[][][] newNode3 = node3.clone();
								final «type.javaName»[][] node2 = node3[0];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new «diamondName(3)»(newNode3, node2[0], tail, 0, size - 1);
							} else {
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length - 1][][][];
								System.arraycopy(node4, 2, newNode4, 1, node4.length - 2);
								final «type.javaName»[][][] node3 = node4[1];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final «type.javaName»[][] node2 = node3[0];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new «diamondName(4)»(newNode4, node2[0], tail, 0, size - 1);
							}
						} else {
							if (node4.length == 2) {
								final «type.javaName»[][][] lastNode3 = node4[1];
								if (firstNode3.length + lastNode3.length == 33) {
									final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
									System.arraycopy(firstNode3, 1, newNode3, 0, firstNode3.length - 1);
									System.arraycopy(lastNode3, 0, newNode3, firstNode3.length - 1, lastNode3.length);
									final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
									final «type.javaName»[][] node2 = firstNode3[1];
									System.arraycopy(node2, 1, newNode2, 0, 31);
									newNode3[0] = newNode2;
									final int newStartIndex = calculateSeq3StartIndex(newNode3, node2[0]);
									return new «diamondName(3)»(newNode3, node2[0], tail, newStartIndex, size - 1);
								}
							}

							final «type.javaName»[][][][] newNode4 = node4.clone();
							final «type.javaName»[][][] newNode3 = new «type.javaName»[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final «type.javaName»[][] node2 = firstNode3[1];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new «diamondName(4)»(newNode4, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final «type.javaName»[][][][] newNode4 = node4.clone();
						final «type.javaName»[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new «diamondName(4)»(newNode4, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new «diamondName(4)»(node4, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final «type.javaName»[][] node2) {
				return (index4 == 0 && index3 == 0) ? «index»2(idx) + node2.length - 32 : «index»2(idx);
			}

			private static int index3(final int idx, final int index4, final «type.javaName»[][][] node3) {
				return (index4 == 0) ? «index»3(idx) + node3.length - 32 : «index»3(idx);
			}

			@Override
			public «type.genericName» get(final int index) {
				try {
					if (index < init.length) {
						return «type.genericCast»init[index];
					} else if (index >= size - tail.length) {
						return «type.genericCast»tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index4 = index4(idx);
						final «type.javaName»[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, node3);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);
						return «type.genericCast»node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = init.clone();
						final «type.genericName» oldValue = «type.genericCast»init[index];
						final «type.genericName» newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new «diamondName(4)»(node4, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final «type.javaName»[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final «type.genericName» oldValue = «type.genericCast»tail[tailIndex];
						final «type.genericName» newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new «diamondName(4)»(node4, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						final int index4 = index4(idx);
						final «type.javaName»[][][] newNode3 = newNode4[index4].clone();
						final int index3 = index3(idx, index4, newNode3);
						final «type.javaName»[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, index4, newNode2);
						final «type.javaName»[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final «type.genericName» oldValue = «type.genericCast»newNode1[index1];
						final «type.genericName» newValue = f.apply(oldValue);
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new «diamondName(4)»(newNode4, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n < init.length) {
					final «type.javaName»[] node1 = new «type.javaName»[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new «diamondName(1)»(node1);
				} else if (n == init.length) {
					return new «diamondName(1)»(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new «diamondName(4)»(node4, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index4 = index4(idx);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new «type.javaName»[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final «type.javaName»[][] newNode2;
							if (index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final «type.javaName»[][] firstNode2 = node4[0][0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new «diamondName(2)»(newNode2, init, newTail, n);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							if (n <= (1 << 15) - calculateSeq3StartIndex(node4[0], init)) {
								final «type.javaName»[][][] newNode3;
								if (index4 == 0) {
									newNode3 = new «type.javaName»[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final «type.javaName»[][][] firstNode3 = node4[0];
									newNode3 = new «type.javaName»[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new «diamondName(3)»(newNode3, init, newTail, newStartIndex, n);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[index4 + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, index4);
								newNode4[index4] = newNode3;
								return new «diamondName(4)»(newNode4, init, newTail, startIndex, n);
							}
						}
					}
				}
			}

			@Override
			public «genericName» drop(final int n) {
				if (n >= size) {
					return empty«shortName»();
				} else if (n > size - tail.length) {
					final «type.javaName»[] node1 = new «type.javaName»[size - n];
					System.arraycopy(tail, n - size + tail.length, node1, 0, node1.length);
					return new «diamondName(1)»(node1);
				} else if (n == size - tail.length) {
					return new «diamondName(1)»(tail);
				} else if (n <= 0) {
					return this;
				} else if (n < init.length) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - n];
					System.arraycopy(init, n, newInit, 0, newInit.length);
					return new «diamondName(4)»(node4, newInit, tail, startIndex + n, size - n);
				} else {
					final int idx = n + startIndex;
					final int index4 = index4(idx);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);
					final int newSize = size - n;

					if (newSize <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[newSize];
						System.arraycopy(node1, index1, newNode1, 0, 32 - index1);
						System.arraycopy(tail, 0, newNode1, 32 - index1, tail.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newInit;
						if (index1 == 0) {
							newInit = node1;
						} else {
							newInit = new «type.javaName»[32 - index1];
							System.arraycopy(node1, index1, newInit, 0, newInit.length);
						}

						if (newSize <= 1024 - 32 + tail.length) {
							final «type.javaName»[][] newNode2;
							if (index4 == node4.length - 1 && index3 == node3.length - 1) {
								if (index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
								}
							} else {
								final «type.javaName»[][][] lastNode3 = node4[node4.length - 1];
								final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
								if (lastNode2.length == 0 && index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1 + lastNode2.length][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, node2.length - index2 - 1);
									System.arraycopy(lastNode2, 0, newNode2, node2.length - index2 - 1, lastNode2.length);
								}
							}
							return new «diamondName(2)»(newNode2, newInit, tail, newSize);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == node2.length - 1) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[node2.length - index2 - 1][];
								System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
							}

							final «type.javaName»[][][] lastNode3 = node4[node4.length - 1];
							if (newSize <= (1 << 15) - calculateSeq3EndIndex(lastNode3, tail)) {
								final «type.javaName»[][][] newNode3;
								if (index4 == node4.length - 1) {
									newNode3 = new «type.javaName»[node3.length - index3][][];
									System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								} else {
									newNode3 = new «type.javaName»[node3.length - index3 + lastNode3.length][][];
									System.arraycopy(node3, index3, newNode3, 0, node3.length - index3);
									System.arraycopy(lastNode3, 0, newNode3, node3.length - index3, lastNode3.length);
								}
								newNode3[0] = newNode2;
								final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);
								return new «diamondName(3)»(newNode3, newInit, tail, newStartIndex, newSize);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - index3][][];
								System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								newNode3[0] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length - index4][][][];
								System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
								newNode4[0] = newNode3;
								final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);
								return new «diamondName(4)»(newNode4, newInit, tail, newStartIndex, newSize);
							}
						}
					}
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				requireNonNull(value);
				if (init.length == 32) {
					final «type.javaName»[][][] node3 = node4[0];
					final «type.javaName»[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								final «type.javaName»[] newInit = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final «type.javaName»[][][][] newNode4 = node4.clone();
								newNode4[0] = newNode3;
								final «type.javaName»[][][][][] newNode5 = { { { EMPTY_NODE2 } }, newNode4 };
								if (startIndex != 0) {
									throw new IllegalStateException("startIndex != 0");
								}
								return new «diamondName(5)»(newNode5, newInit, tail, (1 << 20) - 1, size + 1);
							} else {
								final «type.javaName»[] newInit = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new «type.javaName»[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								if (startIndex != 0) {
									throw new IllegalStateException("startIndex != 0");
								}
								return new «diamondName(4)»(newNode4, newInit, tail, (1 << 15) - 1, size + 1);
							}
						} else {
							final «type.javaName»[] newInit = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							return new «diamondName(4)»(newNode4, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						return new «diamondName(4)»(newNode4, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new «diamondName(4)»(node4, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final «type.javaName»[][][] node3 = node4[node4.length - 1];
					final «type.javaName»[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								final «type.javaName»[] newTail = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[31] = newNode2;
								final «type.javaName»[][][][] newNode4 = node4.clone();
								newNode4[31] = newNode3;
								final «type.javaName»[][][][][] newNode5 = { newNode4, { { EMPTY_NODE2 } } };
								return new «diamondName(5)»(newNode5, init, newTail, startIndex, size + 1);
							} else {
								final «type.javaName»[] newTail = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new «type.javaName»[][][] { EMPTY_NODE2 };
								return new «diamondName(4)»(newNode4, init, newTail, startIndex, size + 1);
							}
						} else {
							final «type.javaName»[] newTail = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							return new «diamondName(4)»(newNode4, init, newTail, startIndex, size + 1);
						}
					} else {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						return new «diamondName(4)»(newNode4, init, newTail, startIndex, size + 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new «diamondName(4)»(node4, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new «diamondName(4)»(node4, init, newTail, startIndex, size + suffixSize);
				}

				final int maxSize = size - init.length - 32*node4[0][0].length - (1 << 10)*(node4[0].length - 1) + (1 << 15) + suffixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 20)) {
					return appendSizedToSeq4(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return appendSizedToSeq5(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(4)» appendSizedToSeq4(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4(node4.length, maxSize);
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);

				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node4.length < newNode4.length) {
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
				} else {
					final int totalSize3 = (maxSize % (1 << 15) == 0) ? (1 << 15) : maxSize % (1 << 15);
					newNode3 = allocateNode3(node3.length, totalSize3);
					if (node3.length < newNode3.length) {
						newNode2 = new «type.javaName»[32][];
					} else {
						final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
						newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
					}
				}
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				newNode4[node4.length - 1] = newNode3;

				return fillSeq4(newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, startIndex, size + suffixSize, suffix);
			}

			private «genericName(5)» appendSizedToSeq5(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5(1, maxSize);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[node4.length - 1] = newNode3;
				for (int index4 = node4.length; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[0] = newNode4;

				return fillSeq5(newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[node4.length - 1] = newNode3;
				for (int index4 = node4.length; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[0] = newNode4;
				for (int index5 = 1; index5 < 32; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new «diamondName(4)»(node4, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final int maxSize = size - tail.length - 32*node3[node3.length - 1].length - (1 << 10)*(node3.length - 1) +
						(1 << 15) + prefixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 20)) {
					return prependSizedToSeq4(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return prependSizedToSeq5(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(4)» prependSizedToSeq4(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4FromStart(node4.length, maxSize);
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);

				final «type.javaName»[][][] node3 = node4[0];
				final «type.javaName»[][] node2 = node3[0];
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node4.length < newNode4.length) {
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
				} else {
					final int totalSize3 = (maxSize % (1 << 15) == 0) ? (1 << 15) : maxSize % (1 << 15);
					newNode3 = allocateNode3FromStart(node3.length, totalSize3);
					if (node3.length < newNode3.length) {
						newNode2 = new «type.javaName»[32][];
					} else {
						final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
						newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
					}
				}
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[newNode2.length - node2.length - 1], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - node3.length] = newNode2;
				newNode4[newNode4.length - node4.length] = newNode3;
				final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);

				return fillSeq4FromStart(newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private «genericName(5)» prependSizedToSeq5(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5FromStart(1, maxSize);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][][] node3 = node4[0];
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[32 - node4.length] = newNode3;
				for (int index4 = 0; index4 < 32 - node4.length; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[newNode5.length - 1] = newNode4;
				final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][][] node3 = node4[0];
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[32 - node4.length] = newNode3;
				for (int index4 = 0; index4 < 32 - node4.length; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[31] = newNode4;
				for (int index5 = 0; index5 < 31; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex,
						size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				builder.node2 = new «type.javaName»[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 0, builder.node4, 0, node4.length - 1);
				builder.node4[node4.length - 1] = builder.node3;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.index3 = node3.length;
				builder.index4 = node4.length;
				builder.startIndex = startIndex;
				builder.size = size;
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				final «type.javaName»[] array = new «type.javaName»[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[][][] node3 : node4) {
					for (final «type.javaName»[][] node2 : node3) {
						for (final «type.javaName»[] node1 : node2) {
							System.arraycopy(node1, 0, array, index, 32);
							index += 32;
						}
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(4)»(node4, init, tail);
			}
		}
	''' }

	def seq5SourceCode() { '''
		final class «genericName(5)» extends «genericName» {
			final «type.javaName»[][][][][] node5;
			final «type.javaName»[] init;
			final «type.javaName»[] tail;
			final int startIndex;
			final int size;

			«shortName»5(final «type.javaName»[][][][][] node5, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size) {
				this.node5 = node5;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final «type.javaName»[][][][] lastNode4 = node5[node5.length - 1];
					final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];

					assert node5.length >= 2 && node5.length <= 32 : "node5.length = " + node5.length;
					assert init.length >= 1 && init.length <= 32 : "init.length = " + init.length;
					assert tail.length >= 1 && tail.length <= 32 : "tail.length = " + tail.length;
					assert size >= 31*32*32*32 + 2 && size <= (1 << 25) : "size = " + size;

					assert node5[0].length >= 1 && node5[0].length <= 32 : "node4.length = " + node5[0].length;
					assert lastNode4.length >= 1 && lastNode4.length <= 32 : "node4.length = " + lastNode4.length;
					assert node5[0][0].length >= 1 && node5[0][0].length <= 32 : "node3.length = " + node5[0][0].length;
					assert lastNode3.length >= 1 && lastNode3.length <= 32 : "node3.length = " + lastNode3.length;

					assert node5[0][0][0].length <= 31 : "node2.length = " + node5[0][0][0].length;
					assert lastNode2.length <= 31 : "node2.length = " + lastNode2.length;
					assert node5[0][0][0].length != 0 || node5[0][0][0] == EMPTY_NODE2;
					assert lastNode2.length != 0 || lastNode2 == EMPTY_NODE2;

					for (int i = 1; i < node5.length - 1; i++) {
						assert node5[i].length == 32 : "node4.length = " + node5[i].length;
						for (final «type.javaName»[][][] node3 : node5[i]) {
							assert node3.length == 32 : "node3.length = " + node3.length;
							for (final «type.javaName»[][] node2 : node3) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
					}
		
					for (int i = 1; i < node5[0].length; i++) {
						assert node5[0][i].length == 32 : "node3.length = " + node5[0][i].length;
						for (final «type.javaName»[][] node2 : node5[0][i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 0; i < lastNode4.length - 1; i++) {
						assert lastNode4[i].length == 32 : "node3.length = " + lastNode4[i].length;
						for (final «type.javaName»[][] node2 : lastNode4[i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 1; i < node5[0][0].length; i++) {
						assert node5[0][0][i].length == 32 : "node2.length = " + node5[0][0][i].length;
					}
					for (int i = 0; i < lastNode3.length - 1; i++) {
						assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
					}
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									assert node1.length == 32 : "node1.length = " + node1.length;
									for (final Object value : node1) {
										assert value != null;
									}
								}
							}
						}
					}
					for (final Object value : init) {
						assert value != null;
					}
					for (final Object value : tail) {
						assert value != null;
					}

					if (node5.length == 2) {
						assert node5[0].length + node5[1].length >= 33;
					}

					assert 32*node5[0][0][0].length + 32*32*(node5[0][0].length - 1) + 32*32*32*(node5[0].length - 1) +
							32*lastNode2.length + 32*32*(lastNode3.length - 1) + 32*32*32*(lastNode4.length - 1) +
							32*32*32*32*(node5.length - 2) + init.length + tail.length == size : "size = " + size;
					assert startIndex == calculateSeq5StartIndex(node5, init) : "startIndex = " + startIndex;
				}
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «type.genericName» head() {
				return «type.genericCast»init[0];
			}

			@Override
			public «type.genericName» last() {
				return «type.genericCast»tail[tail.length - 1];
			}

			@Override
			public «genericName» init() {
				if (tail.length == 1) {
					final «type.javaName»[][][][] lastNode4 = node5[node5.length - 1];
					final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (lastNode4.length == 1) {
								if (node5.length == 2) {
									final «type.javaName»[][][][] node4 = node5[0];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									final «type.javaName»[][][] node3 = node4[node4.length - 1];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][] node2 = node3[node3.length - 1];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new «diamondName(4)»(newNode4, init, node2[node2.length - 1], startIndex, size - 1);
								} else {
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length - 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 2);
									final «type.javaName»[][][][] node4 = node5[node5.length - 2];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode5[node5.length - 2] = newNode4;
									final «type.javaName»[][][] node3 = node4[node4.length - 1];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][] node2 = node3[node3.length - 1];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new «diamondName(5)»(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
								}
							} else {
								if (node5.length == 2) {
									final «type.javaName»[][][][] firstNode4 = node5[0];
									if (firstNode4.length + lastNode4.length == 33) {
										final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(lastNode4, 0, newNode4, firstNode4.length, lastNode4.length - 2);
										final «type.javaName»[][][] node3 = lastNode4[lastNode4.length - 2];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[31] = newNode3;
										final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
										final «type.javaName»[][] node2 = node3[31];
										System.arraycopy(node2, 0, newNode2, 0, 31);
										newNode3[31] = newNode2;
										final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
										return new «diamondName(4)»(newNode4, init, node2[31], newStartIndex, size - 1);
									}
								}

								final «type.javaName»[][][][][] newNode5 = node5.clone();
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[lastNode4.length - 1][][][];
								System.arraycopy(lastNode4, 0, newNode4, 0, lastNode4.length - 2);
								newNode5[node5.length - 1] = newNode4;
								final «type.javaName»[][][] node3 = lastNode4[lastNode4.length - 2];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[lastNode4.length - 2] = newNode3;
								final «type.javaName»[][] node2 = node3[node3.length - 1];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new «diamondName(5)»(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							final «type.javaName»[][][][] newNode4 = lastNode4.clone();
							newNode5[node5.length - 1] = newNode4;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[lastNode4.length - 1] = newNode3;
							final «type.javaName»[][] node2 = lastNode3[lastNode3.length - 2];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new «diamondName(5)»(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						final «type.javaName»[][][][] newNode4 = lastNode4.clone();
						newNode5[node5.length - 1] = newNode4;
						final «type.javaName»[][][] newNode3 = lastNode3.clone();
						newNode4[lastNode4.length - 1] = newNode3;
						final «type.javaName»[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new «diamondName(5)»(newNode5, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new «diamondName(5)»(node5, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public «genericName» tail() {
				if (init.length == 1) {
					final «type.javaName»[][][][] firstNode4 = node5[0];
					final «type.javaName»[][][] firstNode3 = firstNode4[0];
					final «type.javaName»[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (firstNode4.length == 1) {
								if (node5.length == 2) {
									final «type.javaName»[][][][] node4 = node5[1];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									final «type.javaName»[][][] node3 = node4[0];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][] node2 = node3[0];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new «diamondName(4)»(newNode4, node2[0], tail, 0, size - 1);
								} else {
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length - 1][][][][];
									System.arraycopy(node5, 2, newNode5, 1, node5.length - 2);
									final «type.javaName»[][][][] node4 = node5[1];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode5[0] = newNode4;
									final «type.javaName»[][][] node3 = node4[0];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][] node2 = node3[0];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new «diamondName(5)»(newNode5, node2[0], tail, 0, size - 1);
								}
							} else {
								if (node5.length == 2) {
									final «type.javaName»[][][][] lastNode4 = node5[1];
									if (firstNode4.length + lastNode4.length == 33) {
										final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
										System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
										System.arraycopy(lastNode4, 0, newNode4, firstNode4.length - 1, lastNode4.length);
										final «type.javaName»[][][] node3 = firstNode4[1];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
										final «type.javaName»[][] node2 = node3[0];
										System.arraycopy(node2, 1, newNode2, 0, 31);
										newNode3[0] = newNode2;
										final int newStartIndex = calculateSeq4StartIndex(newNode4, node2[0]);
										return new «diamondName(4)»(newNode4, node2[0], tail, newStartIndex, size - 1);
									}
								}

								final «type.javaName»[][][][][] newNode5 = node5.clone();
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[firstNode4.length - 1][][][];
								System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
								newNode5[0] = newNode4;
								final «type.javaName»[][][] node3 = firstNode4[1];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final «type.javaName»[][] node2 = node3[0];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new «diamondName(5)»(newNode5, node2[0], tail, startIndex + 1, size - 1);
							}
						} else {
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							final «type.javaName»[][][][] newNode4 = firstNode4.clone();
							newNode5[0] = newNode4;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final «type.javaName»[][] node2 = firstNode3[1];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new «diamondName(5)»(newNode5, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						final «type.javaName»[][][][] newNode4 = firstNode4.clone();
						newNode5[0] = newNode4;
						final «type.javaName»[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new «diamondName(5)»(newNode5, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new «diamondName(5)»(node5, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final «type.javaName»[][] node2) {
				return (index5 == 0 && index4 == 0 && index3 == 0) ? «index»2(idx) + node2.length - 32 : «index»2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final «type.javaName»[][][] node3) {
				return (index5 == 0 && index4 == 0) ? «index»3(idx) + node3.length - 32 : «index»3(idx);
			}

			private static int index4(final int idx, final int index5, final «type.javaName»[][][][] node4) {
				return (index5 == 0) ? «index»4(idx) + node4.length - 32 : «index»4(idx);
			}

			@Override
			public «type.genericName» get(final int index) {
				try {
					if (index < init.length) {
						return «type.genericCast»init[index];
					} else if (index >= size - tail.length) {
						return «type.genericCast»tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index5 = index5(idx);
						final «type.javaName»[][][][] node4 = node5[index5];
						final int index4 = index4(idx, index5, node4);
						final «type.javaName»[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, index5, node3);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, index5, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);
						return «type.genericCast»node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = init.clone();
						final «type.genericName» oldValue = «type.genericCast»init[index];
						final «type.genericName» newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new «diamondName(5)»(node5, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final «type.javaName»[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final «type.genericName» oldValue = «type.genericCast»tail[tailIndex];
						final «type.genericName» newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new «diamondName(5)»(node5, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						final int index5 = index5(idx);
						final «type.javaName»[][][][] newNode4 = newNode5[index5].clone();
						final int index4 = index4(idx, index5, newNode4);
						final «type.javaName»[][][] newNode3 = newNode4[index4].clone();
						final int index3 = index3(idx, index4, index5, newNode3);
						final «type.javaName»[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, index4, index5, newNode2);
						final «type.javaName»[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final «type.genericName» oldValue = «type.genericCast»newNode1[index1];
						final «type.genericName» newValue = f.apply(oldValue);
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new «diamondName(5)»(newNode5, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n < init.length) {
					final «type.javaName»[] node1 = new «type.javaName»[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new «diamondName(1)»(node1);
				} else if (n == init.length) {
					return new «diamondName(1)»(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new «diamondName(5)»(node5, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index5 = index5(idx);
					final «type.javaName»[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, node4);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new «type.javaName»[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final «type.javaName»[][] newNode2;
							if (index5 == 0 && index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final «type.javaName»[][] firstNode2 = node5[0][0][0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new «diamondName(2)»(newNode2, init, newTail, n);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							if (n <= (1 << 15) - calculateSeq3StartIndex(node5[0][0], init)) {
								final «type.javaName»[][][] newNode3;
								if (index5 == 0 && index4 == 0) {
									newNode3 = new «type.javaName»[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final «type.javaName»[][][] firstNode3 = node5[0][0];
									newNode3 = new «type.javaName»[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new «diamondName(3)»(newNode3, init, newTail, newStartIndex, n);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;

								if (n <= (1 << 20) - calculateSeq4StartIndex(node5[0], init)) {
									final «type.javaName»[][][][] newNode4;
									if (index5 == 0) {
										newNode4 = new «type.javaName»[index4 + 1][][][];
										System.arraycopy(node4, 0, newNode4, 0, index4);
										newNode4[index4] = newNode3;
									} else {
										final «type.javaName»[][][][] firstNode4 = node5[0];
										newNode4 = new «type.javaName»[firstNode4.length + index4 + 1][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(node4, 0, newNode4, firstNode4.length, index4);
										newNode4[firstNode4.length + index4] = newNode3;
									}
									final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
									return new «diamondName(4)»(newNode4, init, newTail, newStartIndex, n);
								} else {
									final «type.javaName»[][][][] newNode4 = new «type.javaName»[index4 + 1][][][];
									System.arraycopy(node4, 0, newNode4, 0, index4);
									newNode4[index4] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[index5 + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, index5);
									newNode5[index5] = newNode4;
									return new «diamondName(5)»(newNode5, init, newTail, startIndex, n);
								}
							}
						}
					}
				}
			}

			@Override
			public «genericName» drop(final int n) {
				if (n >= size) {
					return empty«shortName»();
				} else if (n > size - tail.length) {
					final «type.javaName»[] node1 = new «type.javaName»[size - n];
					System.arraycopy(tail, n - size + tail.length, node1, 0, node1.length);
					return new «diamondName(1)»(node1);
				} else if (n == size - tail.length) {
					return new «diamondName(1)»(tail);
				} else if (n <= 0) {
					return this;
				} else if (n < init.length) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - n];
					System.arraycopy(init, n, newInit, 0, newInit.length);
					return new «diamondName(5)»(node5, newInit, tail, startIndex + n, size - n);
				} else {
					final int idx = n + startIndex;
					final int index5 = index5(idx);
					final «type.javaName»[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, node4);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);
					final int newSize = size - n;

					if (newSize <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[newSize];
						System.arraycopy(node1, index1, newNode1, 0, 32 - index1);
						System.arraycopy(tail, 0, newNode1, 32 - index1, tail.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newInit;
						if (index1 == 0) {
							newInit = node1;
						} else {
							newInit = new «type.javaName»[32 - index1];
							System.arraycopy(node1, index1, newInit, 0, newInit.length);
						}

						if (newSize <= 1024 - 32 + tail.length) {
							final «type.javaName»[][] newNode2;
							if (index5 == node5.length - 1 && index4 == node4.length - 1 && index3 == node3.length - 1) {
								if (index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
								}
							} else {
								final «type.javaName»[][][][] lastNode4 = node5[node5.length - 1];
								final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
								final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
								if (lastNode2.length == 0 && index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1 + lastNode2.length][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, node2.length - index2 - 1);
									System.arraycopy(lastNode2, 0, newNode2, node2.length - index2 - 1, lastNode2.length);
								}
							}
							return new «diamondName(2)»(newNode2, newInit, tail, newSize);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == node2.length - 1) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[node2.length - index2 - 1][];
								System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
							}

							final «type.javaName»[][][][] lastNode4 = node5[node5.length - 1];
							final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
							if (newSize <= (1 << 15) - calculateSeq3EndIndex(lastNode3, tail)) {
								final «type.javaName»[][][] newNode3;
								if (index5 == node5.length - 1 && index4 == node4.length - 1) {
									newNode3 = new «type.javaName»[node3.length - index3][][];
									System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								} else {
									newNode3 = new «type.javaName»[node3.length - index3 + lastNode3.length][][];
									System.arraycopy(node3, index3, newNode3, 0, node3.length - index3);
									System.arraycopy(lastNode3, 0, newNode3, node3.length - index3, lastNode3.length);
								}
								newNode3[0] = newNode2;
								final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);
								return new «diamondName(3)»(newNode3, newInit, tail, newStartIndex, newSize);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - index3][][];
								System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								newNode3[0] = newNode2;

								if (newSize <= (1 << 20) - calculateSeq4EndIndex(lastNode3, tail)) {
									final «type.javaName»[][][][] newNode4;
									if (index5 == node5.length - 1) {
										newNode4 = new «type.javaName»[node4.length - index4][][][];
										System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
									} else {
										newNode4 = new «type.javaName»[node4.length - index4 + lastNode4.length][][][];
										System.arraycopy(node4, index4, newNode4, 0, node4.length - index4);
										System.arraycopy(lastNode4, 0, newNode4, node4.length - index4, lastNode4.length);
									}
									newNode4[0] = newNode3;
									final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);
									return new «diamondName(4)»(newNode4, newInit, tail, newStartIndex, newSize);
								} else {
									final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length - index4][][][];
									System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
									newNode4[0] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length - index5][][][][];
									System.arraycopy(node5, index5, newNode5, 0, newNode5.length);
									newNode5[0] = newNode4;
									final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);
									return new «diamondName(5)»(newNode5, newInit, tail, newStartIndex, newSize);
								}
							}
						}
					}
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				requireNonNull(value);
				if (init.length == 32) {
					final «type.javaName»[][][][] node4 = node5[0];
					final «type.javaName»[][][] node3 = node4[0];
					final «type.javaName»[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									final «type.javaName»[] newInit = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][][][][] newNode5 = node5.clone();
									newNode5[0] = newNode4;
									final «type.javaName»[][][][][][] newNode6 = { { { { EMPTY_NODE2 } } }, newNode5 };
									if (startIndex != 0) {
										throw new IllegalStateException("startIndex != 0");
									}
									return new «diamondName(6)»(newNode6, newInit, tail, (1 << 25) - 1, size + 1);
								} else {
									final «type.javaName»[] newInit = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length + 1][][][][];
									System.arraycopy(node5, 1, newNode5, 2, node5.length - 1);
									newNode5[0] = new «type.javaName»[][][][] { { EMPTY_NODE2 } };
									newNode5[1] = newNode4;
									if (startIndex != 0) {
										throw new IllegalStateException("startIndex != 0");
									}
									return new «diamondName(5)»(newNode5, newInit, tail, (1 << 20) - 1, size + 1);
								}
							} else {
								final «type.javaName»[] newInit = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new «type.javaName»[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								final «type.javaName»[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								return new «diamondName(5)»(newNode5, newInit, tail, startIndex - 1, size + 1);
							}
						} else {
							final «type.javaName»[] newInit = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							return new «diamondName(5)»(newNode5, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						return new «diamondName(5)»(newNode5, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new «diamondName(5)»(node5, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final «type.javaName»[][][][] node4 = node5[node5.length - 1];
					final «type.javaName»[][][] node3 = node4[node4.length - 1];
					final «type.javaName»[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									final «type.javaName»[] newTail = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[31] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[31] = newNode3;
									final «type.javaName»[][][][][] newNode5 = node5.clone();
									newNode5[31] = newNode4;
									final «type.javaName»[][][][][][] newNode6 = { newNode5, { { { EMPTY_NODE2 } } } };
									return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
								} else {
									final «type.javaName»[] newTail = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[node3.length - 1] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
									newNode5[node5.length - 1] = newNode4;
									newNode5[node5.length] = new «type.javaName»[][][][] { { EMPTY_NODE2 } };
									return new «diamondName(5)»(newNode5, init, newTail, startIndex, size + 1);
								}
							} else {
								final «type.javaName»[] newTail = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new «type.javaName»[][][] { EMPTY_NODE2 };
								final «type.javaName»[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								return new «diamondName(5)»(newNode5, init, newTail, startIndex, size + 1);
							}
						} else {
							final «type.javaName»[] newTail = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							return new «diamondName(5)»(newNode5, init, newTail, startIndex, size + 1);
						}
					} else {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						return new «diamondName(5)»(newNode5, init, newTail, startIndex, size + 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new «diamondName(5)»(node5, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new «diamondName(5)»(node5, init, newTail, startIndex, size + suffixSize);
				}

				final int maxSize = size - init.length - 32*node5[0][0][0].length - (1 << 10)*(node5[0][0].length - 1)
						- (1 << 15)*(node5[0].length - 1) + (1 << 20) + suffixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 25)) {
					return appendSizedToSeq5(suffix, suffixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(5)» appendSizedToSeq5(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5(node5.length, maxSize);
				System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);

				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				final «type.javaName»[][][][] newNode4;
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node5.length < newNode5.length) {
					newNode4 = new «type.javaName»[32][][][];
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
					for (int index4 = node4.length; index4 < 32; index4++) {
						newNode4[index4] = new «type.javaName»[32][32][32];
					}
				} else {
					final int totalSize4 = (maxSize % (1 << 20) == 0) ? (1 << 20) : maxSize % (1 << 20);
					newNode4 = allocateNode4(node4.length, totalSize4);
					if (node4.length < newNode4.length) {
						newNode3 = new «type.javaName»[32][][];
						newNode2 = new «type.javaName»[32][];
						for (int index3 = node3.length; index3 < 32; index3++) {
							newNode3[index3] = new «type.javaName»[32][32];
						}
					} else {
						final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
						newNode3 = allocateNode3(node3.length, totalSize3);
						if (node3.length < newNode3.length) {
							newNode2 = new «type.javaName»[32][];
						} else {
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
						}
					}
				}
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				newNode4[node4.length - 1] = newNode3;
				newNode5[node5.length - 1] = newNode4;

				return fillSeq5(newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[node4.length - 1] = newNode3;
				for (int index4 = node4.length; index4 < 32; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[node5.length - 1] = newNode4;
				for (int index5 = node5.length; index5 < 32; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new «diamondName(5)»(node5, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];

				final int maxSize = size - tail.length - 32*node3[node3.length - 1].length - (1 << 10)*(node3.length - 1)
						- (1 << 15)*(node4.length - 1) + (1 << 20) + prefixSize;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (maxSize <= (1 << 25)) {
					return prependSizedToSeq5(prefix, prefixSize, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(5)» prependSizedToSeq5(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5FromStart(node5.length, maxSize);
				System.arraycopy(node5, 1, newNode5, newNode5.length - node5.length + 1, node5.length - 1);

				final «type.javaName»[][][][] node4 = node5[0];
				final «type.javaName»[][][] node3 = node4[0];
				final «type.javaName»[][] node2 = node3[0];
				final «type.javaName»[][][][] newNode4;
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node5.length < newNode5.length) {
					newNode4 = new «type.javaName»[32][][][];
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
					for (int index4 = 0; index4 < 32 - node4.length; index4++) {
						newNode4[index4] = new «type.javaName»[32][32][32];
					}
				} else {
					final int totalSize4 = (maxSize % (1 << 20) == 0) ? (1 << 20) : maxSize % (1 << 20);
					newNode4 = allocateNode4FromStart(node4.length, totalSize4);
					if (node4.length < newNode4.length) {
						newNode3 = new «type.javaName»[32][][];
						newNode2 = new «type.javaName»[32][];
						for (int index3 = 0; index3 < 32 - node3.length; index3++) {
							newNode3[index3] = new «type.javaName»[32][32];
						}
					} else {
						final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
						newNode3 = allocateNode3FromStart(node3.length, totalSize3);
						if (node3.length < newNode3.length) {
							newNode2 = new «type.javaName»[32][];
						} else {
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
						}
					}
				}
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[newNode2.length - node2.length - 1], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - node3.length] = newNode2;
				newNode4[newNode4.length - node4.length] = newNode3;
				newNode5[newNode5.length - node5.length] = newNode4;
				final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, node5.length, newNode4, node4.length, newNode3, node3.length,
						newNode2, node2.length + 1, newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail,
						newStartIndex, size + prefixSize, prefix);
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
				System.arraycopy(node5, 1, newNode5, newNode5.length - node5.length + 1, node5.length - 1);
				final «type.javaName»[][][][] newNode4 = new «type.javaName»[32][][][];
				final «type.javaName»[][][][] node4 = node5[0];
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				final «type.javaName»[][][] newNode3 = new «type.javaName»[32][][];
				final «type.javaName»[][][] node3 = node4[0];
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
				final «type.javaName»[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new «type.javaName»[32][32];
				}
				newNode4[32 - node4.length] = newNode3;
				for (int index4 = 0; index4 < 32 - node4.length; index4++) {
					newNode4[index4] = new «type.javaName»[32][32][32];
				}
				newNode5[32 - node5.length] = newNode4;
				for (int index5 = 0; index5 < 32 - node5.length; index5++) {
					newNode5[index5] = new «type.javaName»[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex,
						size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				builder.node2 = new «type.javaName»[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 0, builder.node4, 0, node4.length - 1);
				builder.node4[node4.length - 1] = builder.node3;
				builder.node5 = new «type.javaName»[32][][][][];
				System.arraycopy(node5, 0, builder.node5, 0, node5.length - 1);
				builder.node5[node5.length - 1] = builder.node4;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.index3 = node3.length;
				builder.index4 = node4.length;
				builder.index5 = node5.length;
				builder.startIndex = startIndex;
				builder.size = size;
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				final «type.javaName»[] array = new «type.javaName»[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[][][][] node4 : node5) {
					for (final «type.javaName»[][][] node3 : node4) {
						for (final «type.javaName»[][] node2 : node3) {
							for (final «type.javaName»[] node1 : node2) {
								System.arraycopy(node1, 0, array, index, 32);
								index += 32;
							}
						}
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(5)»(node5, init, tail);
			}
		}
	''' }

	def seq6SourceCode() { '''
		final class «genericName(6)» extends «genericName» {
			final «type.javaName»[][][][][][] node6;
			final «type.javaName»[] init;
			final «type.javaName»[] tail;
			final int startIndex;
			final int size;

			«shortName»6(final «type.javaName»[][][][][][] node6, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size) {
				this.node6 = node6;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
					final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
					final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];

					assert node6.length >= 2 && node6.length <= 32 : "node6.length = " + node6.length;
					assert init.length >= 1 && init.length <= 32 : "init.length = " + init.length;
					assert tail.length >= 1 && tail.length <= 32 : "tail.length = " + tail.length;
					assert size >= 31*32*32*32*32 + 2 && size <= (1 << 30) : "size = " + size;

					assert node6[0].length >= 1 && node6[0].length <= 32 : "node5.length = " + node6[0].length;
					assert lastNode5.length >= 1 && lastNode5.length <= 32 : "node5.length = " + lastNode5.length;
					assert node6[0][0].length >= 1 && node6[0][0].length <= 32 : "node4.length = " + node6[0][0].length;
					assert lastNode4.length >= 1 && lastNode4.length <= 32 : "node4.length = " + lastNode4.length;
					assert node6[0][0][0].length >= 1 && node6[0][0][0].length <= 32 : "node3.length = " + node6[0][0][0].length;
					assert lastNode3.length >= 1 && lastNode3.length <= 32 : "node3.length = " + lastNode3.length;

					assert node6[0][0][0][0].length <= 31 : "node2.length = " + node6[0][0][0][0].length;
					assert lastNode2.length <= 31 : "node2.length = " + lastNode2.length;
					assert node6[0][0][0][0].length != 0 || node6[0][0][0][0] == EMPTY_NODE2;
					assert lastNode2.length != 0 || lastNode2 == EMPTY_NODE2;

					for (int i = 1; i < node6.length - 1; i++) {
						assert node6[i].length == 32 : "node5.length = " + node6[i].length;
						for (final «type.javaName»[][][][] node4 : node6[i]) {
							assert node4.length == 32 : "node4.length = " + node4.length;
							for (final «type.javaName»[][][] node3 : node4) {
								assert node3.length == 32 : "node3.length = " + node3.length;
								for (final «type.javaName»[][] node2 : node3) {
									assert node2.length == 32 : "node2.length = " + node2.length;
								}
							}
						}
					}

					for (int i = 1; i < node6[0].length; i++) {
						assert node6[0][i].length == 32 : "node4.length = " + node6[0][i].length;
						for (final «type.javaName»[][][] node3 : node6[0][i]) {
							assert node3.length == 32 : "node3.length = " + node3.length;
							for (final «type.javaName»[][] node2 : node3) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
					}
					for (int i = 0; i < lastNode5.length - 1; i++) {
						assert lastNode5[i].length == 32 : "node4.length = " + lastNode5[i].length;
						for (final «type.javaName»[][][] node3 : lastNode5[i]) {
							assert node3.length == 32 : "node3.length = " + node3.length;
							for (final «type.javaName»[][] node2 : node3) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
					}
					for (int i = 1; i < node6[0][0].length; i++) {
						assert node6[0][0][i].length == 32 : "node3.length = " + node6[0][0][i].length;
						for (final «type.javaName»[][] node2 : node6[0][0][i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 0; i < lastNode4.length - 1; i++) {
						assert lastNode4[i].length == 32 : "node3.length = " + lastNode4[i].length;
						for (final «type.javaName»[][] node2 : lastNode4[i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 1; i < node6[0][0][0].length; i++) {
						assert node6[0][0][0][i].length == 32 : "node2.length = " + node6[0][0][0][i].length;
					}
					for (int i = 0; i < lastNode3.length - 1; i++) {
						assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
					}
					for (final «type.javaName»[][][][][] node5 : node6) {
						for (final «type.javaName»[][][][] node4 : node5) {
							for (final «type.javaName»[][][] node3 : node4) {
								for (final «type.javaName»[][] node2 : node3) {
									for (final «type.javaName»[] node1 : node2) {
										assert node1.length == 32 : "node1.length = " + node1.length;
										for (final Object value : node1) {
											assert value != null;
										}
									}
								}
							}
						}
					}
					for (final Object value : init) {
						assert value != null;
					}
					for (final Object value : tail) {
						assert value != null;
					}

					if (node6.length == 2) {
						assert node6[0].length + node6[1].length >= 33;
					}

					assert 32*node6[0][0][0][0].length + 32*32*(node6[0][0][0].length - 1) +
							32*32*32*(node6[0][0].length - 1) + 32*32*32*32*(node6[0].length - 1) +
							32*lastNode2.length + 32*32*(lastNode3.length - 1) +
							32*32*32*(lastNode4.length - 1) + 32*32*32*32*(lastNode5.length - 1) +
							32*32*32*32*32*(node6.length - 2) + init.length + tail.length == size : "size = " + size;
					assert startIndex == calculateSeq6StartIndex(node6, init) : "startIndex = " + startIndex;
				}
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «type.genericName» head() {
				return «type.genericCast»init[0];
			}

			@Override
			public «type.genericName» last() {
				return «type.genericCast»tail[tail.length - 1];
			}

			@Override
			public «genericName» init() {
				if (tail.length == 1) {
					final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
					final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
					final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (lastNode4.length == 1) {
								if (lastNode5.length == 1) {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] node5 = node6[0];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										final «type.javaName»[][][][] node4 = node5[node5.length - 1];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[node5.length - 1] = newNode4;
										final «type.javaName»[][][] node3 = node4[node4.length - 1];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[node4.length - 1] = newNode3;
										final «type.javaName»[][] node2 = node3[node3.length - 1];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
										newNode3[node3.length - 1] = newNode2;
										return new «diamondName(5)»(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
									} else {
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length - 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, node6.length - 2);
										final «type.javaName»[][][][][] node5 = node6[node6.length - 2];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode6[node6.length - 2] = newNode5;
										final «type.javaName»[][][][] node4 = node5[node5.length - 1];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[node5.length - 1] = newNode4;
										final «type.javaName»[][][] node3 = node4[node4.length - 1];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[node4.length - 1] = newNode3;
										final «type.javaName»[][] node2 = node3[node3.length - 1];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
										newNode3[node3.length - 1] = newNode2;
										return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
									}
								} else {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] firstNode5 = node6[0];
										if (firstNode5.length + lastNode5.length == 33) {
											final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
											System.arraycopy(firstNode5, 0, newNode5, 0, firstNode5.length);
											System.arraycopy(lastNode5, 0, newNode5, firstNode5.length, lastNode5.length - 2);
											final «type.javaName»[][][][] node4 = lastNode5[lastNode5.length - 2];
											final «type.javaName»[][][][] newNode4 = node4.clone();
											newNode5[31] = newNode4;
											final «type.javaName»[][][] node3 = node4[31];
											final «type.javaName»[][][] newNode3 = node3.clone();
											newNode4[31] = newNode3;
											final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
											final «type.javaName»[][] node2 = node3[31];
											System.arraycopy(node2, 0, newNode2, 0, 31);
											newNode3[31] = newNode2;
											final int newStartIndex = calculateSeq5StartIndex(newNode5, init);
											return new «diamondName(5)»(newNode5, init, node2[31], newStartIndex, size - 1);
										}
									}

									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[lastNode5.length - 1][][][][];
									System.arraycopy(lastNode5, 0, newNode5, 0, lastNode5.length - 2);
									newNode6[node6.length - 1] = newNode5;
									final «type.javaName»[][][][] node4 = lastNode5[lastNode5.length - 2];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode5[lastNode5.length - 2] = newNode4;
									final «type.javaName»[][][] node3 = node4[node4.length - 1];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][] node2 = node3[node3.length - 1];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
								}
							} else {
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								final «type.javaName»[][][][][] newNode5 = lastNode5.clone();
								newNode6[node6.length - 1] = newNode5;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[lastNode4.length - 1][][][];
								System.arraycopy(lastNode4, 0, newNode4, 0, lastNode4.length - 2);
								newNode5[lastNode5.length - 1] = newNode4;
								final «type.javaName»[][][] node3 = lastNode4[lastNode4.length - 2];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[lastNode4.length - 2] = newNode3;
								final «type.javaName»[][] node2 = node3[node3.length - 1];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							final «type.javaName»[][][][][] newNode5 = lastNode5.clone();
							newNode6[node6.length - 1] = newNode5;
							final «type.javaName»[][][][] newNode4 = lastNode4.clone();
							newNode5[lastNode5.length - 1] = newNode4;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[lastNode4.length - 1] = newNode3;
							final «type.javaName»[][] node2 = lastNode3[lastNode3.length - 2];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						final «type.javaName»[][][][][] newNode5 = lastNode5.clone();
						newNode6[node6.length - 1] = newNode5;
						final «type.javaName»[][][][] newNode4 = lastNode4.clone();
						newNode5[lastNode5.length - 1] = newNode4;
						final «type.javaName»[][][] newNode3 = lastNode3.clone();
						newNode4[lastNode4.length - 1] = newNode3;
						final «type.javaName»[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new «diamondName(6)»(newNode6, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new «diamondName(6)»(node6, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public «genericName» tail() {
				if (init.length == 1) {
					final «type.javaName»[][][][][] firstNode5 = node6[0];
					final «type.javaName»[][][][] firstNode4 = firstNode5[0];
					final «type.javaName»[][][] firstNode3 = firstNode4[0];
					final «type.javaName»[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (firstNode4.length == 1) {
								if (firstNode5.length == 1) {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] node5 = node6[1];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										final «type.javaName»[][][][] node4 = node5[0];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[0] = newNode4;
										final «type.javaName»[][][] node3 = node4[0];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][] node2 = node3[0];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
										newNode3[0] = newNode2;
										return new «diamondName(5)»(newNode5, node2[0], tail, 0, size - 1);
									} else {
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length - 1][][][][][];
										System.arraycopy(node6, 2, newNode6, 1, node6.length - 2);
										final «type.javaName»[][][][][] node5 = node6[1];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode6[0] = newNode5;
										final «type.javaName»[][][][] node4 = node5[0];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[0] = newNode4;
										final «type.javaName»[][][] node3 = node4[0];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][] node2 = node3[0];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
										newNode3[0] = newNode2;
										return new «diamondName(6)»(newNode6, node2[0], tail, 0, size - 1);
									}
								} else {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] lastNode5 = node6[1];
										if (firstNode5.length + lastNode5.length == 33) {
											final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
											System.arraycopy(firstNode5, 2, newNode5, 1, firstNode5.length - 2);
											System.arraycopy(lastNode5, 0, newNode5, firstNode5.length - 1, lastNode5.length);
											final «type.javaName»[][][][] node4 = firstNode5[1];
											final «type.javaName»[][][][] newNode4 = node4.clone();
											newNode5[0] = newNode4;
											final «type.javaName»[][][] node3 = node4[0];
											final «type.javaName»[][][] newNode3 = node3.clone();
											newNode4[0] = newNode3;
											final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
											final «type.javaName»[][] node2 = node3[0];
											System.arraycopy(node2, 1, newNode2, 0, 31);
											newNode3[0] = newNode2;
											final int newStartIndex = calculateSeq5StartIndex(newNode5, node2[0]);
											return new «diamondName(5)»(newNode5, node2[0], tail, newStartIndex, size - 1);
										}
									}

									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[firstNode5.length - 1][][][][];
									System.arraycopy(firstNode5, 2, newNode5, 1, firstNode5.length - 2);
									newNode6[0] = newNode5;
									final «type.javaName»[][][][] node4 = firstNode5[1];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode5[0] = newNode4;
									final «type.javaName»[][][] node3 = node4[0];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][] node2 = node3[0];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new «diamondName(6)»(newNode6, node2[0], tail, startIndex + 1, size - 1);
								}
							} else {
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								final «type.javaName»[][][][][] newNode5 = firstNode5.clone();
								newNode6[0] = newNode5;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[firstNode4.length - 1][][][];
								System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
								newNode5[0] = newNode4;
								final «type.javaName»[][][] node3 = firstNode4[1];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final «type.javaName»[][] node2 = node3[0];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new «diamondName(6)»(newNode6, node2[0], tail, startIndex + 1, size - 1);
							}
						} else {
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							final «type.javaName»[][][][][] newNode5 = firstNode5.clone();
							newNode6[0] = newNode5;
							final «type.javaName»[][][][] newNode4 = firstNode4.clone();
							newNode5[0] = newNode4;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final «type.javaName»[][] node2 = firstNode3[1];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new «diamondName(6)»(newNode6, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						final «type.javaName»[][][][][] newNode5 = firstNode5.clone();
						newNode6[0] = newNode5;
						final «type.javaName»[][][][] newNode4 = firstNode4.clone();
						newNode5[0] = newNode4;
						final «type.javaName»[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new «diamondName(6)»(newNode6, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new «diamondName(6)»(node6, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final int index6, final «type.javaName»[][] node2) {
				return (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) ? «index»2(idx) + node2.length - 32 : «index»2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final int index6, final «type.javaName»[][][] node3) {
				return (index6 == 0 && index5 == 0 && index4 == 0) ? «index»3(idx) + node3.length - 32 : «index»3(idx);
			}

			private static int index4(final int idx, final int index5, final int index6, final «type.javaName»[][][][] node4) {
				return (index6 == 0 && index5 == 0) ? «index»4(idx) + node4.length - 32 : «index»4(idx);
			}

			private static int index5(final int idx, final int index6, final «type.javaName»[][][][][] node5) {
				return (index6 == 0) ? «index»5(idx) + node5.length - 32 : «index»5(idx);
			}

			@Override
			public «type.genericName» get(final int index) {
				try {
					if (index < init.length) {
						return «type.genericCast»init[index];
					} else if (index >= size - tail.length) {
						return «type.genericCast»tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index6 = index6(idx);
						final «type.javaName»[][][][][] node5 = node6[index6];
						final int index5 = index5(idx, index6, node5);
						final «type.javaName»[][][][] node4 = node5[index5];
						final int index4 = index4(idx, index5, index6, node4);
						final «type.javaName»[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, index5, index6, node3);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, index5, index6, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);
						return «type.genericCast»node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» update(final int index, final «updateFunction» f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = init.clone();
						final «type.genericName» oldValue = «type.genericCast»init[index];
						final «type.genericName» newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new «diamondName(6)»(node6, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final «type.javaName»[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final «type.genericName» oldValue = «type.genericCast»tail[tailIndex];
						final «type.genericName» newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new «diamondName(6)»(node6, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						final int index6 = index6(idx);
						final «type.javaName»[][][][][] newNode5 = newNode6[index6].clone();
						final int index5 = index5(idx, index6, newNode5);
						final «type.javaName»[][][][] newNode4 = newNode5[index5].clone();
						final int index4 = index4(idx, index5, index6, newNode4);
						final «type.javaName»[][][] newNode3 = newNode4[index4].clone();
						final int index3 = index3(idx, index4, index5, index6, newNode3);
						final «type.javaName»[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, index4, index5, index6, newNode2);
						final «type.javaName»[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final «type.genericName» oldValue = «type.genericCast»newNode1[index1];
						final «type.genericName» newValue = f.apply(oldValue);
						newNode6[index6] = newNode5;
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new «diamondName(6)»(newNode6, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n < init.length) {
					final «type.javaName»[] node1 = new «type.javaName»[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new «diamondName(1)»(node1);
				} else if (n == init.length) {
					return new «diamondName(1)»(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new «diamondName(6)»(node6, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index6 = index6(idx);
					final «type.javaName»[][][][][] node5 = node6[index6];
					final int index5 = index5(idx, index6, node5);
					final «type.javaName»[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, index6, node4);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, index6, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, index6, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new «type.javaName»[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final «type.javaName»[][] newNode2;
							if (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final «type.javaName»[][] firstNode2 = node6[0][0][0][0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new «diamondName(2)»(newNode2, init, newTail, n);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							if (n <= (1 << 15) - calculateSeq3StartIndex(node6[0][0][0], init)) {
								final «type.javaName»[][][] newNode3;
								if (index6 == 0 && index5 == 0 && index4 == 0) {
									newNode3 = new «type.javaName»[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final «type.javaName»[][][] firstNode3 = node6[0][0][0];
									newNode3 = new «type.javaName»[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new «diamondName(3)»(newNode3, init, newTail, newStartIndex, n);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;

								if (n <= (1 << 20) - calculateSeq4StartIndex(node6[0][0], init)) {
									final «type.javaName»[][][][] newNode4;
									if (index6 == 0 && index5 == 0) {
										newNode4 = new «type.javaName»[index4 + 1][][][];
										System.arraycopy(node4, 0, newNode4, 0, index4);
										newNode4[index4] = newNode3;
									} else {
										final «type.javaName»[][][][] firstNode4 = node6[0][0];
										newNode4 = new «type.javaName»[firstNode4.length + index4 + 1][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(node4, 0, newNode4, firstNode4.length, index4);
										newNode4[firstNode4.length + index4] = newNode3;
									}
									final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
									return new «diamondName(4)»(newNode4, init, newTail, newStartIndex, n);
								} else {
									final «type.javaName»[][][][] newNode4 = new «type.javaName»[index4 + 1][][][];
									System.arraycopy(node4, 0, newNode4, 0, index4);
									newNode4[index4] = newNode3;

									if (n <= (1 << 25) - calculateSeq5StartIndex(node6[0], init)) {
										final «type.javaName»[][][][][] newNode5;
										if (index6 == 0) {
											newNode5 = new «type.javaName»[index5 + 1][][][][];
											System.arraycopy(node5, 0, newNode5, 0, index5);
											newNode5[index5] = newNode4;
										} else {
											final «type.javaName»[][][][][] firstNode5 = node6[0];
											newNode5 = new «type.javaName»[firstNode5.length + index5 + 1][][][][];
											System.arraycopy(firstNode5, 0, newNode5, 0, firstNode5.length);
											System.arraycopy(node5, 0, newNode5, firstNode5.length, index5);
											newNode5[firstNode5.length + index5] = newNode4;
										}
										final int newStartIndex = calculateSeq5StartIndex(newNode5, init);
										return new «diamondName(5)»(newNode5, init, newTail, newStartIndex, n);
									} else {
										final «type.javaName»[][][][][] newNode5 = new «type.javaName»[index5 + 1][][][][];
										System.arraycopy(node5, 0, newNode5, 0, index5);
										newNode5[index5] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[index6 + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, index6);
										newNode6[index6] = newNode5;
										return new «diamondName(6)»(newNode6, init, newTail, startIndex, n);
									}
								}
							}
						}
					}
				}
			}

			@Override
			public «genericName» drop(final int n) {
				if (n >= size) {
					return empty«shortName»();
				} else if (n > size - tail.length) {
					final «type.javaName»[] node1 = new «type.javaName»[size - n];
					System.arraycopy(tail, n - size + tail.length, node1, 0, node1.length);
					return new «diamondName(1)»(node1);
				} else if (n == size - tail.length) {
					return new «diamondName(1)»(tail);
				} else if (n <= 0) {
					return this;
				} else if (n < init.length) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - n];
					System.arraycopy(init, n, newInit, 0, newInit.length);
					return new «diamondName(6)»(node6, newInit, tail, startIndex + n, size - n);
				} else {
					final int idx = n + startIndex;
					final int index6 = index6(idx);
					final «type.javaName»[][][][][] node5 = node6[index6];
					final int index5 = index5(idx, index6, node5);
					final «type.javaName»[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, index6, node4);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, index6, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, index6, node2);
					final «type.javaName»[] node1 = node2[index2];
					final int index1 = index1(idx);
					final int newSize = size - n;

					if (newSize <= 32) {
						final «type.javaName»[] newNode1 = new «type.javaName»[newSize];
						System.arraycopy(node1, index1, newNode1, 0, 32 - index1);
						System.arraycopy(tail, 0, newNode1, 32 - index1, tail.length);
						return new «diamondName(1)»(newNode1);
					} else {
						final «type.javaName»[] newInit;
						if (index1 == 0) {
							newInit = node1;
						} else {
							newInit = new «type.javaName»[32 - index1];
							System.arraycopy(node1, index1, newInit, 0, newInit.length);
						}

						if (newSize <= 1024 - 32 + tail.length) {
							final «type.javaName»[][] newNode2;
							if (index6 == node6.length - 1 && index5 == node5.length - 1 && index4 == node4.length - 1 && index3 == node3.length - 1) {
								if (index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
								}
							} else {
								final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
								final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
								final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
								final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
								if (lastNode2.length == 0 && index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1 + lastNode2.length][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, node2.length - index2 - 1);
									System.arraycopy(lastNode2, 0, newNode2, node2.length - index2 - 1, lastNode2.length);
								}
							}
							return new «diamondName(2)»(newNode2, newInit, tail, newSize);
						} else {
							final «type.javaName»[][] newNode2;
							if (index2 == node2.length - 1) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new «type.javaName»[node2.length - index2 - 1][];
								System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
							}

							final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
							final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
							final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
							if (newSize <= (1 << 15) - calculateSeq3EndIndex(lastNode3, tail)) {
								final «type.javaName»[][][] newNode3;
								if (index6 == node6.length - 1 && index5 == node5.length - 1 && index4 == node4.length - 1) {
									newNode3 = new «type.javaName»[node3.length - index3][][];
									System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								} else {
									newNode3 = new «type.javaName»[node3.length - index3 + lastNode3.length][][];
									System.arraycopy(node3, index3, newNode3, 0, node3.length - index3);
									System.arraycopy(lastNode3, 0, newNode3, node3.length - index3, lastNode3.length);
								}
								newNode3[0] = newNode2;
								final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);
								return new «diamondName(3)»(newNode3, newInit, tail, newStartIndex, newSize);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - index3][][];
								System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								newNode3[0] = newNode2;

								if (newSize <= (1 << 20) - calculateSeq4EndIndex(lastNode3, tail)) {
									final «type.javaName»[][][][] newNode4;
									if (index6 == node6.length - 1 && index5 == node5.length - 1) {
										newNode4 = new «type.javaName»[node4.length - index4][][][];
										System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
									} else {
										newNode4 = new «type.javaName»[node4.length - index4 + lastNode4.length][][][];
										System.arraycopy(node4, index4, newNode4, 0, node4.length - index4);
										System.arraycopy(lastNode4, 0, newNode4, node4.length - index4, lastNode4.length);
									}
									newNode4[0] = newNode3;
									final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);
									return new «diamondName(4)»(newNode4, newInit, tail, newStartIndex, newSize);
								} else {
									final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length - index4][][][];
									System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
									newNode4[0] = newNode3;

									if (newSize <= (1 << 25) - calculateSeq5EndIndex(lastNode4, lastNode3, tail)) {
										final «type.javaName»[][][][][] newNode5;
										if (index6 == node6.length - 1) {
											newNode5 = new «type.javaName»[node5.length - index5][][][][];
											System.arraycopy(node5, index5, newNode5, 0, newNode5.length);
										} else {
											newNode5 = new «type.javaName»[node5.length - index5 + lastNode5.length][][][][];
											System.arraycopy(node5, index5, newNode5, 0, node5.length - index5);
											System.arraycopy(lastNode5, 0, newNode5, node5.length - index5, lastNode5.length);
										}
										newNode5[0] = newNode4;
										final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);
										return new «diamondName(5)»(newNode5, newInit, tail, newStartIndex, newSize);
									} else {
										final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length - index5][][][][];
										System.arraycopy(node5, index5, newNode5, 0, newNode5.length);
										newNode5[0] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length - index6][][][][][];
										System.arraycopy(node6, index6, newNode6, 0, newNode6.length);
										newNode6[0] = newNode5;
										final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);
										return new «diamondName(6)»(newNode6, newInit, tail, newStartIndex, newSize);
									}
								}
							}
						}
					}
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				requireNonNull(value);
				if (init.length == 32) {
					final «type.javaName»[][][][][] node5 = node6[0];
					final «type.javaName»[][][][] node4 = node5[0];
					final «type.javaName»[][][] node3 = node4[0];
					final «type.javaName»[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									if (node6.length == 32) {
										throw new IndexOutOfBoundsException("Seq size limit exceeded");
									} else {
										final «type.javaName»[] newInit = { value };
										final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
										System.arraycopy(node2, 0, newNode2, 1, 31);
										newNode2[0] = init;
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode3[0] = newNode2;
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode5[0] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length + 1][][][][][];
										System.arraycopy(node6, 1, newNode6, 2, node6.length - 1);
										newNode6[0] = new «type.javaName»[][][][][] { { { EMPTY_NODE2 } } };
										newNode6[1] = newNode5;
										if (startIndex != 0) {
											throw new IllegalStateException("startIndex != 0");
										}
										return new «diamondName(6)»(newNode6, newInit, tail, (1 << 25) - 1, size + 1);
									}
								} else {
									final «type.javaName»[] newInit = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length + 1][][][][];
									System.arraycopy(node5, 1, newNode5, 2, node5.length - 1);
									newNode5[0] = new «type.javaName»[][][][] { { EMPTY_NODE2 } };
									newNode5[1] = newNode4;
									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									newNode6[0] = newNode5;
									return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
								}
							} else {
								final «type.javaName»[] newInit = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new «type.javaName»[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								final «type.javaName»[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								newNode6[0] = newNode5;
								return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
							}
						} else {
							final «type.javaName»[] newInit = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							newNode6[0] = newNode5;
							return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						newNode6[0] = newNode5;
						return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new «diamondName(6)»(node6, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
					final «type.javaName»[][][][] node4 = node5[node5.length - 1];
					final «type.javaName»[][][] node3 = node4[node4.length - 1];
					final «type.javaName»[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									if (node6.length == 32) {
										throw new IndexOutOfBoundsException("Seq size limit exceeded");
									} else {
										final «type.javaName»[] newTail = { value };
										final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
										System.arraycopy(node2, 0, newNode2, 0, 31);
										newNode2[31] = tail;
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode3[node3.length - 1] = newNode2;
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode4[node4.length - 1] = newNode3;
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode5[node5.length - 1] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, node6.length - 1);
										newNode6[node6.length - 1] = newNode5;
										newNode6[node6.length] = new «type.javaName»[][][][][] { { { EMPTY_NODE2 } } };
										return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
									}
								} else {
									final «type.javaName»[] newTail = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[node3.length - 1] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
									newNode5[node5.length - 1] = newNode4;
									newNode5[node5.length] = new «type.javaName»[][][][] { { EMPTY_NODE2 } };
									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									newNode6[newNode6.length - 1] = newNode5;
									return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
								}
							} else {
								final «type.javaName»[] newTail = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new «type.javaName»[][][] { EMPTY_NODE2 };
								final «type.javaName»[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								newNode6[newNode6.length - 1] = newNode5;
								return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
							}
						} else {
							final «type.javaName»[] newTail = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							newNode6[newNode6.length - 1] = newNode5;
							return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
						}
					} else {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						newNode6[newNode6.length - 1] = newNode5;
						return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new «diamondName(6)»(node6, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new «diamondName(6)»(node6, init, newTail, startIndex, size + suffixSize);
				}

				final int maxSize = size - init.length - 32*node6[0][0][0][0].length - (1 << 10)*(node6[0][0][0].length - 1)
						- (1 << 15)*(node6[0][0].length - 1) - (1 << 20)*(node6[0].length - 1) + (1 << 25) + suffixSize;
				if (maxSize >= 0 && maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(node6.length, maxSize);
				System.arraycopy(node6, 0, newNode6, 0, node6.length - 1);

				final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				final «type.javaName»[][][][][] newNode5;
				final «type.javaName»[][][][] newNode4;
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node6.length < newNode6.length) {
					newNode5 = new «type.javaName»[32][][][][];
					newNode4 = new «type.javaName»[32][][][];
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
					for (int index4 = node4.length; index4 < 32; index4++) {
						newNode4[index4] = new «type.javaName»[32][32][32];
					}
					for (int index5 = node5.length; index5 < 32; index5++) {
						newNode5[index5] = new «type.javaName»[32][32][32][32];
					}
				} else {
					final int totalSize5 = (maxSize % (1 << 25) == 0) ? (1 << 25) : maxSize % (1 << 25);
					newNode5 = allocateNode5(node5.length, totalSize5);
					if (node5.length < newNode5.length) {
						newNode4 = new «type.javaName»[32][][][];
						newNode3 = new «type.javaName»[32][][];
						newNode2 = new «type.javaName»[32][];
						for (int index4 = node4.length; index4 < 32; index4++) {
							newNode4[index4] = new «type.javaName»[32][32][32];
						}
						for (int index3 = node3.length; index3 < 32; index3++) {
							newNode3[index3] = new «type.javaName»[32][32];
						}
					} else {
						final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
						newNode4 = allocateNode4(node4.length, totalSize4);
						if (node4.length < newNode4.length) {
							newNode3 = new «type.javaName»[32][][];
							newNode2 = new «type.javaName»[32][];
							for (int index3 = node3.length; index3 < 32; index3++) {
								newNode3[index3] = new «type.javaName»[32][32];
							}
						} else {
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							newNode3 = allocateNode3(node3.length, totalSize3);
							if (node3.length < newNode3.length) {
								newNode2 = new «type.javaName»[32][];
							} else {
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
							}
						}
					}
				}
				System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				newNode4[node4.length - 1] = newNode3;
				newNode5[node5.length - 1] = newNode4;
				newNode6[node6.length - 1] = newNode5;

				return fillSeq6(newNode6, node6.length, newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new «diamondName(6)»(node6, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];

				final int maxSize = size - tail.length - 32*node3[node3.length - 1].length - (1 << 10)*(node3.length - 1)
						- (1 << 15)*(node4.length - 1) - (1 << 20)*(node5.length - 1) + (1 << 25) + prefixSize;
				if (maxSize >= 0 && maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(node6.length, maxSize);
				System.arraycopy(node6, 1, newNode6, newNode6.length - node6.length + 1, node6.length - 1);

				final «type.javaName»[][][][][] node5 = node6[0];
				final «type.javaName»[][][][] node4 = node5[0];
				final «type.javaName»[][][] node3 = node4[0];
				final «type.javaName»[][] node2 = node3[0];
				final «type.javaName»[][][][][] newNode5;
				final «type.javaName»[][][][] newNode4;
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node6.length < newNode6.length) {
					newNode5 = new «type.javaName»[32][][][][];
					newNode4 = new «type.javaName»[32][][][];
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
					for (int index4 = 0; index4 < 32 - node4.length; index4++) {
						newNode4[index4] = new «type.javaName»[32][32][32];
					}
					for (int index5 = 0; index5 < 32 - node5.length; index5++) {
						newNode5[index5] = new «type.javaName»[32][32][32][32];
					}
				} else {
					final int totalSize5 = (maxSize % (1 << 25) == 0) ? (1 << 25) : maxSize % (1 << 25);
					newNode5 = allocateNode5FromStart(node5.length, totalSize5);
					if (node5.length < newNode5.length) {
						newNode4 = new «type.javaName»[32][][][];
						newNode3 = new «type.javaName»[32][][];
						newNode2 = new «type.javaName»[32][];
						for (int index4 = 0; index4 < 32 - node4.length; index4++) {
							newNode4[index4] = new «type.javaName»[32][32][32];
						}
						for (int index3 = 0; index3 < 32 - node3.length; index3++) {
							newNode3[index3] = new «type.javaName»[32][32];
						}
					} else {
						final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
						newNode4 = allocateNode4FromStart(node4.length, totalSize4);
						if (node4.length < newNode4.length) {
							newNode3 = new «type.javaName»[32][][];
							newNode2 = new «type.javaName»[32][];
							for (int index3 = 0; index3 < 32 - node3.length; index3++) {
								newNode3[index3] = new «type.javaName»[32][32];
							}
						} else {
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							newNode3 = allocateNode3FromStart(node3.length, totalSize3);
							if (node3.length < newNode3.length) {
								newNode2 = new «type.javaName»[32][];
							} else {
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
							}
						}
					}
				}
				System.arraycopy(node5, 1, newNode5, newNode5.length - node5.length + 1, node5.length - 1);
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
					}
					System.arraycopy(init, 0, newNode2[newNode2.length - node2.length - 1], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - node3.length] = newNode2;
				newNode4[newNode4.length - node4.length] = newNode3;
				newNode5[newNode5.length - node5.length] = newNode4;
				newNode6[newNode6.length - node6.length] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, node6.length, newNode5, node5.length, newNode4, node4.length, newNode3, node3.length,
						newNode2, node2.length + 1, newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail,
						newStartIndex, size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				builder.node2 = new «type.javaName»[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 0, builder.node4, 0, node4.length - 1);
				builder.node4[node4.length - 1] = builder.node3;
				builder.node5 = new «type.javaName»[32][][][][];
				System.arraycopy(node5, 0, builder.node5, 0, node5.length - 1);
				builder.node5[node5.length - 1] = builder.node4;
				builder.node6 = new «type.javaName»[32][][][][][];
				System.arraycopy(node6, 0, builder.node6, 0, node6.length - 1);
				builder.node6[node6.length - 1] = builder.node5;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.index3 = node3.length;
				builder.index4 = node4.length;
				builder.index5 = node5.length;
				builder.index6 = node6.length;
				builder.startIndex = startIndex;
				builder.size = size;
			}

			@Override
			public «type.javaName»[] to«type.javaPrefix»Array() {
				final «type.javaName»[] array = new «type.javaName»[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[][][][][] node5 : node6) {
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									System.arraycopy(node1, 0, array, index, 32);
									index += 32;
								}
							}
						}
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(6)»(node6, init, tail);
			}
		}
	''' }
}
