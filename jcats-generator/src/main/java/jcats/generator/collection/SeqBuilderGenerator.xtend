package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import jcats.generator.Type
import java.util.List
import jcats.generator.Generator

@FinalFieldsConstructor
final class SeqBuilderGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new SeqBuilderGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "SeqBuilder" else type.typeName + "SeqBuilder" }
	def shortSeqName() { if (type == Type.OBJECT) "Seq" else type.typeName + "Seq" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }
	def seqGenericName() { if (type == Type.OBJECT) "Seq<A>" else type.typeName + "Seq" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Arrays;
		import java.util.Collection;

		import static «Constants.COLLECTION».«shortSeqName».empty«shortSeqName»;

		«IF type == Type.OBJECT»
			import static java.util.Objects.requireNonNull;
		«ENDIF»

		public final class «genericName» {
			«type.javaName»[][][][][][] node6;
			«type.javaName»[][][][][] node5;
			«type.javaName»[][][][] node4;
			«type.javaName»[][][] node3;
			«type.javaName»[][] node2;
			«type.javaName»[] node1;
			«type.javaName»[] init;
			int index6;
			int index5;
			int index4;
			int index3;
			int index2;
			int index1;
			int size;
			int startIndex;

			«shortName»() {}

			«shortName»(final «seqGenericName» seq) {
				seq.initSeqBuilder(this);
			}

			/**
			 * O(1)
			 */
			public «genericName» append(final «type.javaName» value) {
				«IF (type == Type.OBJECT)»
					requireNonNull(value);
				«ENDIF»
				if (index1 < 32) {
					if (node1 == null) {
						node1 = new «type.javaName»[32];
					}
					node1[index1++] = value;
				} else if (index2 < (index3 == 0 ? 31 : 32)) {
					if (node2 == null) {
						node2 = new «type.javaName»[31][];
						init = node1;
					}
					node1 = new «type.javaName»[32];
					node2[index2++] = node1;
					node1[0] = value;
					index1 = 1;
				} else if (index3 < 32) {
					if (node3 == null) {
						node3 = new «type.javaName»[32][][];
						node3[0] = node2;
						index3 = 1;
					}
					node2 = new «type.javaName»[32][];
					node1 = new «type.javaName»[32];
					node3[index3++] = node2;
					node2[0] = node1;
					node1[0] = value;
					index2 = 1;
					index1 = 1;
				} else if (index4 < 32) {
					if (node4 == null) {
						node4 = new «type.javaName»[32][][][];
						node4[0] = node3;
						index4 = 1;
					}
					node3 = new «type.javaName»[32][][];
					node2 = new «type.javaName»[32][];
					node1 = new «type.javaName»[32];
					node4[index4++] = node3;
					node3[0] = node2;
					node2[0] = node1;
					node1[0] = value;
					index3 = 1;
					index2 = 1;
					index1 = 1;
				} else if (index5 < 32) {
					if (node5 == null) {
						node5 = new «type.javaName»[32][][][][];
						node5[0] = node4;
						index5 = 1;
					}
					node4 = new «type.javaName»[32][][][];
					node3 = new «type.javaName»[32][][];
					node2 = new «type.javaName»[32][];
					node1 = new «type.javaName»[32];
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
						node6 = new «type.javaName»[32][][][][][];
						node6[0] = node5;
						index6 = 1;
					}
					node5 = new «type.javaName»[32][][][][];
					node4 = new «type.javaName»[32][][][];
					node3 = new «type.javaName»[32][][];
					node2 = new «type.javaName»[32][];
					node1 = new «type.javaName»[32];
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

			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> iterable) {
				iterable.forEach(this::append);
				return this;
			}

			public boolean isEmpty() {
				return (size == 0);
			}

			public int size() {
				return size;
			}

			public «seqGenericName» build() {
				if (node1 == null) {
					return empty«shortSeqName»();
				} else if (node2 == null) {
					return new «shortSeqName»1«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode1());
				} else if (node3 == null) {
					return new «shortSeqName»2«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode2(), init, trimmedNode1(), size);
				} else if (node4 == null) {
					return new «shortSeqName»3«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode3(), init, trimmedNode1(), startIndex, size);
				} else if (node5 == null) {
					return new «shortSeqName»4«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode4(), init, trimmedNode1(), startIndex, size);
				} else if (node6 == null) {
					return new «shortSeqName»5«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode5(), init, trimmedNode1(), startIndex, size);
				} else {
					return new «shortSeqName»6«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode6(), init, trimmedNode1(), startIndex, size);
				}
			}

			private «type.javaName»[] trimmedNode1() {
				if (index1 < 32) {
					return Arrays.copyOf(node1, index1);
				} else {
					return node1;
				}
			}

			private «type.javaName»[][] trimmedNode2() {
				if (index2 == 1) {
					return «shortSeqName».EMPTY_NODE2;
				} else {
					return Arrays.copyOf(node2, index2 - 1);
				}
			}

			private «type.javaName»[][][] trimmedNode3() {
				final «type.javaName»[][][] trimmedNode3 = Arrays.copyOf(node3, index3);
				trimmedNode3[index3 - 1] = trimmedNode2();
				return trimmedNode3;
			}

			private «type.javaName»[][][][] trimmedNode4() {
				final «type.javaName»[][][][] trimmedNode4 = Arrays.copyOf(node4, index4);
				trimmedNode4[index4 - 1] = trimmedNode3();
				return trimmedNode4;
			}

			private «type.javaName»[][][][][] trimmedNode5() {
				final «type.javaName»[][][][][] trimmedNode5 = Arrays.copyOf(node5, index5);
				trimmedNode5[index5 - 1] = trimmedNode4();
				return trimmedNode5;
			}

			private «type.javaName»[][][][][][] trimmedNode6() {
				final «type.javaName»[][][][][][] trimmedNode6 = Arrays.copyOf(node6, index6);
				trimmedNode6[index6 - 1] = trimmedNode5();
				return trimmedNode6;
			}
		}
	''' }
}