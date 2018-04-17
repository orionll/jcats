package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.collection.Common" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.AbstractCollection;
		import java.util.AbstractList;
		import java.util.AbstractMap;
		import java.util.AbstractSet;
		import java.util.Collection;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.List;
		import java.util.ListIterator;
		import java.util.Map;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.BiFunction;
		import java.util.function.Consumer;
		import java.util.function.IntConsumer;
		import java.util.function.DoubleConsumer;
		import java.util.function.LongConsumer;
		import java.util.function.Function;
		import java.util.function.Predicate;
		import java.util.function.UnaryOperator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;

		final class Common {
			«FOR type : Type.values»
				static final «type.javaName»[] «type.emptyArrayName» = new «type.javaName»[0];
			«ENDFOR»
			«FOR type : Type.javaUnboxedTypes»
				static final «type.typeName»«type.typeName»«type.typeName»F2 SUM_«type.javaName.toUpperCase» = (a, b) -> a + b;
			«ENDFOR»

			/**
			 * The maximum size of array to allocate.
			 * Some VMs reserve some header words in an array.
			 * Attempts to allocate larger arrays may result in
			 * OutOfMemoryError: Requested array size exceeds VM limit
			 */
			static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

			private Common() {
			}

			«FOR type : Type.values»
				static «type.javaName»[] update«type.shortName("Array")»(final «type.javaName»[] array, final int index, final «type.updateFunction.replaceAll("<A, A>", "")» f) {
					final «type.javaName»[] result = new «type.javaName»[array.length];
					System.arraycopy(array, 0, result, 0, array.length);
					final «type.javaName» oldValue = array[index];
					final «type.javaName» newValue = f.apply(oldValue);
					result[index] = «type.requireNonNull("newValue")»;
					return result;
				}

			«ENDFOR»
			«FOR type : Type.values»
				static boolean «type.indexedContainerShortName.firstToLowerCase»sEqual(final «type.indexedContainerWildcardName» c1, final «type.indexedContainerWildcardName» c2) {
					if (c1.hasFixedSize() && c2.hasFixedSize()) {
						if (c1.size() == c2.size()) {
							final «type.iteratorWildcardName» iterator1 = c1.iterator();
							final «type.iteratorWildcardName» iterator2 = c2.iterator();
							while (iterator1.hasNext()) {
								«IF type == Type.OBJECT»
									final Object o1 = iterator1.next();
									final Object o2 = requireNonNull(iterator2.next());
									if (!o1.equals(o2)) {
										return false;
									}
								«ELSE»
									final «type.javaName» o1 = iterator1.«type.iteratorNext»();
									final «type.javaName» o2 = iterator2.«type.iteratorNext»();
									if (o1 != o2) {
										return false;
									}
								«ENDIF»
							}
							return true;
						} else {
							return false;
						}
					} else {
						final «type.iteratorWildcardName» iterator1 = c1.iterator();
						final «type.iteratorWildcardName» iterator2 = c2.iterator();
						while (iterator1.hasNext() && iterator2.hasNext()) {
							«IF type == Type.OBJECT»
								final Object o1 = iterator1.next();
								final Object o2 = requireNonNull(iterator2.next());
								if (!o1.equals(o2)) {
									return false;
								}
							«ELSE»
								final «type.javaName» o1 = iterator1.«type.iteratorNext»();
								final «type.javaName» o2 = iterator2.«type.iteratorNext»();
								if (o1 != o2) {
									return false;
								}
							«ENDIF»
						}
						return !(iterator1.hasNext() || iterator2.hasNext());
					}
				}

			«ENDFOR»
			«FOR type : Type.values.filter[it != Type.BOOLEAN]»
				static boolean «type.uniqueContainerShortName.firstToLowerCase»sEqual(final «type.uniqueContainerShortName» c1, final «type.uniqueContainerShortName» c2) {
					if (c1.size() == c2.size()) {
						«IF type == Type.OBJECT || type == Type.BOOLEAN»
							for (final «type.javaName» value : c1) {
								if (!c2.contains(value)) {
									return false;
								}
							}
						«ELSE»
							final «type.iteratorGenericName» iterator1 = c1.iterator();
							while (iterator1.hasNext()) {
								final «type.javaName» value = iterator1.«type.iteratorNext»();
								if (!c2.contains(value)) {
									return false;
								}
							}
						«ENDIF»
						return true;
					} else {
						return false;
					}
				}

			«ENDFOR»
			static boolean keyValuesEqual(final KeyValue<Object, ?> keyValue1, final KeyValue<Object, ?> keyValue2) {
				if (keyValue1.size() == keyValue2.size()) {
					for (final P<?, ?> entry : keyValue1) {
						final Object value = keyValue2.getOrNull(entry.get1());
						if (value == null || !value.equals(entry.get2())) {
							return false;
						}
					}
					return true;
				} else {
					return false;
				}
			}

			static String iterableToString(final Iterable<?> iterable, final String name) {
				final StringBuilder builder = new StringBuilder(name);
				builder.append("(");
				final Iterator<?> iterator = iterable.iterator();
				while (iterator.hasNext()) {
					builder.append(iterator.next());
					if (iterator.hasNext()) {
						builder.append(", ");
					}
				}
				builder.append(")");
				return builder.toString();
			}

			«FOR type : Type.javaUnboxedTypes»
				static String «type.containerShortName.firstToLowerCase»ToString(final «type.containerWildcardName» container, final String name) {
					final «type.iteratorGenericName» iterator = container.iterator();
					final StringBuilder builder = new StringBuilder(name);
					builder.append("(");
					while (iterator.hasNext()) {
						builder.append(iterator.«type.iteratorNext»());
						if (iterator.hasNext()) {
							builder.append(", ");
						}
					}
					builder.append(")");
					return builder.toString();
				}

			«ENDFOR»
			static <A> int containerHashCode(final Container<A> container) {
				return container.foldLeftToInt(1, (hashCode, value) -> 31 * hashCode + value.hashCode());
			}

			«FOR type : Type.primitives»
				static int «type.containerShortName.firstToLowerCase»HashCode(final «type.containerWildcardName» container) {
					return container.foldLeftToInt(1, (hashCode, value) -> 31 * hashCode + «type.genericBoxedName».hashCode(value));
				}

			«ENDFOR»
			static <A> int uniqueContainerHashCode(final UniqueContainer<A> container) {
				return container.foldLeftToInt(0, (hashCode, value) -> hashCode + value.hashCode());
			}

			«FOR type : Type.primitives.filter[it != Type.BOOLEAN]»
				static int «type.uniqueContainerShortName.firstToLowerCase»HashCode(final «type.containerWildcardName» container) {
					return container.foldLeftToInt(0, (hashCode, value) -> hashCode + «type.genericBoxedName».hashCode(value));
				}

			«ENDFOR»
			static void sliceRangeCheck(final int fromIndex, final int toIndex, final int size) {
				if (fromIndex < 0) {
					throw new IndexOutOfBoundsException("fromIndex = " + fromIndex);
				} else if (toIndex > size) {
					throw new IndexOutOfBoundsException("toIndex = " + toIndex);
				} else if (fromIndex > toIndex) {
					throw new IllegalArgumentException(
							"fromIndex (" + fromIndex + ") > toIndex (" + toIndex + ")");
				}
			}
		}

		«FOR type : Type.values»
			final class «IF type == Type.OBJECT»ArrayIterator<A>«ELSE»«type.typeName»ArrayIterator«ENDIF» implements «type.iteratorGenericName» {
				private int i;
				private final «type.javaName»[] array;

				«IF type != Type.OBJECT»«type.typeName»«ENDIF»ArrayIterator(final «type.javaName»[] array) {
					this.array = array;
				}

				@Override
				public boolean hasNext() {
					return (this.i < this.array.length);
				}

				@Override
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					try {
						final «type.genericName» next = «type.genericCast»this.array[this.i];
						this.i++;
						return next;
					} catch (final IndexOutOfBoundsException __) {
						throw new NoSuchElementException();
					}
				}
			}

		«ENDFOR»
		«FOR type : Type.values»
			final class «IF type == Type.OBJECT»ArrayReverseIterator<A>«ELSE»«type.typeName»ArrayReverseIterator«ENDIF» implements «type.iteratorGenericName» {
				private int i;
				private final «type.javaName»[] array;

				«IF type != Type.OBJECT»«type.typeName»«ENDIF»ArrayReverseIterator(final «type.javaName»[] array) {
					assert array.length > 0;
					this.array = array;
					this.i = array.length - 1;
				}

				@Override
				public boolean hasNext() {
					return (this.i >= 0);
				}

				@Override
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					try {
						final «type.genericName» next = «type.genericCast»this.array[this.i];
						this.i--;
						return next;
					} catch (final IndexOutOfBoundsException __) {
						throw new NoSuchElementException();
					}
				}
			}

		«ENDFOR»
		final class ListReverseIterator<A> implements Iterator<A> {
			private final ListIterator<A> iterator;

			ListReverseIterator(final List<A> list, final int index) {
				this.iterator = list.listIterator(index);
			}

			@Override
			public boolean hasNext() {
				return this.iterator.hasPrevious();
			}

			@Override
			public A next() {
				return this.iterator.previous();
			}
		}

		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»ListReverseIterator<A> implements «type.iteratorGenericName» {
				private final ListIterator<«type.boxedName»> iterator;

				«type.typeName»ListReverseIterator(final List<«type.boxedName»> list, final int index) {
					this.iterator = list.listIterator(index);
				}

				@Override
				public boolean hasNext() {
					return this.iterator.hasPrevious();
				}

				@Override
				public «type.javaName» next«type.typeName»() {
					return this.iterator.previous();
				}
			}

		«ENDFOR»
		final class MappedIterator<A, B> implements Iterator<B> {
			private final Iterator<A> iterator;
			private final F<A, B> f;

			MappedIterator(final Iterator<A> iterator, final F<A, B> f) {
				this.iterator = iterator;
				this.f = f;
			}

			@Override
			public boolean hasNext() {
				return iterator.hasNext();
			}

			@Override
			public B next() {
				return f.apply(requireNonNull(iterator.next()));
			}
		}

		«FOR fromType : Type.values»
			«FOR toType : Type.values»
				«IF fromType != Type.OBJECT || toType != Type.OBJECT»
					final class Mapped«fromType.typeName»«toType.typeName»Iterator«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» implements «toType.iteratorGenericName» {
						private final «fromType.iteratorGenericName» iterator;
						private final «IF fromType != Type.OBJECT»«fromType.typeName»«ENDIF»«toType.typeName»F«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» f;

						Mapped«fromType.typeName»«toType.typeName»Iterator(final «fromType.iteratorGenericName» iterator, final «IF fromType != Type.OBJECT»«fromType.typeName»«ENDIF»«toType.typeName»F«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» f) {
							this.iterator = iterator;
							this.f = f;
						}

						@Override
						public boolean hasNext() {
							return iterator.hasNext();
						}

						@Override
						public «toType.genericJavaUnboxedName» «toType.iteratorNext»() {
							return f.apply(iterator.«fromType.iteratorNext»());
						}
					}

				«ENDIF»
			«ENDFOR»
		«ENDFOR»
		final class TableIterator<A> implements Iterator<A> {
			private final int size;
			private final IntObjectF<A> f;
			private int i;

			TableIterator(final int size, final IntObjectF<A> f) {
				this.size = size;
				this.f = f;
			}

			@Override
			public boolean hasNext() {
				return i != size;
			}

			@Override
			public A next() {
				if (i >= size) {
					throw new NoSuchElementException();
				} else {
					return f.apply(i++);
				}
			}
		}

		«FOR type : Type.javaUnboxedTypes»
			final class Table«type.typeName»Iterator implements PrimitiveIterator.Of«type.typeName» {
				private final int size;
				private final Int«type.typeName»F f;
				private int i;

				Table«type.typeName»Iterator(final int size, final Int«type.typeName»F f) {
					this.size = size;
					this.f = f;
				}

				@Override
				public boolean hasNext() {
					return i != size;
				}

				@Override
				public «type.javaName» next«type.typeName»() {
					if (i >= size) {
						throw new NoSuchElementException();
					} else {
						return f.apply(i++);
					}
				}
			}

		«ENDFOR»
		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»Iterator implements PrimitiveIterator.Of«type.typeName» {
				final Iterator<«type.boxedName»> iterator;

				private «type.typeName»Iterator(final Iterator<«type.boxedName»> iterator) {
					this.iterator = iterator;
				}

				@Override
				public boolean hasNext() {
					return this.iterator.hasNext();
				}

				@Override
				public «type.javaName» next«type.typeName»() {
					return this.iterator.next();
				}

				static PrimitiveIterator.Of«type.typeName» getIterator(final Iterator<«type.boxedName»> iterator) {
					if (iterator instanceof PrimitiveIterator.Of«type.typeName») {
						return (PrimitiveIterator.Of«type.typeName») iterator;
					} else {
						return new «type.typeName»Iterator(iterator);
					}
				}
			}

		«ENDFOR»
		final class MappedSpliterator<A, B> implements Spliterator<B> {
			private final Spliterator<A> spliterator;
			private final F<A, B> f;

			MappedSpliterator(final Spliterator<A> spliterator, final F<A, B> f) {
				this.spliterator = spliterator;
				this.f = f;
			}

			@Override
			public boolean tryAdvance(final Consumer<? super B> action) {
				return this.spliterator.tryAdvance((final A value) -> action.accept(this.f.apply(value)));
			}

			@Override
			public void forEachRemaining(final Consumer<? super B> action) {
				this.spliterator.forEachRemaining((final A value) -> action.accept(this.f.apply(value)));
			}

			@Override
			public Spliterator<B> trySplit() {
				return new MappedSpliterator<>(this.spliterator.trySplit(), this.f);
			}

			@Override
			public long estimateSize() {
				return this.spliterator.estimateSize();
			}

			@Override
			public long getExactSizeIfKnown() {
				return this.spliterator.getExactSizeIfKnown();
			}

			@Override
			public int characteristics() {
				return this.spliterator.characteristics();
			}

			@Override
			public boolean hasCharacteristics(final int characteristics) {
				return this.spliterator.hasCharacteristics(characteristics);
			}
		}

		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»Spliterator implements Spliterator.Of«type.typeName» {
				final Spliterator<«type.boxedName»> spliterator;

				private «type.typeName»Spliterator(final Spliterator<«type.boxedName»> spliterator) {
					this.spliterator = spliterator;
				}

				@Override
				public Spliterator.Of«type.typeName» trySplit() {
					final Spliterator<«type.boxedName»> split = this.spliterator.trySplit();
					if (split == null) {
						return null;
					} else {
						return getSpliterator(split);
					}
				}

				@Override
				public long estimateSize() {
					return this.spliterator.estimateSize();
				}

				@Override
				public int characteristics() {
					return this.spliterator.characteristics();
				}

				@Override
				public boolean tryAdvance(final «type.typeName»Consumer action) {
					return this.spliterator.tryAdvance(action::accept);
				}

				static Spliterator.Of«type.typeName» getSpliterator(final Spliterator<«type.boxedName»> iterator) {
					if (iterator instanceof Spliterator.Of«type.typeName») {
						return (Spliterator.Of«type.typeName») iterator;
					} else {
						return new «type.typeName»Spliterator(iterator);
					}
				}
			}

		«ENDFOR»
		final class Product2Iterator<A1, A2, B> implements Iterator<B> {
			private final Iterator<A1> iterator1;
			private final Iterable<A2> iterable2;
			private final F2<A1, A2, B> f;
			private A1 a1;
			private Iterator<A2> iterator2;

			public Product2Iterator(final Iterable<A1> iterable1, final Iterable<A2> iterable2, final F2<A1, A2, B> f) {
				this.iterator1 = iterable1.iterator();
				this.iterable2 = iterable2;
				this.f = f;
				this.a1 = iterator1.next();
				this.iterator2 = iterable2.iterator();
			}

			@Override
			public boolean hasNext() {
				return iterator1.hasNext() || iterator2.hasNext();
			}

			@Override
			public B next() {
				if (iterator2.hasNext()) {
					return f.apply(a1, iterator2.next());
				} else if (iterator1.hasNext()) {
					a1 = iterator1.next();
					iterator2 = iterable2.iterator();
					return f.apply(a1, iterator2.next());
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class Product3Iterator<A1, A2, A3, B> implements Iterator<B> {
			private final Iterator<A1> iterator1;
			private final Iterable<A2> iterable2;
			private final Iterable<A3> iterable3;
			private final F3<A1, A2, A3, B> f;
			private A1 a1;
			private A2 a2;
			private Iterator<A2> iterator2;
			private Iterator<A3> iterator3;

			public Product3Iterator(final Iterable<A1> iterable1, final Iterable<A2> iterable2, final Iterable<A3> iterable3, final F3<A1, A2, A3, B> f) {
				this.iterator1 = iterable1.iterator();
				this.iterable2 = iterable2;
				this.iterable3 = iterable3;
				this.f = f;
				this.a1 = iterator1.next();
				this.iterator2 = iterable2.iterator();
				this.a2 = iterator2.next();
				this.iterator3 = iterable3.iterator();
			}

			@Override
			public boolean hasNext() {
				return iterator1.hasNext() || iterator2.hasNext() || iterator3.hasNext();
			}

			@Override
			public B next() {
				if (iterator3.hasNext()) {
					return f.apply(a1, a2, iterator3.next());
				} else if (iterator2.hasNext()) {
					a2 = iterator2.next();
					iterator3 = iterable3.iterator();
					return f.apply(a1, a2, iterator3.next());
				} else if (iterator1.hasNext()) {
					a1 = iterator1.next();
					iterator2 = iterable2.iterator();
					a2 = iterator2.next();
					iterator3 = iterable3.iterator();
					return f.apply(a1, a2, iterator3.next());
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		abstract class AbstractImmutableCollection<A> extends AbstractCollection<A> {
			@Override
			public final boolean add(final A a) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean remove(final Object o) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeIf(final Predicate<? super A> filter) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean retainAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}
		}

		abstract class AbstractImmutableList<A> extends AbstractList<A> {
			@Override
			public final boolean add(final A a) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final int index, final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean remove(final Object o) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeIf(final Predicate<? super A> filter) {
				throw new UnsupportedOperationException();
			}

			@Override
			protected final void removeRange(final int fromIndex, final int toIndex) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void replaceAll(final UnaryOperator<A> operator) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean retainAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final A set(final int index, final A element) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void sort(final Comparator<? super A> c) {
				throw new UnsupportedOperationException();
			}
		}

		abstract class AbstractImmutableSet<A> extends AbstractSet<A> {
			@Override
			public final boolean add(final A a) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean remove(final Object o) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeIf(final Predicate<? super A> filter) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean retainAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}
		}

		abstract class AbstractImmutableMap<K, A> extends AbstractMap<K, A> {
			@Override
			public void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public A compute(final K key, final BiFunction<? super K, ? super A, ? extends A> remappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A computeIfAbsent(final K key, final Function<? super K, ? extends A> mappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A computeIfPresent(final K key, final BiFunction<? super K, ? super A, ? extends A> remappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A merge(final K key, final A value, final BiFunction<? super A, ? super A, ? extends A> remappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public void putAll(final Map<? extends K, ? extends A> m) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A putIfAbsent(final K key, final A value) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A remove(final Object key) {
				throw new UnsupportedOperationException();
			}

			@Override
			public boolean remove(final Object key, final Object value) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A replace(final K key, final A value) {
				throw new UnsupportedOperationException();
			}

			@Override
			public boolean replace(final K key, final A oldValue, final A newValue) {
				throw new UnsupportedOperationException();
			}

			@Override
			public void replaceAll(final BiFunction<? super K, ? super A, ? extends A> function) {
				throw new UnsupportedOperationException();
			}
		}

		final class ArrayCollection<A> extends AbstractCollection<A> {
			private final Object[] arr;

			ArrayCollection(final Object[] arr) {
				this.arr = arr;
			}

			@Override
			public Iterator<A> iterator() {
				return new ArrayIterator<>(arr);
			}

			@Override
			public int size() {
				return arr.length;
			}

			@Override
			public Object[] toArray() {
				return arr;
			}
		}

		final class ImmutableArrayList<A> extends AbstractImmutableList<A> implements RandomAccess, Serializable {
			private final Object[] arr;

			// Assume arr.length > 0
			ImmutableArrayList(final Object[] arr) {
				this.arr = arr;
			}

			@Override
			public A get(final int index) {
				return (A) arr[index];
			}

			@Override
			public int size() {
				return arr.length;
			}

			@Override
			public void forEach(final Consumer<? super A> action) {
				for (final Object value : arr) {
					action.accept((A) value);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new ArrayIterator<>(arr);
			}

			@Override
			public Spliterator<A> spliterator() {
				return Spliterators.spliterator(arr, Spliterator.ORDERED | Spliterator.IMMUTABLE);
			}
		}
	''' }
}
