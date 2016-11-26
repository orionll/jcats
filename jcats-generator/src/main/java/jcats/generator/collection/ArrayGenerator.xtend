package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class ArrayGenerator implements ClassGenerator {
	override className() { Constants.ARRAY }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.AbstractList;
		import java.util.ArrayList;
		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.List;
		import java.util.NoSuchElementException;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.FUNCTION».BoolF;
		import «Constants.F»;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		import «Constants.EQUATABLE»;
		import «Constants.INDEXED»;
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»
		import «Constants.SIZED»;

		import static java.lang.Math.min;
		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static «Constants.F».id;
		import static «Constants.P».p;

		public final class Array<A> implements Iterable<A>, Equatable<Array<A>>, Sized, Indexed<A>, Serializable {
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
			public A head() {
				return get(0);
			}

			/**
			 * O(1)
			 */
			public A last() {
				return get(array.length - 1);
			}

			/**
			 * O(1)
			 */
			@Override
			public A get(final int index) {
				return (A) array[index];
			}

			/**
			 * O(size)
			 */
			public Array<A> set(final int index, final A value) {
				requireNonNull(value);
				final Object[] result = array.clone();
				result[index] = value;
				return new Array<>(result);
			}

			/**
			 * O(size)
			 */
			public Array<A> prepend(final A value) {
				requireNonNull(value);
				final Object[] newArray = new Object[array.length + 1];
				System.arraycopy(array, 0, newArray, 1, array.length);
				newArray[0] = value;
				return new Array<>(newArray);
			}

			/**
			 * O(size)
			 */
			public Array<A> append(final A value) {
				requireNonNull(value);
				final Object[] newArray = Arrays.copyOf(array, array.length + 1);
				newArray[array.length] = value;
				return new Array<>(newArray);
			}

			static Object[] concatArrays(final Object[] prefix, final Object[] suffix) {
				final Object[] result = new Object[prefix.length + suffix.length];
				System.arraycopy(prefix, 0, result, 0, prefix.length);
				System.arraycopy(suffix, 0, result, prefix.length, suffix.length);
				return result;
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
					return new Array<>(concatArrays(array, suffix.array));
				}
			}

			private static <A> void fillArray(final Object[] array, final int startIndex, final Iterable<A> iterable) {
				int i = startIndex;
				for (final A value : iterable) {
					array[i++] = requireNonNull(value);
				}
			}

			private Array<A> appendSized(final Iterable<A> suffix, final int suffixSize) {
				if (suffixSize == 0) {
					return this;
				} else {
					final Object[] result = Arrays.copyOf(array, array.length + suffixSize);
					fillArray(result, array.length, suffix);
					return new Array<>(result);
				}
			}

			private Array<A> prependSized(final Iterable<A> prefix, final int prefixSize) {
				if (prefixSize == 0) {
					return this;
				} else {
					final Object[] result = new Object[prefixSize + array.length];
					fillArray(result, 0, prefix);
					System.arraycopy(array, 0, result, prefixSize, array.length);
					return new Array<>(result);
				}
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public Array<A> appendAll(final Iterable<A> suffix) {
				if (suffix instanceof Array) {
					return concat((Array<A>) suffix);
				} else if (suffix instanceof Collection<?> && suffix instanceof RandomAccess) {
					final Collection<A> col = (Collection<A>) suffix;
					return col.isEmpty() ? this : appendSized(suffix, col.size());
				} else if (suffix instanceof Sized) {
					return appendSized(suffix, ((Sized) suffix).size());
				} else {
					final Iterator<A> iterator = suffix.iterator();
					if (iterator.hasNext()) {
						final ArrayBuilder<A> builder = new ArrayBuilder<>(array);
						while (iterator.hasNext()) {
							builder.append(iterator.next());
						}
						return builder.build();
					} else {
						return this;
					}
				}
			}

			/**
			 * O(prefix.size + this.size)
			 */
			public Array<A> prependAll(final Iterable<A> prefix) {
				if (prefix instanceof Array) {
					return ((Array<A>) prefix).concat(this);
				} else if (prefix instanceof Collection<?> && prefix instanceof RandomAccess) {
					final Collection<A> col = (Collection<A>) prefix;
					return col.isEmpty() ? this : prependSized(prefix, col.size());
				} else if (prefix instanceof Sized) {
					return prependSized(prefix, ((Sized) prefix).size());
				} else {
					final Iterator<A> iterator = prefix.iterator();
					if (iterator.hasNext()) {
						final ArrayBuilder<A> builder = new ArrayBuilder<>();
						while (iterator.hasNext()) {
							builder.append(iterator.next());
						}
						return builder.build().concat(this);
					} else {
						return this;
					}
				}
			}

			public Array<A> reverse() {
				if (isEmpty() || array.length == 1) {
					return this;
				} else {
					final Object[] newArray = array.clone();
					Collections.reverse(Arrays.asList(newArray));
					return new Array<>(newArray);
				}
			}

			public <B> Array<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return emptyArray();
				} else if (f == F.id()) {
					return (Array<B>) this;
				} else {
					final Object[] newArray = mapArray(array, f);
					return new Array<>(newArray);
				}
			}

			public <B> Array<B> flatMap(final F<A, Array<B>> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return emptyArray();
				} else {
					final ArrayBuilder<B> builder = new ArrayBuilder<>();
					for (final Object value : array) {
						builder.appendArray(f.apply((A) value).array);
					}
					return builder.build();
				}
			}

			public Array<A> filter(final BoolF<A> predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return emptyArray();
				} else {
					final ArrayBuilder<A> builder = new ArrayBuilder<>();
					for (final Object value : array) {
						if (predicate.apply((A) value)) {
							builder.append((A) value);
						}
					}
					return builder.build();
				}
			}

			public Array<A> take(final int n) {
				if (isEmpty() || n <= 0) {
					return emptyArray();
				} else if (n >= array.length) {
					return this;
				} else {
					return new Array<>(Arrays.copyOf(array, n));
				}
			}

			public boolean contains(final A value) {
				requireNonNull(value);
				for (final Object a : array) {
					if (a.equals(value)) {
						return true;
					}
				}
				return false;
			}

			public List<A> asList() {
				return new ArrayAsList<>(this);
			}

			«toArrayList»

			public Seq<A> toSeq() {
				if (array.length == 0) {
					return Seq.emptySeq();
				} else {
					return Seq.seqFromArray(array);
				}
			}

			public Object[] toObjectArray() {
				if (array.length == 0) {
					return array;
				} else {
					final Object[] newArray = new Object[array.length];
					System.arraycopy(array, 0, newArray, 0, array.length);
					return newArray;
				}
			}

			public static <A> Array<A> emptyArray() {
				return EMPTY;
			}

			public static <A> Array<A> singleArray(final A value) {
				requireNonNull(value);
				return new Array<>(new Object[] { value });
			}

			static Object[] mapArray(final Object[] array, final F f) {
				final Object[] newArray = new Object[array.length];
				for (int i = 0; i < array.length; i++) {
					newArray[i] = requireNonNull(f.apply(array[i]));
				}
				return newArray;
			}

			@SafeVarargs
			public static <A> Array<A> array(final A... values) {
				if (values.length == 0) {
					return emptyArray();
				} else {
					for (final Object a : values) {
						requireNonNull(a);
					}
					final Object[] array = new Object[values.length];
					System.arraycopy(values, 0, array, 0, values.length);
					return new Array<>(array);
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

			private static <A> Array<A> sizedToArray(final Iterable<A> iterable, final int iterableSize) {
				final Object[] array = new Object[iterableSize];
				fillArray(array, 0, iterable);
				return new Array<>(array);
			}

			public static <A> Array<A> iterableToArray(final Iterable<A> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof Array) {
					return (Array<A>) iterable;
				} else if (iterable instanceof Collection<?>) {
					final Collection<A> col = (Collection<A>) iterable;
					return col.isEmpty() ? emptyArray() : sizedToArray(iterable, col.size());
				} else if (iterable instanceof Sized) {
					return sizedToArray(iterable, ((Sized) iterable).size());
				} else {
					final Iterator<A> iterator = iterable.iterator();
					if (iterator.hasNext()) {
						final ArrayBuilder<A> builder = new ArrayBuilder<>();
						while (iterator.hasNext()) {
							builder.append(iterator.next());
						}
						return builder.build();
					} else {
						return emptyArray();
					}
				}
			}

			«join»

			@Override
			public Iterator<A> iterator() {
				return isEmpty() ? emptyIterator() : new ArrayIterator<>(array);
			}

			@Override
			public Spliterator<A> spliterator() {
				return isEmpty() ? emptySpliterator() : Spliterators.spliterator(array, Spliterator.ORDERED | Spliterator.IMMUTABLE);
			}

			«stream»

			«parallelStream»

			@Override
			public int hashCode() {
				return Arrays.hashCode(array);
			}

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof Array<?>) {
					return Arrays.equals(array, ((Array) obj).array);
				} else {
					return false;
				}
			}

			«toStr»

			«zip»

			«zipWith»

			/**
			 * O(size)
			 */
			public Array<P<A, Integer>> zipWithIndex() {
				if (isEmpty()) {
					return emptyArray();
				} else {
					final Object[] result = new Object[array.length];
					for (int i = 0; i < array.length; i++) {
						result[i] = p(array[i], i);
					}
					return new Array<>(result);
				}
			}

			«zipN»
			«zipWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["array" + it + ".isEmpty()"].join(" || ")») {
					return emptyArray();
				} else {
					final int length = «(1 ..< arity).map['''min(array«it».array.length'''].join(", ")», array«arity».array.length«(1 ..< arity).map[")"].join»;
					final Object[] array = new Object[length];
					for (int i = 0; i < length; i++) {
						array[i] = requireNonNull(f.apply(«(1 .. arity).map['''array«it».get(i)'''].join(", ")»));
					}
					return new Array<>(array);
				}
			''']»
			«productN»
			«productWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["array" + it + ".isEmpty()"].join(" || ")») {
					return emptyArray();
				} else {
					«FOR i : 1 .. arity»
						final Object[] arr«i» = array«i».array;
					«ENDFOR»
					final long size1 = arr1.length;
					«FOR i : 2 .. arity»
						final long size«i» = size«i-1» * arr«i».length;
						if (size«i» != (int) size«i») {
							throw new IndexOutOfBoundsException("Size overflow");
						}
					«ENDFOR»
					final Object[] array = new Object[(int) size«arity»];
					int i = 0;
					«FOR i : 1 .. arity»
						«(1 ..< i).map["\t"].join»for (final Object a«i» : arr«i») {
					«ENDFOR»
						«(1 ..< arity).map["\t"].join»array[i++] = requireNonNull(f.apply(«(1 .. arity).map['''(A«it») a«it»'''].join(", ")»));
					«FOR i : 1 .. arity»
						«(1 ..< arity - i + 1).map["\t"].join»}
					«ENDFOR»
					return new Array<>(array);
				}
			''']»
			«cast(#["A"], #[], #["A"])»

			public static <A> ArrayBuilder<A> arrayBuilder() {
				return new ArrayBuilder<>();
			}

			public static <A> ArrayBuilder<A> arrayBuilderWithCapacity(final int initialCapacity) {
				return new ArrayBuilder<>(initialCapacity);
			}
		}

		final class ArrayAsList<A> extends IndexedIterableAsList<A, Array<A>> {
			ArrayAsList(final Array<A> array) {
				super(array);
			}

			@Override
			public Object[] toArray() {
				return iterable.toObjectArray();
			}
		}
	''' }
}
