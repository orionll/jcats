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
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»
		import java.util.stream.«type.streamName»;

		import «Constants.JCATS».*;

		«IF type == Type.OBJECT»
			import static java.util.Objects.requireNonNull;
		«ENDIF»
		import static «Constants.COLLECTION».«shortSeqName».empty«shortSeqName»;
		import static «Constants.COMMON».*;

		public final class «genericName» implements Sized {
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
			public «genericName» append(final «type.genericName» value) {
				«IF (type == Type.OBJECT)»
					requireNonNull(value);
				«ENDIF»
				if (this.index1 < 32) {
					if (this.node1 == null) {
						this.node1 = new «type.javaName»[32];
					}
					this.node1[this.index1++] = value;
				} else if (this.index2 < (this.index3 == 0 ? 31 : 32)) {
					if (this.node2 == null) {
						this.node2 = new «type.javaName»[31][];
						this.init = this.node1;
					}
					this.node1 = new «type.javaName»[32];
					this.node2[this.index2++] = this.node1;
					this.node1[0] = value;
					this.index1 = 1;
				} else if (this.index3 < 32) {
					if (this.node3 == null) {
						this.node3 = new «type.javaName»[32][][];
						this.node3[0] = this.node2;
						this.index3 = 1;
					}
					this.node2 = new «type.javaName»[32][];
					this.node1 = new «type.javaName»[32];
					this.node3[this.index3++] = this.node2;
					this.node2[0] = this.node1;
					this.node1[0] = value;
					this.index2 = 1;
					this.index1 = 1;
				} else if (this.index4 < 32) {
					if (this.node4 == null) {
						this.node4 = new «type.javaName»[32][][][];
						this.node4[0] = this.node3;
						this.index4 = 1;
					}
					this.node3 = new «type.javaName»[32][][];
					this.node2 = new «type.javaName»[32][];
					this.node1 = new «type.javaName»[32];
					this.node4[this.index4++] = this.node3;
					this.node3[0] = this.node2;
					this.node2[0] = this.node1;
					this.node1[0] = value;
					this.index3 = 1;
					this.index2 = 1;
					this.index1 = 1;
				} else if (this.index5 < 32) {
					if (this.node5 == null) {
						this.node5 = new «type.javaName»[32][][][][];
						this.node5[0] = this.node4;
						this.index5 = 1;
					}
					this.node4 = new «type.javaName»[32][][][];
					this.node3 = new «type.javaName»[32][][];
					this.node2 = new «type.javaName»[32][];
					this.node1 = new «type.javaName»[32];
					this.node5[this.index5++] = this.node4;
					this.node4[0] = this.node3;
					this.node3[0] = this.node2;
					this.node2[0] = this.node1;
					this.node1[0] = value;
					this.index4 = 1;
					this.index3 = 1;
					this.index2 = 1;
					this.index1 = 1;
				} else if (this.index6 < 32) {
					if (this.node6 == null) {
						this.node6 = new «type.javaName»[32][][][][][];
						this.node6[0] = this.node5;
						this.index6 = 1;
					}
					this.node5 = new «type.javaName»[32][][][][];
					this.node4 = new «type.javaName»[32][][][];
					this.node3 = new «type.javaName»[32][][];
					this.node2 = new «type.javaName»[32][];
					this.node1 = new «type.javaName»[32];
					this.node6[this.index6++] = this.node5;
					this.node5[0] = this.node4;
					this.node4[0] = this.node3;
					this.node3[0] = this.node2;
					this.node2[0] = this.node1;
					this.node1[0] = value;
					this.index5 = 1;
					this.index4 = 1;
					this.index3 = 1;
					this.index2 = 1;
					this.index1 = 1;
				} else {
					throw new SizeOverflowException();
				}
				this.size++;
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
				«IF type.javaUnboxedType»
					if (iterable instanceof «type.containerShortName») {
						((«type.containerShortName») iterable).foreach(this::append);
					} else {
						appendIterator(iterable.iterator());
					}
				«ELSE»
					if (iterable instanceof «type.containerWildcardName») {
						((«type.containerGenericName») iterable).foreach(this::append);
					} else {
						iterable.forEach(this::append);
					}
				«ENDIF»
				return this;
			}

			public «genericName» appendIterator(final Iterator<«type.genericBoxedName»> iterator) {
				«IF type.javaUnboxedType»
					«type.typeName»Iterator.getIterator(iterator).forEachRemaining((«type.typeName»Consumer) this::append);
				«ELSE»
					iterator.forEachRemaining(this::append);
				«ENDIF»
				return this;
			}

			public «genericName» append«type.streamName»(final «type.streamGenericName» stream) {
				«streamForEach(type.genericJavaUnboxedName, "append", true)»
				return this;
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public int size() {
				return this.size;
			}

			public «type.seqGenericName» build() {
				if (this.node1 == null) {
					return empty«shortSeqName»();
				} else if (this.node2 == null) {
					return new «shortSeqName»1«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode1());
				} else if (this.node3 == null) {
					return new «shortSeqName»2«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode2(), this.init, trimmedNode1(), this.size);
				} else if (this.node4 == null) {
					return new «shortSeqName»3«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode3(), this.init, trimmedNode1(), this.startIndex, this.size);
				} else if (this.node5 == null) {
					return new «shortSeqName»4«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode4(), this.init, trimmedNode1(), this.startIndex, this.size);
				} else if (this.node6 == null) {
					return new «shortSeqName»5«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode5(), this.init, trimmedNode1(), this.startIndex, this.size);
				} else {
					return new «shortSeqName»6«IF type == Type.OBJECT»<>«ENDIF»(trimmedNode6(), this.init, trimmedNode1(), this.startIndex, this.size);
				}
			}

			private «type.javaName»[] trimmedNode1() {
				if (this.index1 < 32) {
					return Arrays.copyOf(this.node1, this.index1);
				} else {
					return this.node1;
				}
			}

			private «type.javaName»[][] trimmedNode2() {
				if (this.index2 == 1) {
					return «shortSeqName».EMPTY_NODE2;
				} else {
					return Arrays.copyOf(this.node2, this.index2 - 1);
				}
			}

			private «type.javaName»[][][] trimmedNode3() {
				final «type.javaName»[][][] trimmedNode3 = Arrays.copyOf(this.node3, this.index3);
				trimmedNode3[this.index3 - 1] = trimmedNode2();
				return trimmedNode3;
			}

			private «type.javaName»[][][][] trimmedNode4() {
				final «type.javaName»[][][][] trimmedNode4 = Arrays.copyOf(this.node4, this.index4);
				trimmedNode4[this.index4 - 1] = trimmedNode3();
				return trimmedNode4;
			}

			private «type.javaName»[][][][][] trimmedNode5() {
				final «type.javaName»[][][][][] trimmedNode5 = Arrays.copyOf(this.node5, this.index5);
				trimmedNode5[this.index5 - 1] = trimmedNode4();
				return trimmedNode5;
			}

			private «type.javaName»[][][][][][] trimmedNode6() {
				final «type.javaName»[][][][][][] trimmedNode6 = Arrays.copyOf(this.node6, this.index6);
				trimmedNode6[this.index6 - 1] = trimmedNode5();
				return trimmedNode6;
			}

			«genericName» appendSeqBuilder(final «genericName» builder) {
				builder.appendTo(this);
				return this;
			}

			private void appendTo(final «genericName» builder) {
				if (this.node1 != null) {
					if (this.node2 != null) {
						appendInitTo(builder);
						if (this.node3 == null) {
							appendNode2To(builder);
						} else if (this.node4 == null) {
							appendNode3To(builder);
							appendNode2To(builder);
						} else if (this.node5 == null) {
							appendNode4To(builder);
							appendNode3To(builder);
							appendNode2To(builder);
						} else if (this.node6 == null) {
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
				for (final «type.javaName» value : this.init) {
					builder.append(«type.genericCast»value);
				}
			}

			private void appendNode1To(final «genericName» builder) {
				for (int i = 0; i < this.index1; i++) {
					builder.append(«type.genericCast»this.node1[i]);
				}
			}

			private void appendNode2To(final «genericName» builder) {
				for (int i = 0; i < this.index2 - 1; i++) {
					for (final «type.javaName» value : this.node2[i]) {
						builder.append(«type.genericCast»value);
					}
				}
			}

			private void appendNode3To(final «genericName» builder) {
				for (int i = 0; i < this.index3 - 1; i++) {
					for (final «type.javaName»[] n1 : this.node3[i]) {
						for (final «type.javaName» value : n1) {
							builder.append(«type.genericCast»value);
						}
					}
				}
			}

			private void appendNode4To(final «genericName» builder) {
				for (int i = 0; i < this.index4 - 1; i++) {
					for (final «type.javaName»[][] n2 : this.node4[i]) {
						for (final «type.javaName»[] n1 : n2) {
							for (final «type.javaName» value : n1) {
								builder.append(«type.genericCast»value);
							}
						}
					}
				}
			}

			private void appendNode5To(final «genericName» builder) {
				for (int i = 0; i < this.index5 - 1; i++) {
					for (final «type.javaName»[][][] n3 : this.node5[i]) {
						for (final «type.javaName»[][] n2 : n3) {
							for (final «type.javaName»[] n1 : n2) {
								for (final «type.javaName» value : n1) {
									builder.append(«type.genericCast»value);
								}
							}
						}
					}
				}
			}

			private void appendNode6To(final «genericName» builder) {
				for (int i = 0; i < this.index6 - 1; i++) {
					for (final «type.javaName»[][][][] n4 : this.node6[i]) {
						for (final «type.javaName»[][][] n3 : n4) {
							for (final «type.javaName»[][] n2 : n3) {
								for (final «type.javaName»[] n1 : n2) {
									for (final «type.javaName» value : n1) {
										builder.append(«type.genericCast»value);
									}
								}
							}
						}
					}
				}
			}

			«toStr(type, "build()")»
		}
	''' }
}