package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class SeqGenerator implements ClassGenerator {
	override className() { Constants.SEQ }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Collection;
		import java.util.Iterator;
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
		import static java.util.Collections.unmodifiableList;
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
			public abstract Seq<A> set(final int index, final A value);

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
					return appendSized(suffix.iterator(), ((Collection<A>) suffix).size());
				} else if (suffix instanceof Sized) {
					return appendSized(suffix.iterator(), ((Sized) suffix).size());
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
					return prependSized(prefix.iterator(), ((Collection<A>) prefix).size());
				} else if (prefix instanceof Sized) {
					return prependSized(prefix.iterator(), ((Sized) prefix).size());
				} else {
					final Iterator<A> iterator = prefix.iterator();
					if (iterator.hasNext()) {
						throw new UnsupportedOperationException("Not implemented");
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

			static <A> void fillArray(final Object[] array, final int index, final Iterator<A> iterator) {
				for (int i = index; i < array.length; i++) {
					array[i] = requireNonNull(iterator.next());
				}
			}

			static <A> void fillNode2(final Object[][] node2, final int index2, final Iterator<A> iterator) {
				for (int i = index2; i < node2.length; i++) {
					fillArray(node2[i], 0, iterator);
				}
			}

			static <A> void fillNode3(final Object[][][] node3, final int index3, final Iterator<A> iterator) {
				for (int i = index3; i < node3.length; i++) {
					fillNode2(node3[i], 0, iterator);
				}
			}

			static <A> void fillNode4(final Object[][][][] node4, final int index4, final Iterator<A> iterator) {
				for (int i = index4; i < node4.length; i++) {
					fillNode3(node4[i], 0, iterator);
				}
			}

			static <A> void fillNode5(final Object[][][][][] node5, final int index5, final Iterator<A> iterator) {
				for (int i = index5; i < node5.length; i++) {
					fillNode4(node5[i], 0, iterator);
				}
			}

			static <A> void fillNode6(final Object[][][][][][] node6, final int index6, final Iterator<A> iterator) {
				for (int i = index6; i < node6.length; i++) {
					fillNode5(node6[i], 0, iterator);
				}
			}

			static <A> Seq1<A> fillSeq1(final Object[] node1, final int index1, final Iterator<A> iterator) {
				fillArray(node1, index1, iterator);
				return new Seq1<>(node1);
			}

			static <A> Seq2<A> fillSeq2(final Object[][] node2, final int index2, final Object[] node1, final int index1,
					final Object[] init, final Object[] tail, final int size, final Iterator<A> iterator) {
				fillArray(node1, index1, iterator);
				fillNode2(node2, index2, iterator);
				fillArray(tail, 0, iterator);
				return new Seq2<>(node2, init, tail, size);
			}

			static <A> Seq3<A> fillSeq3(final Object[][][] node3, final int index3, final Object[][] node2, final int index2,
					final Object[] node1, final int index1, final Object[] init, final Object[] tail, final int startIndex,
					final int size, final Iterator<A> iterator) {
				fillArray(node1, index1, iterator);
				fillNode2(node2, index2, iterator);
				fillNode3(node3, index3, iterator);
				fillArray(tail, 0, iterator);
				return new Seq3<>(node3, init, tail, startIndex, size);
			}

			static <A> Seq4<A> fillSeq4(final Object[][][][] node4, final int index4, final Object[][][] node3, final int index3,
					final Object[][] node2, final int index2,  final Object[] node1, final int index1, final Object[] init,
					final Object[] tail, final int startIndex,  final int size, final Iterator<A> iterator) {
				fillArray(node1, index1, iterator);
				fillNode2(node2, index2, iterator);
				fillNode3(node3, index3, iterator);
				fillNode4(node4, index4, iterator);
				fillArray(tail, 0, iterator);
				return new Seq4<>(node4, init, tail, startIndex, size);
			}

			static <A> Seq5<A> fillSeq5(final Object[][][][][] node5, final int index5, final Object[][][][] node4, final int index4,
					final Object[][][] node3, final int index3, final Object[][] node2, final int index2,
					final Object[] node1, final int index1, final Object[] init, final Object[] tail, final int startIndex,
					final int size, final Iterator<A> iterator) {
				fillArray(node1, index1, iterator);
				fillNode2(node2, index2, iterator);
				fillNode3(node3, index3, iterator);
				fillNode4(node4, index4, iterator);
				fillNode5(node5, index5, iterator);
				fillArray(tail, 0, iterator);
				return new Seq5<>(node5, init, tail, startIndex, size);
			}

			static <A> Seq6<A> fillSeq6(final Object[][][][][][] node6, final int index6, final Object[][][][][] node5, final int index5,
					final Object[][][][] node4, final int index4, final Object[][][] node3, final int index3,
					final Object[][] node2, final int index2, final Object[] node1, final int index1,
					final Object[] init, final Object[] tail, final int startIndex, final int size, final Iterator<A> iterator) {
				fillArray(node1, index1, iterator);
				fillNode2(node2, index2, iterator);
				fillNode3(node3, index3, iterator);
				fillNode4(node4, index4, iterator);
				fillNode5(node5, index5, iterator);
				fillNode6(node6, index6, iterator);
				fillArray(tail, 0, iterator);
				return new Seq6<>(node6, init, tail, startIndex, size);
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

			Seq2Iterator(Object[][] node2, Object[] init, Object[] tail) {
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
			public Seq<A> set(final int index, final A __) {
				throw new IndexOutOfBoundsException(Integer.toString(index));
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
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				final Object[] newNode1 = node1.clone();
				newNode1[index] = value;
				return new Seq1<>(newNode1);
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

			private Seq<A> appendSizedToSeq1(final Iterator<A> suffix, final int size) {
				final Object[] newNode1 = new Object[size];
				System.arraycopy(node1, 0, newNode1, 0, node1.length);
				return fillSeq1(newNode1, node1.length, suffix);
			}

			private Seq<A> appendSizedToSeq2(final Iterator<A> suffix, final int suffixSize, final int size) {
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

			private Seq<A> appendSizedToSeq3(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][] newNode3 = allocateNode3(0, maxSize);
				return fillSeq3(newNode3, 1, newNode3[0], 1, newNode3[0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			private Seq<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][][] newNode4 = allocateNode4(0, maxSize);
				return fillSeq4(newNode4, 1, newNode4[0], 1, newNode4[0][0], 1, newNode4[0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private Seq<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][][][] newNode5 = allocateNode5(0, maxSize);
				return fillSeq5(newNode5, 1, newNode5[0], 1, newNode5[0][0], 1, newNode5[0][0][0], 1, newNode5[0][0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private Seq<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int size, final int maxSize) {
				final Object[] newTail = allocateTail(suffixSize);
				final Object[][][][][][] newNode6 = allocateNode6(0, maxSize);
				return fillSeq6(newNode6, 1, newNode6[0], 1, newNode6[0][0], 1, newNode6[0][0][0], 1, newNode6[0][0][0][0], 1,
						newNode6[0][0][0][0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			@Override
			Seq<A> prependSized(final Iterator<A> prefix, final int prefixSize) {
				throw new UnsupportedOperationException("Not implemented");
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
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						newInit[index] = value;
						return new Seq2<>(node2, newInit, tail, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - size] = value;
						return new Seq2<>(node2, init, newTail, size);
					} else {
						final Object[][] newNode2 = node2.clone();
						final int idx = index + 32 - init.length;
						final int index2 = index2(idx) - 1;
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						newNode2[index2] = newNode1;
						newNode1[index1] = value;
						return new Seq2<>(newNode2, init, tail, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
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

			private Seq<A> appendSizedToSeq2(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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
					for (int i = node2.length; i < size2; i++) {
						newNode2[i] = new Object[32];
					}
					System.arraycopy(tail, 0, newNode2[node2.length], 0, tail.length);
					return fillSeq2(newNode2, node2.length + 1, newNode2[node2.length], tail.length,
							init, newTail, size + suffixSize, suffix);
				}
			}

			private Seq<A> appendSizedToSeq3(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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
				throw new UnsupportedOperationException("Not implemented");
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
			public Seq<A> set(final int index, final A value) {
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						newInit[index] = value;
						return new Seq3<>(node3, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - size] = value;
						return new Seq3<>(node3, init, newTail, startIndex, size);
					} else {
						final Object[][][] newNode3 = node3.clone();
						final int idx = index + startIndex;
						final int index3 = index3(idx);
						final Object[][] newNode2 = newNode3[index3].clone();
						final int index2 = index2(idx, index3, newNode2);
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = value;
						return new Seq3<>(newNode3, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
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

			private Seq<A> appendSizedToSeq3(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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
				throw new UnsupportedOperationException("Not implemented");
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
							} else{
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
							} else{
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
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						newInit[index] = value;
						return new Seq4<>(node4, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - size] = value;
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
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = value;
						return new Seq4<>(newNode4, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
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

			private Seq<A> appendSizedToSeq4(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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
				throw new UnsupportedOperationException("Not implemented");
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
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						newInit[index] = value;
						return new Seq5<>(node5, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - size] = value;
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
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = value;
						return new Seq5<>(newNode5, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
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

			private Seq<A> appendSizedToSeq5(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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

			private Seq<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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
				throw new UnsupportedOperationException("Not implemented");
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
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				try {
					if (index < init.length) {
						final Object[] newInit = init.clone();
						newInit[index] = value;
						return new Seq6<>(node6, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - size] = value;
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
						newNode6[index6] = newNode5;
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						newNode1[index1] = value;
						return new Seq6<>(newNode6, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
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

			private Seq<A> appendSizedToSeq6(final Iterator<A> suffix, final int suffixSize, final int maxSize) {
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
				throw new UnsupportedOperationException("Not implemented");
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
			public Iterator<A> iterator() {
				return new Seq6Iterator<>(node6, init, tail);
			}
		}
	''' }
}
