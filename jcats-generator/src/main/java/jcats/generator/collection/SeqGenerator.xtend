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
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Predicate;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.F»;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
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

			public abstract <B> Seq<B> map(final F<A, B> f);

			public <B> Seq<B> flatMap(final F<A, Seq<B>> f) {
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

			public Seq<A> filter(final Predicate<A> predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return emptySeq();
				} else {
					final SeqBuilder<A> builder = new SeqBuilder<>();
					for (final Object value : this) {
						if (predicate.test((A) value)) {
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

			private static <A> Seq<A> seq1FromArray(final Object[] values) {
				final Object[] node1 = new Object[values.length];
				System.arraycopy(values, 0, node1, 0, values.length);
				return new Seq1<>(node1);
			}

			private static <A> Seq<A> seq2FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				if (values.length <= 64) {
					final Object[] tail = new Object[values.length - 32];
					System.arraycopy(values, 32, tail, 0, values.length - 32);
					return new Seq2<>(EMPTY_NODE2, init, tail, 0, values.length);
				} else {
					final Object[] tail = tailFromArray(values);
					final Object[][] node2 = new Object[(values.length - 32 - tail.length) / 32][32];
					int index = 32;
					for (final Object[] node1 : node2) {
						System.arraycopy(values, index, node1, 0, 32);
						index += 32;
					}
					return new Seq2<>(node2, init, tail, 0, values.length);
				}
			}

			private static <A> Seq<A> seq3FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final int size3 = (values.length % (1 << 10) == 0) ? values.length / (1 << 10) : values.length / (1 << 10) + 1;
				final Object[][][] node3 = new Object[size3][][];
				int index = 32;
				for (int index3 = 0; index3 < node3.length; index3++) {
					final int size2;
					if (index3 == 0) {
						size2 = 31;
					} else if (index3 < node3.length - 1) {
						size2 = 32;
					} else {
						final int totalSize2 = (values.length % (1 << 10) == 0) ? (1 << 10) : values.length % (1 << 10);
						size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
					}
					final Object[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
					node3[index3] = node2;
					for (final Object[] node1 : node2) {
						System.arraycopy(values, index, node1, 0, 32);
						index += 32;
					}
				}
				return new Seq3<>(node3, init, tail, 0, values.length);
			}

			private static <A> Seq<A> seq4FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final int size4 = (values.length % (1 << 15) == 0) ? values.length / (1 << 15) : values.length / (1 << 15) + 1;
				final Object[][][][] node4 = new Object[size4][][][];
				int index = 32;
				for (int index4 = 0; index4 < node4.length; index4++) {
					final int size3;
					if (index4 == node4.length - 1) {
						final int totalSize3 = (values.length % (1 << 15) == 0) ? (1 << 15) : values.length % (1 << 15);
						size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
					} else {
						size3 = 32;
					}

					final Object[][][] node3 = new Object[size3][][];
					node4[index4] = node3;

					for (int index3 = 0; index3 < node3.length; index3++) {
						final int size2;
						if (index4 == 0 && index3 == 0) {
							size2 = 31;
						} else if (index4 < node4.length - 1 || index3 < node3.length - 1) {
							size2 = 32;
						} else {
							final int totalSize3 = (values.length % (1 << 15) == 0) ? (1 << 15) : values.length % (1 << 15);
							final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
							size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
						}
						final Object[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
						node3[index3] = node2;
						for (final Object[] node1 : node2) {
							System.arraycopy(values, index, node1, 0, 32);
							index += 32;
						}
					}
				}
				return new Seq4<>(node4, init, tail, 0, values.length);
			}

			private static <A> Seq<A> seq5FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final int size5 = (values.length % (1 << 20) == 0) ? values.length / (1 << 20) : values.length / (1 << 20) + 1;
				final Object[][][][][] node5 = new Object[size5][][][][];
				int index = 32;
				for (int index5 = 0; index5 < node5.length; index5++) {
					final int size4;
					if (index5 == node5.length - 1) {
						final int totalSize4 = (values.length % (1 << 20) == 0) ? (1 << 20) : values.length % (1 << 20);
						size4 = (totalSize4 % (1 << 15) == 0) ? totalSize4 / (1 << 15) : totalSize4 / (1 << 15) + 1;
					} else {
						size4 = 32;
					}

					final Object[][][][] node4 = new Object[size4][][][];
					node5[index5] = node4;

					for (int index4 = 0; index4 < node4.length; index4++) {
						final int size3;
						if (index5 == node5.length - 1 && index4 == node4.length - 1) {
							final int totalSize4 = (values.length % (1 << 20) == 0) ? (1 << 20) : values.length % (1 << 20);
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							size3 = (totalSize3 % (1 << 10) == 0) ? totalSize3 / (1 << 10) : totalSize3 / (1 << 10) + 1;
						} else {
							size3 = 32;
						}

						final Object[][][] node3 = new Object[size3][][];
						node4[index4] = node3;

						for (int index3 = 0; index3 < node3.length; index3++) {
							final int size2;
							if (index5 == 0 && index4 == 0 && index3 == 0) {
								size2 = 31;
							} else if (index5 < node5.length - 1 || index4 < node4.length - 1 || index3 < node3.length - 1) {
								size2 = 32;
							} else {
								final int totalSize4 = (values.length % (1 << 20) == 0) ? (1 << 20) : values.length % (1 << 20);
								final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
							}
							final Object[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
							node3[index3] = node2;
							for (final Object[] node1 : node2) {
								System.arraycopy(values, index, node1, 0, 32);
								index += 32;
							}
						}
					}
				}
				return new Seq5<>(node5, init, tail, 0, values.length);
			}

			private static <A> Seq<A> seq6FromArray(final Object[] values) {
				final Object[] init = initFromArray(values);
				final Object[] tail = tailFromArray(values);
				final int size6 = (values.length % (1 << 25) == 0) ? values.length / (1 << 25) : values.length / (1 << 25) + 1;
				final Object[][][][][][] node6 = new Object[size6][][][][][];
				int index = 32;
				for (int index6 = 0; index6 < node6.length; index6++) {
					final int size5;
					if (index6 == node6.length - 1) {
						final int totalSize5 = (values.length % (1 << 25) == 0) ? (1 << 25) : values.length % (1 << 25);
						size5 = (totalSize5 % (1 << 20) == 0) ? totalSize5 / (1 << 20) : totalSize5 / (1 << 20) + 1;
					} else {
						size5 = 32;
					}

					final Object[][][][][] node5 = new Object[size5][][][][];
					node6[index6] = node5;

					for (int index5 = 0; index5 < node5.length; index5++) {
						final int size4;
						if (index6 == node6.length - 1 && index5 == node5.length - 1) {
							final int totalSize5 = (values.length % (1 << 25) == 0) ? (1 << 25) : values.length % (1 << 25);
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
								final int totalSize5 = (values.length % (1 << 25) == 0) ? (1 << 25) : values.length % (1 << 25);
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
									final int totalSize5 = (values.length % (1 << 25) == 0) ? (1 << 25) : values.length % (1 << 25);
									final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
									final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
									final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
									size2 = (totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32;
								}
								final Object[][] node2 = (size2 == 0) ? EMPTY_NODE2 : new Object[size2][32];
								node3[index3] = node2;
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

			private static Object[] initFromArray(final Object[] values) {
				final Object[] init = new Object[32];
				System.arraycopy(values, 0, init, 0, 32);
				return init;
			}

			private static Object[] tailFromArray(final Object[] values) {
				final Object[] tail = new Object[((values.length % 32) == 0) ? 32 : values.length % 32];
				System.arraycopy(values, values.length - tail.length, tail, 0, tail.length);
				return tail;
			}

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
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				return emptySeq();
			}

			@Override
			public Iterator<A> iterator() {
				return emptyIterator();
			}
		}

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
					return new Seq2<>(Seq2.EMPTY_NODE2, init, node1, 31, 33);
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
					return new Seq2<>(Seq2.EMPTY_NODE2, node1, tail, 0, 33);
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length);
					newNode1[node1.length] = value;
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					final Object[] newNode1 = mapArray(node1, f);
					return new Seq1<>(newNode1);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new ArrayIterator<>(node1);
			}
		}

		final class Seq2<A> extends Seq<A> {
			final Object[][] node2;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int length;

			Seq2(final Object[][] node2, final Object[] init, final Object[] tail, final int startIndex, final int length) {
				this.node2 = node2;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.length = length;
			}

			@Override
			public int size() {
				return length;
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
						return new Seq2<>(EMPTY_NODE2, init, node2[0], startIndex, length - 1);
					} else {
						final Object[][] newNode2 = new Object[node2.length - 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
						return new Seq2<>(newNode2, init, node2[node2.length - 1], startIndex, length - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq2<>(node2, init, newTail, startIndex, length - 1);
				}
			}

			@Override
			public Seq<A> tail() {
				if (init.length == 1) {
					if (node2.length == 0) {
						return new Seq1<>(tail);
					} else if (node2.length == 1) {
						return new Seq2<>(EMPTY_NODE2, node2[0], tail, 0, length - 1);
					} else {
						final Object[][] newNode2 = new Object[node2.length - 1][];
						System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
						return new Seq2<>(newNode2, node2[0], tail, 0, length - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq2<>(node2, newInit, tail, startIndex + 1, length - 1);
				}
			}

			@Override
			public A get(final int index) {
				try {
					if (index < init.length) {
						return (A) init[index];
					} else if (index >= length - tail.length) {
						return (A) tail[index + tail.length - length];
					} else {
						final int idx = index + startIndex;
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
						return new Seq2<>(node2, newInit, tail, startIndex, length);
					} else if (index >= length - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - length] = value;
						return new Seq2<>(node2, init, newTail, startIndex, length);
					} else {
						final Object[][] newNode2 = node2.clone();
						final int idx = index + startIndex;
						final int index2 = index2(idx) - 1;
						final Object[] newNode1 = newNode2[index2].clone();
						final int index1 = index1(idx);
						newNode2[index2] = newNode1;
						newNode1[index1] = value;
						return new Seq2<>(newNode2, init, tail, startIndex, length);
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
						if (startIndex != 0) {
							throw new IllegalStateException("startIndex != 0");
						}
						return new Seq3<>(newNode3, newInit, tail, (1 << 10) - 1, length + 1);
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						return new Seq2<>(newNode2, newInit, tail, 31, length + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq2<>(node2, newInit, tail, startIndex - 1, length + 1);
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
						return new Seq3<>(newNode3, init, newTail, startIndex, length + 1);
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						return new Seq2<>(newNode2, init, newTail, startIndex, length + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq2<>(node2, init, newTail, startIndex, length + 1);
				}
			}

			@Override
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					final Object[] newInit = mapArray(init, f);
					final Object[][] newNode2 = new Object[node2.length][];
					for (int index2 = 0; index2 < node2.length; index2++) {
						newNode2[index2] = mapArray(node2[index2], f);
					}
					final Object[] newTail = mapArray(tail, f);
					return new Seq2<>(newNode2, newInit, newTail, startIndex, length);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq2Iterator<>(node2, init, tail);
			}
		}

		final class Seq3<A> extends Seq<A> {
			final Object[][][] node3;
			final int startIndex;
			final Object[] init;
			final Object[] tail;
			final int length;

			Seq3(final Object[][][] node3, final Object[] init, final Object[] tail, final int startIndex, final int length) {
				this.node3 = node3;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.length = length;
			}

			@Override
			public int size() {
				return length;
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
							return new Seq2<>(newNode2, init, node2[node2.length - 1], startIndex, length - 1);
						} else {
							final Object[][][] newNode3 = new Object[node3.length - 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 2);
							final Object[][] node2 = node3[node3.length - 2];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[node3.length - 2] = newNode2;
							return new Seq3<>(newNode3, init, node2[node2.length - 1], startIndex, length - 1);
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
						return new Seq3<>(newNode3, init, lastNode2[lastNode2.length - 1], startIndex, length - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq3<>(node3, init, newTail, startIndex, length - 1);
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
							return new Seq2<>(newNode2, node2[0], tail, 0, length - 1);
						} else {
							final Object[][][] newNode3 = new Object[node3.length - 1][][];
							System.arraycopy(node3, 2, newNode3, 1, node3.length - 2);
							final Object[][] node2 = node3[1];
							final Object[][] newNode2 = new Object[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new Seq3<>(newNode3, node2[0], tail, 0, length - 1);
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
						return new Seq3<>(newNode3, firstNode2[0], tail, startIndex + 1, length - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq3<>(node3, newInit, tail, startIndex + 1, length - 1);
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
					} else if (index >= length - tail.length) {
						return (A) tail[index + tail.length - length];
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
						return new Seq3<>(node3, newInit, tail, startIndex, length);
					} else if (index >= length - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - length] = value;
						return new Seq3<>(node3, init, newTail, startIndex, length);
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
						return new Seq3<>(newNode3, init, tail, startIndex, length);
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
							return new Seq4<>(newNode4, newInit, tail, (1 << 15) - 1, length + 1);
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
							return new Seq3<>(newNode3, newInit, tail, (1 << 10) - 1, length + 1);
						}
					} else {
						final Object[] newInit = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						return new Seq3<>(newNode3, newInit, tail, startIndex - 1, length + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq3<>(node3, newInit, tail, startIndex - 1, length + 1);
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
							return new Seq4<>(newNode4, init, newTail, startIndex, length + 1);
						} else {
							final Object[] newTail = { value };
							final Object[][] newNode2 = new Object[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							return new Seq3<>(newNode3, init, newTail, startIndex, length + 1);
						}
					} else {
						final Object[] newTail = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						return new Seq3<>(newNode3, init, newTail, startIndex, length + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq3<>(node3, init, newTail, startIndex, length + 1);
				}
			}

			@Override
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					final Object[] newInit = mapArray(init, f);
					final Object[][][] newNode3 = new Object[node3.length][][];
					for (int index3 = 0; index3 < node3.length; index3++) {
						final Object[][] node2 = node3[index3];
						final Object[][] newNode2 = new Object[node2.length][];
						newNode3[index3] = newNode2;
						for (int index2 = 0; index2 < node2.length; index2++) {
							newNode2[index2] = mapArray(node2[index2], f);
						}
					}
					final Object[] newTail = mapArray(tail, f);
					return new Seq3<>(newNode3, newInit, newTail, startIndex, length);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq3Iterator<>(node3, init, tail);
			}
		}

		final class Seq4<A> extends Seq<A> {
			final Object[][][][] node4;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int length;

			Seq4(final Object[][][][] node4, final Object[] init, final Object[] tail, final int startIndex, final int length) {
				this.node4 = node4;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.length = length;
			}

			@Override
			public int size() {
				return length;
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
								return new Seq3<>(newNode3, init, node2[node2.length - 1], startIndex, length - 1);
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
								return new Seq4<>(newNode4, init, node2[node2.length - 1], startIndex, length - 1);
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
							return new Seq4<>(newNode4, init, node2[node2.length - 1], startIndex, length - 1);
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
						return new Seq4<>(newNode4, init, lastNode2[lastNode2.length - 1], startIndex, length - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq4<>(node4, init, newTail, startIndex, length - 1);
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
								return new Seq3<>(newNode3, node2[0], tail, 0, length - 1);
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
								return new Seq4<>(newNode4, node2[0], tail, 0, length - 1);
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
							return new Seq4<>(newNode4, node2[0], tail, startIndex + 1, length - 1);
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
						return new Seq4<>(newNode4, firstNode2[0], tail, startIndex + 1, length - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq4<>(node4, newInit, tail, startIndex + 1, length - 1);
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
					} else if (index >= length - tail.length) {
						return (A) tail[index + tail.length - length];
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
						return new Seq4<>(node4, newInit, tail, startIndex, length);
					} else if (index >= length - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - length] = value;
						return new Seq4<>(node4, init, newTail, startIndex, length);
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
						return new Seq4<>(newNode4, init, tail, startIndex, length);
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
								return new Seq5<>(newNode5, newInit, tail, (1 << 20) - 1, length + 1);
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
								return new Seq4<>(newNode4, newInit, tail, (1 << 15) - 1, length + 1);
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
							return new Seq4<>(newNode4, newInit, tail, startIndex - 1, length + 1);
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
						return new Seq4<>(newNode4, newInit, tail, startIndex - 1, length + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq4<>(node4, newInit, tail, startIndex - 1, length + 1);
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
								return new Seq5<>(newNode5, init, newTail, startIndex, length + 1);
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
								return new Seq4<>(newNode4, init, newTail, startIndex, length + 1);
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
							return new Seq4<>(newNode4, init, newTail, startIndex, length + 1);
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
						return new Seq4<>(newNode4, init, newTail, startIndex, length + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq4<>(node4, init, newTail, startIndex, length + 1);
				}
			}

			@Override
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					final Object[] newInit = mapArray(init, f);
					final Object[][][][] newNode4 = new Object[node4.length][][][];
					for (int index4 = 0; index4 < node4.length; index4++) {
						final Object[][][] node3 = node4[index4];
						final Object[][][] newNode3 = new Object[node3.length][][];
						newNode4[index4] = newNode3;
						for (int index3 = 0; index3 < node3.length; index3++) {
							final Object[][] node2 = node3[index3];
							final Object[][] newNode2 = new Object[node2.length][];
							newNode3[index3] = newNode2;
							for (int index2 = 0; index2 < node2.length; index2++) {
								newNode2[index2] = mapArray(node2[index2], f);
							}
						}
					}
					final Object[] newTail = mapArray(tail, f);
					return new Seq4<>(newNode4, newInit, newTail, startIndex, length);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq4Iterator<>(node4, init, tail);
			}
		}

		final class Seq5<A> extends Seq<A> {
			final Object[][][][][] node5;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int length;

			Seq5(final Object[][][][][] node5, final Object[] init, final Object[] tail, final int startIndex, final int length) {
				this.node5 = node5;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.length = length;
			}

			@Override
			public int size() {
				return length;
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
									return new Seq4<>(newNode4, init, node2[node2.length - 1], startIndex, length - 1);
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
									return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, length - 1);
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
								return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, length - 1);
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
							return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, length - 1);
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
						return new Seq5<>(newNode5, init, lastNode2[lastNode2.length - 1], startIndex, length - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq5<>(node5, init, newTail, startIndex, length - 1);
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
									return new Seq4<>(newNode4, node2[0], tail, 0, length - 1);
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
									return new Seq5<>(newNode5, node2[0], tail, 0, length - 1);
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
								return new Seq5<>(newNode5, node2[0], tail, startIndex + 1, length - 1);
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
							return new Seq5<>(newNode5, node2[0], tail, startIndex + 1, length - 1);
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
						return new Seq5<>(newNode5, firstNode2[0], tail, startIndex + 1, length - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq5<>(node5, newInit, tail, startIndex + 1, length - 1);
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
					} else if (index >= length - tail.length) {
						return (A) tail[index + tail.length - length];
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
						return new Seq5<>(node5, newInit, tail, startIndex, length);
					} else if (index >= length - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - length] = value;
						return new Seq5<>(node5, init, newTail, startIndex, length);
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
						return new Seq5<>(newNode5, init, tail, startIndex, length);
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
									return new Seq6<>(newNode6, newInit, tail, (1 << 25) - 1, length + 1);
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
									return new Seq5<>(newNode5, newInit, tail, (1 << 20) - 1, length + 1);
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
								return new Seq5<>(newNode5, newInit, tail, startIndex - 1, length + 1);
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
							return new Seq5<>(newNode5, newInit, tail, startIndex - 1, length + 1);
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
						return new Seq5<>(newNode5, newInit, tail, startIndex - 1, length + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq5<>(node5, newInit, tail, startIndex - 1, length + 1);
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
									return new Seq6<>(newNode6, init, newTail, startIndex, length + 1);
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
									return new Seq5<>(newNode5, init, newTail, startIndex, length + 1);
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
								return new Seq5<>(newNode5, init, newTail, startIndex, length + 1);
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
							return new Seq5<>(newNode5, init, newTail, startIndex, length + 1);
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
						return new Seq5<>(newNode5, init, newTail, startIndex, length + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq5<>(node5, init, newTail, startIndex, length + 1);
				}
			}

			@Override
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					final Object[] newInit = mapArray(init, f);
					final Object[][][][][] newNode5 = new Object[node5.length][][][][];
					for (int index5 = 0; index5 < node5.length; index5++) {
						final Object[][][][] node4 = node5[index5];
						final Object[][][][] newNode4 = new Object[node4.length][][][];
						newNode5[index5] = newNode4;
						for (int index4 = 0; index4 < node4.length; index4++) {
							final Object[][][] node3 = node4[index4];
							final Object[][][] newNode3 = new Object[node3.length][][];
							newNode4[index4] = newNode3;
							for (int index3 = 0; index3 < node3.length; index3++) {
								final Object[][] node2 = node3[index3];
								final Object[][] newNode2 = new Object[node2.length][];
								newNode3[index3] = newNode2;
								for (int index2 = 0; index2 < node2.length; index2++) {
									newNode2[index2] = mapArray(node2[index2], f);
								}
							}
						}
					}
					final Object[] newTail = mapArray(tail, f);
					return new Seq5<>(newNode5, newInit, newTail, startIndex, length);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq5Iterator<>(node5, init, tail);
			}
		}

		final class Seq6<A> extends Seq<A> {
			final Object[][][][][][] node6;
			final Object[] init;
			final Object[] tail;
			final int startIndex;
			final int length;

			Seq6(final Object[][][][][][] node6, final Object[] init, final Object[] tail, final int startIndex, final int length) {
				this.node6 = node6;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.length = length;
			}

			@Override
			public int size() {
				return length;
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
										return new Seq5<>(newNode5, init, node2[node2.length - 1], startIndex, length - 1);
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
										return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, length - 1);
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
									return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, length - 1);
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
								return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, length - 1);
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
							return new Seq6<>(newNode6, init, node2[node2.length - 1], startIndex, length - 1);
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
						return new Seq6<>(newNode6, init, lastNode2[lastNode2.length - 1], startIndex, length - 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new Seq6<>(node6, init, newTail, startIndex, length - 1);
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
										return new Seq5<>(newNode5, node2[0], tail, 0, length - 1);
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
										return new Seq6<>(newNode6, node2[0], tail, 0, length - 1);
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
									return new Seq6<>(newNode6, node2[0], tail, startIndex + 1, length - 1);
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
								return new Seq6<>(newNode6, node2[0], tail, startIndex + 1, length - 1);
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
							return new Seq6<>(newNode6, node2[0], tail, startIndex + 1, length - 1);
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
						return new Seq6<>(newNode6, firstNode2[0], tail, startIndex + 1, length - 1);
					}
				} else {
					final Object[] newInit = new Object[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new Seq6<>(node6, newInit, tail, startIndex + 1, length - 1);
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
					} else if (index >= length - tail.length) {
						return (A) tail[index + tail.length - length];
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
						return new Seq6<>(node6, newInit, tail, startIndex, length);
					} else if (index >= length - tail.length) {
						final Object[] newTail = tail.clone();
						newTail[index + tail.length - length] = value;
						return new Seq6<>(node6, init, newTail, startIndex, length);
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
						return new Seq6<>(newNode6, init, tail, startIndex, length);
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
										return new Seq6<>(newNode6, newInit, tail, (1 << 25) - 1, length + 1);
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
									return new Seq6<>(newNode6, newInit, tail, startIndex - 1, length + 1);
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
								return new Seq6<>(newNode6, newInit, tail, startIndex - 1, length + 1);
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
							return new Seq6<>(newNode6, newInit, tail, startIndex - 1, length + 1);
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
						return new Seq6<>(newNode6, newInit, tail, startIndex - 1, length + 1);
					}
				} else {
					final Object[] newInit = new Object[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new Seq6<>(node6, newInit, tail, startIndex - 1, length + 1);
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
										return new Seq6<>(newNode6, init, newTail, startIndex, length + 1);
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
									return new Seq6<>(newNode6, init, newTail, startIndex, length + 1);
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
								return new Seq6<>(newNode6, init, newTail, startIndex, length + 1);
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
							return new Seq6<>(newNode6, init, newTail, startIndex, length + 1);
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
						return new Seq6<>(newNode6, init, newTail, startIndex, length + 1);
					}
				} else {
					final Object[] newTail = new Object[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new Seq6<>(node6, init, newTail, startIndex, length + 1);
				}
			}

			@Override
			public <B> Seq<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (f == F.id()) {
					return (Seq<B>) this;
				} else {
					final Object[] newInit = mapArray(init, f);
					final Object[][][][][][] newNode6 = new Object[node6.length][][][][][];
					for (int index6 = 0; index6 < node6.length; index6++) {
						final Object[][][][][] node5 = node6[index6];
						final Object[][][][][] newNode5 = new Object[node5.length][][][][];
						newNode6[index6] = newNode5;
						for (int index5 = 0; index5 < node5.length; index5++) {
							final Object[][][][] node4 = node5[index5];
							final Object[][][][] newNode4 = new Object[node4.length][][][];
							newNode5[index5] = newNode4;
							for (int index4 = 0; index4 < node4.length; index4++) {
								final Object[][][] node3 = node4[index4];
								final Object[][][] newNode3 = new Object[node3.length][][];
								newNode4[index4] = newNode3;
								for (int index3 = 0; index3 < node3.length; index3++) {
									final Object[][] node2 = node3[index3];
									final Object[][] newNode2 = new Object[node2.length][];
									newNode3[index3] = newNode2;
									for (int index2 = 0; index2 < node2.length; index2++) {
										newNode2[index2] = mapArray(node2[index2], f);
									}
								}
							}
						}
					}
					final Object[] newTail = mapArray(tail, f);
					return new Seq6<>(newNode6, newInit, newTail, startIndex, length);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new Seq6Iterator<>(node6, init, tail);
			}
		}

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
}
