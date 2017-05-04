package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.collection.Common" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;

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
					if (c1.size() == c2.size()) {
						final «type.iteratorWildcardName» iterator1 = c1.iterator();
						final «type.iteratorWildcardName» iterator2 = c2.iterator();
						while (iterator1.hasNext()) {
							«IF type == Type.OBJECT»
								final Object o1 = iterator1.next();
								final Object o2 = iterator2.next();
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

			static int iterableHashCode(final Iterable<?> iterable) {
				int hashCode = 1;
				for (final Object value : iterable) {
					hashCode = 31 * hashCode + value.hashCode();
				}
				return hashCode;
			}

			static int keyValueHashCode(final KeyValue<?, ?> keyValue) {
				int result = 0;
				for (final P<?, ?> entry : keyValue) {
					result += entry.hashCode();
				}
				return result;
			}

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
					return (i < array.length);
				}

				@Override
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					return «type.genericCast»array[i++];
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
					return (i >= 0);
				}

				@Override
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					return «type.genericCast»array[i--];
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
					return iterator.hasNext();
				}

				@Override
				public «type.javaName» next«type.typeName»() {
					return iterator.next();
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
	''' }
}
