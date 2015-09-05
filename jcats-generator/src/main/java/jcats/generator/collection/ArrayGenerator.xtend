package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ArrayGenerator implements Generator {
	override className() { Constants.ARRAY }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Predicate;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.F»;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;

		public final class Array<A> implements Iterable<A>, Sized, Serializable {
			private static final Array EMPTY = new Array(new Object[0]);

			final Object[] array;

			Array(final Object[] array) {
				this.array = array;
			}

			/**
			 * O(1)
			 */
			@Override
			public int size() {
				return array.length;
			}

			/**
			 * O(1)
			 */
			@Override
			public boolean isEmpty() {
				return (array.length == 0);
			}

			/**
			 * O(1)
			 */
			@Override
			public boolean isNotEmpty() {
				return (array.length != 0);
			}

			/**
			 * O(1)
			 */
			public A head() {
				return get(0);
			}

			/**
			 * O(1)
			 */
			public A get(final int index) {
				return (A) array[index];
			}

			/**
			 * O(this.size)
			 */
			public Array<A> prepend(final A value) {
				requireNonNull(value);
				final Object[] newArray = new Object[array.length + 1];
				System.arraycopy(array, 0, newArray, 1, array.length);
				newArray[0] = value;
				return new Array<>(newArray);
			}

			/**
			 * O(this.size)
			 */
			public Array<A> append(final A value) {
				requireNonNull(value);
				final Object[] newArray = Arrays.copyOf(array, array.length + 1);
				newArray[array.length] = value;
				return new Array<>(newArray);
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public Array<A> concat(final Array<A> suffix) {
				requireNonNull(suffix);
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					final Object[] result = new Object[array.length + suffix.array.length];
					System.arraycopy(array, 0, result, 0, array.length);
					System.arraycopy(suffix.array, 0, result, array.length, suffix.array.length);
					return new Array<>(result);
				}
			}

			public Array<A> appendAll(final Iterable<A> suffix) {
				if (suffix instanceof Array) {
					return concat((Array<A>) suffix);
				} else if (suffix instanceof Collection) {
					final Collection<A> col = (Collection<A>) suffix;
					if (isEmpty() && col.isEmpty()) {
						return emptyArray();
					} else {
						return appendSized(suffix, col.size());
					}
				} else if (suffix instanceof Sized) {
					final Sized sized = (Sized) suffix;
					if (isEmpty() && sized.isEmpty()) {
						return emptyArray();
					} else {
						return appendSized(suffix, sized.size());
					}
				} else {
					final ArrayBuilder<A> builder = new ArrayBuilder<>();
					builder.appendArray(this);
					builder.appendAll(suffix);
					return builder.toArray();
				}
			}

			private Array<A> appendSized(final Iterable<A> suffix, final int suffixSize) {
				final Object[] result = Arrays.copyOf(array, array.length + suffixSize);
				int i = array.length;
				for (final A a : suffix) {
					result[i++] = requireNonNull(a);
				}
				return new Array<>(result);
			}

			public Array<A> prependAll(final Iterable<A> prefix) {
				return null;
			}

			public <B> Array<B> map(final F<A, B> f) {
				return null;
			}

			public <B> Array<B> flatMap(final F<A, Array<B>> f) {
				return null;
			}

			public Array<A> filter(final Predicate<A> predicate) {
				return null;
			}

			public Array<A> take(final int n) {
				return null;
			}

			public static <A> Array<A> emptyArray() {
				return EMPTY;
			}

			public static <A> Array<A> singleArray(final A value) {
				requireNonNull(value);
				return new Array<>(new Object[] { value });
			}

			@SafeVarargs
			public static <A> Array<A> array(final A... values) {
				if (values.length == 0) {
					return emptyArray();
				} else {
					for (final Object a : values) {
						requireNonNull(a);
					}
					return new Array<>(Arrays.copyOf(values, values.length, Object[].class));
				}
			}

			«FOR primitive : PRIMITIVES»
				public static Array<«primitive.boxedName»> «primitive.shortName»Array(final «primitive»... values) {
					if (values.length == 0) {
						return emptyArray();
					} else {
						final Object[] array = new Object[values.length];
						for (int i = 0; i < values.length; i++) {
							array[i] = values[i];
						}
						return new Array<>(array);
					}
				}

			«ENDFOR»
			public static Array<Character> stringToCharArray(final String str) {
				if (str.isEmpty()) {
					return emptyArray();
				} else {
					final Object[] array = new Object[str.length()];
					for (int i = 0; i < str.length(); i++) {
						array[i] = str.charAt(i);
					}
					return new Array<>(array);
				}
			}

			public static <A> Array<A> iterableToArray(final Iterable<A> values) {
				return null;
			}

			@Override
			public Iterator<A> iterator() {
				return isEmpty() ? emptyIterator() : new ArrayIterator<>(array);
			}

			@Override
			public Spliterator<A> spliterator() {
				return isEmpty() ? emptySpliterator() : Spliterators.spliterator(array, Spliterator.IMMUTABLE);
			}

			«stream»

			«parallelStream»
		}
	''' }
}
