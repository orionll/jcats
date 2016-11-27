package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class SeqGenerator implements ClassGenerator {
	override className() { Constants.SEQ }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.HashSet;
		import java.util.List;
		import java.util.NoSuchElementException;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.FUNCTION».BoolF;
		import «Constants.F»;
		import «Constants.F0»;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		import «Constants.FUNCTION».IntObjectF;
		import «Constants.EQUATABLE»;
		import «Constants.INDEXED»;
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»
		import «Constants.SIZED»;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static jcats.collection.Array.mapArray;
		import static «Constants.F».id;
		import static «Constants.P».p;

		public abstract class Seq<A> implements Iterable<A>, Equatable<Seq<A>>, Sized, Indexed<A>, Serializable {
			private static final Seq EMPTY = new Seq0();

			static final Object[][] EMPTY_NODE2 = new Object[0][];

			Seq() {
			}

			/**
			 * O(1)
			 */
			@Override
			public abstract int size();

			/**
			 * O(1)
			 */
			public abstract A head();

			/**
			 * O(1)
			 */
			public abstract A last();

			/**
			 * O(1)
			 */
			public abstract Seq<A> init();

			/**
			 * O(1)
			 */
			public abstract Seq<A> tail();

			/**
			 * O(log(size))
			 */
			@Override
			public abstract A get(final int index);

			/**
			 * O(log(size))
			 */
			public final Seq<A> set(final int index, final A value) {
				return update(index, F.constant(value));
			}

			/**
			 * O(log(size))
			 */
			public abstract Seq<A> update(final int index, final F<A, A> f);

			public abstract Seq<A> take(final int n);

			«takeWhile(true)»

			/**
			 * O(1)
			 */
			public abstract Seq<A> prepend(final A value);

			/**
			 * O(1)
			 */
			public abstract Seq<A> append(final A value);

			/**
			 * O(min(this.size, suffix.size))
			 */
			public Seq<A> concat(final Seq<A> suffix) {
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

			abstract Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize);

			abstract Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize);

			public final Seq<A> appendAll(final Iterable<A> suffix) {
				requireNonNull(suffix);
				if (suffix instanceof Seq<?>) {
					return concat((Seq<A>) suffix);
				} else if (suffix instanceof Collection<?> && suffix instanceof RandomAccess) {
					final int suffixSize = ((Collection<A>) suffix).size();
					if (suffixSize == 0) {
						return this;
					} else {
						return appendSized(suffix.iterator(), suffixSize);
					}
				} else if (suffix instanceof Sized) {
					final int suffixSize = ((Sized) suffix).size();
					if (suffixSize == 0) {
						return this;
					} else {
						return appendSized(suffix.iterator(), suffixSize);
					}
				} else {
					final Iterator<A> iterator = suffix.iterator();
					if (iterator.hasNext()) {
						final SeqBuilder<A> builder = new SeqBuilder<>(this);
						while (iterator.hasNext()) {
							builder.append(iterator.next());
						}
						return builder.build();
					} else {
						return this;
					}
				}
			}

			public final Seq<A> prependAll(final Iterable<A> prefix) {
				requireNonNull(prefix);
				if (prefix instanceof Seq<?>) {
					return ((Seq<A>) prefix).concat(this);
				} else if (prefix instanceof Collection<?> && prefix instanceof RandomAccess) {
					final int prefixSize = ((Collection<A>) prefix).size();
					if (prefixSize == 0) {
						return this;
					} else {
						return prependSized(prefix.iterator(), prefixSize);
					}
				} else if (prefix instanceof Sized) {
					final int prefixSize = ((Sized) prefix).size();
					if (prefixSize == 0) {
						return this;
					} else {
						return prependSized(prefix.iterator(), prefixSize);
					}
				} else {
					final Iterator<A> iterator = prefix.iterator();
					if (iterator.hasNext()) {
						if (isEmpty()) {
							final SeqBuilder<A> builder = new SeqBuilder<>();
							while (iterator.hasNext()) {
								builder.append(iterator.next());
							}
							return builder.build();
						} else {
							// We must know exact size, so use a temporary list
							final BufferedList<A> tempList = new BufferedList<>();
							int size = 0;
							while (iterator.hasNext()) {
								tempList.append(iterator.next());
								size++;
							}
							return prependSized(tempList.iterator(), size);
						}
					} else {
						return this;
					}
				}
			}

			public final <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					return sizedToSeq(new MappedIterator<>(iterator(), f), size());
				}
			}

			public final <B> Seq<B> flatMap(final F<A, Seq<B>> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return emptySeq();
				} else {
					final SeqBuilder<B> builder = new SeqBuilder<>();
					for (final A value : this) {
						builder.appendAll(f.apply(value));
					}
					return builder.build();
				}
			}

			public final Seq<A> filter(final BoolF<A> predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return emptySeq();
				} else {
					final SeqBuilder<A> builder = new SeqBuilder<>();
					for (final Object value : this) {
						if (predicate.apply((A) value)) {
							builder.append((A) value);
						}
					}
					return builder.build();
				}
			}

			public final List<A> asList() {
				return new SeqAsList<>(this);
			}

			«toArrayList(true)»

			«toHashSet(true)»

			public final Array<A> toArray() {
				if (isEmpty()) {
					return Array.emptyArray();
				} else {
					return new Array<>(toObjectArray());
				}
			}

			public abstract Object[] toObjectArray();

			public static <A> Seq<A> emptySeq() {
				return Seq.EMPTY;
			}

			public static <A> Seq<A> singleSeq(final A value) {
				final Object[] node1 = { requireNonNull(value) };
				return new Seq1<>(node1);
			}

			@SafeVarargs
			public static <A> Seq<A> seq(final A... values) {
				if (values.length == 0) {
					return emptySeq();
				} else {
					for (final Object value : values) {
						requireNonNull(value);
					}
					return seqFromArray(values);
				}
			}

			public static <A> Seq<A> replicate(final int size, final A value) {
				return tabulate(size, IntObjectF.constant(value));
			}

			public static <A> Seq<A> fill(final int size, final F0<A> f) {
				return tabulate(size, f.toConstIntObjectF());
			}

			public static <A> Seq<A> tabulate(final int size, final IntObjectF<A> f) {
				requireNonNull(f);
				if (size <= 0) {
					return emptySeq();
				} else {
					return sizedToSeq(new TableIterator<>(size, f), size);
				}
			}

			static <A> void fillArray(final Object[] array, final int startIndex, final Iterator<A> iterator) {
				for (int i = startIndex; i < array.length; i++) {
					array[i] = requireNonNull(iterator.next());
				}
			}

			private static <A> void fillNode2(final Object[][] node2, final int startIndex2, final int endIndex2, final Iterator<A> iterator) {
				for (int i = startIndex2; i < endIndex2; i++) {
					fillArray(node2[i], 0, iterator);
				}
			}

			private static <A> void fillNode3(final Object[][][] node3, final int startIndex3, final int endIndex3, final Iterator<A> iterator) {
				for (int i = startIndex3; i < endIndex3; i++) {
					fillNode2(node3[i], 0, node3[i].length, iterator);
				}
			}

			private static <A> void fillNode4(final Object[][][][] node4, final int startIndex4, final int endIndex4, final Iterator<A> iterator) {
				for (int i = startIndex4; i < endIndex4; i++) {
					fillNode3(node4[i], 0, node4[i].length, iterator);
				}
			}

			private static <A> void fillNode5(final Object[][][][][] node5, final int startIndex5, final int endIndex5, final Iterator<A> iterator) {
				for (int i = startIndex5; i < endIndex5; i++) {
					fillNode4(node5[i], 0, node5[i].length, iterator);
				}
			}

			private static <A> void fillNode6(final Object[][][][][][] node6, final int startIndex6, final int endIndex6, final Iterator<A> iterator) {
				for (int i = startIndex6; i < endIndex6; i++) {
					fillNode5(node6[i], 0, node6[i].length, iterator);
				}
			}

			static <A> Seq1<A> fillSeq1(final Object[] node1, final int startIndex1, final Iterator<A> iterator) {
				fillArray(node1, startIndex1, iterator);
				return new Seq1<>(node1);
			}

			static <A> Seq2<A> fillSeq2(final Object[][] node2, final int startIndex2, final Object[] node1, final int startIndex1,
					final Object[] init, final Object[] tail, final int size, final Iterator<A> iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillArray(tail, 0, iterator);
				return new Seq2<>(node2, init, tail, size);
			}

			static <A> Seq3<A> fillSeq3(final Object[][][] node3, final int startIndex3, final Object[][] node2, final int startIndex2,
					final Object[] node1, final int startIndex1, final Object[] init, final Object[] tail, final int startIndex,
					final int size, final Iterator<A> iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillArray(tail, 0, iterator);
				return new Seq3<>(node3, init, tail, startIndex, size);
			}

			static <A> Seq4<A> fillSeq4(final Object[][][][] node4, final int startIndex4, final Object[][][] node3, final int startIndex3,
					final Object[][] node2, final int startIndex2,  final Object[] node1, final int startIndex1, final Object[] init,
					final Object[] tail, final int startIndex,  final int size, final Iterator<A> iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillNode4(node4, startIndex4, node4.length, iterator);
				fillArray(tail, 0, iterator);
				return new Seq4<>(node4, init, tail, startIndex, size);
			}

			static <A> Seq5<A> fillSeq5(final Object[][][][][] node5, final int startIndex5, final Object[][][][] node4, final int startIndex4,
					final Object[][][] node3, final int startIndex3, final Object[][] node2, final int startIndex2,
					final Object[] node1, final int startIndex1, final Object[] init, final Object[] tail, final int startIndex,
					final int size, final Iterator<A> iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillNode4(node4, startIndex4, node4.length, iterator);
				fillNode5(node5, startIndex5, node5.length, iterator);
				fillArray(tail, 0, iterator);
				return new Seq5<>(node5, init, tail, startIndex, size);
			}

			static <A> Seq6<A> fillSeq6(final Object[][][][][][] node6, final int startIndex6, final Object[][][][][] node5, final int startIndex5,
					final Object[][][][] node4, final int startIndex4, final Object[][][] node3, final int startIndex3,
					final Object[][] node2, final int startIndex2, final Object[] node1, final int startIndex1,
					final Object[] init, final Object[] tail, final int startIndex, final int size, final Iterator<A> iterator) {
				fillArray(node1, startIndex1, iterator);
				fillNode2(node2, startIndex2, node2.length, iterator);
				fillNode3(node3, startIndex3, node3.length, iterator);
				fillNode4(node4, startIndex4, node4.length, iterator);
				fillNode5(node5, startIndex5, node5.length, iterator);
				fillNode6(node6, startIndex6, node6.length, iterator);
				fillArray(tail, 0, iterator);
				return new Seq6<>(node6, init, tail, startIndex, size);
			}

			static <A> void fillArrayFromStart(final Object[] array, final int endIndex, final Iterator<A> iterator) {
				for (int i = 0; i < endIndex; i++) {
					array[i] = requireNonNull(iterator.next());
				}
			}

			static <A> Seq1<A> fillSeq1FromStart(final Object[] node1, final int endIndex1, final Iterator<A> iterator) {
				fillArrayFromStart(node1, endIndex1, iterator);
				return new Seq1<>(node1);
			}

			static <A> Seq2<A> fillSeq2FromStart(final Object[][] node2, final int fromEndIndex2, final Object[] node1,
					final int fromEndIndex1, final Object[] init, final Object[] tail, final int size, final Iterator<A> iterator) {
				fillArray(init, 0, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new Seq2<>(node2, init, tail, size);
			}

			static <A> Seq3<A> fillSeq3FromStart(final Object[][][] node3, final int fromEndIndex3, final Object[][] node2,
					final int fromEndIndex2, final Object[] node1, final int fromEndIndex1, final Object[] init,
					final Object[] tail, final int startIndex, final int size, final Iterator<A> iterator) {
				fillArray(init, 0, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new Seq3<>(node3, init, tail, startIndex, size);
			}

			static <A> Seq4<A> fillSeq4FromStart(final Object[][][][] node4, final int fromEndIndex4, final Object[][][] node3,
					final int fromEndIndex3, final Object[][] node2, final int fromEndIndex2, final Object[] node1,
					final int fromEndIndex1, final Object[] init, final Object[] tail, final int startIndex, final int size,
					final Iterator<A> iterator) {
				fillArray(init, 0, iterator);
				fillNode4(node4, 0, node4.length - fromEndIndex4, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new Seq4<>(node4, init, tail, startIndex, size);
			}

			static <A> Seq5<A> fillSeq5FromStart(final Object[][][][][] node5, final int fromEndIndex5, final Object[][][][] node4,
					final int fromEndIndex4, final Object[][][] node3, final int fromEndIndex3, final Object[][] node2,
					final int fromEndIndex2, final Object[] node1, final int fromEndIndex1, final Object[] init, final Object[] tail,
					final int startIndex, final int size, final Iterator<A> iterator) {
				fillArray(init, 0, iterator);
				fillNode5(node5, 0, node5.length - fromEndIndex5, iterator);
				fillNode4(node4, 0, node4.length - fromEndIndex4, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new Seq5<>(node5, init, tail, startIndex, size);
			}

			static <A> Seq6<A> fillSeq6FromStart(final Object[][][][][][] node6, final int fromEndIndex6, final Object[][][][][] node5,
					final int fromEndIndex5, final Object[][][][] node4, final int fromEndIndex4, final Object[][][] node3,
					final int fromEndIndex3, final Object[][] node2, final int fromEndIndex2, final Object[] node1, final int fromEndIndex1,
					final Object[] init, final Object[] tail, final int startIndex, final int size, final Iterator<A> iterator) {
				fillArray(init, 0, iterator);
				fillNode6(node6, 0, node6.length - fromEndIndex6, iterator);
				fillNode5(node5, 0, node5.length - fromEndIndex5, iterator);
				fillNode4(node4, 0, node4.length - fromEndIndex4, iterator);
				fillNode3(node3, 0, node3.length - fromEndIndex3, iterator);
				fillNode2(node2, 0, node2.length - fromEndIndex2, iterator);
				fillArrayFromStart(node1, node1.length - fromEndIndex1, iterator);
				return new Seq6<>(node6, init, tail, startIndex, size);
			}

			static <A> Seq<A> seqFromArray(final Object[] values) {
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

			private static <A> Seq1<A> seq1FromArray(final Object[] values) {
				final Object[] node1 = new Object[values.length];
				System.arraycopy(values, 0, node1, 0, values.length);
				return new Seq1<>(node1);
			}

			private static <A> Seq2<A> seq2FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				if (values.length <= 64) {
					final Object[] tail = new Object[values.length - 32];
					System.arraycopy(values, 32, tail, 0, values.length - 32);
					return new Seq2<>(EMPTY_NODE2, init, tail, values.length);
				} else {
					final Object[] tail = tailFromArray(values);
					final Object[][] node2 = new Object[(values.length - 32 - tail.length) / 32][32];
					int index = 32;
					for (final Object[] node1 : node2) {
						System.arraycopy(values, index, node1, 0, 32);
						index += 32;
					}
					return new Seq2<>(node2, init, tail, values.length);
				}
			}

			private static <A> Seq3<A> seq3FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final Object[][][] node3 = allocateNode3(0, values.length);
				int index = 32;
				for (final Object[][] node2 : node3) {
					for (final Object[] node1 : node2) {
						System.arraycopy(values, index, node1, 0, 32);
						index += 32;
					}
				}
				return new Seq3<>(node3, init, tail, 0, values.length);
			}

			private static <A> Seq4<A> seq4FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final Object[][][][] node4 = allocateNode4(0, values.length);
				int index = 32;
				for (final Object[][][] node3 : node4) {
					for (final Object[][] node2 : node3) {
						for (final Object[] node1 : node2) {
							System.arraycopy(values, index, node1, 0, 32);
							index += 32;
						}
					}
				}
				return new Seq4<>(node4, init, tail, 0, values.length);
			}

			private static <A> Seq5<A> seq5FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final Object[][][][][] node5 = allocateNode5(0, values.length);

				int index = 32;
				for (final Object[][][][] node4 : node5) {
					for (final Object[][][] node3 : node4) {
						for (final Object[][] node2 : node3) {
							for (final Object[] node1 : node2) {
								System.arraycopy(values, index, node1, 0, 32);
								index += 32;
							}
						}
					}
				}
				return new Seq5<>(node5, init, tail, 0, values.length);
			}

			private static <A> Seq6<A> seq6FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final Object[][][][][][] node6 = allocateNode6(0, values.length);

				int index = 32;
				for (final Object[][][][][] node5 : node6) {
					for (final Object[][][][] node4 : node5) {
						for (final Object[][][] node3 : node4) {
							for (final Object[][] node2 : node3) {
								for (final Object[] node1 : node2) {
									System.arraycopy(values, index, node1, 0, 32);
									index += 32;
								}
							}
						}
					}
				}
				return new Seq6<>(node6, init, tail, 0, values.length);
			}

			static Object[] allocateTail(final int size) {
				return new Object[((size % 32) == 0) ? 32 : size % 32];
			}

			private static Object[] initFromArray(final Object[] values) {
				final Object[] init = new Object[32];
				System.arraycopy(values, 0, init, 0, 32);
				return init;
			}

			private static Object[] tailFromArray(final Object[] values) {
				final Object[] tail = allocateTail(values.length);
				System.arraycopy(values, values.length - tail.length, tail, 0, tail.length);
				return tail;
			}

			public static <A> Seq<A> iterableToSeq(final Iterable<A> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof Seq<?>) {
					return (Seq<A>) iterable;
				} else if (iterable instanceof Collection<?> && iterable instanceof RandomAccess) {
					return sizedToSeq(iterable.iterator(), ((Collection<A>) iterable).size());
				} else if (iterable instanceof Sized) {
					return sizedToSeq(iterable.iterator(), ((Sized) iterable).size());
				} else {
					final Iterator<A> iterator = iterable.iterator();
					if (iterator.hasNext()) {
						final SeqBuilder<A> builder = new SeqBuilder<>();
						while (iterator.hasNext()) {
							builder.append(iterator.next());
						}
						return builder.build();
					} else {
						return emptySeq();
					}
				}
			}

			static <A> Seq<A> sizedToSeq(final Iterator<A> iterator, final int size) {
				if (size == 0) {
					return emptySeq();
				} else if (size <= 32) {
					return fillSeq1(new Object[size], 0, iterator);
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

			private static <A> Seq<A> sizedToSeq2(final Iterator<A> iterator, final int size) {
				final Object[] init = new Object[32];
				fillArray(init, 0, iterator);
				final Object[] tail = allocateTail(size);
				final int size2 = (size - 32 - tail.length) / 32;
				if (size2 == 0) {
					fillArray(tail, 0, iterator);
					return new Seq2<>(EMPTY_NODE2, init, tail, size);
				} else {
					final Object[][] node2 = new Object[size2][32];
					return fillSeq2(node2, 1, node2[0], 0, init, tail, size, iterator);
				}
			}

			private static <A> Seq<A> sizedToSeq3(final Iterator<A> iterator, final int size) {
				final Object[] init = new Object[32];
				fillArray(init, 0, iterator);
				final Object[] tail = allocateTail(size);
				final Object[][][] node3 = allocateNode3(0, size);
				return fillSeq3(node3, 1, node3[0], 1, node3[0][0], 0, init, tail, 0, size, iterator);
			}

			private static <A> Seq<A> sizedToSeq4(final Iterator<A> iterator, final int size) {
				final Object[] init = new Object[32];
				fillArray(init, 0, iterator);
				final Object[] tail = allocateTail(size);
				final Object[][][][] node4 = allocateNode4(0, size);
				return fillSeq4(node4, 1, node4[0], 1, node4[0][0], 1, node4[0][0][0], 0, init, tail, 0, size, iterator);
			}

			private static <A> Seq<A> sizedToSeq5(final Iterator<A> iterator, final int size) {
				final Object[] init = new Object[32];
				fillArray(init, 0, iterator);
				final Object[] tail = allocateTail(size);
				final Object[][][][][] node5 = allocateNode5(0, size);
				return fillSeq5(node5, 1, node5[0], 1, node5[0][0], 1, node5[0][0][0], 1, node5[0][0][0][0], 0,
						init, tail, 0, size, iterator);
			}

			private static <A> Seq<A> sizedToSeq6(final Iterator<A> iterator, final int size) {
				final Object[] init = new Object[32];
				fillArray(init, 0, iterator);
				final Object[] tail = allocateTail(size);
				final Object[][][][][][] node6 = allocateNode6(0, size);
				return fillSeq6(node6, 1, node6[0], 1, node6[0][0], 1, node6[0][0][0], 1, node6[0][0][0][0], 1,
						node6[0][0][0][0][0], 0, init, tail, 0, size, iterator);
			}

			static Object[][][] allocateNode3(final int startIndex3, final int size) {
				final Object[][][] node3 = new Object[(size % (1 << 10) == 0) ? size / (1 << 10) : size / (1 << 10) + 1][][];
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
					node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
				}
				return node3;
			}

			static Object[][][][] allocateNode4(final int startIndex4, final int size) {
				final Object[][][][] node4 = new Object[(size % (1 << 15) == 0) ? size / (1 << 15) : size / (1 << 15) + 1][][][];
				for (int index4 = startIndex4; index4 < node4.length; index4++) {
					final int size3;
					if (index4 == node4.length - 1) {
						final int totalSize3 = (size % (1 << 15) == 0) ? (1 << 15) : size % (1 << 15);
						size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
					} else {
						size3 = 32;
					}
					final Object[][][] node3 = new Object[size3][][];
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
						node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
					}
				}
				return node4;
			}

			static Object[][][][][] allocateNode5(final int startIndex5, final int size) {
				final Object[][][][][] node5 = new Object[(size % (1 << 20) == 0) ? size / (1 << 20) : size / (1 << 20) + 1][][][][];
				for (int index5 = startIndex5; index5 < node5.length; index5++) {
					final int size4;
					if (index5 == node5.length - 1) {
						final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
						size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
					} else {
						size4 = 32;
					}

					final Object[][][][] node4 = new Object[size4][][][];
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

						final Object[][][] node3 = new Object[size3][][];
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
							node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
						}
					}
				}
				return node5;
			}

			static Object[][][][][][] allocateNode6(final int startIndex6, final int size) {
				final Object[][][][][][] node6 = new Object[(size % (1 << 25) == 0) ? size / (1 << 25) : size / (1 << 25) + 1][][][][][];
				for (int index6 = startIndex6; index6 < node6.length; index6++) {
					final int size5;
					if (index6 == node6.length - 1) {
						final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
						size5 = (totalSize5 % (1 << 20) == 0) ? totalSize5 / (1 << 20) : totalSize5 / (1 << 20) + 1;
					} else {
						size5 = 32;
					}

					final Object[][][][][] node5 = new Object[size5][][][][];
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

						final Object[][][][] node4 = new Object[size4][][][];
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

							final Object[][][] node3 = new Object[size3][][];
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
								final Object[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
								node3[index3] = node2;
							}
						}
					}
				}
				return node6;
			}

			static Object[][][] allocateNode3FromStart(final int fromEndIndex3, final int size) {
				final int size3 = (size % (1 << 10) == 0) ? size / (1 << 10) : size / (1 << 10) + 1;
				final Object[][][] node3 = new Object[size3][][];
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
					node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
				}
				return node3;
			}

			static Object[][][][] allocateNode4FromStart(final int fromEndIndex4, final int size) {
				final int size4 = (size % (1 << 15) == 0) ? size / (1 << 15) : size / (1 << 15) + 1;
				final Object[][][][] node4 = new Object[size4][][][];
				for (int index4 = 0; index4 < size4 - fromEndIndex4; index4++) {
					final int size3;
					if (index4 == 0) {
						final int totalSize3 = (size % (1 << 15) == 0) ? (1 << 15) : size % (1 << 15);
						size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
					} else {
						size3 = 32;
					}
					final Object[][][] node3 = new Object[size3][][];
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
						node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
					}
				}
				return node4;
			}

			static Object[][][][][] allocateNode5FromStart(final int fromEndIndex5, final int size) {
				final int size5 = (size % (1 << 20) == 0) ? size / (1 << 20) : size / (1 << 20) + 1;
				final Object[][][][][] node5 = new Object[size5][][][][];
				for (int index5 = 0; index5 < size5 - fromEndIndex5; index5++) {
					final int size4;
					if (index5 == 0) {
						final int totalSize4 = (size % (1 << 20) == 0) ? (1 << 20) : size % (1 << 20);
						size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
					} else {
						size4 = 32;
					}

					final Object[][][][] node4 = new Object[size4][][][];
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

						final Object[][][] node3 = new Object[size3][][];
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
							node3[index3] = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
						}
					}
				}
				return node5;
			}

			static Object[][][][][][] allocateNode6FromStart(final int fromEndIndex6, final int size) {
				final int size6 = (size % (1 << 25) == 0) ? size / (1 << 25) : size / (1 << 25) + 1;
				final Object[][][][][][] node6 = new Object[size6][][][][][];
				for (int index6 = 0; index6 < size6 - fromEndIndex6; index6++) {
					final int size5;
					if (index6 == 0) {
						final int totalSize5 = (size % (1 << 25) == 0) ? (1 << 25) : size % (1 << 25);
						size5 = (totalSize5 % (1 << 20) == 0) ? totalSize5 / (1 << 20) : totalSize5 / (1 << 20) + 1;
					} else {
						size5 = 32;
					}

					final Object[][][][][] node5 = new Object[size5][][][][];
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

						final Object[][][][] node4 = new Object[size4][][][];
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

							final Object[][][] node3 = new Object[size3][][];
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
								final Object[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
								node3[index3] = node2;
							}
						}
					}
				}
				return node6;
			}

			static int calculateSeq3StartIndex(final Object[][][] node3, final Object[] init) {
				return (1 << 10) - 32*node3[0].length - init.length;
			}

			static int calculateSeq4StartIndex(final Object[][][][] node4, final Object[] init) {
				return (1 << 15) - 32*node4[0][0].length - (1 << 10)*(node4[0].length - 1) - init.length;
			}

			static int calculateSeq5StartIndex(final Object[][][][][] node5, final Object[] init) {
				return (1 << 20) - 32*node5[0][0][0].length - (1 << 10)*(node5[0][0].length - 1) - (1 << 15)*(node5[0].length - 1)
						- init.length;
			}

			static int calculateSeq6StartIndex(final Object[][][][][][] node6, final Object[] init) {
				return (1 << 25) - 32*node6[0][0][0][0].length - (1 << 10)*(node6[0][0][0].length - 1) -
						(1 << 15)*(node6[0][0].length - 1) - (1 << 20)*(node6[0].length - 1) - init.length;
			}

			abstract void initSeqBuilder(final SeqBuilder<A> builder);

			«join»

			@Override
			public Spliterator<A> spliterator() {
				return isEmpty() ? emptySpliterator() : Spliterators.spliterator(iterator(), size(), Spliterator.ORDERED | Spliterator.IMMUTABLE);
			}

			public Stream<A> stream() {
				return StreamSupport.stream(spliterator(), false);
			}

			public Stream<A> parallelStream() {
				return StreamSupport.stream(spliterator(), true);
			}

			«hashcode»

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof Seq<?>) {
					final Seq<?> seq = (Seq<?>) obj;
					if (size() == seq.size()) {
						final Iterator<?> iterator1 = iterator();
						final Iterator<?> iterator2 = seq.iterator();
						while (iterator1.hasNext()) {
							final Object o1 = iterator1.next();
							final Object o2 = iterator2.next();
							if (!o1.equals(o2)) {
								return false;
							}
						}
						return true;
					} else {
						return false;
					}
				} else {
					return false;
				}
			}

			«toStr»

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

			«cast(#["A"], #[], #["A"])»

			public static <A> SeqBuilder<A> seqBuilder() {
				return new SeqBuilder<>();
			}
		}

		«seq0SourceCode»

		«seq1SourceCode»

		«seq2SourceCode»

		«seq3SourceCode»

		«seq4SourceCode»

		«seq5SourceCode»

		«seq6SourceCode»

		final class Seq2Iterator<A> implements Iterator<A> {
			private final Object[][] node2;
			private final Object[] tail;

			private int index2;
			private int index1;
			private Object[] node1;

			Seq2Iterator(final Object[][] node2, final Object[] init, final Object[] tail) {
				this.node2 = node2;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || index2 <= node2.length);
			}

			@Override
			public A next() {
				if (index1 < node1.length) {
					return (A) node1[index1++];
				} else if (index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return (A) node1[0];
				} else if (index2 == node2.length) {
					node1 = tail;
					index2++;
					index1 = 1;
					return (A) node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class Seq3Iterator<A> implements Iterator<A> {
			private final Object[][][] node3;
			private final Object[] tail;

			private int index3;
			private int index2;
			private int index1;
			private Object[][] node2;
			private Object[] node1;

			Seq3Iterator(final Object[][][] node3, final Object[] init, final Object[] tail) {
				this.node3 = node3;
				this.tail = tail;
				node1 = init;
			}

			@Override
			public boolean hasNext() {
				return (index1 < node1.length || (node2 != null && index2 < node2.length) || index3 <= node3.length);
			}

			@Override
			public A next() {
				if (index1 < node1.length) {
					return (A) node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return (A) node1[0];
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
					return (A) node1[0];
				} else if (index3 == node3.length) {
					node2 = null;
					node1 = tail;
					index3++;
					index1 = 1;
					return (A) node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class Seq4Iterator<A> implements Iterator<A> {
			private final Object[][][][] node4;
			private final Object[] tail;

			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private Object[][][] node3;
			private Object[][] node2;
			private Object[] node1;

			Seq4Iterator(final Object[][][][] node4, final Object[] init, final Object[] tail) {
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
			public A next() {
				if (index1 < node1.length) {
					return (A) node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return (A) node1[0];
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
					return (A) node1[0];
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
					return (A) node1[0];
				} else if (index4 == node4.length) {
					node3 = null;
					node2 = null;
					node1 = tail;
					index4++;
					index1 = 1;
					return (A) node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class Seq5Iterator<A> implements Iterator<A> {
			private final Object[][][][][] node5;
			private final Object[] tail;

			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private Object[][][][] node4;
			private Object[][][] node3;
			private Object[][] node2;
			private Object[] node1;

			Seq5Iterator(final Object[][][][][] node5, final Object[] init, final Object[] tail) {
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
			public A next() {
				if (index1 < node1.length) {
					return (A) node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return (A) node1[0];
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
					return (A) node1[0];
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
					return (A) node1[0];
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
					return (A) node1[0];
				} else if (index5 == node5.length) {
					node4 = null;
					node3 = null;
					node2 = null;
					node1 = tail;
					index5++;
					index1 = 1;
					return (A) node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class Seq6Iterator<A> implements Iterator<A> {
			private final Object[][][][][][] node6;
			private final Object[] tail;

			private int index6;
			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private Object[][][][][] node5;
			private Object[][][][] node4;
			private Object[][][] node3;
			private Object[][] node2;
			private Object[] node1;

			Seq6Iterator(final Object[][][][][][] node6, final Object[] init, final Object[] tail) {
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
			public A next() {
				if (index1 < node1.length) {
					return (A) node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return (A) node1[0];
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
					return (A) node1[0];
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
					return (A) node1[0];
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
					return (A) node1[0];
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
					return (A) node1[0];
				} else if (index6 == node6.length) {
					node5 = null;
					node4 = null;
					node3 = null;
					node2 = null;
					node1 = tail;
					index6++;
					index1 = 1;
					return (A) node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class SeqAsList<A> extends IndexedIterableAsList<A, Seq<A>> {
			SeqAsList(final Seq<A> seq) {
				super(seq);
			}

			@Override
			public Object[] toArray() {
				return iterable.toObjectArray();
			}
		}
	''' }

	def seq0SourceCode() { '''
		final class Seq0<A> extends Seq<A> {
			@Override
			public int size() {
				return 0;
			}

			@Override
			public A head() {
				throw new NoSuchElementException();
			}

			@Override
			public A last() {
				throw new NoSuchElementException();
			}

			@Override
			public Seq<A> init() {
				throw new NoSuchElementException();
			}

			@Override
			public Seq<A> tail() {
				throw new NoSuchElementException();
			}

			@Override
			public A get(final int index) {
				throw new IndexOutOfBoundsException(Integer.toString(index));
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> __) {
				throw new IndexOutOfBoundsException(Integer.toString(index));
			}

			@Override
			public Seq<A> take(final int n) {
				return emptySeq();
			}

			@Override
			public Seq<A> prepend(final A value) {
				return append(value);
			}

			@Override
			public Seq<A> append(final A value) {
				final Object[] node1 = { requireNonNull(value) };
				return new Seq1<>(node1);
			}

			@Override
			public Seq<A> concat(final Seq<A> suffix) {
				return requireNonNull(suffix);
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
				return sizedToSeq(suffix, suffixSize);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				return sizedToSeq(prefix, prefixSize);
			}

			@Override
			void initSeqBuilder(final SeqBuilder<A> builder) {
			}

			@Override
			public Object[] toObjectArray() {
				return Array.emptyArray().array;
			}

			@Override
			public Iterator<A> iterator() {
				return emptyIterator();
			}
		}
	''' }

	def seq1SourceCode() { '''
		final class Seq1<A> extends Seq<A> {
			final Object[] node1;

			Seq1(final Object[] node1) {
				this.node1 = node1;
				assert node1.length >= 1 && node1.length <= 32 : "node1.length = " + node1.length;
			}

			@Override
			public int size() {
				return node1.length;
			}

			@Override
			public A head() {
				return (A) node1[0];
			}

			@Override
			public A last() {
				return (A) node1[node1.length - 1];
			}

			@Override
			public Seq<A> init() {
				if (node1.length == 1) {
					return emptySeq();
				} else {
					final Object[] newNode1 = new Object[node1.length - 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length - 1);
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (node1.length == 1) {
					return emptySeq();
				} else {
					final Object[] newNode1 = new Object[node1.length - 1];
					System.arraycopy(node1, 1, newNode1, 0, node1.length - 1);
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public A get(final int index) {
				return (A) node1[index];
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> f) {
				requireNonNull(f);
				final Object[] newNode1 = node1.clone();
				final A oldValue = (A) node1[index];
				final A newValue = f.apply(oldValue);
				newNode1[index] = newValue;
				return new Seq1<>(newNode1);
			}

			@Override
			public Seq<A> take(final int n) {
				if (n <= 0) {
					return emptySeq();
				} else if (n >= node1.length) {
					return this;
				} else {
					final Object[] newNode1 = new Object[n];
					System.arraycopy(node1, 0, newNode1, 0, n);
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				if (node1.length == 32) {
					final Object[] init = { value };
					return new Seq2<>(Seq2.EMPTY_NODE2, init, node1, 33);
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				if (node1.length == 32) {
					final Object[] tail = { value };
					return new Seq2<>(Seq2.EMPTY_NODE2, node1, tail, 33);
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length);
					newNode1[node1.length] = value;
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public Seq<A> concat(final Seq<A> suffix) {
				if (suffix.size() <= 32) {
					return appendSized(suffix.iterator(), suffix.size());
				} else {
					return suffix.prependSized(iterator(), node1.length);
				}
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
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

			private Seq1<A> appendSizedToSeq1(final Iterator<A> suffix, final int size) {
				final Object[] newNode1 = new Object[size];
				System.arraycopy(node1, 0, newNode1, 0, node1.length);
				return fillSeq1(newNode1, node1.length, suffix);
			}

			private Seq2<A> appendSizedToSeq2(final Iterator<A> suffix, final int suffixSize, final int size) {
				final Object[] newTail = allocateTail(suffixSize);
				final int size2 = (suffixSize - newTail.length) / 32;
				final Object[][] newNode2;
				if (size2 == 0) {
					fillArray(newTail, 0, suffix);
					return new Seq2<>(EMPTY_NODE2, node1, newTail, size);
				} else {
					newNode2 = new Object[size2][32];
					return fillSeq2(newNode2, 1, newNode2[0], 0, node1, newTail, size, suffix);
				}
			}

			private Seq3<A> appendSizedToSeq3(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][] newNode3 = allocateNode3(0, maxSize);
				return fillSeq3(newNode3, 1, newNode3[0], 1, newNode3[0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			private Seq4<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][][] newNode4 = allocateNode4(0, maxSize);
				return fillSeq4(newNode4, 1, newNode4[0], 1, newNode4[0][0], 1, newNode4[0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private Seq5<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][][][] newNode5 = allocateNode5(0, maxSize);
				return fillSeq5(newNode5, 1, newNode5[0], 1, newNode5[0][0], 1, newNode5[0][0][0], 1, newNode5[0][0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private Seq6<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][][][][] newNode6 = allocateNode6(0, maxSize);
				return fillSeq6(newNode6, 1, newNode6[0], 1, newNode6[0][0], 1, newNode6[0][0][0], 1, newNode6[0][0][0][0], 1,
						newNode6[0][0][0][0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
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

			private Seq1<A> prependSizedToSeq1(final Iterator<A> prefix, final int size) {
				final Object[] newNode1 = new Object[size];
				System.arraycopy(node1, 0, newNode1, size - node1.length, node1.length);
				return fillSeq1FromStart(newNode1, size - node1.length, prefix);
			}

			private Seq2<A> prependSizedToSeq2(final Iterator<A> prefix, final int prefixSize, final int size) {
				final Object[] newInit = allocateTail(prefixSize);
				final int size2 = (prefixSize - newInit.length) / 32;
				final Object[][] newNode2;
				if (size2 == 0) {
					fillArray(newInit, 0, prefix);
					return new Seq2<>(EMPTY_NODE2, newInit, node1, size);
				} else {
					newNode2 = new Object[size2][32];
					return fillSeq2FromStart(newNode2, 1, newNode2[size2 - 1], 0, newInit, node1, size, prefix);
				}
			}

			private Seq3<A> prependSizedToSeq3(final Iterator<A> prefix, final int prefixSize, final int size, final int maxSize) {
				final Object[] newInit = allocateTail(prefixSize);
				final Object[][][] newNode3 = allocateNode3FromStart(0, maxSize);
				final int startIndex = calculateSeq3StartIndex(newNode3, newInit);
				return fillSeq3FromStart(newNode3, 1, newNode3[newNode3.length - 1], 1, newNode3[newNode3.length - 1][30], 0,
						newInit, node1, startIndex, size, prefix);
			}

			private Seq4<A> prependSizedToSeq4(final Iterator<A> prefix, final int prefixSize, final int size, final int maxSize) {
				final Object[] newInit = allocateTail(prefixSize);
				final Object[][][][] newNode4 = allocateNode4FromStart(0, maxSize);
				final int startIndex = calculateSeq4StartIndex(newNode4, newInit);
				return fillSeq4FromStart(newNode4, 1, newNode4[newNode4.length - 1], 1, newNode4[newNode4.length - 1][31], 1,
						newNode4[newNode4.length - 1][31][30], 0, newInit, node1, startIndex, size, prefix);
			}

			private Seq5<A> prependSizedToSeq5(final Iterator<A> prefix, final int prefixSize, final int size, final int maxSize) {
				final Object[] newInit = allocateTail(prefixSize);
				final Object[][][][][] newNode5 = allocateNode5FromStart(0, maxSize);
				final int startIndex = calculateSeq5StartIndex(newNode5, newInit);
				return fillSeq5FromStart(newNode5, 1, newNode5[newNode5.length - 1], 1, newNode5[newNode5.length - 1][31], 1,
						newNode5[newNode5.length - 1][31][31], 1, newNode5[newNode5.length - 1][31][31][30], 0, newInit, node1,
						startIndex, size, prefix);
			}

			private Seq6<A> prependSizedToSeq6(final Iterator<A> prefix, final int prefixSize, final int size, final int maxSize) {
				final Object[] newInit = allocateTail(prefixSize);
				final Object[][][][][][] newNode6 = allocateNode6FromStart(0, maxSize);
				final int startIndex = calculateSeq6StartIndex(newNode6, newInit);
				return fillSeq6FromStart(newNode6, 1, newNode6[newNode6.length - 1], 1, newNode6[newNode6.length - 1][31], 1,
						newNode6[newNode6.length - 1][31][31], 1, newNode6[newNode6.length - 1][31][31][31], 1,
						newNode6[newNode6.length - 1][31][31][31][30], 0, newInit, node1, startIndex, size, prefix);
			}

			@Override
			void initSeqBuilder(final SeqBuilder<A> builder) {
				if (node1.length == 32) {
					builder.node1 = node1;
				} else {
					builder.node1 = new Object[32];
					System.arraycopy(node1, 0, builder.node1, 0, node1.length);
				}
				builder.index1 = node1.length;
				builder.size = node1.length;
			}

			@Override
			public Object[] toObjectArray() {
				final Object[] array = new Object[node1.length];
				System.arraycopy(node1, 0, array, 0, node1.length);
				return array;
			}

			@Override
			public Iterator<A> iterator() {
				return new ArrayIterator<>(node1);
			}
		}
	''' }

	def seq2SourceCode() { '''
		final class Seq2<A> extends Seq<A> {
			final Object[][] node2;
			final Object[] init;
			final Object[] tail;
			final int size;

			Seq2(final Object[][] node2, final Object[] init, final Object[] tail, final int size) {
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
					for (final Object[] node1 : node2) {
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
			public A head() {
				return (A) init[0];
			}

			@Override
			public A last() {
				return (A) tail[tail.length - 1];
			}

			@Override
			public Seq<A> init() {
				if (tail.length == 1) {
					if (node2.length == 0) {
						return new Seq1<>(init);
					} else if (node2.length == 1) {
						return new Seq2<>(EMPTY_NODE2, init, node2[0], size - 1);
					} else {
						final Object[][] newNode2 = new Object[node2.length - 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
						return new Seq2<>(newNode2, init, node2[node2.length - 1], size - 1);
					}
				} else if (node2.length == 0 && init.length + tail.length == 33) {
					final Object[] node1 = new Object[32];
					System.arraycopy(init, 0, node1, 0, init.length);
					System.arraycopy(tail, 0, node1, init.length, tail.length - 1);
					return new Seq1<>(node1);
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq2<>(node2, init, newTail, size - 1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (init.length == 1) {
					if (node2.length == 0) {
						return new Seq1<>(tail);
					} else if (node2.length == 1) {
						return new Seq2<>(EMPTY_NODE2, node2[0], tail, size - 1);
					} else {
						final Object[][] newNode2 = new Object[node2.length - 1][];
						System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
						return new Seq2<>(newNode2, node2[0], tail, size - 1);
					}
				} else if (node2.length == 0 && init.length + tail.length == 33) {
					final Object[] node1 = new Object[32];
					System.arraycopy(init, 1, node1, 0, init.length - 1);
					System.arraycopy(tail, 0, node1, init.length - 1, tail.length);
					return new Seq1<>(node1);
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq2<>(node2, newInit, tail, size - 1);
				}
			}

			@Override
			public A get(final int index) {
				try {
					if (index < init.length) {
						return (A) init[index];
					} else if (index >= size - tail.length) {
						return (A) tail[index + tail.length - size];
					} else {
						final int idx = index + 32 - init.length;
						return (A) node2[index2(idx) - 1][index1(idx)];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						final A oldValue = (A) init[index];
						final A newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new Seq2<>(node2, newInit, tail, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final A oldValue = (A) tail[tailIndex];
						final A newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new Seq2<>(node2, init, newTail, size);
					} else {
						final Object[][] newNode2 = node2.clone();
						final int idx = index + 32 - init.length;
						final int index2 = index2(idx) - 1;
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final A oldValue = (A) newNode1[index1];
						final A newValue = f.apply(oldValue);
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new Seq2<>(newNode2, init, tail, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> take(final int n) {
				if (n <= 0) {
					return emptySeq();
				} else if (n < init.length) {
					final Object[] node1 = new Object[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new Seq1<>(node1);
				} else if (n == init.length) {
					return new Seq1<>(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					if (n <= 32) {
						final Object[] newNode1 = new Object[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(tail, 0, newNode1, init.length, n - init.length);
						return new Seq1<>(newNode1);
					} else {
						final Object[] newTail = new Object[tail.length + n - size];
						System.arraycopy(tail, 0, newTail, 0, newTail.length);
						return new Seq2<>(node2, init, newTail, n);
					}
				} else {
					final int idx = n + 31 - init.length;
					final int index2 = index2(idx) - 1;
					final Object[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final Object[] newNode1 = new Object[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new Seq1<>(newNode1);
					} else {
						final Object[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new Object[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						final Object[][] newNode2;
						if (index2 == 0) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[index2][];
							System.arraycopy(node2, 0, newNode2, 0, index2);
						}

						return new Seq2<>(newNode2, init, newTail, n);
					}
				}
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				if (init.length == 32) {
					if (node2.length == 30) {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[31][];
						System.arraycopy(node2, 0, newNode2, 1, 30);
						newNode2[0] = init;
						final Object[][][] newNode3 = { EMPTY_NODE2, newNode2 };
						return new Seq3<>(newNode3, newInit, tail, (1 << 10) - 1, size + 1);
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						return new Seq2<>(newNode2, newInit, tail, size + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq2<>(node2, newInit, tail, size + 1);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				if (tail.length == 32) {
					if (node2.length == 30) {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[31][];
						System.arraycopy(node2, 0, newNode2, 0, 30);
						newNode2[30] = tail;
						final Object[][][] newNode3 = { newNode2, EMPTY_NODE2 };
						return new Seq3<>(newNode3, init, newTail, 32 - init.length, size + 1);
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						return new Seq2<>(newNode2, init, newTail, size + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq2<>(node2, init, newTail, size + 1);
				}
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final Object[] newTail = new Object[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new Seq2<>(node2, init, newTail, size + suffixSize);
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

			private Seq2<A> appendSizedToSeq2(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final int size2 = (maxSize - 32 - newTail.length) / 32;
				final Object[][] newNode2 = new Object[size2][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < size2; index2++) {
						newNode2[index2] = new Object[32];
					}
					return fillSeq2(newNode2, node2.length + 1, tail, 32, init, newTail, size + suffixSize, suffix);
				} else {
					for (int index2 = node2.length; index2 < size2; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
					return fillSeq2(newNode2, node2.length + 1, newNode2[node2.length], tail.length,
							init, newTail, size + suffixSize, suffix);
				}
			}

			private Seq3<A> appendSizedToSeq3(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][] newNode3 = allocateNode3(1, maxSize);
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;

				return fillSeq3(newNode3, 1, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			private Seq4<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][] newNode4 = allocateNode4(1, maxSize);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;
				for (int index3 = 1; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[0] = newNode3;

				return fillSeq4(newNode4, 1, newNode3, 1, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			private Seq5<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5(1, maxSize);
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;
				for (int index3 = 1; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[0] = newNode4;

				return fillSeq5(newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			private Seq6<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 31; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[0] = newNode2;
				for (int index3 = 1; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[0] = newNode4;
				for (int index5 = 1; index5 < 32; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, 32 - init.length, size + suffixSize, suffix);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final Object[] newInit = new Object[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new Seq2<>(node2, newInit, tail, size + prefixSize);
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

			private Seq2<A> prependSizedToSeq2(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final int size2 = (maxSize - 32 - newInit.length) / 32;
				final Object[][] newNode2 = new Object[size2][];
				System.arraycopy(node2, 0, newNode2, size2 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[size2 - node2.length - 1] = init;
					for (int index2 = 0; index2 < size2 - node2.length - 1; index2++) {
						newNode2[index2] = new Object[32];
					}
					return fillSeq2FromStart(newNode2, node2.length + 1, init, 32, newInit, tail, size + prefixSize, prefix);
				} else {
					for (int index2 = 0; index2 < size2 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[size2 - node2.length - 1], 32 - init.length, init.length);
					return fillSeq2FromStart(newNode2, node2.length + 1, newNode2[size2 - node2.length - 1], init.length,
							newInit, tail, size + prefixSize, prefix);
				}
			}

			private Seq3<A> prependSizedToSeq3(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][] newNode3 = allocateNode3FromStart(1, maxSize);
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - 1] = newNode2;
				final int startIndex = calculateSeq3StartIndex(newNode3, newInit);

				return fillSeq3FromStart(newNode3, 1, newNode2, node2.length + 1, newNode2[30 - node2.length], init.length,
						newInit, tail, startIndex, size + prefixSize, prefix);
			}

			private Seq4<A> prependSizedToSeq4(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][] newNode4 = allocateNode4FromStart(1, maxSize);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[31] = newNode2;
				for (int index3 = 0; index3 < 31; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[newNode4.length - 1] = newNode3;
				final int startIndex = calculateSeq4StartIndex(newNode4, newInit);

				return fillSeq4FromStart(newNode4, 1, newNode3, 1, newNode2, node2.length + 1, newNode2[30 - node2.length],
						init.length, newInit, tail, startIndex, size + prefixSize, prefix);
			}

			private Seq5<A> prependSizedToSeq5(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5FromStart(1, maxSize);
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[31] = newNode2;
				for (int index3 = 0; index3 < 31; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[newNode5.length - 1] = newNode4;
				final int startIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[30 - node2.length], init.length, newInit, tail, startIndex, size + prefixSize, prefix);
			}

			private Seq6<A> prependSizedToSeq6(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][] newNode2 = new Object[31][];
				System.arraycopy(node2, 0, newNode2, 31 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[30 - node2.length] = init;
					for (int index2 = 0; index2 < 30 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[30 - node2.length], 32 - init.length, init.length);
				}
				newNode3[31] = newNode2;
				for (int index3 = 0; index3 < 31; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[31] = newNode4;
				for (int index5 = 0; index5 < 31; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int startIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, 1, newNode2, node2.length + 1,
						newNode2[30 - node2.length], init.length, newInit, tail, startIndex, size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final SeqBuilder<A> builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new Object[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				builder.node2 = new Object[31][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.startIndex = 32 - init.length;
				builder.size = size;
			}

			@Override
			public Object[] toObjectArray() {
				final Object[] array = new Object[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final Object[] node1 : node2) {
					System.arraycopy(node1, 0, array, index, 32);
					index += 32;
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq2Iterator<>(node2, init, tail);
			}
		}
	''' }

	def seq3SourceCode() { '''
		final class Seq3<A> extends Seq<A> {
			final Object[][][] node3;
			final int startIndex;
			final Object[] init;
			final Object[] tail;
			final int size;

			Seq3(final Object[][][] node3, final Object[] init, final Object[] tail, final int startIndex, final int size) {
				this.node3 = node3;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final Object[][] lastNode2 = node3[node3.length - 1];

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
					for (final Object[][] node2 : node3) {
						for (final Object[] node1 : node2) {
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
			public A head() {
				return (A) init[0];
			}

			@Override
			public A last() {
				return (A) tail[tail.length - 1];
			}

			@Override
			public Seq<A> init() {
				if (tail.length == 1) {
					final Object[][] lastNode2 = node3[node3.length - 1];
					if (lastNode2.length == 0) {
						if (node3.length == 2) {
							final Object[][] node2 = node3[0];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							return new Seq2<>(newNode2, init, node2[node2.length - 1], size - 1);
						} else {
							final Object[][][] newNode3 = new Object[node3.length - 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 2);
							final Object[][] node2 = node3[node3.length - 2];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[node3.length - 2] = newNode2;
							return new Seq3<>(newNode3, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						if (node3.length == 2) {
							final Object[][] firstNode2 = node3[0];
							if (firstNode2.length + lastNode2.length == 31) {
								final Object[][] newNode2 = new Object[30][];
								System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
								System.arraycopy(lastNode2, 0, newNode2, firstNode2.length, lastNode2.length - 1);
								return new Seq2<>(newNode2, init, lastNode2[lastNode2.length - 1], size - 1);
							}
						}

						final Object[][][] newNode3 = node3.clone();
						final Object[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[node3.length - 1] = newNode2;
						return new Seq3<>(newNode3, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq3<>(node3, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (init.length == 1) {
					final Object[][] firstNode2 = node3[0];
					if (firstNode2.length == 0) {
						if (node3.length == 2) {
							final Object[][] node2 = node3[1];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							return new Seq2<>(newNode2, node2[0], tail, size - 1);
						} else {
							final Object[][][] newNode3 = new Object[node3.length - 1][][];
							System.arraycopy(node3, 2, newNode3, 1, node3.length - 2);
							final Object[][] node2 = node3[1];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new Seq3<>(newNode3, node2[0], tail, 0, size - 1);
						}
					} else {
						if (node3.length == 2) {
							final Object[][] lastNode2 = node3[1];
							if (firstNode2.length + lastNode2.length == 31) {
								final Object[][] newNode2 = new Object[30][];
								System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
								System.arraycopy(lastNode2, 0, newNode2, firstNode2.length - 1, lastNode2.length);
								return new Seq2<>(newNode2, firstNode2[0], tail, size - 1);
							}
						}

						final Object[][][] newNode3 = node3.clone();
						final Object[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new Seq3<>(newNode3, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq3<>(node3, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final Object[][] node2) {
				return (index3 == 0) ? index2(idx) + node2.length - 32 : index2(idx);
			}

			@Override
			public A get(final int index) {
				try {
					if (index < init.length) {
						return (A) init[index];
					} else if (index >= size - tail.length) {
						return (A) tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index3 = index3(idx);
						final Object[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, node2);
						final Object[] node1 = node2[index2];
						final int index1 = index1(idx);
						return (A) node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						final A oldValue = (A) init[index];
						final A newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new Seq3<>(node3, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final A oldValue = (A) tail[tailIndex];
						final A newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new Seq3<>(node3, init, newTail, startIndex, size);
					} else {
						final Object[][][] newNode3 = node3.clone();
						final int idx = index + startIndex;
						final int index3 = index3(idx);
						final Object[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, newNode2);
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final A oldValue = (A) newNode1[index1];
						final A newValue = f.apply(oldValue);
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new Seq3<>(newNode3, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> take(final int n) {
				if (n <= 0) {
					return emptySeq();
				} else if (n < init.length) {
					final Object[] node1 = new Object[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new Seq1<>(node1);
				} else if (n == init.length) {
					return new Seq1<>(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final Object[] newTail = new Object[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new Seq3<>(node3, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index3 = index3(idx);
					final Object[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, node2);
					final Object[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final Object[] newNode1 = new Object[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new Seq1<>(newNode1);
					} else {
						final Object[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new Object[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final Object[][] newNode2;
							if (index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final Object[][] firstNode2 = node3[0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new Seq2<>(newNode2, init, newTail, n);
						} else {
							final Object[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new Object[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							final Object[][][] newNode3 = new Object[index3 + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, index3);
							newNode3[index3] = newNode2;
							return new Seq3<>(newNode3, init, newTail, startIndex, n);
						}
					}
				}
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				if (init.length == 32) {
					final Object[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							final Object[] newInit = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final Object[][][] newNode3 = node3.clone();
							newNode3[0] = newNode2;
							final Object[][][][] newNode4 = { { EMPTY_NODE2 }, newNode3 };
							if (startIndex != 0) {
								throw new IllegalStateException("startIndex != 0");
							}
							return new Seq4<>(newNode4, newInit, tail, (1 << 15) - 1, size + 1);
						} else {
							final Object[] newInit = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							if (startIndex != 0) {
								throw new IllegalStateException("startIndex != 0");
							}
							return new Seq3<>(newNode3, newInit, tail, (1 << 10) - 1, size + 1);
						}
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						return new Seq3<>(newNode3, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq3<>(node3, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final Object[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							final Object[] newTail = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final Object[][][] newNode3 = node3.clone();
							newNode3[31] = newNode2;
							final Object[][][][] newNode4 = { newNode3, { EMPTY_NODE2 } };
							return new Seq4<>(newNode4, init, newTail, startIndex, size + 1);
						} else {
							final Object[] newTail = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							return new Seq3<>(newNode3, init, newTail, startIndex, size + 1);
						}
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						return new Seq3<>(newNode3, init, newTail, startIndex, size + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq3<>(node3, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final Object[] newTail = new Object[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new Seq3<>(node3, init, newTail, startIndex, size + suffixSize);
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

			private Seq3<A> appendSizedToSeq3(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][] newNode3 = allocateNode3(node3.length, maxSize);
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);

				final Object[][] newNode2;
				if (node3.length < newNode3.length) {
					newNode2 = new Object[32][];
				} else {
					final int totalSize2 = (maxSize % (1 << 10) == 0) ? (1 << 10) : maxSize % (1 << 10);
					newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
				}
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);

				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;

				return fillSeq3(newNode3, node3.length, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, startIndex, size + suffixSize, suffix);
			}

			private Seq4<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][] newNode4 = allocateNode4(1, maxSize);
				final Object[][][] newNode3 = new Object[32][][];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[0] = newNode3;

				return fillSeq4(newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, startIndex, size + suffixSize, suffix);
			}

			private Seq5<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5(1, maxSize);
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[0] = newNode4;

				return fillSeq5(newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			private Seq6<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[0] = newNode3;
				for (int index4 = 1; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[0] = newNode4;
				for (int index5 = 1; index5 < 32; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final Object[] newInit = new Object[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new Seq3<>(node3, newInit, tail, startIndex - prefixSize, size + prefixSize);
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

			private Seq3<A> prependSizedToSeq3(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][] newNode3 = allocateNode3FromStart(node3.length, maxSize);
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);

				final Object[][] newNode2;
				if (node3.length < newNode3.length) {
					newNode2 = new Object[32][];
				} else {
					final int totalSize2 = (maxSize % (1 << 10) == 0) ? (1 << 10) : maxSize % (1 << 10);
					newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
				}
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);

				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[newNode2.length - node2.length - 1], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - node3.length] = newNode2;
				final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);

				return fillSeq3FromStart(newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex,
						size + prefixSize, prefix);
			}

			private Seq4<A> prependSizedToSeq4(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][] newNode4 = allocateNode4FromStart(1, maxSize);
				final Object[][][] newNode3 = new Object[32][][];
				System.arraycopy(node3, 1, newNode3, 33 - node3.length, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, 32 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[newNode4.length - 1] = newNode3;
				final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);

				return fillSeq4FromStart(newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[31 - node2.length], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private Seq5<A> prependSizedToSeq5(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5FromStart(1, maxSize);
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				System.arraycopy(node3, 1, newNode3, 33 - node3.length, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, 32 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[newNode5.length - 1] = newNode4;
				final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[31 - node2.length], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private Seq6<A> prependSizedToSeq6(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][] newNode3 = new Object[32][][];
				System.arraycopy(node3, 1, newNode3, 33 - node3.length, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, 32 - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[31] = newNode3;
				for (int index4 = 0; index4 < 31; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[31] = newNode4;
				for (int index5 = 0; index5 < 31; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, 1, newNode4, 1, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[31 - node2.length], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final SeqBuilder<A> builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new Object[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final Object[][] node2 = node3[node3.length - 1];
				builder.node2 = new Object[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new Object[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.index1 = tail.length;
				builder.index2 = node2.length + 1;
				builder.index3 = node3.length;
				builder.startIndex = startIndex;
				builder.size = size;
			}

			@Override
			public Object[] toObjectArray() {
				final Object[] array = new Object[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final Object[][] node2 : node3) {
					for (final Object[] node1 : node2) {
						System.arraycopy(node1, 0, array, index, 32);
						index += 32;
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq3Iterator<>(node3, init, tail);
			}
		}
	''' }

	def seq4SourceCode() { '''
		final class Seq4<A> extends Seq<A> {
			final Object[][][][] node4;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int size;

			Seq4(final Object[][][][] node4, final Object[] init, final Object[] tail, final int startIndex, final int size) {
				this.node4 = node4;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final Object[][][] lastNode3 = node4[node4.length - 1];
					final Object[][] lastNode2 = lastNode3[lastNode3.length - 1];

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
						for (final Object[][] node2 : node4[i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 1; i < node4[0].length; i++) {
						assert node4[0][i].length == 32 : "node2.length = " + node4[0][i].length;
					}
					for (int i = 0; i < lastNode3.length - 1; i++) {
						assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
					}

					for (final Object[][][] node3 : node4) {
						for (final Object[][] node2 : node3) {
							for (final Object[] node1 : node2) {
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
			public A head() {
				return (A) init[0];
			}

			@Override
			public A last() {
				return (A) tail[tail.length - 1];
			}

			@Override
			public Seq<A> init() {
				if (tail.length == 1) {
					final Object[][][] lastNode3 = node4[node4.length - 1];
					final Object[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (node4.length == 2) {
								final Object[][][] node3 = node4[0];
								final Object[][][] newNode3 = node3.clone();
								final Object[][] node2 = node3[node3.length - 1];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new Seq3<>(newNode3, init, node2[node2.length - 1], startIndex, size - 1);
							} else {
								final Object[][][][] newNode4 = new Object[node4.length - 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 2);
								final Object[][][] node3 = node4[node4.length - 2];
								final Object[][][] newNode3 = node3.clone();
								newNode4[node4.length - 2] = newNode3;
								final Object[][] node2 = node3[node3.length - 1];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new Seq4<>(newNode4, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							if (node4.length == 2) {
								final Object[][][] firstNode3 = node4[0];
								if (firstNode3.length + lastNode3.length == 33) {
									final Object[][][] newNode3 = new Object[32][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(lastNode3, 0, newNode3, firstNode3.length, lastNode3.length - 1);
									final Object[][] newNode2 = new Object[31][];
									final Object[][] node2 = lastNode3[lastNode3.length - 2];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode3[31] = newNode2;
									final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
									return new Seq3<>(newNode3, init, node2[31], newStartIndex, size - 1);
								}
							}

							final Object[][][][] newNode4 = node4.clone();
							final Object[][][] newNode3 = new Object[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[node4.length - 1] = newNode3;
							final Object[][] node2 = lastNode3[lastNode3.length - 2];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new Seq4<>(newNode4, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final Object[][][][] newNode4 = node4.clone();
						final Object[][][] newNode3 = lastNode3.clone();
						newNode4[node4.length - 1] = newNode3;
						final Object[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new Seq4<>(newNode4, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq4<>(node4, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (init.length == 1) {
					final Object[][][] firstNode3 = node4[0];
					final Object[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (node4.length == 2) {
								final Object[][][] node3 = node4[1];
								final Object[][][] newNode3 = node3.clone();
								final Object[][] node2 = node3[0];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new Seq3<>(newNode3, node2[0], tail, 0, size - 1);
							} else {
								final Object[][][][] newNode4 = new Object[node4.length - 1][][][];
								System.arraycopy(node4, 2, newNode4, 1, node4.length - 2);
								final Object[][][] node3 = node4[1];
								final Object[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final Object[][] node2 = node3[0];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new Seq4<>(newNode4, node2[0], tail, 0, size - 1);
							}
						} else {
							if (node4.length == 2) {
								final Object[][][] lastNode3 = node4[1];
								if (firstNode3.length + lastNode3.length == 33) {
									final Object[][][] newNode3 = new Object[32][][];
									System.arraycopy(firstNode3, 1, newNode3, 0, firstNode3.length - 1);
									System.arraycopy(lastNode3, 0, newNode3, firstNode3.length - 1, lastNode3.length);
									final Object[][] newNode2 = new Object[31][];
									final Object[][] node2 = firstNode3[1];
									System.arraycopy(node2, 1, newNode2, 0, 31);
									newNode3[0] = newNode2;
									final int newStartIndex = calculateSeq3StartIndex(newNode3, node2[0]);
									return new Seq3<>(newNode3, node2[0], tail, newStartIndex, size - 1);
								}
							}

							final Object[][][][] newNode4 = node4.clone();
							final Object[][][] newNode3 = new Object[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final Object[][] node2 = firstNode3[1];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new Seq4<>(newNode4, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final Object[][][][] newNode4 = node4.clone();
						final Object[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final Object[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new Seq4<>(newNode4, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq4<>(node4, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final Object[][] node2) {
				return (index4 == 0 && index3 == 0) ? index2(idx) + node2.length - 32 : index2(idx);
			}

			private static int index3(final int idx, final int index4, final Object[][][] node3) {
				return (index4 == 0) ? index3(idx) + node3.length - 32 : index3(idx);
			}

			@Override
			public A get(final int index) {
				try {
					if (index < init.length) {
						return (A) init[index];
					} else if (index >= size - tail.length) {
						return (A) tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index4 = index4(idx);
						final Object[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, node3);
						final Object[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, node2);
						final Object[] node1 = node2[index2];
						final int index1 = index1(idx);
						return (A) node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						final A oldValue = (A) init[index];
						final A newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new Seq4<>(node4, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final A oldValue = (A) tail[tailIndex];
						final A newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new Seq4<>(node4, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final Object[][][][] newNode4 = node4.clone();
						final int index4 = index4(idx);
						final Object[][][] newNode3 = newNode4[index4].clone();
						final int index3 = index3(idx, index4, newNode3);
						final Object[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, index4, newNode2);
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final A oldValue = (A) newNode1[index1];
						final A newValue = f.apply(oldValue);
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new Seq4<>(newNode4, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> take(final int n) {
				if (n <= 0) {
					return emptySeq();
				} else if (n < init.length) {
					final Object[] node1 = new Object[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new Seq1<>(node1);
				} else if (n == init.length) {
					return new Seq1<>(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final Object[] newTail = new Object[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new Seq4<>(node4, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index4 = index4(idx);
					final Object[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, node3);
					final Object[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, node2);
					final Object[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final Object[] newNode1 = new Object[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new Seq1<>(newNode1);
					} else {
						final Object[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new Object[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final Object[][] newNode2;
							if (index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final Object[][] firstNode2 = node4[0][0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new Seq2<>(newNode2, init, newTail, n);
						} else {
							final Object[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new Object[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							if (n <= (1 << 15) - calculateSeq3StartIndex(node4[0], init)) {
								final Object[][][] newNode3;
								if (index4 == 0) {
									newNode3 = new Object[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final Object[][][] firstNode3 = node4[0];
									newNode3 = new Object[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new Seq3<>(newNode3, init, newTail, newStartIndex, n);
							} else {
								final Object[][][] newNode3 = new Object[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;
								final Object[][][][] newNode4 = new Object[index4 + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, index4);
								newNode4[index4] = newNode3;
								return new Seq4<>(newNode4, init, newTail, startIndex, n);
							}
						}
					}
				}
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				if (init.length == 32) {
					final Object[][][] node3 = node4[0];
					final Object[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								final Object[] newInit = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final Object[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final Object[][][][] newNode4 = node4.clone();
								newNode4[0] = newNode3;
								final Object[][][][][] newNode5 = { { { EMPTY_NODE2 } }, newNode4 };
								if (startIndex != 0) {
									throw new IllegalStateException("startIndex != 0");
								}
								return new Seq5<>(newNode5, newInit, tail, (1 << 20) - 1, size + 1);
							} else {
								final Object[] newInit = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final Object[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new Object[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								if (startIndex != 0) {
									throw new IllegalStateException("startIndex != 0");
								}
								return new Seq4<>(newNode4, newInit, tail, (1 << 15) - 1, size + 1);
							}
						} else {
							final Object[] newInit = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							return new Seq4<>(newNode4, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						return new Seq4<>(newNode4, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq4<>(node4, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final Object[][][] node3 = node4[node4.length - 1];
					final Object[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								final Object[] newTail = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final Object[][][] newNode3 = node3.clone();
								newNode3[31] = newNode2;
								final Object[][][][] newNode4 = node4.clone();
								newNode4[31] = newNode3;
								final Object[][][][][] newNode5 = { newNode4, { { EMPTY_NODE2 } } };
								return new Seq5<>(newNode5, init, newTail, startIndex, size + 1);
							} else {
								final Object[] newTail = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final Object[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new Object[][][] { EMPTY_NODE2 };
								return new Seq4<>(newNode4, init, newTail, startIndex, size + 1);
							}
						} else {
							final Object[] newTail = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							return new Seq4<>(newNode4, init, newTail, startIndex, size + 1);
						}
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						return new Seq4<>(newNode4, init, newTail, startIndex, size + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq4<>(node4, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final Object[] newTail = new Object[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new Seq4<>(node4, init, newTail, startIndex, size + suffixSize);
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

			private Seq4<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][] newNode4 = allocateNode4(node4.length, maxSize);
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);

				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				final Object[][][] newNode3;
				final Object[][] newNode2;
				if (node4.length < newNode4.length) {
					newNode3 = new Object[32][][];
					newNode2 = new Object[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new Object[32][32];
					}
				} else {
					final int totalSize3 = (maxSize % (1 << 15) == 0) ? (1 << 15) : maxSize % (1 << 15);
					newNode3 = allocateNode3(node3.length, totalSize3);
					if (node3.length < newNode3.length) {
						newNode2 = new Object[32][];
					} else {
						final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
						newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
					}
				}
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				newNode4[node4.length - 1] = newNode3;

				return fillSeq4(newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1, newNode2[node2.length], tail.length,
						init, newTail, startIndex, size + suffixSize, suffix);
			}

			private Seq5<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5(1, maxSize);
				final Object[][][][] newNode4 = new Object[32][][][];
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][][] node3 = node4[node4.length - 1];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[node4.length - 1] = newNode3;
				for (int index4 = node4.length; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[0] = newNode4;

				return fillSeq5(newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			private Seq6<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				final Object[][][][] newNode4 = new Object[32][][][];
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][][] node3 = node4[node4.length - 1];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[node4.length - 1] = newNode3;
				for (int index4 = node4.length; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[0] = newNode4;
				for (int index5 = 1; index5 < 32; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final Object[] newInit = new Object[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new Seq4<>(node4, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final Object[][][] node3 = node4[node4.length - 1];
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

			private Seq4<A> prependSizedToSeq4(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][] newNode4 = allocateNode4FromStart(node4.length, maxSize);
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);

				final Object[][][] node3 = node4[0];
				final Object[][] node2 = node3[0];
				final Object[][][] newNode3;
				final Object[][] newNode2;
				if (node4.length < newNode4.length) {
					newNode3 = new Object[32][][];
					newNode2 = new Object[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new Object[32][32];
					}
				} else {
					final int totalSize3 = (maxSize % (1 << 15) == 0) ? (1 << 15) : maxSize % (1 << 15);
					newNode3 = allocateNode3FromStart(node3.length, totalSize3);
					if (node3.length < newNode3.length) {
						newNode2 = new Object[32][];
					} else {
						final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
						newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
					}
				}
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[newNode2.length - node2.length - 1], 32 - init.length, init.length);
				}
				newNode3[newNode3.length - node3.length] = newNode2;
				newNode4[newNode4.length - node4.length] = newNode3;
				final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);

				return fillSeq4FromStart(newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private Seq5<A> prependSizedToSeq5(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5FromStart(1, maxSize);
				final Object[][][][] newNode4 = new Object[32][][][];
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][][] node3 = node4[0];
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[32 - node4.length] = newNode3;
				for (int index4 = 0; index4 < 32 - node4.length; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[newNode5.length - 1] = newNode4;
				final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);

				return fillSeq5FromStart(newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex, size + prefixSize, prefix);
			}

			private Seq6<A> prependSizedToSeq6(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				final Object[][][][] newNode4 = new Object[32][][][];
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][][] node3 = node4[0];
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[32 - node4.length] = newNode3;
				for (int index4 = 0; index4 < 32 - node4.length; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[31] = newNode4;
				for (int index5 = 0; index5 < 31; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, 1, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex,
						size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final SeqBuilder<A> builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new Object[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				builder.node2 = new Object[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new Object[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new Object[32][][][];
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
			public Object[] toObjectArray() {
				final Object[] array = new Object[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final Object[][][] node3 : node4) {
					for (final Object[][] node2 : node3) {
						for (final Object[] node1 : node2) {
							System.arraycopy(node1, 0, array, index, 32);
							index += 32;
						}
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				return array;
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq4Iterator<>(node4, init, tail);
			}
		}
	''' }

	def seq5SourceCode() { '''
		final class Seq5<A> extends Seq<A> {
			final Object[][][][][] node5;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int size;

			Seq5(final Object[][][][][] node5, final Object[] init, final Object[] tail, final int startIndex, final int size) {
				this.node5 = node5;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final Object[][][][] lastNode4 = node5[node5.length - 1];
					final Object[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final Object[][] lastNode2 = lastNode3[lastNode3.length - 1];

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
						for (final Object[][][] node3 : node5[i]) {
							assert node3.length == 32 : "node3.length = " + node3.length;
							for (final Object[][] node2 : node3) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
					}
		
					for (int i = 1; i < node5[0].length; i++) {
						assert node5[0][i].length == 32 : "node3.length = " + node5[0][i].length;
						for (final Object[][] node2 : node5[0][i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 0; i < lastNode4.length - 1; i++) {
						assert lastNode4[i].length == 32 : "node3.length = " + lastNode4[i].length;
						for (final Object[][] node2 : lastNode4[i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 1; i < node5[0][0].length; i++) {
						assert node5[0][0][i].length == 32 : "node2.length = " + node5[0][0][i].length;
					}
					for (int i = 0; i < lastNode3.length - 1; i++) {
						assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
					}
					for (final Object[][][][] node4 : node5) {
						for (final Object[][][] node3 : node4) {
							for (final Object[][] node2 : node3) {
								for (final Object[] node1 : node2) {
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
			public A head() {
				return (A) init[0];
			}

			@Override
			public A last() {
				return (A) tail[tail.length - 1];
			}

			@Override
			public Seq<A> init() {
				if (tail.length == 1) {
					final Object[][][][] lastNode4 = node5[node5.length - 1];
					final Object[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final Object[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (lastNode4.length == 1) {
								if (node5.length == 2) {
									final Object[][][][] node4 = node5[0];
									final Object[][][][] newNode4 = node4.clone();
									final Object[][][] node3 = node4[node4.length - 1];
									final Object[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final Object[][] node2 = node3[node3.length - 1];
									final Object[][] newNode2 = new Object[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new Seq4<>(newNode4, init, node2[node2.length - 1], startIndex, size - 1);
								} else {
									final Object[][][][][] newNode5 = new Object[node5.length - 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 2);
									final Object[][][][] node4 = node5[node5.length - 2];
									final Object[][][][] newNode4 = node4.clone();
									newNode5[node5.length - 2] = newNode4;
									final Object[][][] node3 = node4[node4.length - 1];
									final Object[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final Object[][] node2 = node3[node3.length - 1];
									final Object[][] newNode2 = new Object[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
								}
							} else {
								if (node5.length == 2) {
									final Object[][][][] firstNode4 = node5[0];
									if (firstNode4.length + lastNode4.length == 33) {
										final Object[][][][] newNode4 = new Object[32][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(lastNode4, 0, newNode4, firstNode4.length, lastNode4.length - 2);
										final Object[][][] node3 = lastNode4[lastNode4.length - 2];
										final Object[][][] newNode3 = node3.clone();
										newNode4[31] = newNode3;
										final Object[][] newNode2 = new Object[31][];
										final Object[][] node2 = node3[31];
										System.arraycopy(node2, 0, newNode2, 0, 31);
										newNode3[31] = newNode2;
										final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
										return new Seq4<>(newNode4, init, node2[31], newStartIndex, size - 1);
									}
								}

								final Object[][][][][] newNode5 = node5.clone();
								final Object[][][][] newNode4 = new Object[lastNode4.length - 1][][][];
								System.arraycopy(lastNode4, 0, newNode4, 0, lastNode4.length - 2);
								newNode5[node5.length - 1] = newNode4;
								final Object[][][] node3 = lastNode4[lastNode4.length - 2];
								final Object[][][] newNode3 = node3.clone();
								newNode4[lastNode4.length - 2] = newNode3;
								final Object[][] node2 = node3[node3.length - 1];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							final Object[][][][][] newNode5 = node5.clone();
							final Object[][][][] newNode4 = lastNode4.clone();
							newNode5[node5.length - 1] = newNode4;
							final Object[][][] newNode3 = new Object[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[lastNode4.length - 1] = newNode3;
							final Object[][] node2 = lastNode3[lastNode3.length - 2];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final Object[][][][][] newNode5 = node5.clone();
						final Object[][][][] newNode4 = lastNode4.clone();
						newNode5[node5.length - 1] = newNode4;
						final Object[][][] newNode3 = lastNode3.clone();
						newNode4[lastNode4.length - 1] = newNode3;
						final Object[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new Seq5<>(newNode5, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq5<>(node5, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (init.length == 1) {
					final Object[][][][] firstNode4 = node5[0];
					final Object[][][] firstNode3 = firstNode4[0];
					final Object[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (firstNode4.length == 1) {
								if (node5.length == 2) {
									final Object[][][][] node4 = node5[1];
									final Object[][][][] newNode4 = node4.clone();
									final Object[][][] node3 = node4[0];
									final Object[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final Object[][] node2 = node3[0];
									final Object[][] newNode2 = new Object[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new Seq4<>(newNode4, node2[0], tail, 0, size - 1);
								} else {
									final Object[][][][][] newNode5 = new Object[node5.length - 1][][][][];
									System.arraycopy(node5, 2, newNode5, 1, node5.length - 2);
									final Object[][][][] node4 = node5[1];
									final Object[][][][] newNode4 = node4.clone();
									newNode5[0] = newNode4;
									final Object[][][] node3 = node4[0];
									final Object[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final Object[][] node2 = node3[0];
									final Object[][] newNode2 = new Object[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new Seq5<>(newNode5, node2[0], tail, 0, size - 1);
								}
							} else {
								if (node5.length == 2) {
									final Object[][][][] lastNode4 = node5[1];
									if (firstNode4.length + lastNode4.length == 33) {
										final Object[][][][] newNode4 = new Object[32][][][];
										System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
										System.arraycopy(lastNode4, 0, newNode4, firstNode4.length - 1, lastNode4.length);
										final Object[][][] node3 = firstNode4[1];
										final Object[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final Object[][] newNode2 = new Object[31][];
										final Object[][] node2 = node3[0];
										System.arraycopy(node2, 1, newNode2, 0, 31);
										newNode3[0] = newNode2;
										final int newStartIndex = calculateSeq4StartIndex(newNode4, node2[0]);
										return new Seq4<>(newNode4, node2[0], tail, newStartIndex, size - 1);
									}
								}

								final Object[][][][][] newNode5 = node5.clone();
								final Object[][][][] newNode4 = new Object[firstNode4.length - 1][][][];
								System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
								newNode5[0] = newNode4;
								final Object[][][] node3 = firstNode4[1];
								final Object[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final Object[][] node2 = node3[0];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new Seq5<>(newNode5, node2[0], tail, startIndex + 1, size - 1);
							}
						} else {
							final Object[][][][][] newNode5 = node5.clone();
							final Object[][][][] newNode4 = firstNode4.clone();
							newNode5[0] = newNode4;
							final Object[][][] newNode3 = new Object[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final Object[][] node2 = firstNode3[1];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new Seq5<>(newNode5, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final Object[][][][][] newNode5 = node5.clone();
						final Object[][][][] newNode4 = firstNode4.clone();
						newNode5[0] = newNode4;
						final Object[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final Object[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new Seq5<>(newNode5, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq5<>(node5, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final Object[][] node2) {
				return (index5 == 0 && index4 == 0 && index3 == 0) ? index2(idx) + node2.length - 32 : index2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final Object[][][] node3) {
				return (index5 == 0 && index4 == 0) ? index3(idx) + node3.length - 32 : index3(idx);
			}

			private static int index4(final int idx, final int index5, final Object[][][][] node4) {
				return (index5 == 0) ? index4(idx) + node4.length - 32 : index4(idx);
			}

			@Override
			public A get(final int index) {
				try {
					if (index < init.length) {
						return (A) init[index];
					} else if (index >= size - tail.length) {
						return (A) tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index5 = index5(idx);
						final Object[][][][] node4 = node5[index5];
						final int index4 = index4(idx, index5, node4);
						final Object[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, index5, node3);
						final Object[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, index5, node2);
						final Object[] node1 = node2[index2];
						final int index1 = index1(idx);
						return (A) node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						final A oldValue = (A) init[index];
						final A newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new Seq5<>(node5, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final A oldValue = (A) tail[tailIndex];
						final A newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new Seq5<>(node5, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final Object[][][][][] newNode5 = node5.clone();
						final int index5 = index5(idx);
						final Object[][][][] newNode4 = newNode5[index5].clone();
						final int index4 = index4(idx, index5, newNode4);
						final Object[][][] newNode3 = newNode4[index4].clone();
						final int index3 = index3(idx, index4, index5, newNode3);
						final Object[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, index4, index5, newNode2);
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final A oldValue = (A) newNode1[index1];
						final A newValue = f.apply(oldValue);
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new Seq5<>(newNode5, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> take(final int n) {
				if (n <= 0) {
					return emptySeq();
				} else if (n < init.length) {
					final Object[] node1 = new Object[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new Seq1<>(node1);
				} else if (n == init.length) {
					return new Seq1<>(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final Object[] newTail = new Object[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new Seq5<>(node5, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index5 = index5(idx);
					final Object[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, node4);
					final Object[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, node3);
					final Object[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, node2);
					final Object[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final Object[] newNode1 = new Object[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new Seq1<>(newNode1);
					} else {
						final Object[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new Object[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final Object[][] newNode2;
							if (index5 == 0 && index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final Object[][] firstNode2 = node5[0][0][0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new Seq2<>(newNode2, init, newTail, n);
						} else {
							final Object[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new Object[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							if (n <= (1 << 15) - calculateSeq3StartIndex(node5[0][0], init)) {
								final Object[][][] newNode3;
								if (index5 == 0 && index4 == 0) {
									newNode3 = new Object[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final Object[][][] firstNode3 = node5[0][0];
									newNode3 = new Object[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new Seq3<>(newNode3, init, newTail, newStartIndex, n);
							} else {
								final Object[][][] newNode3 = new Object[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;

								if (n <= (1 << 20) - calculateSeq4StartIndex(node5[0], init)) {
									final Object[][][][] newNode4;
									if (index5 == 0) {
										newNode4 = new Object[index4 + 1][][][];
										System.arraycopy(node4, 0, newNode4, 0, index4);
										newNode4[index4] = newNode3;
									} else {
										final Object[][][][] firstNode4 = node5[0];
										newNode4 = new Object[firstNode4.length + index4 + 1][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(node4, 0, newNode4, firstNode4.length, index4);
										newNode4[firstNode4.length + index4] = newNode3;
									}
									final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
									return new Seq4<>(newNode4, init, newTail, newStartIndex, n);
								} else {
									final Object[][][][] newNode4 = new Object[index4 + 1][][][];
									System.arraycopy(node4, 0, newNode4, 0, index4);
									newNode4[index4] = newNode3;
									final Object[][][][][] newNode5 = new Object[index5 + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, index5);
									newNode5[index5] = newNode4;
									return new Seq5<>(newNode5, init, newTail, startIndex, n);
								}
							}
						}
					}
				}
			}
		

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				if (init.length == 32) {
					final Object[][][][] node4 = node5[0];
					final Object[][][] node3 = node4[0];
					final Object[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									final Object[] newInit = { value };
									final Object[][] newNode2 = new Object[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final Object[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final Object[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final Object[][][][][] newNode5 = node5.clone();
									newNode5[0] = newNode4;
									final Object[][][][][][] newNode6 = { { { { EMPTY_NODE2 } } }, newNode5 };
									if (startIndex != 0) {
										throw new IllegalStateException("startIndex != 0");
									}
									return new Seq6<>(newNode6, newInit, tail, (1 << 25) - 1, size + 1);
								} else {
									final Object[] newInit = { value };
									final Object[][] newNode2 = new Object[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final Object[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final Object[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final Object[][][][][] newNode5 = new Object[node5.length + 1][][][][];
									System.arraycopy(node5, 1, newNode5, 2, node5.length - 1);
									newNode5[0] = new Object[][][][] { { EMPTY_NODE2 } };
									newNode5[1] = newNode4;
									if (startIndex != 0) {
										throw new IllegalStateException("startIndex != 0");
									}
									return new Seq5<>(newNode5, newInit, tail, (1 << 20) - 1, size + 1);
								}
							} else {
								final Object[] newInit = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final Object[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new Object[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								return new Seq5<>(newNode5, newInit, tail, startIndex - 1, size + 1);
							}
						} else {
							final Object[] newInit = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							return new Seq5<>(newNode5, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						return new Seq5<>(newNode5, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq5<>(node5, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final Object[][][][] node4 = node5[node5.length - 1];
					final Object[][][] node3 = node4[node4.length - 1];
					final Object[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									final Object[] newTail = { value };
									final Object[][] newNode2 = new Object[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final Object[][][] newNode3 = node3.clone();
									newNode3[31] = newNode2;
									final Object[][][][] newNode4 = node4.clone();
									newNode4[31] = newNode3;
									final Object[][][][][] newNode5 = node5.clone();
									newNode5[31] = newNode4;
									final Object[][][][][][] newNode6 = { newNode5, { { { EMPTY_NODE2 } } } };
									return new Seq6<>(newNode6, init, newTail, startIndex, size + 1);
								} else {
									final Object[] newTail = { value };
									final Object[][] newNode2 = new Object[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final Object[][][] newNode3 = node3.clone();
									newNode3[node3.length - 1] = newNode2;
									final Object[][][][] newNode4 = node4.clone();
									newNode4[node4.length - 1] = newNode3;
									final Object[][][][][] newNode5 = new Object[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
									newNode5[node5.length - 1] = newNode4;
									newNode5[node5.length] = new Object[][][][] { { EMPTY_NODE2 } };
									return new Seq5<>(newNode5, init, newTail, startIndex, size + 1);
								}
							} else {
								final Object[] newTail = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final Object[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new Object[][][] { EMPTY_NODE2 };
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								return new Seq5<>(newNode5, init, newTail, startIndex, size + 1);
							}
						} else {
							final Object[] newTail = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							return new Seq5<>(newNode5, init, newTail, startIndex, size + 1);
						}
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						return new Seq5<>(newNode5, init, newTail, startIndex, size + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq5<>(node5, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final Object[] newTail = new Object[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new Seq5<>(node5, init, newTail, startIndex, size + suffixSize);
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

			private Seq5<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5(node5.length, maxSize);
				System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);

				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				final Object[][][][] newNode4;
				final Object[][][] newNode3;
				final Object[][] newNode2;
				if (node5.length < newNode5.length) {
					newNode4 = new Object[32][][][];
					newNode3 = new Object[32][][];
					newNode2 = new Object[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new Object[32][32];
					}
					for (int index4 = node4.length; index4 < 32; index4++) {
						newNode4[index4] = new Object[32][32][32];
					}
				} else {
					final int totalSize4 = (maxSize % (1 << 20) == 0) ? (1 << 20) : maxSize % (1 << 20);
					newNode4 = allocateNode4(node4.length, totalSize4);
					if (node4.length < newNode4.length) {
						newNode3 = new Object[32][][];
						newNode2 = new Object[32][];
						for (int index3 = node3.length; index3 < 32; index3++) {
							newNode3[index3] = new Object[32][32];
						}
					} else {
						final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
						newNode3 = allocateNode3(node3.length, totalSize3);
						if (node3.length < newNode3.length) {
							newNode2 = new Object[32][];
						} else {
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
						}
					}
				}
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				newNode4[node4.length - 1] = newNode3;
				newNode5[node5.length - 1] = newNode4;

				return fillSeq5(newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2, node2.length + 1,
						newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			private Seq6<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][][] node4 = node5[node5.length - 1];
				System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][][] node3 = node4[node4.length - 1];
				System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[node3.length - 1];
				System.arraycopy(node2, 0, newNode2, 0, node2.length);
				if (tail.length == 32) {
					newNode2[node2.length] = tail;
					for (int index2 = node2.length + 1; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < 32; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
				}
				newNode3[node3.length - 1] = newNode2;
				for (int index3 = node3.length; index3 < 32; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[node4.length - 1] = newNode3;
				for (int index4 = node4.length; index4 < 32; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[node5.length - 1] = newNode4;
				for (int index5 = node5.length; index5 < 32; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[0] = newNode5;

				return fillSeq6(newNode6, 1, newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[node2.length], tail.length, init, newTail, startIndex, size + suffixSize, suffix);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final Object[] newInit = new Object[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new Seq5<>(node5, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];

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

			private Seq5<A> prependSizedToSeq5(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][] newNode5 = allocateNode5FromStart(node5.length, maxSize);
				System.arraycopy(node5, 1, newNode5, newNode5.length - node5.length + 1, node5.length - 1);

				final Object[][][][] node4 = node5[0];
				final Object[][][] node3 = node4[0];
				final Object[][] node2 = node3[0];
				final Object[][][][] newNode4;
				final Object[][][] newNode3;
				final Object[][] newNode2;
				if (node5.length < newNode5.length) {
					newNode4 = new Object[32][][][];
					newNode3 = new Object[32][][];
					newNode2 = new Object[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new Object[32][32];
					}
					for (int index4 = 0; index4 < 32 - node4.length; index4++) {
						newNode4[index4] = new Object[32][32][32];
					}
				} else {
					final int totalSize4 = (maxSize % (1 << 20) == 0) ? (1 << 20) : maxSize % (1 << 20);
					newNode4 = allocateNode4FromStart(node4.length, totalSize4);
					if (node4.length < newNode4.length) {
						newNode3 = new Object[32][][];
						newNode2 = new Object[32][];
						for (int index3 = 0; index3 < 32 - node3.length; index3++) {
							newNode3[index3] = new Object[32][32];
						}
					} else {
						final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
						newNode3 = allocateNode3FromStart(node3.length, totalSize3);
						if (node3.length < newNode3.length) {
							newNode2 = new Object[32][];
						} else {
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
						}
					}
				}
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[newNode2.length - node2.length - 1] = init;
					for (int index2 = 0; index2 < newNode2.length - node2.length - 1; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new Object[32];
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

			private Seq6<A> prependSizedToSeq6(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6FromStart(1, maxSize);
				final Object[][][][][] newNode5 = new Object[32][][][][];
				System.arraycopy(node5, 1, newNode5, newNode5.length - node5.length + 1, node5.length - 1);
				final Object[][][][] newNode4 = new Object[32][][][];
				final Object[][][][] node4 = node5[0];
				System.arraycopy(node4, 1, newNode4, newNode4.length - node4.length + 1, node4.length - 1);
				final Object[][][] newNode3 = new Object[32][][];
				final Object[][][] node3 = node4[0];
				System.arraycopy(node3, 1, newNode3, newNode3.length - node3.length + 1, node3.length - 1);
				final Object[][] newNode2 = new Object[32][];
				final Object[][] node2 = node3[0];
				System.arraycopy(node2, 0, newNode2, newNode2.length - node2.length, node2.length);
				if (init.length == 32) {
					newNode2[31 - node2.length] = init;
					for (int index2 = 0; index2 < 31 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < 32 - node2.length; index2++) {
						newNode2[index2] = new Object[32];
					}
					System.arraycopy(init, 0, newNode2[31 - node2.length], 32 - init.length, init.length);
				}
				newNode3[32 - node3.length] = newNode2;
				for (int index3 = 0; index3 < 32 - node3.length; index3++) {
					newNode3[index3] = new Object[32][32];
				}
				newNode4[32 - node4.length] = newNode3;
				for (int index4 = 0; index4 < 32 - node4.length; index4++) {
					newNode4[index4] = new Object[32][32][32];
				}
				newNode5[32 - node5.length] = newNode4;
				for (int index5 = 0; index5 < 32 - node5.length; index5++) {
					newNode5[index5] = new Object[32][32][32][32];
				}
				newNode6[newNode6.length - 1] = newNode5;
				final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);

				return fillSeq6FromStart(newNode6, 1, newNode5, node5.length, newNode4, node4.length, newNode3, node3.length, newNode2,
						node2.length + 1, newNode2[newNode2.length - node2.length - 1], init.length, newInit, tail, newStartIndex,
						size + prefixSize, prefix);
			}

			@Override
			void initSeqBuilder(final SeqBuilder<A> builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new Object[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				builder.node2 = new Object[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new Object[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new Object[32][][][];
				System.arraycopy(node4, 0, builder.node4, 0, node4.length - 1);
				builder.node4[node4.length - 1] = builder.node3;
				builder.node5 = new Object[32][][][][];
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
			public Object[] toObjectArray() {
				final Object[] array = new Object[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final Object[][][][] node4 : node5) {
					for (final Object[][][] node3 : node4) {
						for (final Object[][] node2 : node3) {
							for (final Object[] node1 : node2) {
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
			public Iterator<A> iterator() {
				return new Seq5Iterator<>(node5, init, tail);
			}
		}
	''' }

	def seq6SourceCode() { '''
		final class Seq6<A> extends Seq<A> {
			final Object[][][][][][] node6;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int size;

			Seq6(final Object[][][][][][] node6, final Object[] init, final Object[] tail, final int startIndex, final int size) {
				this.node6 = node6;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;

				boolean ea = false;
				assert ea = true;
				if (ea) {
					final Object[][][][][] lastNode5 = node6[node6.length - 1];
					final Object[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
					final Object[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final Object[][] lastNode2 = lastNode3[lastNode3.length - 1];

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
						for (final Object[][][][] node4 : node6[i]) {
							assert node4.length == 32 : "node4.length = " + node4.length;
							for (final Object[][][] node3 : node4) {
								assert node3.length == 32 : "node3.length = " + node3.length;
								for (final Object[][] node2 : node3) {
									assert node2.length == 32 : "node2.length = " + node2.length;
								}
							}
						}
					}

					for (int i = 1; i < node6[0].length; i++) {
						assert node6[0][i].length == 32 : "node4.length = " + node6[0][i].length;
						for (final Object[][][] node3 : node6[0][i]) {
							assert node3.length == 32 : "node3.length = " + node3.length;
							for (final Object[][] node2 : node3) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
					}
					for (int i = 0; i < lastNode5.length - 1; i++) {
						assert lastNode5[i].length == 32 : "node4.length = " + lastNode5[i].length;
						for (final Object[][][] node3 : lastNode5[i]) {
							assert node3.length == 32 : "node3.length = " + node3.length;
							for (final Object[][] node2 : node3) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
					}
					for (int i = 1; i < node6[0][0].length; i++) {
						assert node6[0][0][i].length == 32 : "node3.length = " + node6[0][0][i].length;
						for (final Object[][] node2 : node6[0][0][i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 0; i < lastNode4.length - 1; i++) {
						assert lastNode4[i].length == 32 : "node3.length = " + lastNode4[i].length;
						for (final Object[][] node2 : lastNode4[i]) {
							assert node2.length == 32 : "node2.length = " + node2.length;
						}
					}
					for (int i = 1; i < node6[0][0][0].length; i++) {
						assert node6[0][0][0][i].length == 32 : "node2.length = " + node6[0][0][0][i].length;
					}
					for (int i = 0; i < lastNode3.length - 1; i++) {
						assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
					}
					for (final Object[][][][][] node5 : node6) {
						for (final Object[][][][] node4 : node5) {
							for (final Object[][][] node3 : node4) {
								for (final Object[][] node2 : node3) {
									for (final Object[] node1 : node2) {
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
			public A head() {
				return (A) init[0];
			}

			@Override
			public A last() {
				return (A) tail[tail.length - 1];
			}

			@Override
			public Seq<A> init() {
				if (tail.length == 1) {
					final Object[][][][][] lastNode5 = node6[node6.length - 1];
					final Object[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
					final Object[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final Object[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (lastNode4.length == 1) {
								if (lastNode5.length == 1) {
									if (node6.length == 2) {
										final Object[][][][][] node5 = node6[0];
										final Object[][][][][] newNode5 = node5.clone();
										final Object[][][][] node4 = node5[node5.length - 1];
										final Object[][][][] newNode4 = node4.clone();
										newNode5[node5.length - 1] = newNode4;
										final Object[][][] node3 = node4[node4.length - 1];
										final Object[][][] newNode3 = node3.clone();
										newNode4[node4.length - 1] = newNode3;
										final Object[][] node2 = node3[node3.length - 1];
										final Object[][] newNode2 = new Object[node2.length - 1][];
										System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
										newNode3[node3.length - 1] = newNode2;
										return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
									} else {
										final Object[][][][][][] newNode6 = new Object[node6.length - 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, node6.length - 2);
										final Object[][][][][] node5 = node6[node6.length - 2];
										final Object[][][][][] newNode5 = node5.clone();
										newNode6[node6.length - 2] = newNode5;
										final Object[][][][] node4 = node5[node5.length - 1];
										final Object[][][][] newNode4 = node4.clone();
										newNode5[node5.length - 1] = newNode4;
										final Object[][][] node3 = node4[node4.length - 1];
										final Object[][][] newNode3 = node3.clone();
										newNode4[node4.length - 1] = newNode3;
										final Object[][] node2 = node3[node3.length - 1];
										final Object[][] newNode2 = new Object[node2.length - 1][];
										System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
										newNode3[node3.length - 1] = newNode2;
										return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
									}
								} else {
									if (node6.length == 2) {
										final Object[][][][][] firstNode5 = node6[0];
										if (firstNode5.length + lastNode5.length == 33) {
											final Object[][][][][] newNode5 = new Object[32][][][][];
											System.arraycopy(firstNode5, 0, newNode5, 0, firstNode5.length);
											System.arraycopy(lastNode5, 0, newNode5, firstNode5.length, lastNode5.length - 2);
											final Object[][][][] node4 = lastNode5[lastNode5.length - 2];
											final Object[][][][] newNode4 = node4.clone();
											newNode5[31] = newNode4;
											final Object[][][] node3 = node4[31];
											final Object[][][] newNode3 = node3.clone();
											newNode4[31] = newNode3;
											final Object[][] newNode2 = new Object[31][];
											final Object[][] node2 = node3[31];
											System.arraycopy(node2, 0, newNode2, 0, 31);
											newNode3[31] = newNode2;
											final int newStartIndex = calculateSeq5StartIndex(newNode5, init);
											return new Seq5<>(newNode5, init, node2[31], newStartIndex, size - 1);
										}
									}

									final Object[][][][][][] newNode6 = node6.clone();
									final Object[][][][][] newNode5 = new Object[lastNode5.length - 1][][][][];
									System.arraycopy(lastNode5, 0, newNode5, 0, lastNode5.length - 2);
									newNode6[node6.length - 1] = newNode5;
									final Object[][][][] node4 = lastNode5[lastNode5.length - 2];
									final Object[][][][] newNode4 = node4.clone();
									newNode5[lastNode5.length - 2] = newNode4;
									final Object[][][] node3 = node4[node4.length - 1];
									final Object[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final Object[][] node2 = node3[node3.length - 1];
									final Object[][] newNode2 = new Object[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
								}
							} else {
								final Object[][][][][][] newNode6 = node6.clone();
								final Object[][][][][] newNode5 = lastNode5.clone();
								newNode6[node6.length - 1] = newNode5;
								final Object[][][][] newNode4 = new Object[lastNode4.length - 1][][][];
								System.arraycopy(lastNode4, 0, newNode4, 0, lastNode4.length - 2);
								newNode5[lastNode5.length - 1] = newNode4;
								final Object[][][] node3 = lastNode4[lastNode4.length - 2];
								final Object[][][] newNode3 = node3.clone();
								newNode4[lastNode4.length - 2] = newNode3;
								final Object[][] node2 = node3[node3.length - 1];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							final Object[][][][][][] newNode6 = node6.clone();
							final Object[][][][][] newNode5 = lastNode5.clone();
							newNode6[node6.length - 1] = newNode5;
							final Object[][][][] newNode4 = lastNode4.clone();
							newNode5[lastNode5.length - 1] = newNode4;
							final Object[][][] newNode3 = new Object[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[lastNode4.length - 1] = newNode3;
							final Object[][] node2 = lastNode3[lastNode3.length - 2];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final Object[][][][][][] newNode6 = node6.clone();
						final Object[][][][][] newNode5 = lastNode5.clone();
						newNode6[node6.length - 1] = newNode5;
						final Object[][][][] newNode4 = lastNode4.clone();
						newNode5[lastNode5.length - 1] = newNode4;
						final Object[][][] newNode3 = lastNode3.clone();
						newNode4[lastNode4.length - 1] = newNode3;
						final Object[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new Seq6<>(newNode6, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq6<>(node6, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (init.length == 1) {
					final Object[][][][][] firstNode5 = node6[0];
					final Object[][][][] firstNode4 = firstNode5[0];
					final Object[][][] firstNode3 = firstNode4[0];
					final Object[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (firstNode4.length == 1) {
								if (firstNode5.length == 1) {
									if (node6.length == 2) {
										final Object[][][][][] node5 = node6[1];
										final Object[][][][][] newNode5 = node5.clone();
										final Object[][][][] node4 = node5[0];
										final Object[][][][] newNode4 = node4.clone();
										newNode5[0] = newNode4;
										final Object[][][] node3 = node4[0];
										final Object[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final Object[][] node2 = node3[0];
										final Object[][] newNode2 = new Object[node2.length - 1][];
										System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
										newNode3[0] = newNode2;
										return new Seq5<>(newNode5, node2[0], tail, 0, size - 1);
									} else {
										final Object[][][][][][] newNode6 = new Object[node6.length - 1][][][][][];
										System.arraycopy(node6, 2, newNode6, 1, node6.length - 2);
										final Object[][][][][] node5 = node6[1];
										final Object[][][][][] newNode5 = node5.clone();
										newNode6[0] = newNode5;
										final Object[][][][] node4 = node5[0];
										final Object[][][][] newNode4 = node4.clone();
										newNode5[0] = newNode4;
										final Object[][][] node3 = node4[0];
										final Object[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final Object[][] node2 = node3[0];
										final Object[][] newNode2 = new Object[node2.length - 1][];
										System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
										newNode3[0] = newNode2;
										return new Seq6<>(newNode6, node2[0], tail, 0, size - 1);
									}
								} else {
									if (node6.length == 2) {
										final Object[][][][][] lastNode5 = node6[1];
										if (firstNode5.length + lastNode5.length == 33) {
											final Object[][][][][] newNode5 = new Object[32][][][][];
											System.arraycopy(firstNode5, 2, newNode5, 1, firstNode5.length - 2);
											System.arraycopy(lastNode5, 0, newNode5, firstNode5.length - 1, lastNode5.length);
											final Object[][][][] node4 = firstNode5[1];
											final Object[][][][] newNode4 = node4.clone();
											newNode5[0] = newNode4;
											final Object[][][] node3 = node4[0];
											final Object[][][] newNode3 = node3.clone();
											newNode4[0] = newNode3;
											final Object[][] newNode2 = new Object[31][];
											final Object[][] node2 = node3[0];
											System.arraycopy(node2, 1, newNode2, 0, 31);
											newNode3[0] = newNode2;
											final int newStartIndex = calculateSeq5StartIndex(newNode5, node2[0]);
											return new Seq5<>(newNode5, node2[0], tail, newStartIndex, size - 1);
										}
									}

									final Object[][][][][][] newNode6 = node6.clone();
									final Object[][][][][] newNode5 = new Object[firstNode5.length - 1][][][][];
									System.arraycopy(firstNode5, 2, newNode5, 1, firstNode5.length - 2);
									newNode6[0] = newNode5;
									final Object[][][][] node4 = firstNode5[1];
									final Object[][][][] newNode4 = node4.clone();
									newNode5[0] = newNode4;
									final Object[][][] node3 = node4[0];
									final Object[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final Object[][] node2 = node3[0];
									final Object[][] newNode2 = new Object[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new Seq6<>(newNode6, node2[0], tail, startIndex + 1, size - 1);
								}
							} else {
								final Object[][][][][][] newNode6 = node6.clone();
								final Object[][][][][] newNode5 = firstNode5.clone();
								newNode6[0] = newNode5;
								final Object[][][][] newNode4 = new Object[firstNode4.length - 1][][][];
								System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
								newNode5[0] = newNode4;
								final Object[][][] node3 = firstNode4[1];
								final Object[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final Object[][] node2 = node3[0];
								final Object[][] newNode2 = new Object[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new Seq6<>(newNode6, node2[0], tail, startIndex + 1, size - 1);
							}
						} else {
							final Object[][][][][][] newNode6 = node6.clone();
							final Object[][][][][] newNode5 = firstNode5.clone();
							newNode6[0] = newNode5;
							final Object[][][][] newNode4 = firstNode4.clone();
							newNode5[0] = newNode4;
							final Object[][][] newNode3 = new Object[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final Object[][] node2 = firstNode3[1];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new Seq6<>(newNode6, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final Object[][][][][][] newNode6 = node6.clone();
						final Object[][][][][] newNode5 = firstNode5.clone();
						newNode6[0] = newNode5;
						final Object[][][][] newNode4 = firstNode4.clone();
						newNode5[0] = newNode4;
						final Object[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final Object[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new Object[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new Seq6<>(newNode6, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq6<>(node6, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final int index6, final Object[][] node2) {
				return (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) ? index2(idx) + node2.length - 32 : index2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final int index6, final Object[][][] node3) {
				return (index6 == 0 && index5 == 0 && index4 == 0) ? index3(idx) + node3.length - 32 : index3(idx);
			}

			private static int index4(final int idx, final int index5, final int index6, final Object[][][][] node4) {
				return (index6 == 0 && index5 == 0) ? index4(idx) + node4.length - 32 : index4(idx);
			}

			private static int index5(final int idx, final int index6, final Object[][][][][] node5) {
				return (index6 == 0) ? index5(idx) + node5.length - 32 : index5(idx);
			}

			@Override
			public A get(final int index) {
				try {
					if (index < init.length) {
						return (A) init[index];
					} else if (index >= size - tail.length) {
						return (A) tail[index + tail.length - size];
					} else {
						final int idx = index + startIndex;
						final int index6 = index6(idx);
						final Object[][][][][] node5 = node6[index6];
						final int index5 = index5(idx, index6, node5);
						final Object[][][][] node4 = node5[index5];
						final int index4 = index4(idx, index5, index6, node4);
						final Object[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, index5, index6, node3);
						final Object[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, index5, index6, node2);
						final Object[] node1 = node2[index2];
						final int index1 = index1(idx);
						return (A) node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> update(final int index, final F<A, A> f) {
				requireNonNull(f);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						final A oldValue = (A) init[index];
						final A newValue = f.apply(oldValue);
						newInit[index] = newValue;
						return new Seq6<>(node6, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						final int tailIndex = index + tail.length - size;
						final A oldValue = (A) tail[tailIndex];
						final A newValue = f.apply(oldValue);
						newTail[tailIndex] = newValue;
						return new Seq6<>(node6, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final Object[][][][][][] newNode6 = node6.clone();
						final int index6 = index6(idx);
						final Object[][][][][] newNode5 = newNode6[index6].clone();
						final int index5 = index5(idx, index6, newNode5);
						final Object[][][][] newNode4 = newNode5[index5].clone();
						final int index4 = index4(idx, index5, index6, newNode4);
						final Object[][][] newNode3 = newNode4[index4].clone();
						final int index3 = index3(idx, index4, index5, index6, newNode3);
						final Object[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, index4, index5, index6, newNode2);
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						final A oldValue = (A) newNode1[index1];
						final A newValue = f.apply(oldValue);
						newNode6[index6] = newNode5;
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = newValue;
						return new Seq6<>(newNode6, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public Seq<A> take(final int n) {
				if (n <= 0) {
					return emptySeq();
				} else if (n < init.length) {
					final Object[] node1 = new Object[n];
					System.arraycopy(init, 0, node1, 0, n);
					return new Seq1<>(node1);
				} else if (n == init.length) {
					return new Seq1<>(init);
				} else if (n >= size) {
					return this;
				} else if (n > size - tail.length) {
					final Object[] newTail = new Object[tail.length + n - size];
					System.arraycopy(tail, 0, newTail, 0, newTail.length);
					return new Seq6<>(node6, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index6 = index6(idx);
					final Object[][][][][] node5 = node6[index6];
					final int index5 = index5(idx, index6, node5);
					final Object[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, index6, node4);
					final Object[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, index6, node3);
					final Object[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, index6, node2);
					final Object[] node1 = node2[index2];
					final int index1 = index1(idx);

					if (n <= 32) {
						final Object[] newNode1 = new Object[n];
						System.arraycopy(init, 0, newNode1, 0, init.length);
						System.arraycopy(node1, 0, newNode1, init.length, index1 + 1);
						return new Seq1<>(newNode1);
					} else {
						final Object[] newTail;
						if (index1 == 31) {
							newTail = node1;
						} else {
							newTail = new Object[index1 + 1];
							System.arraycopy(node1, 0, newTail, 0, newTail.length);
						}

						if (n <= 1024 - 32 + init.length) {
							final Object[][] newNode2;
							if (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final Object[][] firstNode2 = node6[0][0][0][0];
								if (firstNode2.length + index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new Object[firstNode2.length + index2][];
									System.arraycopy(firstNode2, 0, newNode2, 0, firstNode2.length);
									System.arraycopy(node2, 0, newNode2, firstNode2.length, index2);
								}
							}
							return new Seq2<>(newNode2, init, newTail, n);
						} else {
							final Object[][] newNode2;
							if (index2 == 0) {
								newNode2 = EMPTY_NODE2;
							} else {
								newNode2 = new Object[index2][];
								System.arraycopy(node2, 0, newNode2, 0, index2);
							}

							if (n <= (1 << 15) - calculateSeq3StartIndex(node6[0][0][0], init)) {
								final Object[][][] newNode3;
								if (index6 == 0 && index5 == 0 && index4 == 0) {
									newNode3 = new Object[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final Object[][][] firstNode3 = node6[0][0][0];
									newNode3 = new Object[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new Seq3<>(newNode3, init, newTail, newStartIndex, n);
							} else {
								final Object[][][] newNode3 = new Object[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;

								if (n <= (1 << 20) - calculateSeq4StartIndex(node6[0][0], init)) {
									final Object[][][][] newNode4;
									if (index6 == 0 && index5 == 0) {
										newNode4 = new Object[index4 + 1][][][];
										System.arraycopy(node4, 0, newNode4, 0, index4);
										newNode4[index4] = newNode3;
									} else {
										final Object[][][][] firstNode4 = node6[0][0];
										newNode4 = new Object[firstNode4.length + index4 + 1][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(node4, 0, newNode4, firstNode4.length, index4);
										newNode4[firstNode4.length + index4] = newNode3;
									}
									final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
									return new Seq4<>(newNode4, init, newTail, newStartIndex, n);
								} else {
									final Object[][][][] newNode4 = new Object[index4 + 1][][][];
									System.arraycopy(node4, 0, newNode4, 0, index4);
									newNode4[index4] = newNode3;

									if (n <= (1 << 25) - calculateSeq5StartIndex(node6[0], init)) {
										final Object[][][][][] newNode5;
										if (index6 == 0) {
											newNode5 = new Object[index5 + 1][][][][];
											System.arraycopy(node5, 0, newNode5, 0, index5);
											newNode5[index5] = newNode4;
										} else {
											final Object[][][][][] firstNode5 = node6[0];
											newNode5 = new Object[firstNode5.length + index5 + 1][][][][];
											System.arraycopy(firstNode5, 0, newNode5, 0, firstNode5.length);
											System.arraycopy(node5, 0, newNode5, firstNode5.length, index5);
											newNode5[firstNode5.length + index5] = newNode4;
										}
										final int newStartIndex = calculateSeq5StartIndex(newNode5, init);
										return new Seq5<>(newNode5, init, newTail, newStartIndex, n);
									} else {
										final Object[][][][][] newNode5 = new Object[index5 + 1][][][][];
										System.arraycopy(node5, 0, newNode5, 0, index5);
										newNode5[index5] = newNode4;
										final Object[][][][][][] newNode6 = new Object[index6 + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, index6);
										newNode6[index6] = newNode5;
										return new Seq6<>(newNode6, init, newTail, startIndex, n);
									}
								}
							}
						}
					}
				}
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				if (init.length == 32) {
					final Object[][][][][] node5 = node6[0];
					final Object[][][][] node4 = node5[0];
					final Object[][][] node3 = node4[0];
					final Object[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									if (node6.length == 32) {
										throw new IndexOutOfBoundsException("Seq size limit exceeded");
									} else {
										final Object[] newInit = { value };
										final Object[][] newNode2 = new Object[32][];
										System.arraycopy(node2, 0, newNode2, 1, 31);
										newNode2[0] = init;
										final Object[][][] newNode3 = node3.clone();
										newNode3[0] = newNode2;
										final Object[][][][] newNode4 = node4.clone();
										newNode4[0] = newNode3;
										final Object[][][][][] newNode5 = node5.clone();
										newNode5[0] = newNode4;
										final Object[][][][][][] newNode6 = new Object[node6.length + 1][][][][][];
										System.arraycopy(node6, 1, newNode6, 2, node6.length - 1);
										newNode6[0] = new Object[][][][][] { { { EMPTY_NODE2 } } };
										newNode6[1] = newNode5;
										if (startIndex != 0) {
											throw new IllegalStateException("startIndex != 0");
										}
										return new Seq6<>(newNode6, newInit, tail, (1 << 25) - 1, size + 1);
									}
								} else {
									final Object[] newInit = { value };
									final Object[][] newNode2 = new Object[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final Object[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final Object[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final Object[][][][][] newNode5 = new Object[node5.length + 1][][][][];
									System.arraycopy(node5, 1, newNode5, 2, node5.length - 1);
									newNode5[0] = new Object[][][][] { { EMPTY_NODE2 } };
									newNode5[1] = newNode4;
									final Object[][][][][][] newNode6 = node6.clone();
									newNode6[0] = newNode5;
									return new Seq6<>(newNode6, newInit, tail, startIndex - 1, size + 1);
								}
							} else {
								final Object[] newInit = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final Object[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new Object[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								final Object[][][][][][] newNode6 = node6.clone();
								newNode6[0] = newNode5;
								return new Seq6<>(newNode6, newInit, tail, startIndex - 1, size + 1);
							}
						} else {
							final Object[] newInit = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							final Object[][][][][][] newNode6 = node6.clone();
							newNode6[0] = newNode5;
							return new Seq6<>(newNode6, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						final Object[][][][][][] newNode6 = node6.clone();
						newNode6[0] = newNode5;
						return new Seq6<>(newNode6, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq6<>(node6, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				if (tail.length == 32) {
					final Object[][][][][] node5 = node6[node6.length - 1];
					final Object[][][][] node4 = node5[node5.length - 1];
					final Object[][][] node3 = node4[node4.length - 1];
					final Object[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									if (node6.length == 32) {
										throw new IndexOutOfBoundsException("Seq size limit exceeded");
									} else {
										final Object[] newTail = { value };
										final Object[][] newNode2 = new Object[32][];
										System.arraycopy(node2, 0, newNode2, 0, 31);
										newNode2[31] = tail;
										final Object[][][] newNode3 = node3.clone();
										newNode3[node3.length - 1] = newNode2;
										final Object[][][][] newNode4 = node4.clone();
										newNode4[node4.length - 1] = newNode3;
										final Object[][][][][] newNode5 = node5.clone();
										newNode5[node5.length - 1] = newNode4;
										final Object[][][][][][] newNode6 = new Object[node6.length + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, node6.length - 1);
										newNode6[node6.length - 1] = newNode5;
										newNode6[node6.length] = new Object[][][][][] { { { EMPTY_NODE2 } } };
										return new Seq6<>(newNode6, init, newTail, startIndex, size + 1);
									}
								} else {
									final Object[] newTail = { value };
									final Object[][] newNode2 = new Object[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final Object[][][] newNode3 = node3.clone();
									newNode3[node3.length - 1] = newNode2;
									final Object[][][][] newNode4 = node4.clone();
									newNode4[node4.length - 1] = newNode3;
									final Object[][][][][] newNode5 = new Object[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
									newNode5[node5.length - 1] = newNode4;
									newNode5[node5.length] = new Object[][][][] { { EMPTY_NODE2 } };
									final Object[][][][][][] newNode6 = node6.clone();
									newNode6[newNode6.length - 1] = newNode5;
									return new Seq6<>(newNode6, init, newTail, startIndex, size + 1);
								}
							} else {
								final Object[] newTail = { value };
								final Object[][] newNode2 = new Object[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final Object[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new Object[][][] { EMPTY_NODE2 };
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								final Object[][][][][][] newNode6 = node6.clone();
								newNode6[newNode6.length - 1] = newNode5;
								return new Seq6<>(newNode6, init, newTail, startIndex, size + 1);
							}
						} else {
							final Object[] newTail = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							final Object[][][][][][] newNode6 = node6.clone();
							newNode6[newNode6.length - 1] = newNode5;
							return new Seq6<>(newNode6, init, newTail, startIndex, size + 1);
						}
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						final Object[][][][][][] newNode6 = node6.clone();
						newNode6[newNode6.length - 1] = newNode5;
						return new Seq6<>(newNode6, init, newTail, startIndex, size + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq6<>(node6, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			Seq<A> appendSized(final Iterator<A> suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (tail.length + suffixSize <= 32) {
					final Object[] newTail = new Object[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new Seq6<>(node6, init, newTail, startIndex, size + suffixSize);
				}

				final int maxSize = size - init.length - 32*node6[0][0][0][0].length - (1 << 10)*(node6[0][0][0].length - 1)
						- (1 << 15)*(node6[0][0].length - 1) - (1 << 20)*(node6[0].length - 1) + (1 << 25) + suffixSize;
				if (maxSize >= 0 && maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private Seq6<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
				final Object[] newTail = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6(node6.length, maxSize);
				System.arraycopy(node6, 0, newNode6, 0, node6.length - 1);

				final Object[][][][][] node5 = node6[node6.length - 1];
				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				final Object[][][][][] newNode5;
				final Object[][][][] newNode4;
				final Object[][][] newNode3;
				final Object[][] newNode2;
				if (node6.length < newNode6.length) {
					newNode5 = new Object[32][][][][];
					newNode4 = new Object[32][][][];
					newNode3 = new Object[32][][];
					newNode2 = new Object[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new Object[32][32];
					}
					for (int index4 = node4.length; index4 < 32; index4++) {
						newNode4[index4] = new Object[32][32][32];
					}
					for (int index5 = node5.length; index5 < 32; index5++) {
						newNode5[index5] = new Object[32][32][32][32];
					}
				} else {
					final int totalSize5 = (maxSize % (1 << 25) == 0) ? (1 << 25) : maxSize % (1 << 25);
					newNode5 = allocateNode5(node5.length, totalSize5);
					if (node5.length < newNode5.length) {
						newNode4 = new Object[32][][][];
						newNode3 = new Object[32][][];
						newNode2 = new Object[32][];
						for (int index4 = node4.length; index4 < 32; index4++) {
							newNode4[index4] = new Object[32][32][32];
						}
						for (int index3 = node3.length; index3 < 32; index3++) {
							newNode3[index3] = new Object[32][32];
						}
					} else {
						final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
						newNode4 = allocateNode4(node4.length, totalSize4);
						if (node4.length < newNode4.length) {
							newNode3 = new Object[32][][];
							newNode2 = new Object[32][];
							for (int index3 = node3.length; index3 < 32; index3++) {
								newNode3[index3] = new Object[32][32];
							}
						} else {
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							newNode3 = allocateNode3(node3.length, totalSize3);
							if (node3.length < newNode3.length) {
								newNode2 = new Object[32][];
							} else {
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
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
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new Object[32];
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
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (init.length + prefixSize <= 32) {
					final Object[] newInit = new Object[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new Seq6<>(node6, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final Object[][][][][] node5 = node6[node6.length - 1];
				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];

				final int maxSize = size - tail.length - 32*node3[node3.length - 1].length - (1 << 10)*(node3.length - 1)
						- (1 << 15)*(node4.length - 1) - (1 << 20)*(node5.length - 1) + (1 << 25) + prefixSize;
				if (maxSize >= 0 && maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private Seq6<A> prependSizedToSeq6(final Iterator<A> prefix, final int prefixSize, final int maxSize) {
				final Object[] newInit = allocateTail(maxSize);
				final Object[][][][][][] newNode6 = allocateNode6FromStart(node6.length, maxSize);
				System.arraycopy(node6, 1, newNode6, newNode6.length - node6.length + 1, node6.length - 1);

				final Object[][][][][] node5 = node6[0];
				final Object[][][][] node4 = node5[0];
				final Object[][][] node3 = node4[0];
				final Object[][] node2 = node3[0];
				final Object[][][][][] newNode5;
				final Object[][][][] newNode4;
				final Object[][][] newNode3;
				final Object[][] newNode2;
				if (node6.length < newNode6.length) {
					newNode5 = new Object[32][][][][];
					newNode4 = new Object[32][][][];
					newNode3 = new Object[32][][];
					newNode2 = new Object[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new Object[32][32];
					}
					for (int index4 = 0; index4 < 32 - node4.length; index4++) {
						newNode4[index4] = new Object[32][32][32];
					}
					for (int index5 = 0; index5 < 32 - node5.length; index5++) {
						newNode5[index5] = new Object[32][32][32][32];
					}
				} else {
					final int totalSize5 = (maxSize % (1 << 25) == 0) ? (1 << 25) : maxSize % (1 << 25);
					newNode5 = allocateNode5FromStart(node5.length, totalSize5);
					if (node5.length < newNode5.length) {
						newNode4 = new Object[32][][][];
						newNode3 = new Object[32][][];
						newNode2 = new Object[32][];
						for (int index4 = 0; index4 < 32 - node4.length; index4++) {
							newNode4[index4] = new Object[32][32][32];
						}
						for (int index3 = 0; index3 < 32 - node3.length; index3++) {
							newNode3[index3] = new Object[32][32];
						}
					} else {
						final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
						newNode4 = allocateNode4FromStart(node4.length, totalSize4);
						if (node4.length < newNode4.length) {
							newNode3 = new Object[32][][];
							newNode2 = new Object[32][];
							for (int index3 = 0; index3 < 32 - node3.length; index3++) {
								newNode3[index3] = new Object[32][32];
							}
						} else {
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							newNode3 = allocateNode3FromStart(node3.length, totalSize3);
							if (node3.length < newNode3.length) {
								newNode2 = new Object[32][];
							} else {
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								newNode2 = new Object[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
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
						newNode2[index2] = new Object[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new Object[32];
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
			void initSeqBuilder(final SeqBuilder<A> builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new Object[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final Object[][][][][] node5 = node6[node6.length - 1];
				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				builder.node2 = new Object[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new Object[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new Object[32][][][];
				System.arraycopy(node4, 0, builder.node4, 0, node4.length - 1);
				builder.node4[node4.length - 1] = builder.node3;
				builder.node5 = new Object[32][][][][];
				System.arraycopy(node5, 0, builder.node5, 0, node5.length - 1);
				builder.node5[node5.length - 1] = builder.node4;
				builder.node6 = new Object[32][][][][][];
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
			public Object[] toObjectArray() {
				final Object[] array = new Object[size];
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final Object[][][][][] node5 : node6) {
					for (final Object[][][][] node4 : node5) {
						for (final Object[][][] node3 : node4) {
							for (final Object[][] node2 : node3) {
								for (final Object[] node1 : node2) {
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
			public Iterator<A> iterator() {
				return new Seq6Iterator<>(node6, init, tail);
			}
		}
	''' }
}
