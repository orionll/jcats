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

	def shortName() { type.shortName("ArrayBuilder") }
	def genericName() { type.genericName("ArrayBuilder") }
	def arrayGenericName() { type.arrayGenericName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Collection;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ENDIF»

		import «Constants.SIZED»;

		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static «Constants.ARRAY»Builder.*;
		«ENDIF»
		import static «Constants.COLLECTION».«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array.empty«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array;
		«IF type == Type.OBJECT»
			import static «Constants.COMMON».*;
		«ENDIF»


		public final class «genericName» {
			«IF type == Type.OBJECT»
				static final int MIN_CAPACITY = 16;

			«ENDIF»
			private «type.javaName»[] array;
			private int size;

			«shortName»(final «type.javaName»[] array, final int size) {
				this.array = array;
				this.size = size;
			}

			«IF type == Type.OBJECT»
				static int expandedCapacity(final int arrayLength, final int minCapacity) {
					// Assume minCapacity > 0
					if (arrayLength == 0 && minCapacity < MIN_CAPACITY) {
						return MIN_CAPACITY;
					} else {
						int newCapacity = arrayLength << 1;
						if (newCapacity - minCapacity < 0) {
							newCapacity = minCapacity;
						}
						if (newCapacity - MAX_ARRAY_SIZE > 0) {
							newCapacity = hugeCapacity(minCapacity);
						}
						return newCapacity;
					}
				}

				private static int hugeCapacity(final int minCapacity) {
					return (minCapacity > MAX_ARRAY_SIZE) ? Integer.MAX_VALUE : MAX_ARRAY_SIZE;
				}

			«ENDIF»
			public void ensureCapacity(final int minCapacity) {
				if (minCapacity > 0 && (minCapacity > MIN_CAPACITY || array.length != 0)) {
					ensureCapacityInternal(minCapacity);
				}
			}

			private void ensureCapacityInternal(final int minCapacity) {
				if (minCapacity < 0) {
					throw new OutOfMemoryError("ArrayBuilder size limit exceeded");
				} else if (minCapacity > array.length) {
					final int newCapacity = expandedCapacity(array.length, minCapacity);
					final «type.javaName»[] newArray = new «type.javaName»[newCapacity];
					System.arraycopy(array, 0, newArray, 0, array.length);
					array = newArray;
				}
			}

			«genericName» appendArray(final «type.javaName»[] values) {
				ensureCapacityInternal(size + values.length);
				System.arraycopy(values, 0, array, size, values.length);
				size += values.length;
				return this;
			}
			«IF type == Type.OBJECT»
				ArrayBuilder<A> appendArrayBuilder(final ArrayBuilder<A> builder) {
					ensureCapacityInternal(size + builder.size);
					System.arraycopy(builder.array, 0, array, size, builder.size);
					size += builder.size;
					return this;
				}

			«ENDIF»
			private «genericName» appendSized(final Iterable<«type.genericBoxedName»> iterable, final int iterableLength) {
				if (iterableLength == 0) {
					return this;
				} else {
					ensureCapacityInternal(size + iterableLength);
					«IF Type.javaUnboxedTypes.contains(type)»
						final PrimitiveIterator.Of«type.typeName» iterator = «type.typeName»Iterator.getIterator(iterable.iterator());
						while (iterator.hasNext()) {
							array[size++] = iterator.next«type.typeName»();
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
				ensureCapacityInternal(size + 1);
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
							ensureCapacityInternal(size + col.size());
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
					return empty«type.arrayShortName»();
				} else if (size < array.length) {
					final «type.javaName»[] result = new «type.javaName»[size];
					System.arraycopy(array, 0, result, 0, size);
					return new «type.arrayDiamondName»(result);
				} else {
					return new «type.arrayDiamondName»(array);
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