package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class SeqGenerator implements ClassGenerator {
	override className() { Constants.SEQ }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Arrays;
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
		import «Constants.INDEXED»;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»
		import «Constants.PRECISE_SIZE»;
		import «Constants.SIZED»;

		import static java.util.Collections.emptyIterator;
		import static java.util.Collections.unmodifiableList;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static «Constants.F».id;
		import static «Constants.P2».p2;
		import static «Constants.SIZE».preciseSize;

		public abstract class Seq<A> implements Sized, Indexed<A>, Serializable {
			private static final Seq EMPTY = new Seq0();

			Seq() {
			}

			public final boolean isEmpty() {
				return (this == Seq.EMPTY);
			}

			@Override
			public final PreciseSize size() {
				return preciseSize(length());
			}

			public abstract int length();

			public abstract Seq<A> set(final int index, final A value);

			public abstract Seq<A> prepend(final A value);

			public abstract Seq<A> append(final A value);

			public static <A> Seq<A> emptySeq() {
				return Seq.EMPTY;
			}

			public static <A> Seq<A> singleSeq(final A value) {
				final Object[] node1 = { requireNonNull(value) };
				return new Seq1<>(node1);
			}

			static int checkRangeAndConvert(final int index, final int startIndex, final int endIndex) {
				final int idx = index + startIndex;
				if (index >= 0 && idx < endIndex) {
					return idx;
				} else {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

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
		}

		final class Seq0<A> extends Seq<A> {
			@Override
			public int length() {
				return 0;
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
		}

		final class Seq1<A> extends Seq<A> {
			private final Object[] node1;

			Seq1(final Object[] node1) {
				this.node1 = node1;
			}

			@Override
			public int length() {
				return node1.length;
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
				if (node1.length == 1 << 5) {
					final Object[] newNode1 = { value };
					final Object[][] newNode2 = { newNode1, node1 };
					return new Seq2<>(newNode2, (1 << 5) - 1, 1 << 6);
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
				if (node1.length < 1 << 5) {
					final Object[] newNode1 = Arrays.copyOf(node1, node1.length + 1);
					newNode1[node1.length] = value;
					return new Seq1<>(newNode1);
				} else {
					final Object[] newNode1 = { value };
					final Object[][] newNode2 = { node1, newNode1 };
					return new Seq2<>(newNode2, 0, (1 << 5) + 1);
				}
			}
		}

		final class Seq2<A> extends Seq<A> {
			private final Object[][] node2;
			private final int startIndex;
			private final int endIndex;

			Seq2(final Object[][] node2, final int startIndex, final int endIndex) {
				this.node2 = node2;
				this.startIndex = startIndex;
				this.endIndex = endIndex;
			}

			@Override
			public int length() {
				return (endIndex - startIndex);
			}

			private static int index1(final int idx, final int index2, final Object[] node1) {
				return (index2 == 0) ? index1(idx) + node1.length - (1 << 5) : index1(idx);
			}

			@Override
			public A get(final int index) {
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final int index2 = index2(idx);
				final Object[] node1 = node2[index2];
				final int index1 = index1(idx, index2, node1);
				return (A) node1[index1];
			}

			@Override
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final Object[][] newNode2 = node2.clone();
				final int index2 = index2(idx);
				final Object[] newNode1 = newNode2[index2].clone();
				final int index1 = index1(idx, index2, newNode1);
				newNode2[index2] = newNode1;
				newNode1[index1] = value;
				return new Seq2<>(newNode2, startIndex, endIndex);
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				final Object[] node1 = node2[0];
				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = { newNode1} ;
						final Object[][][] newNode3 = { newNode2, node2 };
						if (startIndex != 0) {
							throw new IllegalStateException("startIndex != 0");
						}
						return new Seq3<>(newNode3, (1 << 10) - 1, (1 << 10) + endIndex);
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = newNode1;
						return new Seq2<>(newNode2, (1 << 5) - 1, (1 << 5) + endIndex);
					}
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[0] = newNode1;
					return new Seq2<>(newNode2, startIndex - 1, endIndex);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);
				final Object[] node1 = node2[node2.length - 1];
				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = { newNode1 };
						final Object[][][] newNode3 = { node2, newNode2 };
						return new Seq3<>(newNode3, startIndex, endIndex + 1);
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = Arrays.copyOf(node2, node2.length + 1);
						newNode2[node2.length] = newNode1;
						return new Seq2<>(newNode2, startIndex, endIndex + 1);
					}
				} else {
					final Object[] newNode1 = Arrays.copyOf(node1, node1.length + 1);
					newNode1[node1.length] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[newNode2.length - 1] = newNode1;
					return new Seq2<>(newNode2, startIndex, endIndex + 1);
				}
			}
		}

		final class Seq3<A> extends Seq<A> {
			private final Object[][][] node3;
			private final int startIndex;
			private final int endIndex;

			Seq3(final Object[][][] node3, final int startIndex, final int endIndex) {
				this.node3 = node3;
				this.startIndex = startIndex;
				this.endIndex = endIndex;
			}

			@Override
			public int length() {
				return (endIndex - startIndex);
			}

			private static int index1(final int idx, final int index2, final int index3, final Object[] node1) {
				return (index3 == 0 && index2 == 0) ? index1(idx) + node1.length - (1 << 5) : index1(idx);
			}

			private static int index2(final int idx, final int index3, final Object[][] node2) {
				return (index3 == 0) ? index2(idx) + node2.length - (1 << 5) : index2(idx);
			}

			@Override
			public A get(final int index) {
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final int index3 = index3(idx);
				final Object[][] node2 = node3[index3];
				final int index2 = index2(idx, index3, node2);
				final Object[] node1 = node2[index2];
				final int index1 = index1(idx, index2, index3, node1);
				return (A) node1[index1];
			}

			@Override
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final Object[][][] newNode3 = node3.clone();
				final int index3 = index3(idx);
				final Object[][] newNode2 = newNode3[index3].clone();
				final int index2 = index2(idx, index3, newNode2);
				final Object[] newNode1 = newNode2[index2].clone();
				final int index1 = index1(idx, index2, index3, newNode1);
				newNode3[index3] = newNode2;
				newNode2[index2] = newNode1;
				newNode1[index1] = value;
				return new Seq3<>(newNode3, startIndex, endIndex);
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				final Object[][] node2 = node3[0];
				final Object[] node1 = node2[0];
				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = { newNode2 };
							final Object[][][][] newNode4 = { newNode3, node3 };
							if (startIndex != 0) {
								throw new IllegalStateException("startIndex != 0");
							}
							return new Seq4<>(newNode4, (1 << 15) - 1, (1 << 15) + endIndex);
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 1, node3.length);
							newNode3[0] = newNode2;
							if (startIndex != 0) {
								throw new IllegalStateException("startIndex != 0");
							}
							return new Seq3<>(newNode3, (1 << 10) - 1, (1 << 10) + endIndex);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						return new Seq3<>(newNode3, startIndex - 1, endIndex);
					}
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[0] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[0] = newNode2;
					return new Seq3<>(newNode3, startIndex - 1, endIndex);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);

				final Object[][] node2 = node3[node3.length - 1];
				final Object[] node1 = node2[node2.length - 1];

				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = { newNode2 };
							final Object[][][][] newNode4 = { node3, newNode3 };
							return new Seq4<>(newNode4, startIndex, endIndex + 1);
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = Arrays.copyOf(node3, node3.length + 1);
							newNode3[node3.length] = newNode2;
							return new Seq3<>(newNode3, startIndex, endIndex + 1);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = Arrays.copyOf(node2, node2.length + 1);
						newNode2[node2.length] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						return new Seq3<>(newNode3, startIndex, endIndex + 1);
					}
				} else {
					final Object[] newNode1 = Arrays.copyOf(node1, node1.length + 1);
					newNode1[node1.length] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[newNode2.length - 1] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[newNode3.length - 1] = newNode2;
					return new Seq3<>(newNode3, startIndex, endIndex + 1);
				}
			}
		}

		final class Seq4<A> extends Seq<A> {
			private final Object[][][][] node4;
			private final int startIndex;
			private final int endIndex;

			Seq4(final Object[][][][] node4, final int startIndex, final int endIndex) {
				this.node4 = node4;
				this.startIndex = startIndex;
				this.endIndex = endIndex;
			}

			@Override
			public int length() {
				return (endIndex - startIndex);
			}

			private static int index1(final int idx, final int index2, final int index3, final int index4, final Object[] node1) {
				return (index4 == 0 && index3 == 0 && index2 == 0) ? index1(idx) + node1.length - (1 << 5) : index1(idx);
			}

			private static int index2(final int idx, final int index3, final int index4, final Object[][] node2) {
				return (index4 == 0 && index3 == 0) ? index2(idx) + node2.length - (1 << 5) : index2(idx);
			}

			private static int index3(final int idx, final int index4, final Object[][][] node3) {
				return (index4 == 0) ? index3(idx) + node3.length - (1 << 5) : index3(idx);
			}

			@Override
			public A get(final int index) {
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final int index4 = index4(idx);
				final Object[][][] node3 = node4[index4];
				final int index3 = index3(idx, index4, node3);
				final Object[][] node2 = node3[index3];
				final int index2 = index2(idx, index3, index4, node2);
				final Object[] node1 = node2[index2];
				final int index1 = index1(idx, index2, index3, index4, node1);
				return (A) node1[index1];
			}

			@Override
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final Object[][][][] newNode4 = node4.clone();
				final int index4 = index4(idx);
				final Object[][][] newNode3 = newNode4[index4].clone();
				final int index3 = index3(idx, index4, newNode3);
				final Object[][] newNode2 = newNode3[index3].clone();
				final int index2 = index2(idx, index3, index4, newNode2);
				final Object[] newNode1 = newNode2[index2].clone();
				final int index1 = index1(idx, index2, index3, index4, newNode1);
				newNode4[index4] = newNode3;
				newNode3[index3] = newNode2;
				newNode2[index2] = newNode1;
				newNode1[index1] = value;
				return new Seq4<>(newNode4, startIndex, endIndex);
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				final Object[][][] node3 = node4[0];
				final Object[][] node2 = node3[0];
				final Object[] node1 = node2[0];
				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							if (node4.length == 1 << 5) {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = { newNode3 };
								final Object[][][][][] newNode5 = { newNode4, node4 };
								if (startIndex != 0) {
									throw new IllegalStateException("startIndex != 0");
								}
								return new Seq5<>(newNode5, (1 << 20) - 1, (1 << 20) + endIndex);
							} else {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 1, node4.length);
								newNode4[0] = newNode3;
								if (startIndex != 0) {
									throw new IllegalStateException("startIndex != 0");
								}
								return new Seq4<>(newNode4, (1 << 15) - 1, (1 << 15) + endIndex);
							}
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 1, node3.length);
							newNode3[0] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							return new Seq4<>(newNode4, startIndex - 1, endIndex);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						return new Seq4<>(newNode4, startIndex - 1, endIndex);
					}
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[0] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[0] = newNode2;
					final Object[][][][] newNode4 = node4.clone();
					newNode4[0] = newNode3;
					return new Seq4<>(newNode4, startIndex - 1, endIndex);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);

				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				final Object[] node1 = node2[node2.length - 1];

				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							if (node4.length == 1 << 5) {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = { newNode3 };
								final Object[][][][][] newNode5 = { node4, newNode4 };
								return new Seq5<>(newNode5, startIndex, endIndex + 1);
							} else {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = Arrays.copyOf(node4, node4.length + 1);
								newNode4[node4.length] = newNode3;
								return new Seq4<>(newNode4, startIndex, endIndex + 1);
							}
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = Arrays.copyOf(node3, node3.length + 1);
							newNode3[node3.length] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							return new Seq4<>(newNode4, startIndex, endIndex + 1);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = Arrays.copyOf(node2, node2.length + 1);
						newNode2[node2.length] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						return new Seq4<>(newNode4, startIndex, endIndex + 1);
					}
				} else {
					final Object[] newNode1 = Arrays.copyOf(node1, node1.length + 1);
					newNode1[node1.length] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[newNode2.length - 1] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[newNode3.length - 1] = newNode2;
					final Object[][][][] newNode4 = node4.clone();
					newNode4[newNode4.length - 1] = newNode3;
					return new Seq4<>(newNode4, startIndex, endIndex + 1);
				}
			}
		}

		final class Seq5<A> extends Seq<A> {
			private final Object[][][][][] node5;
			private final int startIndex;
			private final int endIndex;

			Seq5(final Object[][][][][] node5, final int startIndex, final int endIndex) {
				this.node5 = node5;
				this.startIndex = startIndex;
				this.endIndex = endIndex;
			}

			@Override
			public int length() {
				return (endIndex - startIndex);
			}

			private static int index1(final int idx, final int index2, final int index3, final int index4, final int index5, final Object[] node1) {
				return (index5 == 0 && index4 == 0 && index3 == 0 && index2 == 0) ? index1(idx) + node1.length - (1 << 5) : index1(idx);
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final Object[][] node2) {
				return (index5 == 0 && index4 == 0 && index3 == 0) ? index2(idx) + node2.length - (1 << 5) : index2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final Object[][][] node3) {
				return (index5 == 0 && index4 == 0) ? index3(idx) + node3.length - (1 << 5) : index3(idx);
			}

			private static int index4(final int idx, final int index5, final Object[][][][] node4) {
				return (index5 == 0) ? index4(idx) + node4.length - (1 << 5) : index4(idx);
			}

			@Override
			public A get(final int index) {
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final int index5 = index5(idx);
				final Object[][][][] node4 = node5[index5];
				final int index4 = index4(idx, index5, node4);
				final Object[][][] node3 = node4[index4];
				final int index3 = index3(idx, index4, index5, node3);
				final Object[][] node2 = node3[index3];
				final int index2 = index2(idx, index3, index4, index5, node2);
				final Object[] node1 = node2[index2];
				final int index1 = index1(idx, index2, index3, index4, index5, node1);
				return (A) node1[index1];
			}

			@Override
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
				final Object[][][][][] newNode5 = node5.clone();
				final int index5 = index5(idx);
				final Object[][][][] newNode4 = newNode5[index5].clone();
				final int index4 = index4(idx, index5, newNode4);
				final Object[][][] newNode3 = newNode4[index4].clone();
				final int index3 = index3(idx, index4, index5, newNode3);
				final Object[][] newNode2 = newNode3[index3].clone();
				final int index2 = index2(idx, index3, index4, index5, newNode2);
				final Object[] newNode1 = newNode2[index2].clone();
				final int index1 = index1(idx, index2, index3, index4, index5, newNode1);
				newNode5[index5] = newNode4;
				newNode4[index4] = newNode3;
				newNode3[index3] = newNode2;
				newNode2[index2] = newNode1;
				newNode1[index1] = value;
				return new Seq5<>(newNode5, startIndex, endIndex);
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);
				final Object[][][][] node4 = node5[0];
				final Object[][][] node3 = node4[0];
				final Object[][] node2 = node3[0];
				final Object[] node1 = node2[0];
				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							if (node4.length == 1 << 5) {
								if (node5.length == 1 << 5) {
									final Object[] newNode1 = { value };
									final Object[][] newNode2 = { newNode1 };
									final Object[][][] newNode3 = { newNode2 };
									final Object[][][][] newNode4 = { newNode3 };
									final Object[][][][][] newNode5 = { newNode4 };
									final Object[][][][][][] newNode6 = { newNode5, node5 };
									if (startIndex != 0) {
										throw new IllegalStateException("startIndex != 0");
									}
									return new Seq6<>(newNode6, (1 << 25) - 1, (1 << 25) + endIndex);
								} else {
									final Object[] newNode1 = { value };
									final Object[][] newNode2 = { newNode1 };
									final Object[][][] newNode3 = { newNode2 };
									final Object[][][][] newNode4 = { newNode3 };
									final Object[][][][][] newNode5 = new Object[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 1, node5.length);
									newNode5[0] = newNode4;
									if (startIndex != 0) {
										throw new IllegalStateException("startIndex != 0");
									}
									return new Seq5<>(newNode5, (1 << 20) - 1, (1 << 20) + endIndex);
								}
							} else {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 1, node4.length);
								newNode4[0] = newNode3;
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								return new Seq5<>(newNode5, startIndex - 1, endIndex);
							}
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 1, node3.length);
							newNode3[0] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							return new Seq5<>(newNode5, startIndex - 1, endIndex);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						return new Seq5<>(newNode5, startIndex - 1, endIndex);
					}
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[0] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[0] = newNode2;
					final Object[][][][] newNode4 = node4.clone();
					newNode4[0] = newNode3;
					final Object[][][][][] newNode5 = node5.clone();
					newNode5[0] = newNode4;
					return new Seq5<>(newNode5, startIndex - 1, endIndex);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);

				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				final Object[] node1 = node2[node2.length - 1];

				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							if (node4.length == 1 << 5) {
								if (node5.length == 1 << 5) {
									final Object[] newNode1 = { value };
									final Object[][] newNode2 = { newNode1 };
									final Object[][][] newNode3 = { newNode2 };
									final Object[][][][] newNode4 = { newNode3 };
									final Object[][][][][] newNode5 = { newNode4 };
									final Object[][][][][][] newNode6 = { node5, newNode5 };
									return new Seq6<>(newNode6, startIndex, endIndex + 1);
								} else {
									final Object[] newNode1 = { value };
									final Object[][] newNode2 = { newNode1 };
									final Object[][][] newNode3 = { newNode2 };
									final Object[][][][] newNode4 = { newNode3 };
									final Object[][][][][] newNode5 = Arrays.copyOf(node5, node5.length + 1);
									newNode5[node5.length] = newNode4;
									return new Seq5<>(newNode5, startIndex, endIndex + 1);
								}
							} else {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = Arrays.copyOf(node4, node4.length + 1);
								newNode4[newNode4.length - 1] = newNode3;
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								return new Seq5<>(newNode5, startIndex, endIndex + 1);
							}
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = Arrays.copyOf(node3, node3.length + 1);
							newNode3[node3.length] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							return new Seq5<>(newNode5, startIndex, endIndex + 1);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = Arrays.copyOf(node2, node2.length + 1);
						newNode2[node2.length] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						return new Seq5<>(newNode5, startIndex, endIndex + 1);
					}
				} else {
					final Object[] newNode1 = Arrays.copyOf(node1, node1.length + 1);
					newNode1[node1.length] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[newNode2.length - 1] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[newNode3.length - 1] = newNode2;
					final Object[][][][] newNode4 = node4.clone();
					newNode4[newNode4.length - 1] = newNode3;
					final Object[][][][][] newNode5 = node5.clone();
					newNode5[newNode5.length - 1] = newNode4;
					return new Seq5<>(newNode5, startIndex, endIndex + 1);
				}
			}
		}

		final class Seq6<A> extends Seq<A> {
			private final Object[][][][][][] node6;
			private final int startIndex;
			private final int endIndex;

			Seq6(final Object[][][][][][] node6, final int startIndex, final int endIndex) {
				this.node6 = node6;
				this.startIndex = startIndex;
				this.endIndex = endIndex;
			}

			@Override
			public int length() {
				return (endIndex - startIndex);
			}

			private static int index1(final int idx, final int index2, final int index3, final int index4, final int index5, final int index6, final Object[] node1) {
				return (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0 && index2 == 0) ? index1(idx) + node1.length - (1 << 5) : index1(idx);
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final int index6, final Object[][] node2) {
				return (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) ? index2(idx) + node2.length - (1 << 5) : index2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final int index6, final Object[][][] node3) {
				return (index6 == 0 && index5 == 0 && index4 == 0) ? index3(idx) + node3.length - (1 << 5) : index3(idx);
			}

			private static int index4(final int idx, final int index5, final int index6, final Object[][][][] node4) {
				return (index6 == 0 && index5 == 0) ? index4(idx) + node4.length - (1 << 5) : index4(idx);
			}

			private static int index5(final int idx, final int index6, final Object[][][][][] node5) {
				return (index6 == 0) ? index5(idx) + node5.length - (1 << 5) : index5(idx);
			}

			@Override
			public A get(final int index) {
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
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
				final int index1 = index1(idx, index2, index3, index4, index5, index6, node1);
				return (A) node1[index1];
			}

			@Override
			public Seq<A> set(final int index, final A value) {
				requireNonNull(value);
				final int idx = checkRangeAndConvert(index, startIndex, endIndex);
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
				final int index1 = index1(idx, index2, index3, index4, index5, index6, newNode1);
				newNode6[index6] = newNode5;
				newNode5[index5] = newNode4;
				newNode4[index4] = newNode3;
				newNode3[index3] = newNode2;
				newNode2[index2] = newNode1;
				newNode1[index1] = value;
				return new Seq6<>(newNode6, startIndex, endIndex);
			}

			@Override
			public Seq<A> prepend(final A value) {
				requireNonNull(value);

				final Object[][][][][] node5 = node6[0];
				final Object[][][][] node4 = node5[0];
				final Object[][][] node3 = node4[0];
				final Object[][] node2 = node3[0];
				final Object[] node1 = node2[0];

				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							if (node4.length == 1 << 5) {
								if (node5.length == 1 << 5) {
									if (node6.length == 1 << 5) {
										throw new IndexOutOfBoundsException("Seq size limit exceeded");
									} else {
										final Object[] newNode1 = { value };
										final Object[][] newNode2 = { newNode1 };
										final Object[][][] newNode3 = { newNode2 };
										final Object[][][][] newNode4 = { newNode3 };
										final Object[][][][][] newNode5 = { newNode4 };
										final Object[][][][][][] newNode6 = new Object[node6.length + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 1, node6.length);
										newNode6[0] = newNode5;
										if (startIndex != 0) {
											throw new IllegalStateException("startIndex != 0");
										}
										return new Seq6<>(newNode6, (1 << 25) - 1, (1 << 25) + endIndex);
									}
								} else {
									final Object[] newNode1 = { value };
									final Object[][] newNode2 = { newNode1 };
									final Object[][][] newNode3 = { newNode2 };
									final Object[][][][] newNode4 =  { newNode3 };
									final Object[][][][][] newNode5 = new Object[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 1, node5.length);
									newNode5[0] = newNode4;
									final Object[][][][][][] newNode6 = node6.clone();
									newNode6[0] = newNode5;
									return new Seq6<>(newNode6, startIndex - 1, endIndex);
								}
							} else {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = new Object[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 1, node4.length);
								newNode4[0] = newNode3;
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								final Object[][][][][][] newNode6 = node6.clone();
								newNode6[0] = newNode5;
								return new Seq6<>(newNode6, startIndex - 1, endIndex);
							}
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = new Object[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 1, node3.length);
							newNode3[0] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							final Object[][][][][][] newNode6 = node6.clone();
							newNode6[0] = newNode5;
							return new Seq6<>(newNode6, startIndex - 1, endIndex);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = new Object[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						final Object[][][][][][] newNode6 = node6.clone();
						newNode6[0] = newNode5;
						return new Seq6<>(newNode6, startIndex - 1, endIndex);
					}
				} else {
					final Object[] newNode1 = new Object[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[0] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[0] = newNode2;
					final Object[][][][] newNode4 = node4.clone();
					newNode4[0] = newNode3;
					final Object[][][][][] newNode5 = node5.clone();
					newNode5[0] = newNode4;
					final Object[][][][][][] newNode6 = node6.clone();
					newNode6[0] = newNode5;
					return new Seq6<>(newNode6, startIndex - 1, endIndex);
				}
			}

			@Override
			public Seq<A> append(final A value) {
				requireNonNull(value);

				final Object[][][][][] node5 = node6[node6.length - 1];
				final Object[][][][] node4 = node5[node5.length - 1];
				final Object[][][] node3 = node4[node4.length - 1];
				final Object[][] node2 = node3[node3.length - 1];
				final Object[] node1 = node2[node2.length - 1];

				if (node1.length == 1 << 5) {
					if (node2.length == 1 << 5) {
						if (node3.length == 1 << 5) {
							if (node4.length == 1 << 5) {
								if (node5.length == 1 << 5) {
									if (node6.length == 1 << 5) {
										throw new IndexOutOfBoundsException("Seq size limit exceeded");
									} else {
										final Object[] newNode1 = { value };
										final Object[][] newNode2 = { newNode1 };
										final Object[][][] newNode3 = { newNode2 };
										final Object[][][][] newNode4 = { newNode3 };
										final Object[][][][][] newNode5 = { newNode4 };
										final Object[][][][][][] newNode6 = Arrays.copyOf(node6, node6.length + 1);
										newNode6[node6.length] = newNode5;
										return new Seq6<>(newNode6, startIndex, endIndex + 1);
									}
								} else {
									final Object[] newNode1 = { value };
									final Object[][] newNode2 = { newNode1 };
									final Object[][][] newNode3 = { newNode2 };
									final Object[][][][] newNode4 = { newNode3 };
									final Object[][][][][] newNode5 = Arrays.copyOf(node5, node5.length + 1);
									newNode5[newNode5.length - 1] = newNode4;
									final Object[][][][][][] newNode6 = node6.clone();
									newNode6[newNode6.length - 1] = newNode5;
									return new Seq6<>(newNode6, startIndex, endIndex + 1);
								}
							} else {
								final Object[] newNode1 = { value };
								final Object[][] newNode2 = { newNode1 };
								final Object[][][] newNode3 = { newNode2 };
								final Object[][][][] newNode4 = Arrays.copyOf(node4, node4.length + 1);
								newNode4[newNode4.length - 1] = newNode3;
								final Object[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								final Object[][][][][][] newNode6 = node6.clone();
								newNode6[newNode6.length - 1] = newNode5;
								return new Seq6<>(newNode6, startIndex, endIndex + 1);
							}
						} else {
							final Object[] newNode1 = { value };
							final Object[][] newNode2 = { newNode1 };
							final Object[][][] newNode3 = Arrays.copyOf(node3, node3.length + 1);
							newNode3[node3.length] = newNode2;
							final Object[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final Object[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							final Object[][][][][][] newNode6 = node6.clone();
							newNode6[newNode6.length - 1] = newNode5;
							return new Seq6<>(newNode6, startIndex, endIndex + 1);
						}
					} else {
						final Object[] newNode1 = { value };
						final Object[][] newNode2 = Arrays.copyOf(node2, node2.length + 1);
						newNode2[node2.length] = newNode1;
						final Object[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final Object[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final Object[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						final Object[][][][][][] newNode6 = node6.clone();
						newNode6[newNode6.length - 1] = newNode5;
						return new Seq6<>(newNode6, startIndex, endIndex + 1);
					}
				} else {
					final Object[] newNode1 = Arrays.copyOf(node1, node1.length + 1);
					newNode1[node1.length] = value;
					final Object[][] newNode2 = node2.clone();
					newNode2[newNode2.length - 1] = newNode1;
					final Object[][][] newNode3 = node3.clone();
					newNode3[newNode3.length - 1] = newNode2;
					final Object[][][][] newNode4 = node4.clone();
					newNode4[newNode4.length - 1] = newNode3;
					final Object[][][][][] newNode5 = node5.clone();
					newNode5[newNode5.length - 1] = newNode4;
					final Object[][][][][][] newNode6 = node6.clone();
					newNode6[newNode6.length - 1] = newNode5;
					return new Seq6<>(newNode6, startIndex, endIndex + 1);
				}
			}
		}
	''' }
}
