package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

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
		import java.util.Iterator;
		import java.util.RandomAccess;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»
		import java.util.stream.«type.streamName»;

		import «Constants.SIZED»;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static «Constants.ARRAY»Builder.*;
		«ENDIF»
		import static «Constants.COLLECTION».«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array.empty«IF type != Type.OBJECT»«type.typeName»«ENDIF»Array;
		import static «Constants.COMMON».*;


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
				if (minCapacity > 0 && (minCapacity > MIN_CAPACITY || this.array.length != 0)) {
					ensureCapacityInternal(minCapacity);
				}
			}

			private void ensureCapacityInternal(final int minCapacity) {
				if (minCapacity < 0) {
					throw new OutOfMemoryError("ArrayBuilder size limit exceeded");
				} else if (minCapacity > this.array.length) {
					final int newCapacity = expandedCapacity(this.array.length, minCapacity);
					final «type.javaName»[] newArray = new «type.javaName»[newCapacity];
					System.arraycopy(this.array, 0, newArray, 0, this.array.length);
					this.array = newArray;
				}
			}

			«genericName» appendArray(final «type.javaName»[] values) {
				ensureCapacityInternal(this.size + values.length);
				System.arraycopy(values, 0, this.array, this.size, values.length);
				this.size += values.length;
				return this;
			}

			«genericName» appendArrayBuilder(final «genericName» builder) {
				ensureCapacityInternal(this.size + builder.size);
				System.arraycopy(builder.array, 0, this.array, this.size, builder.size);
				this.size += builder.size;
				return this;
			}

			private «genericName» appendSized(final Iterable<«type.genericBoxedName»> iterable, final int iterableLength) {
				if (iterableLength > 0) {
					ensureCapacityInternal(this.size + iterableLength);
					«IF type.javaUnboxedType»
						if (iterable instanceof Container<?>) {
							((Container<«type.boxedName»>) iterable).foreach((final «type.boxedName» value) -> this.array[this.size++] = value);
						} else {
							final PrimitiveIterator.Of«type.typeName» iterator = «type.typeName»Iterator.getIterator(iterable.iterator());
							while (iterator.hasNext()) {
								this.array[this.size++] = iterator.next«type.typeName»();
							}
						}
					«ELSE»
						for (final «type.genericBoxedName» value : iterable) {
							this.array[this.size++] = «IF type == Type.OBJECT»requireNonNull(value)«ELSE»value«ENDIF»;
						}
					«ENDIF»
				}
				return this;
			}

			/**
			 * O(1)
			 */
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				ensureCapacityInternal(this.size + 1);
				this.array[this.size++] = value;
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
				if (iterable instanceof «type.arrayWildcardName») {
					return appendArray(((«arrayGenericName») iterable).array);
				} else if (iterable instanceof «type.containerWildcardName») {
					return append«type.containerShortName»((«type.containerGenericName») iterable);
				} else if (iterable instanceof Sized && ((Sized) iterable).hasFixedSize()) {
					return appendSized(iterable, ((Sized) iterable).size());
				} else {
					if (iterable instanceof Collection<?> && iterable instanceof RandomAccess) {
						final Collection<«type.genericBoxedName»> col = (Collection<«type.genericBoxedName»>) iterable;
						if (col.isEmpty()) {
							return this;
						} else {
							ensureCapacityInternal(this.size + col.size());
						}
					}
					iterable.forEach(this::append);
					return this;
				}
			}

			private «genericName» append«type.containerShortName»(final «type.containerGenericName» container) {
				if (container.hasFixedSize()) {
					if (container.isNotEmpty()) {
						ensureCapacityInternal(this.size + container.size());
						container.foreach((final «type.genericName» value) -> this.array[this.size++] = value);
					}
				} else {
					container.foreach(this::append);
				}
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

			public boolean isEmpty() {
				return (this.size == 0);
			}

			public int size() {
				return this.size;
			}

			«type.javaName»[] buildArray() {
				if (this.size == 0) {
					return EMPTY_«type.typeName.toUpperCase»_ARRAY;
				} else if (this.size < this.array.length) {
					final «type.javaName»[] result = new «type.javaName»[this.size];
					System.arraycopy(this.array, 0, result, 0, this.size);
					return result;
				} else {
					return this.array;
				}
			}

			«IF type == Type.OBJECT»
				A[] buildPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] result = supplier.apply(this.size);
					System.arraycopy(this.array, 0, result, 0, this.size);
					return result;
				}

			«ENDIF»
			public «arrayGenericName» build() {
				if (this.size == 0) {
					return empty«type.arrayShortName»();
				} else if (this.size < this.array.length) {
					final «type.javaName»[] result = new «type.javaName»[this.size];
					System.arraycopy(this.array, 0, result, 0, this.size);
					return new «type.arrayDiamondName»(result);
				} else {
					return new «type.arrayDiamondName»(this.array);
				}
			}

			@Override
			public String toString() {
				final StringBuilder builder = new StringBuilder("«shortName»(");
				for (int i = 0; i < this.size; i++) {
					builder.append(this.array[i]);
					if (i < this.size - 1) {
						builder.append(", ");
					}
				}
				builder.append(")");
				return builder.toString();
			}
		}
	''' }
}