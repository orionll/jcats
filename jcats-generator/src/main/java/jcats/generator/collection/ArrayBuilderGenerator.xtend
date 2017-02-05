package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.List
import jcats.generator.Generator

@FinalFieldsConstructor
final class ArrayBuilderGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ArrayBuilderGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "ArrayBuilder" else type.typeName + "ArrayBuilder" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }
	def arrayGenericName() { if (type == Type.OBJECT) "Array<A>" else type.typeName + "Array" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Arrays;
		import java.util.Collection;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ENDIF»

		import «Constants.SIZED»;

		«IF type != Type.OBJECT»
			import static «Constants.ARRAY»Builder.expandedCapacity;
		«ENDIF»
		import static «Constants.COLLECTION».«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array.empty«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array;

		import static java.util.Objects.requireNonNull;

		public final class «genericName» {
			private «type.javaName»[] array;
			private int size;

			«shortName»(final int initialCapacity) {
				array = new «type.javaName»[initialCapacity];
				size = 0;
			}

			«shortName»() {
				this(10);
			}

			«shortName»(final «type.javaName»[] values) {
				array = values;
				size = values.length;
			}

			«IF type == Type.OBJECT»
				static int expandedCapacity(final int arrayLength, final int minCapacity) {
					// careful of overflow!
					int newCapacity = arrayLength + (arrayLength >> 1) + 1;
					if (newCapacity < minCapacity) {
						newCapacity = Integer.highestOneBit(minCapacity - 1) << 1;
					}
					if (newCapacity < 0) {
						newCapacity = Integer.MAX_VALUE;
						// guaranteed to be >= newCapacity
					}
					return newCapacity;
				}

			«ENDIF»
			private void ensureCapacity(final int minCapacity) {
				if (minCapacity < 0) {
					throw new Error("Cannot store more than " + Integer.MAX_VALUE + " elements");
				}
				if (array.length < minCapacity) {
					array = Arrays.copyOf(array, expandedCapacity(array.length, minCapacity));
				}
			}

			«genericName» appendArray(final «type.javaName»[] values) {
				ensureCapacity(size + values.length);
				System.arraycopy(values, 0, array, size, values.length);
				size += values.length;
				return this;
			}

			private «genericName» appendSized(final Iterable<«type.genericBoxedName»> iterable, final int iterableLength) {
				if (iterableLength == 0) {
					return this;
				} else {
					ensureCapacity(size + iterableLength);
					«IF Type.javaUnboxedTypes.contains(type)»
						final PrimitiveIterator.Of«type.javaPrefix» iterator = «type.typeName»Iterator.getIterator(iterable.iterator());
						while (iterator.hasNext()) {
							array[size++] = iterator.next«type.javaPrefix»();
						}
					«ELSE»
						for (final «type.genericBoxedName» value : iterable) {
							array[size++] = «IF type == Type.OBJECT»requireNonNull(value)«ELSE»value«ENDIF»;
						}
					«ENDIF»
					return this;
				}
			}

			/**
			 * O(1)
			 */
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				ensureCapacity(size + 1);
				array[size++] = value;
				return this;
			}

			/**
			 * O(values.size)
			 */
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public final «genericName» appendValues(final «type.genericName»... values) {
				«IF type == Type.OBJECT»
					for (final A value : values) {
						requireNonNull(value);
					}
				«ENDIF»
				return appendArray(values);
			}

			/**
			 * O(iterable.size)
			 */
			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof «type.arrayShortName») {
					return appendArray(((«arrayGenericName») iterable).array);
				} else if (iterable instanceof Sized) {
					return appendSized(iterable, ((Sized) iterable).size());
				} else {
					if (iterable instanceof Collection) {
						final Collection<«type.genericBoxedName»> col = (Collection<«type.genericBoxedName»>) iterable;
						if (col.isEmpty()) {
							return this;
						} else {
							ensureCapacity(size + col.size());
						}
					}
					iterable.forEach(this::append);
					return this;
				}
			}

			public boolean isEmpty() {
				return (size == 0);
			}

			public int size() {
				return size;
			}

			public «arrayGenericName» build() {
				if (size == 0) {
					return empty«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array();
				} else if (size < array.length) {
					return new «IF type != Type.OBJECT»«type.typeName»«ENDIF»Array«IF type == Type.OBJECT»<>«ENDIF»(Arrays.copyOf(array, size));
				} else {
					return new «IF type != Type.OBJECT»«type.typeName»«ENDIF»Array«IF type == Type.OBJECT»<>«ENDIF»(array);
				}
			}

			@Override
			public String toString() {
				final StringBuilder builder = new StringBuilder("«shortName»(");
				for (int i = 0; i < size; i++) {
					builder.append(array[i]);
					if (i < size - 1) {
						builder.append(", ");
					}
				}
				builder.append(")");
				return builder.toString();
			}
		}
	''' }
}