package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class Seq1Generator extends SeqGenerator {

	def static List<Generator> generators() {
		Type.values.toList.map[new Seq1Generator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName + "1" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Arrays;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static jcats.collection.Seq.*;
		«ENDIF»
		import static «Constants.COMMON».*;

		final class «genericName(1)» extends «genericName» {
			final «type.javaName»[] node1;

			«shortName»1(final «type.javaName»[] node1) {
				this.node1 = node1;
				«IF ea»
					assert node1.length >= 1 && node1.length <= 32 : "node1.length = " + node1.length;
				«ENDIF»
			}

			@Override
			public int size() {
				return node1.length;
			}

			@Override
			public «genericName» init() {
				if (node1.length == 1) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length - 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length - 1);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» tail() {
				if (node1.length == 1) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length - 1];
					System.arraycopy(node1, 1, newNode1, 0, node1.length - 1);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «type.genericName» get(final int index) {
				try {
					return «type.genericCast»node1[index];
				} catch (final ArrayIndexOutOfBoundsException __) {
					«indexOutOfBounds(shortName)»
				}
			}

			@Override
			public «genericName» update(final int index, final «type.updateFunction» f) {
				return new «diamondName(1)»(«type.updateArray("node1", "index")»);
			}

			@Override
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return empty«shortName»();
				} else if (n >= node1.length) {
					return this;
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[n];
					System.arraycopy(node1, 0, newNode1, 0, n);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n >= node1.length) {
					return empty«shortName»();
				} else if (n == 0) {
					return this;
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length - n];
					System.arraycopy(node1, n, newNode1, 0, newNode1.length);
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (node1.length == 32) {
					final «type.javaName»[] init = { value };
					return new «diamondName(2)»(«shortName»2.EMPTY_NODE2, init, node1, 33);
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 1, node1.length);
					newNode1[0] = value;
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (node1.length == 32) {
					final «type.javaName»[] tail = { value };
					return new «diamondName(2)»(«shortName»2.EMPTY_NODE2, node1, tail, 33);
				} else {
					final «type.javaName»[] newNode1 = new «type.javaName»[node1.length + 1];
					System.arraycopy(node1, 0, newNode1, 0, node1.length);
					newNode1[node1.length] = value;
					return new «diamondName(1)»(newNode1);
				}
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
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

			private «genericName(1)» appendSizedToSeq1(final «type.iteratorGenericName» suffix, final int size) {
				final «type.javaName»[] newNode1 = new «type.javaName»[size];
				System.arraycopy(node1, 0, newNode1, 0, node1.length);
				return fillSeq1(newNode1, node1.length, suffix);
			}

			private «genericName(2)» appendSizedToSeq2(final «type.iteratorGenericName» suffix, final int suffixSize, final int size) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final int size2 = (suffixSize - newTail.length) / 32;
				final «type.javaName»[][] newNode2;
				if (size2 == 0) {
					fillArray(newTail, 0, suffix);
					return new «diamondName(2)»(EMPTY_NODE2, node1, newTail, size);
				} else {
					newNode2 = new «type.javaName»[size2][32];
					return fillSeq2(newNode2, 1, newNode2[0], 0, node1, newTail, size, suffix);
				}
			}

			private «genericName(3)» appendSizedToSeq3(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][] newNode3 = allocateNode3(0, maxSize);
				return fillSeq3(newNode3, 1, newNode3[0], 1, newNode3[0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			private «genericName(4)» appendSizedToSeq4(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4(0, maxSize);
				return fillSeq4(newNode4, 1, newNode4[0], 1, newNode4[0][0], 1, newNode4[0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private «genericName(5)» appendSizedToSeq5(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5(0, maxSize);
				return fillSeq5(newNode5, 1, newNode5[0], 1, newNode5[0][0], 1, newNode5[0][0][0], 1, newNode5[0][0][0][0], 0,
						node1, newTail, 32 - node1.length, size, suffix);
			}

			private «genericName(6)» appendSizedToSeq6(final «type.iteratorGenericName» suffix, final int suffixSize, final int size, final int maxSize) {
				final «type.javaName»[] newTail = allocateTail(suffixSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6(0, maxSize);
				return fillSeq6(newNode6, 1, newNode6[0], 1, newNode6[0][0], 1, newNode6[0][0][0], 1, newNode6[0][0][0][0], 1,
						newNode6[0][0][0][0][0], 0, node1, newTail, 32 - node1.length, size, suffix);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				final int size = prefixSize + node1.length;
				final int maxSize = prefixSize + 32;
				if (maxSize < 0) {
					// Overflow
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				} else if (size <= 32) {
					return prependSizedToSeq1(prefix, size);
				} else if (maxSize <= (1 << 10)) {
					return prependSizedToSeq2(prefix, prefixSize, size);
				} else if (maxSize <= (1 << 15)) {
					return prependSizedToSeq3(prefix, prefixSize, size, maxSize);
				} else if (maxSize <= (1 << 20)) {
					return prependSizedToSeq4(prefix, prefixSize, size, maxSize);
				} else if (maxSize <= (1 << 25)) {
					return prependSizedToSeq5(prefix, prefixSize, size, maxSize);
				} else if (maxSize <= (1 << 30)) {
					return prependSizedToSeq6(prefix, prefixSize, size, maxSize);
				} else {
					throw new IndexOutOfBoundsException("Seq size limit exceeded");
				}
			}

			private «genericName(1)» prependSizedToSeq1(final «type.iteratorGenericName» prefix, final int size) {
				final «type.javaName»[] newNode1 = new «type.javaName»[size];
				System.arraycopy(node1, 0, newNode1, size - node1.length, node1.length);
				return fillSeq1FromStart(newNode1, size - node1.length, prefix);
			}

			private «genericName(2)» prependSizedToSeq2(final «type.iteratorGenericName» prefix, final int prefixSize, final int size) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final int size2 = (prefixSize - newInit.length) / 32;
				final «type.javaName»[][] newNode2;
				if (size2 == 0) {
					fillArray(newInit, 0, prefix);
					return new «diamondName(2)»(EMPTY_NODE2, newInit, node1, size);
				} else {
					newNode2 = new «type.javaName»[size2][32];
					return fillSeq2FromStart(newNode2, 1, newNode2[size2 - 1], 0, newInit, node1, size, prefix);
				}
			}

			private «genericName(3)» prependSizedToSeq3(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][] newNode3 = allocateNode3FromStart(0, maxSize);
				final int startIndex = calculateSeq3StartIndex(newNode3, newInit);
				return fillSeq3FromStart(newNode3, 1, newNode3[newNode3.length - 1], 1, newNode3[newNode3.length - 1][30], 0,
						newInit, node1, startIndex, size, prefix);
			}

			private «genericName(4)» prependSizedToSeq4(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][][] newNode4 = allocateNode4FromStart(0, maxSize);
				final int startIndex = calculateSeq4StartIndex(newNode4, newInit);
				return fillSeq4FromStart(newNode4, 1, newNode4[newNode4.length - 1], 1, newNode4[newNode4.length - 1][31], 1,
						newNode4[newNode4.length - 1][31][30], 0, newInit, node1, startIndex, size, prefix);
			}

			private «genericName(5)» prependSizedToSeq5(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][][][] newNode5 = allocateNode5FromStart(0, maxSize);
				final int startIndex = calculateSeq5StartIndex(newNode5, newInit);
				return fillSeq5FromStart(newNode5, 1, newNode5[newNode5.length - 1], 1, newNode5[newNode5.length - 1][31], 1,
						newNode5[newNode5.length - 1][31][31], 1, newNode5[newNode5.length - 1][31][31][30], 0, newInit, node1,
						startIndex, size, prefix);
			}

			private «genericName(6)» prependSizedToSeq6(final «type.iteratorGenericName» prefix, final int prefixSize, final int size, final int maxSize) {
				final «type.javaName»[] newInit = allocateTail(prefixSize);
				final «type.javaName»[][][][][][] newNode6 = allocateNode6FromStart(0, maxSize);
				final int startIndex = calculateSeq6StartIndex(newNode6, newInit);
				return fillSeq6FromStart(newNode6, 1, newNode6[newNode6.length - 1], 1, newNode6[newNode6.length - 1][31], 1,
						newNode6[newNode6.length - 1][31][31], 1, newNode6[newNode6.length - 1][31][31][31], 1,
						newNode6[newNode6.length - 1][31][31][31][30], 0, newInit, node1, startIndex, size, prefix);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
				if (node1.length == 32) {
					builder.node1 = node1;
				} else {
					builder.node1 = new «type.javaName»[32];
					System.arraycopy(node1, 0, builder.node1, 0, node1.length);
				}
				builder.index1 = node1.length;
				builder.size = node1.length;
			}

			«IF type == Type.OBJECT»
				@Override
				void copyToArray(final Object[] array) {
					System.arraycopy(node1, 0, array, 0, node1.length);
				}

				@Override
				Object[] toSharedObjectArray() {
					return this.node1;
				}
			«ELSE»
				@Override
				public «type.javaName»[] «type.toArrayName»() {
					final «type.javaName»[] array = new «type.javaName»[node1.length];
					System.arraycopy(node1, 0, array, 0, node1.length);
					return array;
				}

				@Override
				«type.javaName»[] toSharedPrimitiveArray() {
					return this.node1;
				}
			«ENDIF»

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type == Type.OBJECT»
					return new ArrayIterator<>(node1);
				«ELSE»
					return new «type.typeName»ArrayIterator(node1);
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				«IF type == Type.OBJECT»
					return new ArrayReverseIterator<>(node1);
				«ELSE»
					return new «type.typeName»ArrayReverseIterator(node1);
				«ENDIF»
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				for (final «type.javaName» value : node1) {
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
				for (final «type.javaName» value : node1) {
					eff.apply(i++, «type.genericCast»value);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				for (final «type.javaName» value : node1) {
					if (!eff.apply(«type.genericCast»value)) {
						return false;
					}
				}
				return true;
			}

			@Override
			public String toString() {
				return Arrays.toString(this.node1);
			}
		}
	''' }
}
