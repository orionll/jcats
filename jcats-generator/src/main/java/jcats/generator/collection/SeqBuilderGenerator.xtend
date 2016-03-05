package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class SeqBuilderGenerator implements ClassGenerator {
	override className() { Constants.SEQ + "Builder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Arrays;
		import java.util.Collection;

		import static «Constants.SEQ».emptySeq;

		import static java.util.Objects.requireNonNull;

		public final class SeqBuilder<A> {
			private Object[][][][][][] node6;
			private Object[][][][][] node5;
			private Object[][][][] node4;
			private Object[][][] node3;
			private Object[][] node2;
			private Object[] node1;
			private Object[] init;
			private int index6;
			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private int size;

			SeqBuilder() {}

			/**
			 * O(1)
			 */
			public SeqBuilder<A> append(final A value) {
				requireNonNull(value);
				if (index1 < 32) {
					if (node1 == null) {
						node1 = new Object[32];
					}
					node1[index1++] = value;
				} else if (index2 < (index3 == 0 ? 31 : 32)) {
					if (node2 == null) {
						node2 = new Object[31][];
						init = node1;
					}
					node1 = new Object[32];
					node2[index2++] = node1;
					node1[0] = value;
					index1 = 1;
				} else if (index3 < 32) {
					if (node3 == null) {
						node3 = new Object[32][][];
						node3[0] = node2;
						index3 = 1;
					}
					node2 = new Object[32][];
					node1 = new Object[32];
					node3[index3++] = node2;
					node2[0] = node1;
					node1[0] = value;
					index2 = 1;
					index1 = 1;
				} else if (index4 < 32) {
					if (node4 == null) {
						node4 = new Object[32][][][];
						node4[0] = node3;
						index4 = 1;
					}
					node3 = new Object[32][][];
					node2 = new Object[32][];
					node1 = new Object[32];
					node4[index4++] = node3;
					node3[0] = node2;
					node2[0] = node1;
					node1[0] = value;
					index3 = 1;
					index2 = 1;
					index1 = 1;
				} else if (index5 < 32) {
					if (node5 == null) {
						node5 = new Object[32][][][][];
						node5[0] = node4;
						index5 = 1;
					}
					node4 = new Object[32][][][];
					node3 = new Object[32][][];
					node2 = new Object[32][];
					node1 = new Object[32];
					node5[index5++] = node4;
					node4[0] = node3;
					node3[0] = node2;
					node2[0] = node1;
					node1[0] = value;
					index4 = 1;
					index3 = 1;
					index2 = 1;
					index1 = 1;
				} else if (index6 < 32) {
					if (node6 == null) {
						node6 = new Object[32][][][][][];
						node6[0] = node5;
						index6 = 1;
					}
					node5 = new Object[32][][][][];
					node4 = new Object[32][][][];
					node3 = new Object[32][][];
					node2 = new Object[32][];
					node1 = new Object[32];
					node6[index6++] = node5;
					node5[0] = node4;
					node4[0] = node3;
					node3[0] = node2;
					node2[0] = node1;
					node1[0] = value;
					index5 = 1;
					index4 = 1;
					index3 = 1;
					index2 = 1;
					index1 = 1;
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
				size++;
				return this;
			}

			public Seq<A> build() {
				if (node1 == null) {
					return emptySeq();
				} else if (node2 == null) {
					return new Seq1<>(trimmedNode1());
				} else if (node3 == null) {
					return new Seq2<>(trimmedNode2(), init, trimmedNode1(), 0, size);
				} else if (node4 == null) {
					return new Seq3<>(trimmedNode3(), init, trimmedNode1(), 0, size);
				} else if (node5 == null) {
					return new Seq4<>(trimmedNode4(), init, trimmedNode1(), 0, size);
				} else if (node6 == null) {
					return new Seq5<>(trimmedNode5(), init, trimmedNode1(), 0, size);
				} else {
					return new Seq6<>(trimmedNode6(), init, trimmedNode1(), 0, size);
				}
			}

			private Object[] trimmedNode1() {
				if (index1 < 32) {
					return Arrays.copyOf(node1, index1);
				} else {
					return node1;
				}
			}

			private Object[][] trimmedNode2() {
				if (index2 == 1) {
					return Seq.EMPTY_NODE2;
				} else {
					return Arrays.copyOf(node2, index2 - 1);
				}
			}

			private Object[][][] trimmedNode3() {
				final Object[][][] trimmedNode3 = Arrays.copyOf(node3, index3);
				trimmedNode3[index3 - 1] = trimmedNode2();
				return trimmedNode3;
			}

			private Object[][][][] trimmedNode4() {
				final Object[][][][] trimmedNode4 = Arrays.copyOf(node4, index4);
				trimmedNode4[index4 - 1] = trimmedNode3();
				return trimmedNode4;
			}

			private Object[][][][][] trimmedNode5() {
				final Object[][][][][] trimmedNode5 = Arrays.copyOf(node5, index5);
				trimmedNode5[index5 - 1] = trimmedNode4();
				return trimmedNode5;
			}

			private Object[][][][][][] trimmedNode6() {
				final Object[][][][][][] trimmedNode6 = Arrays.copyOf(node6, index6);
				trimmedNode6[index6 - 1] = trimmedNode5();
				return trimmedNode6;
			}
		}
	''' }
}