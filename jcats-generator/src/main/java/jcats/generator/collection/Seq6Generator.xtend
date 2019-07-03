package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class Seq6Generator extends SeqGenerator {

	def static List<Generator> generators() {
		Type.values.toList.map[new Seq6Generator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName + "6" }

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

		final class «genericName(6)» extends «genericName» {
			final «type.javaName»[][][][][][] node6;
			final «type.javaName»[] init;
			final «type.javaName»[] tail;
			final int startIndex;
			final int size;

			«shortName»6(final «type.javaName»[][][][][][] node6, final «type.javaName»[] init, final «type.javaName»[] tail, final int startIndex, final int size) {
				this.node6 = node6;
				this.init = init;
				this.tail = tail;
				this.startIndex = startIndex;
				this.size = size;
				«IF ea»

					boolean ea = false;
					assert ea = true;
					if (ea) {
						final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
						final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
						final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
						final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];

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
							for (final «type.javaName»[][][][] node4 : node6[i]) {
								assert node4.length == 32 : "node4.length = " + node4.length;
								for (final «type.javaName»[][][] node3 : node4) {
									assert node3.length == 32 : "node3.length = " + node3.length;
									for (final «type.javaName»[][] node2 : node3) {
										assert node2.length == 32 : "node2.length = " + node2.length;
									}
								}
							}
						}

						for (int i = 1; i < node6[0].length; i++) {
							assert node6[0][i].length == 32 : "node4.length = " + node6[0][i].length;
							for (final «type.javaName»[][][] node3 : node6[0][i]) {
								assert node3.length == 32 : "node3.length = " + node3.length;
								for (final «type.javaName»[][] node2 : node3) {
									assert node2.length == 32 : "node2.length = " + node2.length;
								}
							}
						}
						for (int i = 0; i < lastNode5.length - 1; i++) {
							assert lastNode5[i].length == 32 : "node4.length = " + lastNode5[i].length;
							for (final «type.javaName»[][][] node3 : lastNode5[i]) {
								assert node3.length == 32 : "node3.length = " + node3.length;
								for (final «type.javaName»[][] node2 : node3) {
									assert node2.length == 32 : "node2.length = " + node2.length;
								}
							}
						}
						for (int i = 1; i < node6[0][0].length; i++) {
							assert node6[0][0][i].length == 32 : "node3.length = " + node6[0][0][i].length;
							for (final «type.javaName»[][] node2 : node6[0][0][i]) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
						for (int i = 0; i < lastNode4.length - 1; i++) {
							assert lastNode4[i].length == 32 : "node3.length = " + lastNode4[i].length;
							for (final «type.javaName»[][] node2 : lastNode4[i]) {
								assert node2.length == 32 : "node2.length = " + node2.length;
							}
						}
						for (int i = 1; i < node6[0][0][0].length; i++) {
							assert node6[0][0][0][i].length == 32 : "node2.length = " + node6[0][0][0][i].length;
						}
						for (int i = 0; i < lastNode3.length - 1; i++) {
							assert lastNode3[i].length == 32 : "node2.length = " + lastNode3[i].length;
						}
						for (final «type.javaName»[][][][][] node5 : node6) {
							for (final «type.javaName»[][][][] node4 : node5) {
								for (final «type.javaName»[][][] node3 : node4) {
									for (final «type.javaName»[][] node2 : node3) {
										for (final «type.javaName»[] node1 : node2) {
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
				«ENDIF»
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «genericName» init() {
				if (tail.length == 1) {
					final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
					final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
					final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
					final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
					if (lastNode2.length == 0) {
						if (lastNode3.length == 1) {
							if (lastNode4.length == 1) {
								if (lastNode5.length == 1) {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] node5 = node6[0];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										final «type.javaName»[][][][] node4 = node5[node5.length - 1];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[node5.length - 1] = newNode4;
										final «type.javaName»[][][] node3 = node4[node4.length - 1];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[node4.length - 1] = newNode3;
										final «type.javaName»[][] node2 = node3[node3.length - 1];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
										newNode3[node3.length - 1] = newNode2;
										return new «diamondName(5)»(newNode5, init, node2[node2.length - 1], startIndex, size - 1);
									} else {
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length - 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, node6.length - 2);
										final «type.javaName»[][][][][] node5 = node6[node6.length - 2];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode6[node6.length - 2] = newNode5;
										final «type.javaName»[][][][] node4 = node5[node5.length - 1];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[node5.length - 1] = newNode4;
										final «type.javaName»[][][] node3 = node4[node4.length - 1];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[node4.length - 1] = newNode3;
										final «type.javaName»[][] node2 = node3[node3.length - 1];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
										newNode3[node3.length - 1] = newNode2;
										return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
									}
								} else {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] firstNode5 = node6[0];
										if (firstNode5.length + lastNode5.length == 33) {
											final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
											System.arraycopy(firstNode5, 0, newNode5, 0, firstNode5.length);
											System.arraycopy(lastNode5, 0, newNode5, firstNode5.length, lastNode5.length - 2);
											final «type.javaName»[][][][] node4 = lastNode5[lastNode5.length - 2];
											final «type.javaName»[][][][] newNode4 = node4.clone();
											newNode5[31] = newNode4;
											final «type.javaName»[][][] node3 = node4[31];
											final «type.javaName»[][][] newNode3 = node3.clone();
											newNode4[31] = newNode3;
											final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
											final «type.javaName»[][] node2 = node3[31];
											System.arraycopy(node2, 0, newNode2, 0, 31);
											newNode3[31] = newNode2;
											final int newStartIndex = calculateSeq5StartIndex(newNode5, init);
											return new «diamondName(5)»(newNode5, init, node2[31], newStartIndex, size - 1);
										}
									}

									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[lastNode5.length - 1][][][][];
									System.arraycopy(lastNode5, 0, newNode5, 0, lastNode5.length - 2);
									newNode6[node6.length - 1] = newNode5;
									final «type.javaName»[][][][] node4 = lastNode5[lastNode5.length - 2];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode5[lastNode5.length - 2] = newNode4;
									final «type.javaName»[][][] node3 = node4[node4.length - 1];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][] node2 = node3[node3.length - 1];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
									newNode3[node3.length - 1] = newNode2;
									return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
								}
							} else {
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								final «type.javaName»[][][][][] newNode5 = lastNode5.clone();
								newNode6[node6.length - 1] = newNode5;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[lastNode4.length - 1][][][];
								System.arraycopy(lastNode4, 0, newNode4, 0, lastNode4.length - 2);
								newNode5[lastNode5.length - 1] = newNode4;
								final «type.javaName»[][][] node3 = lastNode4[lastNode4.length - 2];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[lastNode4.length - 2] = newNode3;
								final «type.javaName»[][] node2 = node3[node3.length - 1];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
								newNode3[node3.length - 1] = newNode2;
								return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
							}
						} else {
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							final «type.javaName»[][][][][] newNode5 = lastNode5.clone();
							newNode6[node6.length - 1] = newNode5;
							final «type.javaName»[][][][] newNode4 = lastNode4.clone();
							newNode5[lastNode5.length - 1] = newNode4;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[lastNode3.length - 1][][];
							System.arraycopy(lastNode3, 0, newNode3, 0, lastNode3.length - 2);
							newNode4[lastNode4.length - 1] = newNode3;
							final «type.javaName»[][] node2 = lastNode3[lastNode3.length - 2];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 0, newNode2, 0, node2.length - 1);
							newNode3[lastNode3.length - 2] = newNode2;
							return new «diamondName(6)»(newNode6, init, node2[node2.length - 1], startIndex, size - 1);
						}
					} else {
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						final «type.javaName»[][][][][] newNode5 = lastNode5.clone();
						newNode6[node6.length - 1] = newNode5;
						final «type.javaName»[][][][] newNode4 = lastNode4.clone();
						newNode5[lastNode5.length - 1] = newNode4;
						final «type.javaName»[][][] newNode3 = lastNode3.clone();
						newNode4[lastNode4.length - 1] = newNode3;
						final «type.javaName»[][] newNode2;
						if (lastNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[lastNode2.length - 1][];
							System.arraycopy(lastNode2, 0, newNode2, 0, lastNode2.length - 1);
						}
						newNode3[lastNode3.length - 1] = newNode2;
						return new «diamondName(6)»(newNode6, init, lastNode2[lastNode2.length - 1], startIndex, size - 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length - 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length - 1);
					return new «diamondName(6)»(node6, init, newTail, startIndex, size - 1);
				}
			}

			@Override
			public «genericName» tail() {
				if (init.length == 1) {
					final «type.javaName»[][][][][] firstNode5 = node6[0];
					final «type.javaName»[][][][] firstNode4 = firstNode5[0];
					final «type.javaName»[][][] firstNode3 = firstNode4[0];
					final «type.javaName»[][] firstNode2 = firstNode3[0];
					if (firstNode2.length == 0) {
						if (firstNode3.length == 1) {
							if (firstNode4.length == 1) {
								if (firstNode5.length == 1) {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] node5 = node6[1];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										final «type.javaName»[][][][] node4 = node5[0];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[0] = newNode4;
										final «type.javaName»[][][] node3 = node4[0];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][] node2 = node3[0];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
										newNode3[0] = newNode2;
										return new «diamondName(5)»(newNode5, node2[0], tail, 0, size - 1);
									} else {
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length - 1][][][][][];
										System.arraycopy(node6, 2, newNode6, 1, node6.length - 2);
										final «type.javaName»[][][][][] node5 = node6[1];
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode6[0] = newNode5;
										final «type.javaName»[][][][] node4 = node5[0];
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode5[0] = newNode4;
										final «type.javaName»[][][] node3 = node4[0];
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][] node2 = node3[0];
										final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
										System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
										newNode3[0] = newNode2;
										return new «diamondName(6)»(newNode6, node2[0], tail, 0, size - 1);
									}
								} else {
									if (node6.length == 2) {
										final «type.javaName»[][][][][] lastNode5 = node6[1];
										if (firstNode5.length + lastNode5.length == 33) {
											final «type.javaName»[][][][][] newNode5 = new «type.javaName»[32][][][][];
											System.arraycopy(firstNode5, 2, newNode5, 1, firstNode5.length - 2);
											System.arraycopy(lastNode5, 0, newNode5, firstNode5.length - 1, lastNode5.length);
											final «type.javaName»[][][][] node4 = firstNode5[1];
											final «type.javaName»[][][][] newNode4 = node4.clone();
											newNode5[0] = newNode4;
											final «type.javaName»[][][] node3 = node4[0];
											final «type.javaName»[][][] newNode3 = node3.clone();
											newNode4[0] = newNode3;
											final «type.javaName»[][] newNode2 = new «type.javaName»[31][];
											final «type.javaName»[][] node2 = node3[0];
											System.arraycopy(node2, 1, newNode2, 0, 31);
											newNode3[0] = newNode2;
											final int newStartIndex = calculateSeq5StartIndex(newNode5, node2[0]);
											return new «diamondName(5)»(newNode5, node2[0], tail, newStartIndex, size - 1);
										}
									}

									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[firstNode5.length - 1][][][][];
									System.arraycopy(firstNode5, 2, newNode5, 1, firstNode5.length - 2);
									newNode6[0] = newNode5;
									final «type.javaName»[][][][] node4 = firstNode5[1];
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode5[0] = newNode4;
									final «type.javaName»[][][] node3 = node4[0];
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][] node2 = node3[0];
									final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
									System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
									newNode3[0] = newNode2;
									return new «diamondName(6)»(newNode6, node2[0], tail, startIndex + 1, size - 1);
								}
							} else {
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								final «type.javaName»[][][][][] newNode5 = firstNode5.clone();
								newNode6[0] = newNode5;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[firstNode4.length - 1][][][];
								System.arraycopy(firstNode4, 2, newNode4, 1, firstNode4.length - 2);
								newNode5[0] = newNode4;
								final «type.javaName»[][][] node3 = firstNode4[1];
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode4[0] = newNode3;
								final «type.javaName»[][] node2 = node3[0];
								final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
								System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
								newNode3[0] = newNode2;
								return new «diamondName(6)»(newNode6, node2[0], tail, startIndex + 1, size - 1);
							}
						} else {
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							final «type.javaName»[][][][][] newNode5 = firstNode5.clone();
							newNode6[0] = newNode5;
							final «type.javaName»[][][][] newNode4 = firstNode4.clone();
							newNode5[0] = newNode4;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[firstNode3.length - 1][][];
							System.arraycopy(firstNode3, 2, newNode3, 1, firstNode3.length - 2);
							newNode4[0] = newNode3;
							final «type.javaName»[][] node2 = firstNode3[1];
							final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length - 1][];
							System.arraycopy(node2, 1, newNode2, 0, node2.length - 1);
							newNode3[0] = newNode2;
							return new «diamondName(6)»(newNode6, node2[0], tail, startIndex + 1, size - 1);
						}
					} else {
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						final «type.javaName»[][][][][] newNode5 = firstNode5.clone();
						newNode6[0] = newNode5;
						final «type.javaName»[][][][] newNode4 = firstNode4.clone();
						newNode5[0] = newNode4;
						final «type.javaName»[][][] newNode3 = firstNode3.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][] newNode2;
						if (firstNode2.length == 1) {
							newNode2 = EMPTY_NODE2;
						} else {
							newNode2 = new «type.javaName»[firstNode2.length - 1][];
							System.arraycopy(firstNode2, 1, newNode2, 0, firstNode2.length - 1);
						}
						newNode3[0] = newNode2;
						return new «diamondName(6)»(newNode6, firstNode2[0], tail, startIndex + 1, size - 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length - 1];
					System.arraycopy(init, 1, newInit, 0, init.length - 1);
					return new «diamondName(6)»(node6, newInit, tail, startIndex + 1, size - 1);
				}
			}

			private static int index2(final int idx, final int index3, final int index4, final int index5, final int index6, final «type.javaName»[][] node2) {
				return (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) ? «index»2(idx) + node2.length - 32 : «index»2(idx);
			}

			private static int index3(final int idx, final int index4, final int index5, final int index6, final «type.javaName»[][][] node3) {
				return (index6 == 0 && index5 == 0 && index4 == 0) ? «index»3(idx) + node3.length - 32 : «index»3(idx);
			}

			private static int index4(final int idx, final int index5, final int index6, final «type.javaName»[][][][] node4) {
				return (index6 == 0 && index5 == 0) ? «index»4(idx) + node4.length - 32 : «index»4(idx);
			}

			private static int index5(final int idx, final int index6, final «type.javaName»[][][][][] node5) {
				return (index6 == 0) ? «index»5(idx) + node5.length - 32 : «index»5(idx);
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
						final int index6 = index6(idx);
						final «type.javaName»[][][][][] node5 = node6[index6];
						final int index5 = index5(idx, index6, node5);
						final «type.javaName»[][][][] node4 = node5[index5];
						final int index4 = index4(idx, index5, index6, node4);
						final «type.javaName»[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, index5, index6, node3);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, index5, index6, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);
						return «type.genericCast»node1[index1];
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					«indexOutOfBounds»
				}
			}

			@Override
			public «genericName» update(final int index, final «type.endoGenericName» f) {
				try {
					if (index < init.length) {
						final «type.javaName»[] newInit = updateArray(init, index, f);
						return new «diamondName(6)»(node6, newInit, tail, startIndex, size);
					} else if (index >= size - tail.length) {
						final int tailIndex = index + tail.length - size;
						final «type.javaName»[] newTail = updateArray(tail, tailIndex, f);
						return new «diamondName(6)»(node6, init, newTail, startIndex, size);
					} else {
						final int idx = index + startIndex;
						final int index6 = index6(idx);
						final «type.javaName»[][][][][] node5 = node6[index6];
						final int index5 = index5(idx, index6, node5);
						final «type.javaName»[][][][] node4 = node5[index5];
						final int index4 = index4(idx, index5, index6, node4);
						final «type.javaName»[][][] node3 = node4[index4];
						final int index3 = index3(idx, index4, index5, index6, node3);
						final «type.javaName»[][] node2 = node3[index3];
						final int index2 = index2(idx, index3, index4, index5, index6, node2);
						final «type.javaName»[] node1 = node2[index2];
						final int index1 = index1(idx);

						final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length][][][][][];
						System.arraycopy(node6, 0, newNode6, 0, node6.length);
						final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length][][][][];
						System.arraycopy(node5, 0, newNode5, 0, node5.length);
						final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length][][][];
						System.arraycopy(node4, 0, newNode4, 0, node4.length);
						final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length][][];
						System.arraycopy(node3, 0, newNode3, 0, node3.length);
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						final «type.javaName»[] newNode1 = updateArray(node1, index1, f);
						newNode6[index6] = newNode5;
						newNode5[index5] = newNode4;
						newNode4[index4] = newNode3;
						newNode3[index3] = newNode2;
						newNode2[index2] = newNode1;
						return new «diamondName(6)»(newNode6, init, tail, startIndex, size);
					}
				} catch (final ArrayIndexOutOfBoundsException __) {
					«indexOutOfBounds»
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
					return new «diamondName(6)»(node6, init, newTail, startIndex, n);
				} else {
					final int idx = n + startIndex - 1;
					final int index6 = index6(idx);
					final «type.javaName»[][][][][] node5 = node6[index6];
					final int index5 = index5(idx, index6, node5);
					final «type.javaName»[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, index6, node4);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, index6, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, index6, node2);
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
							if (index6 == 0 && index5 == 0 && index4 == 0 && index3 == 0) {
								if (index2 == 0) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[index2][];
									System.arraycopy(node2, 0, newNode2, 0, index2);
								}
							} else {
								final «type.javaName»[][] firstNode2 = node6[0][0][0][0];
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

							if (n <= (1 << 15) - calculateSeq3StartIndex(node6[0][0][0], init)) {
								final «type.javaName»[][][] newNode3;
								if (index6 == 0 && index5 == 0 && index4 == 0) {
									newNode3 = new «type.javaName»[index3 + 1][][];
									System.arraycopy(node3, 0, newNode3, 0, index3);
									newNode3[index3] = newNode2;
								} else {
									final «type.javaName»[][][] firstNode3 = node6[0][0][0];
									newNode3 = new «type.javaName»[firstNode3.length + index3 + 1][][];
									System.arraycopy(firstNode3, 0, newNode3, 0, firstNode3.length);
									System.arraycopy(node3, 0, newNode3, firstNode3.length, index3);
									newNode3[firstNode3.length + index3] = newNode2;
								}
								final int newStartIndex = calculateSeq3StartIndex(newNode3, init);
								return new «diamondName(3)»(newNode3, init, newTail, newStartIndex, n);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[index3 + 1][][];
								System.arraycopy(node3, 0, newNode3, 0, index3);
								newNode3[index3] = newNode2;

								if (n <= (1 << 20) - calculateSeq4StartIndex(node6[0][0], init)) {
									final «type.javaName»[][][][] newNode4;
									if (index6 == 0 && index5 == 0) {
										newNode4 = new «type.javaName»[index4 + 1][][][];
										System.arraycopy(node4, 0, newNode4, 0, index4);
										newNode4[index4] = newNode3;
									} else {
										final «type.javaName»[][][][] firstNode4 = node6[0][0];
										newNode4 = new «type.javaName»[firstNode4.length + index4 + 1][][][];
										System.arraycopy(firstNode4, 0, newNode4, 0, firstNode4.length);
										System.arraycopy(node4, 0, newNode4, firstNode4.length, index4);
										newNode4[firstNode4.length + index4] = newNode3;
									}
									final int newStartIndex = calculateSeq4StartIndex(newNode4, init);
									return new «diamondName(4)»(newNode4, init, newTail, newStartIndex, n);
								} else {
									final «type.javaName»[][][][] newNode4 = new «type.javaName»[index4 + 1][][][];
									System.arraycopy(node4, 0, newNode4, 0, index4);
									newNode4[index4] = newNode3;

									if (n <= (1 << 25) - calculateSeq5StartIndex(node6[0], init)) {
										final «type.javaName»[][][][][] newNode5;
										if (index6 == 0) {
											newNode5 = new «type.javaName»[index5 + 1][][][][];
											System.arraycopy(node5, 0, newNode5, 0, index5);
											newNode5[index5] = newNode4;
										} else {
											final «type.javaName»[][][][][] firstNode5 = node6[0];
											newNode5 = new «type.javaName»[firstNode5.length + index5 + 1][][][][];
											System.arraycopy(firstNode5, 0, newNode5, 0, firstNode5.length);
											System.arraycopy(node5, 0, newNode5, firstNode5.length, index5);
											newNode5[firstNode5.length + index5] = newNode4;
										}
										final int newStartIndex = calculateSeq5StartIndex(newNode5, init);
										return new «diamondName(5)»(newNode5, init, newTail, newStartIndex, n);
									} else {
										final «type.javaName»[][][][][] newNode5 = new «type.javaName»[index5 + 1][][][][];
										System.arraycopy(node5, 0, newNode5, 0, index5);
										newNode5[index5] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[index6 + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, index6);
										newNode6[index6] = newNode5;
										return new «diamondName(6)»(newNode6, init, newTail, startIndex, n);
									}
								}
							}
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
					return new «diamondName(6)»(node6, newInit, tail, startIndex + n, size - n);
				} else {
					final int idx = n + startIndex;
					final int index6 = index6(idx);
					final «type.javaName»[][][][][] node5 = node6[index6];
					final int index5 = index5(idx, index6, node5);
					final «type.javaName»[][][][] node4 = node5[index5];
					final int index4 = index4(idx, index5, index6, node4);
					final «type.javaName»[][][] node3 = node4[index4];
					final int index3 = index3(idx, index4, index5, index6, node3);
					final «type.javaName»[][] node2 = node3[index3];
					final int index2 = index2(idx, index3, index4, index5, index6, node2);
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
							if (index6 == node6.length - 1 && index5 == node5.length - 1 && index4 == node4.length - 1 && index3 == node3.length - 1) {
								if (index2 == node2.length - 1) {
									newNode2 = EMPTY_NODE2;
								} else {
									newNode2 = new «type.javaName»[node2.length - index2 - 1][];
									System.arraycopy(node2, index2 + 1, newNode2, 0, newNode2.length);
								}
							} else {
								final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
								final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
								final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
								final «type.javaName»[][] lastNode2 = lastNode3[lastNode3.length - 1];
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

							final «type.javaName»[][][][][] lastNode5 = node6[node6.length - 1];
							final «type.javaName»[][][][] lastNode4 = lastNode5[lastNode5.length - 1];
							final «type.javaName»[][][] lastNode3 = lastNode4[lastNode4.length - 1];
							if (newSize <= (1 << 15) - calculateSeq3EndIndex(lastNode3, tail)) {
								final «type.javaName»[][][] newNode3;
								if (index6 == node6.length - 1 && index5 == node5.length - 1 && index4 == node4.length - 1) {
									newNode3 = new «type.javaName»[node3.length - index3][][];
									System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								} else {
									newNode3 = new «type.javaName»[node3.length - index3 + lastNode3.length][][];
									System.arraycopy(node3, index3, newNode3, 0, node3.length - index3);
									System.arraycopy(lastNode3, 0, newNode3, node3.length - index3, lastNode3.length);
								}
								newNode3[0] = newNode2;
								final int newStartIndex = calculateSeq3StartIndex(newNode3, newInit);
								return new «diamondName(3)»(newNode3, newInit, tail, newStartIndex, newSize);
							} else {
								final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length - index3][][];
								System.arraycopy(node3, index3, newNode3, 0, newNode3.length);
								newNode3[0] = newNode2;

								if (newSize <= (1 << 20) - calculateSeq4EndIndex(lastNode3, tail)) {
									final «type.javaName»[][][][] newNode4;
									if (index6 == node6.length - 1 && index5 == node5.length - 1) {
										newNode4 = new «type.javaName»[node4.length - index4][][][];
										System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
									} else {
										newNode4 = new «type.javaName»[node4.length - index4 + lastNode4.length][][][];
										System.arraycopy(node4, index4, newNode4, 0, node4.length - index4);
										System.arraycopy(lastNode4, 0, newNode4, node4.length - index4, lastNode4.length);
									}
									newNode4[0] = newNode3;
									final int newStartIndex = calculateSeq4StartIndex(newNode4, newInit);
									return new «diamondName(4)»(newNode4, newInit, tail, newStartIndex, newSize);
								} else {
									final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length - index4][][][];
									System.arraycopy(node4, index4, newNode4, 0, newNode4.length);
									newNode4[0] = newNode3;

									if (newSize <= (1 << 25) - calculateSeq5EndIndex(lastNode4, lastNode3, tail)) {
										final «type.javaName»[][][][][] newNode5;
										if (index6 == node6.length - 1) {
											newNode5 = new «type.javaName»[node5.length - index5][][][][];
											System.arraycopy(node5, index5, newNode5, 0, newNode5.length);
										} else {
											newNode5 = new «type.javaName»[node5.length - index5 + lastNode5.length][][][][];
											System.arraycopy(node5, index5, newNode5, 0, node5.length - index5);
											System.arraycopy(lastNode5, 0, newNode5, node5.length - index5, lastNode5.length);
										}
										newNode5[0] = newNode4;
										final int newStartIndex = calculateSeq5StartIndex(newNode5, newInit);
										return new «diamondName(5)»(newNode5, newInit, tail, newStartIndex, newSize);
									} else {
										final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length - index5][][][][];
										System.arraycopy(node5, index5, newNode5, 0, newNode5.length);
										newNode5[0] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length - index6][][][][][];
										System.arraycopy(node6, index6, newNode6, 0, newNode6.length);
										newNode6[0] = newNode5;
										final int newStartIndex = calculateSeq6StartIndex(newNode6, newInit);
										return new «diamondName(6)»(newNode6, newInit, tail, newStartIndex, newSize);
									}
								}
							}
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
					final «type.javaName»[][][][][] node5 = node6[0];
					final «type.javaName»[][][][] node4 = node5[0];
					final «type.javaName»[][][] node3 = node4[0];
					final «type.javaName»[][] node2 = node3[0];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									if (node6.length == 32) {
										throw new SizeOverflowException();
									} else {
										final «type.javaName»[] newInit = { value };
										final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
										System.arraycopy(node2, 0, newNode2, 1, 31);
										newNode2[0] = init;
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode3[0] = newNode2;
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode4[0] = newNode3;
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode5[0] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length + 1][][][][][];
										System.arraycopy(node6, 1, newNode6, 2, node6.length - 1);
										newNode6[0] = new «type.javaName»[][][][][] { { { EMPTY_NODE2 } } };
										newNode6[1] = newNode5;
										if (startIndex != 0) {
											throw new IllegalStateException("startIndex != 0");
										}
										return new «diamondName(6)»(newNode6, newInit, tail, (1 << 25) - 1, size + 1);
									}
								} else {
									final «type.javaName»[] newInit = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 1, 31);
									newNode2[0] = init;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[0] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[0] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length + 1][][][][];
									System.arraycopy(node5, 1, newNode5, 2, node5.length - 1);
									newNode5[0] = new «type.javaName»[][][][] { { EMPTY_NODE2 } };
									newNode5[1] = newNode4;
									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									newNode6[0] = newNode5;
									return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
								}
							} else {
								final «type.javaName»[] newInit = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 1, 31);
								newNode2[0] = init;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[0] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 1, newNode4, 2, node4.length - 1);
								newNode4[0] = new «type.javaName»[][][] { EMPTY_NODE2 };
								newNode4[1] = newNode3;
								final «type.javaName»[][][][][] newNode5 = node5.clone();
								newNode5[0] = newNode4;
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								newNode6[0] = newNode5;
								return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
							}
						} else {
							final «type.javaName»[] newInit = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 1, 31);
							newNode2[0] = init;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 1, newNode3, 2, node3.length - 1);
							newNode3[0] = EMPTY_NODE2;
							newNode3[1] = newNode2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[0] = newNode3;
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							newNode5[0] = newNode4;
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							newNode6[0] = newNode5;
							return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
						}
					} else {
						final «type.javaName»[] newInit = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 1, node2.length);
						newNode2[0] = init;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[0] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[0] = newNode3;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						newNode5[0] = newNode4;
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						newNode6[0] = newNode5;
						return new «diamondName(6)»(newNode6, newInit, tail, startIndex - 1, size + 1);
					}
				} else {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + 1];
					System.arraycopy(init, 0, newInit, 1, init.length);
					newInit[0] = value;
					return new «diamondName(6)»(node6, newInit, tail, startIndex - 1, size + 1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (tail.length == 32) {
					final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
					final «type.javaName»[][][][] node4 = node5[node5.length - 1];
					final «type.javaName»[][][] node3 = node4[node4.length - 1];
					final «type.javaName»[][] node2 = node3[node3.length - 1];
					if (node2.length == 31) {
						if (node3.length == 32) {
							if (node4.length == 32) {
								if (node5.length == 32) {
									if (node6.length == 32) {
										throw new SizeOverflowException();
									} else {
										final «type.javaName»[] newTail = { value };
										final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
										System.arraycopy(node2, 0, newNode2, 0, 31);
										newNode2[31] = tail;
										final «type.javaName»[][][] newNode3 = node3.clone();
										newNode3[node3.length - 1] = newNode2;
										final «type.javaName»[][][][] newNode4 = node4.clone();
										newNode4[node4.length - 1] = newNode3;
										final «type.javaName»[][][][][] newNode5 = node5.clone();
										newNode5[node5.length - 1] = newNode4;
										final «type.javaName»[][][][][][] newNode6 = new «type.javaName»[node6.length + 1][][][][][];
										System.arraycopy(node6, 0, newNode6, 0, node6.length - 1);
										newNode6[node6.length - 1] = newNode5;
										newNode6[node6.length] = new «type.javaName»[][][][][] { { { EMPTY_NODE2 } } };
										return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
									}
								} else {
									final «type.javaName»[] newTail = { value };
									final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
									System.arraycopy(node2, 0, newNode2, 0, 31);
									newNode2[31] = tail;
									final «type.javaName»[][][] newNode3 = node3.clone();
									newNode3[node3.length - 1] = newNode2;
									final «type.javaName»[][][][] newNode4 = node4.clone();
									newNode4[node4.length - 1] = newNode3;
									final «type.javaName»[][][][][] newNode5 = new «type.javaName»[node5.length + 1][][][][];
									System.arraycopy(node5, 0, newNode5, 0, node5.length - 1);
									newNode5[node5.length - 1] = newNode4;
									newNode5[node5.length] = new «type.javaName»[][][][] { { EMPTY_NODE2 } };
									final «type.javaName»[][][][][][] newNode6 = node6.clone();
									newNode6[newNode6.length - 1] = newNode5;
									return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
								}
							} else {
								final «type.javaName»[] newTail = { value };
								final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
								System.arraycopy(node2, 0, newNode2, 0, 31);
								newNode2[31] = tail;
								final «type.javaName»[][][] newNode3 = node3.clone();
								newNode3[node3.length - 1] = newNode2;
								final «type.javaName»[][][][] newNode4 = new «type.javaName»[node4.length + 1][][][];
								System.arraycopy(node4, 0, newNode4, 0, node4.length - 1);
								newNode4[node4.length - 1] = newNode3;
								newNode4[node4.length] = new «type.javaName»[][][] { EMPTY_NODE2 };
								final «type.javaName»[][][][][] newNode5 = node5.clone();
								newNode5[newNode5.length - 1] = newNode4;
								final «type.javaName»[][][][][][] newNode6 = node6.clone();
								newNode6[newNode6.length - 1] = newNode5;
								return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
							}
						} else {
							final «type.javaName»[] newTail = { value };
							final «type.javaName»[][] newNode2 = new «type.javaName»[32][];
							System.arraycopy(node2, 0, newNode2, 0, 31);
							newNode2[31] = tail;
							final «type.javaName»[][][] newNode3 = new «type.javaName»[node3.length + 1][][];
							System.arraycopy(node3, 0, newNode3, 0, node3.length - 1);
							newNode3[node3.length - 1] = newNode2;
							newNode3[node3.length] = EMPTY_NODE2;
							final «type.javaName»[][][][] newNode4 = node4.clone();
							newNode4[newNode4.length - 1] = newNode3;
							final «type.javaName»[][][][][] newNode5 = node5.clone();
							newNode5[newNode5.length - 1] = newNode4;
							final «type.javaName»[][][][][][] newNode6 = node6.clone();
							newNode6[newNode6.length - 1] = newNode5;
							return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
						}
					} else {
						final «type.javaName»[] newTail = { value };
						final «type.javaName»[][] newNode2 = new «type.javaName»[node2.length + 1][];
						System.arraycopy(node2, 0, newNode2, 0, node2.length);
						newNode2[node2.length] = tail;
						final «type.javaName»[][][] newNode3 = node3.clone();
						newNode3[newNode3.length - 1] = newNode2;
						final «type.javaName»[][][][] newNode4 = node4.clone();
						newNode4[newNode4.length - 1] = newNode3;
						final «type.javaName»[][][][][] newNode5 = node5.clone();
						newNode5[newNode5.length - 1] = newNode4;
						final «type.javaName»[][][][][][] newNode6 = node6.clone();
						newNode6[newNode6.length - 1] = newNode5;
						return new «diamondName(6)»(newNode6, init, newTail, startIndex, size + 1);
					}
				} else {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + 1];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					newTail[tail.length] = value;
					return new «diamondName(6)»(node6, init, newTail, startIndex, size + 1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				if (tail.length + suffixSize < 0) {
					// Overflow
					throw new SizeOverflowException();
				} else if (tail.length + suffixSize <= 32) {
					final «type.javaName»[] newTail = new «type.javaName»[tail.length + suffixSize];
					System.arraycopy(tail, 0, newTail, 0, tail.length);
					fillArray(newTail, tail.length, suffix);
					return new «diamondName(6)»(node6, init, newTail, startIndex, size + suffixSize);
				}

				final int maxSize = size - init.length - 32*node6[0][0][0][0].length - (1 << 10)*(node6[0][0][0].length - 1)
						- (1 << 15)*(node6[0][0].length - 1) - (1 << 20)*(node6[0].length - 1) + (1 << 25) + suffixSize;
				if (maxSize >= 0 && maxSize <= (1 << 30)) {
					return appendSizedToSeq6(suffix, suffixSize, maxSize);
				} else {
					throw new SizeOverflowException();
				}
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(node6.length, maxSize);
				System.arraycopy(node6, 0, newNode6, 0, node6.length - 1);

				final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				final «type.javaName»[][][][][] newNode5;
				final «type.javaName»[][][][] newNode4;
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node6.length < newNode6.length) {
					newNode5 = new «type.javaName»[32][][][][];
					newNode4 = new «type.javaName»[32][][][];
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = node3.length; index3 < 32; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
					for (int index4 = node4.length; index4 < 32; index4++) {
						newNode4[index4] = new «type.javaName»[32][32][32];
					}
					for (int index5 = node5.length; index5 < 32; index5++) {
						newNode5[index5] = new «type.javaName»[32][32][32][32];
					}
				} else {
					final int totalSize5 = (maxSize % (1 << 25) == 0) ? (1 << 25) : maxSize % (1 << 25);
					newNode5 = allocateNode5(node5.length, totalSize5);
					if (node5.length < newNode5.length) {
						newNode4 = new «type.javaName»[32][][][];
						newNode3 = new «type.javaName»[32][][];
						newNode2 = new «type.javaName»[32][];
						for (int index4 = node4.length; index4 < 32; index4++) {
							newNode4[index4] = new «type.javaName»[32][32][32];
						}
						for (int index3 = node3.length; index3 < 32; index3++) {
							newNode3[index3] = new «type.javaName»[32][32];
						}
					} else {
						final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
						newNode4 = allocateNode4(node4.length, totalSize4);
						if (node4.length < newNode4.length) {
							newNode3 = new «type.javaName»[32][][];
							newNode2 = new «type.javaName»[32][];
							for (int index3 = node3.length; index3 < 32; index3++) {
								newNode3[index3] = new «type.javaName»[32][32];
							}
						} else {
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							newNode3 = allocateNode3(node3.length, totalSize3);
							if (node3.length < newNode3.length) {
								newNode2 = new «type.javaName»[32][];
							} else {
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
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
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = node2.length; index2 < newNode2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
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
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				if (init.length + prefixSize < 0) {
					// Overflow
					throw new SizeOverflowException();
				} else if (init.length + prefixSize <= 32) {
					final «type.javaName»[] newInit = new «type.javaName»[init.length + prefixSize];
					System.arraycopy(init, 0, newInit, prefixSize, init.length);
					fillArrayFromStart(newInit, prefixSize, prefix);
					return new «diamondName(6)»(node6, newInit, tail, startIndex - prefixSize, size + prefixSize);
				}

				final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];

				final int maxSize = size - tail.length - 32*node3[node3.length - 1].length - (1 << 10)*(node3.length - 1)
						- (1 << 15)*(node4.length - 1) - (1 << 20)*(node5.length - 1) + (1 << 25) + prefixSize;
				if (maxSize >= 0 && maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, maxSize);
				} else {
					throw new SizeOverflowException();
				}
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(maxSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(node6.length, maxSize);
				System.arraycopy(node6, 1, newNode6, newNode6.length - node6.length + 1, node6.length - 1);

				final «type.javaName»[][][][][] node5 = node6[0];
				final «type.javaName»[][][][] node4 = node5[0];
				final «type.javaName»[][][] node3 = node4[0];
				final «type.javaName»[][] node2 = node3[0];
				final «type.javaName»[][][][][] newNode5;
				final «type.javaName»[][][][] newNode4;
				final «type.javaName»[][][] newNode3;
				final «type.javaName»[][] newNode2;
				if (node6.length < newNode6.length) {
					newNode5 = new «type.javaName»[32][][][][];
					newNode4 = new «type.javaName»[32][][][];
					newNode3 = new «type.javaName»[32][][];
					newNode2 = new «type.javaName»[32][];
					for (int index3 = 0; index3 < 32 - node3.length; index3++) {
						newNode3[index3] = new «type.javaName»[32][32];
					}
					for (int index4 = 0; index4 < 32 - node4.length; index4++) {
						newNode4[index4] = new «type.javaName»[32][32][32];
					}
					for (int index5 = 0; index5 < 32 - node5.length; index5++) {
						newNode5[index5] = new «type.javaName»[32][32][32][32];
					}
				} else {
					final int totalSize5 = (maxSize % (1 << 25) == 0) ? (1 << 25) : maxSize % (1 << 25);
					newNode5 = allocateNode5FromStart(node5.length, totalSize5);
					if (node5.length < newNode5.length) {
						newNode4 = new «type.javaName»[32][][][];
						newNode3 = new «type.javaName»[32][][];
						newNode2 = new «type.javaName»[32][];
						for (int index4 = 0; index4 < 32 - node4.length; index4++) {
							newNode4[index4] = new «type.javaName»[32][32][32];
						}
						for (int index3 = 0; index3 < 32 - node3.length; index3++) {
							newNode3[index3] = new «type.javaName»[32][32];
						}
					} else {
						final int totalSize4 = (totalSize5 % (1 << 20) == 0) ? (1 << 20) : totalSize5 % (1 << 20);
						newNode4 = allocateNode4FromStart(node4.length, totalSize4);
						if (node4.length < newNode4.length) {
							newNode3 = new «type.javaName»[32][][];
							newNode2 = new «type.javaName»[32][];
							for (int index3 = 0; index3 < 32 - node3.length; index3++) {
								newNode3[index3] = new «type.javaName»[32][32];
							}
						} else {
							final int totalSize3 = (totalSize4 % (1 << 15) == 0) ? (1 << 15) : totalSize4 % (1 << 15);
							newNode3 = allocateNode3FromStart(node3.length, totalSize3);
							if (node3.length < newNode3.length) {
								newNode2 = new «type.javaName»[32][];
							} else {
								final int totalSize2 = (totalSize3 % (1 << 10) == 0) ? (1 << 10) : totalSize3 % (1 << 10);
								newNode2 = new «type.javaName»[(totalSize2 % 32 == 0) ? totalSize2 / 32 - 1 : totalSize2 / 32][];
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
						newNode2[index2] = new «type.javaName»[32];
					}
				} else {
					for (int index2 = 0; index2 < newNode2.length - node2.length; index2++) {
						newNode2[index2] = new «type.javaName»[32];
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
			void initSeqBuilder(final «seqBuilderName» builder) {
				builder.init = init;
				if (tail.length == 32) {
					builder.node1 = tail;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(tail, 0, builder.node1, 0, tail.length);
				}
				final «type.javaName»[][][][][] node5 = node6[node6.length - 1];
				final «type.javaName»[][][][] node4 = node5[node5.length - 1];
				final «type.javaName»[][][] node3 = node4[node4.length - 1];
				final «type.javaName»[][] node2 = node3[node3.length - 1];
				builder.node2 = new «type.javaName»[32][];
				System.arraycopy(node2, 0, builder.node2, 0, node2.length);
				builder.node2[node2.length] = builder.node1;
				builder.node3 = new «type.javaName»[32][][];
				System.arraycopy(node3, 0, builder.node3, 0, node3.length - 1);
				builder.node3[node3.length - 1] = builder.node2;
				builder.node4 = new «type.javaName»[32][][][];
				System.arraycopy(node4, 0, builder.node4, 0, node4.length - 1);
				builder.node4[node4.length - 1] = builder.node3;
				builder.node5 = new «type.javaName»[32][][][][];
				System.arraycopy(node5, 0, builder.node5, 0, node5.length - 1);
				builder.node5[node5.length - 1] = builder.node4;
				builder.node6 = new «type.javaName»[32][][][][][];
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
			«IF type == Type.OBJECT»
				void copyToArray(final Object[] array) {
			«ELSE»
				public «type.javaName»[] «type.toArrayName»() {
					final «type.javaName»[] array = new «type.javaName»[size];
			«ENDIF»
				System.arraycopy(init, 0, array, 0, init.length);
				int index = init.length;
				for (final «type.javaName»[][][][][] node5 : node6) {
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									System.arraycopy(node1, 0, array, index, 32);
									index += 32;
								}
							}
						}
					}
				}
				System.arraycopy(tail, 0, array, index, tail.length);
				«IF type != Type.OBJECT»
					return array;
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return new «iteratorDiamondName(6)»(node6, init, tail);
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return new «reverseIteratorDiamondName(6)»(node6, init, tail);
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				for (final «type.javaName» value : init) {
					eff.apply(«type.genericCast»value);
				}
				for (final «type.javaName»[][][][][] node5 : node6) {
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									for (final «type.javaName» value : node1) {
										eff.apply(«type.genericCast»value);
									}
								}
							}
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
				for (final «type.javaName»[][][][][] node5 : node6) {
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									for (final «type.javaName» value : node1) {
										eff.apply(i++, «type.genericCast»value);
									}
								}
							}
						}
					}
				}
				for (final «type.javaName» value : tail) {
					eff.apply(i++, «type.genericCast»value);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				for (final «type.javaName» value : init) {
					if (!eff.apply(«type.genericCast»value)) {
						return false;
					}
				}
				for (final «type.javaName»[][][][][] node5 : node6) {
					for (final «type.javaName»[][][][] node4 : node5) {
						for (final «type.javaName»[][][] node3 : node4) {
							for (final «type.javaName»[][] node2 : node3) {
								for (final «type.javaName»[] node1 : node2) {
									for (final «type.javaName» value : node1) {
										if (!eff.apply(«type.genericCast»value)) {
											return false;
										}
									}
								}
							}
						}
					}
				}
				for (final «type.javaName» value : tail) {
					if (!eff.apply(«type.genericCast»value)) {
						return false;
					}
				}
				return true;
			}
		}

		final class «iteratorName(6)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][][][][] node6;
			private final «type.javaName»[] tail;

			private int index6;
			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][][][][] node5;
			private «type.javaName»[][][][] node4;
			private «type.javaName»[][][] node3;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»6Iterator(final «type.javaName»[][][][][][] node6, final «type.javaName»[] init, final «type.javaName»[] tail) {
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
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (index1 < node1.length) {
					return «type.genericCast»node1[index1++];
				} else if (node2 != null && index2 < node2.length) {
					node1 = node2[index2++];
					index1 = 1;
					return «type.genericCast»node1[0];
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
					return «type.genericCast»node1[0];
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
					return «type.genericCast»node1[0];
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
					return «type.genericCast»node1[0];
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
					return «type.genericCast»node1[0];
				} else if (index6 == node6.length) {
					node5 = null;
					node4 = null;
					node3 = null;
					node2 = null;
					node1 = tail;
					index6++;
					index1 = 1;
					return «type.genericCast»node1[0];
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class «reverseIteratorName(6)» implements «type.iteratorGenericName» {
			private final «type.javaName»[][][][][][] node6;
			private final «type.javaName»[] init;

			private int index6;
			private int index5;
			private int index4;
			private int index3;
			private int index2;
			private int index1;
			private «type.javaName»[][][][][] node5;
			private «type.javaName»[][][][] node4;
			private «type.javaName»[][][] node3;
			private «type.javaName»[][] node2;
			private «type.javaName»[] node1;

			«shortName»6ReverseIterator(final «type.javaName»[][][][][][] node6, final «type.javaName»[] init, final «type.javaName»[] tail) {
				this.node6 = node6;
				this.init = init;
				node1 = tail;
				index6 = node6.length - 1;
				index1 = node1.length - 1;
			}

			@Override
			public boolean hasNext() {
				return (index1 >= 0 || (node2 != null && index2 >= 0) ||
						(node3 != null && index3 >= 0) || (node4 != null && index4 >= 0) ||
						(node5 != null && index5 >= 0) || index6 >= -1);
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (index1 >= 0) {
					return «type.genericCast»node1[index1--];
				} else if (node2 != null && index2 >= 0) {
					node1 = node2[index2--];
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (node3 != null && index3 >= 0) {
					if (node3[index3].length == 0) {
						node5 = null;
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = init;
						index6 -= 2;
					} else {
						node2 = node3[index3--];
						node1 = node2[node2.length - 1];
						index2 = node2.length - 2;
					}
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (node4 != null && index4 >= 0) {
					final «type.javaName»[][][] nextNode3 = node4[index4];
					final «type.javaName»[][] nextNode2 = nextNode3[nextNode3.length - 1];
					if (nextNode2.length == 0) {
						node5 = null;
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = init;
						index6 -= 2;
					} else {
						node3 = nextNode3;
						node2 = nextNode2;
						node1 = node2[node2.length - 1];
						index4--;
						index3 = node3.length - 2;
						index2 = node2.length - 2;
					}
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (node5 != null && index5 >= 0) {
					final «type.javaName»[][][][] nextNode4 = node5[index5];
					final «type.javaName»[][][] nextNode3 = nextNode4[nextNode4.length - 1];
					final «type.javaName»[][] nextNode2 = nextNode3[nextNode3.length - 1];
					if (nextNode2.length == 0) {
						node5 = null;
						node4 = null;
						node3 = null;
						node2 = null;
						node1 = init;
						index6 -= 2;
					} else {
						node4 = nextNode4;
						node3 = nextNode3;
						node2 = nextNode2;
						node1 = node2[node2.length - 1];
						index5--;
						index4 = node4.length - 2;
						index3 = node3.length - 2;
						index2 = node2.length - 2;
					}
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (index6 >= 0) {
					final «type.javaName»[][][][][] nextNode5 = node6[index6];
					final «type.javaName»[][][][] nextNode4 = nextNode5[nextNode5.length - 1];
					final «type.javaName»[][][] nextNode3 = nextNode4[nextNode4.length - 1];
					final «type.javaName»[][] nextNode2 = nextNode3[nextNode3.length - 1];
					if (nextNode2.length == 0) {
						if (nextNode3.length == 1) {
							if (nextNode4.length == 1) {
								if (nextNode5.length == 1) {
									if (index6 == 0) {
										node5 = null;
										node4 = null;
										node3 = null;
										node2 = null;
										node1 = init;
										index6 -= 2;
									} else {
										index6--;
										node5 = node6[index6--];
										node4 = node5[node5.length - 1];
										node3 = node4[node4.length - 1];
										node2 = node3[node3.length - 1];
										node1 = node2[node2.length - 1];
										index5 = node5.length - 2;
										index4 = node4.length - 2;
										index3 = node3.length - 2;
										index2 = node2.length - 2;
									}
								} else {
									node5 = nextNode5;
									node4 = node5[node5.length - 2];
									node3 = node4[node4.length - 1];
									node2 = node3[node3.length - 1];
									node1 = node2[node2.length - 1];
									index6--;
									index5 = node5.length - 3;
									index4 = node4.length - 2;
									index3 = node3.length - 2;
									index2 = node2.length - 2;
								}
							} else {
								node5 = nextNode5;
								node4 = nextNode4;
								node3 = node4[node4.length - 2];
								node2 = node3[node3.length - 1];
								node1 = node2[node2.length - 1];
								index6--;
								index5 = node5.length - 2;
								index4 = node4.length - 3;
								index3 = node3.length - 2;
								index2 = node2.length - 2;
							}
						} else {
							node5 = nextNode5;
							node4 = nextNode4;
							node3 = nextNode3;
							node2 = node3[node3.length - 2];
							node1 = node2[node2.length - 1];
							index6--;
							index5 = node5.length - 2;
							index4 = node4.length - 2;
							index3 = node3.length - 3;
							index2 = node2.length - 2;
						}
					} else {
						node5 = nextNode5;
						node4 = nextNode4;
						node3 = nextNode3;
						node2 = nextNode2;
						node1 = node2[node2.length - 1];
						index6--;
						index5 = node5.length - 2;
						index4 = node4.length - 2;
						index3 = node3.length - 2;
						index2 = node2.length - 2;
					}
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else if (index6 == -1) {
					node5 = null;
					node4 = null;
					node3 = null;
					node2 = null;
					node1 = init;
					index6--;
					index1 = node1.length - 2;
					return «type.genericCast»node1[node1.length - 1];
				} else {
					throw new NoSuchElementException();
				}
			}
		}
	''' }
}
