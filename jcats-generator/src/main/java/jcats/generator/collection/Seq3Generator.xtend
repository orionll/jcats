package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class Seq3Generator extends SeqGenerator {

	def static List<Generator> generators() {
		Type.values.toList.map[new Seq3Generator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName + "3" }

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
					«indexOutOfBounds(shortName)»
				}
			}

			@Override
			public «genericName» update(final int index, final «type.updateFunction» f) {
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = «type.updateArray("init", "index")»;
						return new «diamondName(3)»(node3, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final int tailIndex = index + tail.length - size;
						final «type.javaName»[] newTail = «type.updateArray("tail", "tailIndex")»;
						return new «diamondName(3)»(node3, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final int index3 = index3(idx);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);

						final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length][][];
						System.arraycopy(node3, 0, newNode3, 0, node3.length);
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						final «type.javaName»[] newNode1 = «type.updateArray("node1", "index1")»;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						return new «diamondName(3)»(newNode3, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			}

			@Override
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
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
			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n >= size) {
					return empty«shortName»();
				} else if (n > size - tail.length) {
					final «type.javaName»[] node1 = new «type.javaName»[size - n];
					System.arraycopy(tail, n - size + tail.length, node1, 0, node1.length);
					return new «diamondName(1)»(node1);
				} else if (n == size - tail.length) {
					return new «diamondName(1)»(tail);
				} else if (n == 0) {
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
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
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
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
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
			«IF type == Type.OBJECT»
				void copyToArray(final Object[] array) {
			«ELSE»
				public «type.javaName»[] «type.toArrayName»() {
					final «type.javaName»[] array = new «type.javaName»[size];
			«ENDIF»
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[][] node2 : node3) {
					for (final «type.javaName»[] node1 : node2) {
						System.arraycopy(node1, 0, array, index, 32);
						index += 32;
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				«IF type != Type.OBJECT»
					return array;
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(3)»(node3, init, tail);
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return new «reverseIteratorDiamondName(3)»(node3, init, tail);
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				for (final «type.javaName» value : init) {
					eff.apply(«type.genericCast»value);
				}
				for (final «type.javaName»[][] node2 : node3) {
					for (final «type.javaName»[] node1 : node2) {
						for (final «type.javaName» value : node1) {
							eff.apply(«type.genericCast»value);
						}
					}
				}
				for (final «type.javaName» value : tail) {
					eff.apply(«type.genericCast»value);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				int i = 0;
				for (final «type.javaName» value : init) {
					eff.apply(i++, «type.genericCast»value);
				}
				for (final «type.javaName»[][] node2 : node3) {
					for (final «type.javaName»[] node1 : node2) {
						for (final «type.javaName» value : node1) {
							eff.apply(i++, «type.genericCast»value);
						}
					}
				}
				for (final «type.javaName» value : tail) {
					eff.apply(i++, «type.genericCast»value);
				}
			}

			@Override
			public void foreachUntil(final «type.boolFName» eff) {
				for (final «type.javaName» value : init) {
					if (!eff.apply(«type.genericCast»value)) {
						return;
					}
				}
				for (final «type.javaName»[][] node2 : node3) {
					for (final «type.javaName»[] node1 : node2) {
						for (final «type.javaName» value : node1) {
							if (!eff.apply(«type.genericCast»value)) {
								return;
							}
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
			public «type.iteratorReturnType» «type.iteratorNext»() {
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

		final class «reverseIteratorName(3)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][] node3;
			private final «type.javaName»[] init;

			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»3ReverseIterator(final «type.javaName»[][][] node3, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node3 = node3;
				this.init = init;
				node1 = tail;
				index3 = node3.length - 1;
				index1 = node1.length - 1;
			}

			@Override
			public boolean hasNext() {
				return (index1 >= 0 || (node2 != null && index2 >= 0) || index3 >= -1);
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (index1 >= 0) {
					return «type.genericCast»node1[index1--];
				} else if (node2 != null && index2 >= 0) {
					node1 = node2[index2--];
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (index3 >= 0) {
					if (node3[index3].length == 0) {
						if (index3 == 0) {
							node2 = null;
							node1 = init;
							index3 -= 2;
						} else {
							node2 = node3[node3.length - 2];
							node1 = node2[node2.length - 1];
							index3 -= 2;
							index2 = node2.length - 2;
						}
					} else {
						node2 = node3[index3--];
						node1 = node2[node2.length - 1];
						index2 = node2.length - 2;
					}
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (index3 == -1) {
					node2 = null;
					node1 = init;
					index3--;
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else {
					throw new NoSuchElementException();
				}
			}
		}
	''' }
}
