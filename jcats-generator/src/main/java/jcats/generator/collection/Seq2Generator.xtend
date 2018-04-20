package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Seq2Generator extends SeqGenerator {

	def static List<Generator> generators() {
		Type.values.toList.map[new Seq2Generator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName + "2" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.NoSuchElementException;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static jcats.collection.Seq.*;
		«ENDIF»
		import static «Constants.COMMON».*;

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
					«indexOutOfBounds(shortName)»
				}
			}

			@Override
			public «genericName» update(final int index, final «type.updateFunction» f) {
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = «type.updateArray("init", "index")»;
						return new «diamondName(2)»(node2, newInit, tail, size);
					} else if (index >= size - tail.length) {
						final int tailIndex = index + tail.length - size;
						final «type.javaName»[] newTail = «type.updateArray("tail", "tailIndex")»;
						return new «diamondName(2)»(node2, init, newTail, size);
					} else {
						final int idx = index + 32 - init.length;
						final int index2 = index2(idx) - 1;
						final int index1 = index1(idx);
						final «type.javaName»[] node1 = node2[index2];

						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						final «type.javaName»[] newNode1 = «type.updateArray("node1", "index1")»;
						newNode2[index2] = newNode1;
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
			«IF type == Type.OBJECT»
				void copyToArray(final Object[] array) {
			«ELSE»
				public «type.javaName»[] «type.toArrayName»() {
					final «type.javaName»[] array = new «type.javaName»[size];
			«ENDIF»
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[] node1 : node2) {
					System.arraycopy(node1, 0, array, index, 32);
					index += 32;
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				«IF type != Type.OBJECT»
					return array;
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(2)»(node2, init, tail);
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return new «reverseIteratorDiamondName(2)»(node2, init, tail);
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				for (final «type.javaName» value : init) {
					eff.apply(«type.genericCast»value);
				}
				for (final «type.javaName»[] node1 : node2) {
					for (final «type.javaName» value : node1) {
						eff.apply(«type.genericCast»value);
					}
				}
				for (final «type.javaName» value : tail) {
					eff.apply(«type.genericCast»value);
				}
			}

			@Override
			public void foreachUntil(final «type.boolFName» eff) {
				for (final «type.javaName» value : init) {
					if (!eff.apply(«type.genericCast»value)) {
						return;
					}
				}
				for (final «type.javaName»[] node1 : node2) {
					for (final «type.javaName» value : node1) {
						if (!eff.apply(«type.genericCast»value)) {
							return;
						}
					}
				}
				for (final «type.javaName» value : tail) {
					if (!eff.apply(«type.genericCast»value)) {
						return;
					}
				}
			}
		}

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
			public «type.iteratorReturnType» «type.iteratorNext»() {
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

		final class «reverseIteratorName(2)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][] node2;
			private final «type.javaName»[] init;

			private int index2;
			private int index1;
			private «type.javaName»[] node1;

			«shortName»2ReverseIterator(final «type.javaName»[][] node2, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node2 = node2;
				this.init = init;
				node1 = tail;
				index2 = node2.length - 1;
				index1 = tail.length - 1;
			}

			@Override
			public boolean hasNext() {
				return (index1 >= 0 || index2 >= -1);
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (index1 >= 0) {
					return «type.genericCast»node1[index1--];
				} else if (index2 >= 0) {
					node1 = node2[index2--];
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (index2 == -1) {
					node1 = init;
					index2--;
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else {
					throw new NoSuchElementException();
				}
			}
		}
	''' }
}
