package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SeqBuilderGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new SeqBuilderGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("SeqBuilder") }
	def shortSeqName() { if (type == Type.OBJECT) "Seq" else type.typeName + "Seq" }
	def genericName() { type.genericName("SeqBuilder") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Iterator;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»

		import static «Constants.COLLECTION».«shortSeqName».empty«shortSeqName»;
		import static «Constants.COMMON».*;

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

			«shortName»(final «type.seqGenericName» seq) {
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

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public final «genericName» appendValues(final «type.genericName»... values) {
				for (final «type.genericName» value : values) {
					append(value);
				}
				return this;
			}

			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> iterable) {
				«IF Type.javaUnboxedTypes.contains(type)»
					appendIterator(iterable.iterator());
				«ELSE»
					iterable.forEach(this::append);
				«ENDIF»
				return this;
			}

			public «genericName» appendIterator(final Iterator<«type.genericBoxedName»> iterator) {
				«IF Type.javaUnboxedTypes.contains(type)»
					«type.typeName»Iterator.getIterator(iterator).forEachRemaining((«type.typeName»Consumer) this::append);
				«ELSE»
					iterator.forEachRemaining(this::append);
				«ENDIF»
				return this;
			}

			public boolean isEmpty() {
				return (size == 0);
			}

			public int size() {
				return size;
			}

			public «type.seqGenericName» build() {
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
			«IF type == Type.OBJECT»

				«genericName» appendSeqBuilder(final «genericName» builder) {
					builder.appendTo(this);
					return this;
				}

				private void appendTo(final «genericName» builder) {
					if (node1 != null) {
						if (node2 != null) {
							appendInitTo(builder);
							if (node3 == null) {
								appendNode2To(builder);
							} else if (node4 == null) {
								appendNode3To(builder);
								appendNode2To(builder);
							} else if (node5 == null) {
								appendNode4To(builder);
								appendNode3To(builder);
								appendNode2To(builder);
							} else if (node6 == null) {
								appendNode5To(builder);
								appendNode4To(builder);
								appendNode3To(builder);
								appendNode2To(builder);
							} else {
								appendNode6To(builder);
								appendNode5To(builder);
								appendNode4To(builder);
								appendNode3To(builder);
								appendNode2To(builder);
							}
						}
						appendNode1To(builder);
					}
				}

				private void appendInitTo(final «genericName» builder) {
					for (final «type.javaName» value : init) {
						builder.append(value);
					}
				}

				private void appendNode1To(final «genericName» builder) {
					for (int i = 0; i < index1; i++) {
						builder.append(node1[i]);
					}
				}

				private void appendNode2To(final «genericName» builder) {
					for (int i = 0; i < index2 - 1; i++) {
						for (final «type.javaName» value : node2[i]) {
							builder.append(value);
						}
					}
				}

				private void appendNode3To(final «genericName» builder) {
					for (int i = 0; i < index3 - 1; i++) {
						for (final «type.javaName»[] n1 : node3[i]) {
							for (final «type.javaName» value : n1) {
								builder.append(value);
							}
						}
					}
				}

				private void appendNode4To(final «genericName» builder) {
					for (int i = 0; i < index4 - 1; i++) {
						for (final «type.javaName»[][] n2 : node4[i]) {
							for (final «type.javaName»[] n1 : n2) {
								for (final «type.javaName» value : n1) {
									builder.append(value);
								}
							}
						}
					}
				}

				private void appendNode5To(final «genericName» builder) {
					for (int i = 0; i < index5 - 1; i++) {
						for (final «type.javaName»[][][] n3 : node5[i]) {
							for (final «type.javaName»[][] n2 : n3) {
								for (final «type.javaName»[] n1 : n2) {
									for (final «type.javaName» value : n1) {
										builder.append(value);
									}
								}
							}
						}
					}
				}

				private void appendNode6To(final «genericName» builder) {
					for (int i = 0; i < index6 - 1; i++) {
						for (final «type.javaName»[][][][] n4 : node6[i]) {
							for (final «type.javaName»[][][] n3 : n4) {
								for (final «type.javaName»[][] n2 : n3) {
									for (final «type.javaName»[] n1 : n2) {
										for (final «type.javaName» value : n1) {
											builder.append(value);
										}
									}
								}
							}
						}
					}
				}
			«ENDIF»

			@Override
			public String toString() {
				«IF Type.javaUnboxedTypes.contains(type)»
					return «type.containerShortName.firstToLowerCase»ToString(build(), "«shortName»");
				«ELSE»
					return iterableToString(build(), "«shortName»");
				«ENDIF»
			}
		}
	''' }
}