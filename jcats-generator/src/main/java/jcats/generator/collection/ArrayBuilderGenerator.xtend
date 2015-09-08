package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ArrayBuilderGenerator implements Generator {
	override className() { Constants.ARRAY + "Builder" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Arrays;
		import java.util.Collection;

		import «Constants.PRECISE_SIZE»;
		import «Constants.SIZE»;
		import «Constants.SIZED»;

		import static «Constants.ARRAY».emptyArray;

		import static java.util.Objects.requireNonNull;

		public final class ArrayBuilder<A> {
			private Object[] array;
			private int length;

			public ArrayBuilder(final int initialCapacity) {
				array = new Object[initialCapacity];
				length = 0;
			}

			public ArrayBuilder() {
				this(10);
			}

			ArrayBuilder(final Object[] values) {
				array = values;
				length = values.length;
			}

			private int expandedCapacity(final int minCapacity) {
				// careful of overflow!
				int newCapacity = array.length + (array.length >> 1) + 1;
				if (newCapacity < minCapacity) {
					newCapacity = Integer.highestOneBit(minCapacity - 1) << 1;
				}
				if (newCapacity < 0) {
					newCapacity = Integer.MAX_VALUE;
					// guaranteed to be >= newCapacity
				}
				return newCapacity;
			}

			private void ensureCapacity(final int minCapacity) {
				if (minCapacity < 0) {
					throw new Error("Cannot store more than " + Integer.MAX_VALUE + " elements");
				}
				if (array.length < minCapacity) {
					array = Arrays.copyOf(array, expandedCapacity(minCapacity));
				}
			}

			ArrayBuilder<A> appendArray(final Object[] values) {
				ensureCapacity(length + values.length);
				System.arraycopy(values, 0, array, length, values.length);
				length += values.length;
				return this;
			}

			private ArrayBuilder<A> appendSized(final Iterable<A> iterable, final int iterableLength) {
				if (iterableLength == 0) {
					return this;
				} else {
					ensureCapacity(length + iterableLength);
					for (final A value : iterable) {
						array[length++] = requireNonNull(value);
					}
					return this;
				}
			}

			/**
			 * O(1)
			 */
			public ArrayBuilder<A> append(final A value) {
				requireNonNull(value);
				ensureCapacity(length + 1);
				array[length++] = value;
				return this;
			}

			/**
			 * O(values.size)
			 */
			@SafeVarargs
			public final ArrayBuilder<A> appendValues(final A... values) {
				for (final A value : values) {
					requireNonNull(value);
				}
				return appendArray(values);
			}

			/**
			 * O(iterable.size)
			 */
			public ArrayBuilder<A> appendAll(final Iterable<A> iterable) {
				if (iterable instanceof Array) {
					return appendArray(((Array<A>) iterable).array);
				}

				if (iterable instanceof Collection) {
					final Collection<A> col = (Collection<A>) iterable;
					if (!col.isEmpty()) {
						return appendSized(iterable, col.size());
					}
				} else if (iterable instanceof Sized) {
					return ((Sized) iterable).size().match(precise -> appendSized(iterable, precise.length()),
							() -> { throw new IllegalArgumentException("Cannot append infinite iterable to array build"); });
				} else {
					for (final A value : iterable) {
						append(value);
					}
				}

				return this;
			}

			public boolean isEmpty() {
				return (length == 0);
			}

			public int length() {
				return length;
			}

			public Array<A> build() {
				if (length == 0) {
					return emptyArray();
				} else if (length < array.length) {
					return new Array<>(Arrays.copyOf(array, length));
				} else {
					return new Array<>(array);
				}
			}

			@Override
			public String toString() {
				final StringBuilder builder = new StringBuilder("ArrayBuilder(");
				for (int i = 0; i < length; i++) {
					builder.append(array[i]);
					if (i < length - 1) {
						builder.append(", ");
					}
				}
				builder.append(")");
				return builder.toString();
			}
		}
	''' }
}