package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.collection.Common" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.AbstractList;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.RandomAccess;
		import java.util.Spliterator;

		import jcats.Indexed;
		import jcats.Sized;
		import «Constants.F»;
		«FOR type : Type.javaUnboxedTypes»
			import «Constants.FUNCTION».«type.typeName»ObjectF;
			import «Constants.FUNCTION».Int«type.typeName»F;
		«ENDFOR»

		import static java.util.Objects.requireNonNull;

		«FOR type : Type.values»
			«IF type == Type.OBJECT»
				final class ArrayIterator<A> implements Iterator<A> {
			«ELSEIF type == Type.BOOL»
				final class BoolArrayIterator implements Iterator<Boolean> {
			«ELSE»
				final class «type.typeName»ArrayIterator implements PrimitiveIterator.Of«type.javaPrefix» {
			«ENDIF»
				private int i;
				private final «type.javaName»[] array;

				«IF type != Type.OBJECT»«type.typeName»«ENDIF»ArrayIterator(final «type.javaName»[] array) {
					this.array = array;
				}

				@Override
				public boolean hasNext() {
					return (i != array.length);
				}

				@Override
				«IF type == Type.OBJECT»
					public A next() {
				«ELSEIF type == Type.BOOL»
					public Boolean next() {
				«ELSE»
					public «type.javaName» next«type.javaPrefix»() {
				«ENDIF»
					if (i >= array.length) {
						throw new NoSuchElementException();
					} else {
						return («type.genericName») array[i++];
					}
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

		«FOR type : Type.javaUnboxedTypes»
			final class Mapped«type.typeName»ObjectIterator<A> implements Iterator<A> {
				private final PrimitiveIterator.Of«type.javaPrefix» iterator;
				private final «type.typeName»ObjectF<A> f;

				Mapped«type.typeName»ObjectIterator(final PrimitiveIterator.Of«type.javaPrefix» iterator, final «type.typeName»ObjectF<A> f) {
					this.iterator = iterator;
					this.f = f;
				}

				@Override
				public boolean hasNext() {
					return iterator.hasNext();
				}

				@Override
				public A next() {
					return f.apply(iterator.next«type.javaPrefix»());
				}
			}
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
			final class Table«type.typeName»Iterator implements PrimitiveIterator.Of«type.javaPrefix» {
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
				public «type.javaName» next«type.javaPrefix»() {
					if (i >= size) {
						throw new NoSuchElementException();
					} else {
						return f.apply(i++);
					}
				}
			}

		«ENDFOR»
		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»Iterator implements PrimitiveIterator.Of«type.javaPrefix» {
				final Iterator<«type.boxedName»> iterator;

				private «type.javaPrefix»Iterator(final Iterator<«type.boxedName»> iterator) {
					this.iterator = iterator;
				}

				@Override
				public boolean hasNext() {
					return iterator.hasNext();
				}

				@Override
				public «type.javaName» next«type.javaPrefix»() {
					return iterator.next();
				}

				static PrimitiveIterator.Of«type.javaPrefix» getIterator(final Iterator<«type.boxedName»> iterator) {
					if (iterator instanceof PrimitiveIterator.Of«type.javaPrefix») {
						return (PrimitiveIterator.Of«type.javaPrefix») iterator;
					} else {
						return new «type.javaPrefix»Iterator(iterator);
					}
				}
			}

			final class Empty«type.typeName»Iterator implements PrimitiveIterator.Of«type.javaPrefix» {
				private static final Empty«type.typeName»Iterator INSTANCE = new Empty«type.typeName»Iterator();

				private Empty«type.javaPrefix»Iterator() {
				}

				@Override
				public boolean hasNext() {
					return false;
				}

				@Override
				public «type.javaName» next«type.javaPrefix»() {
					throw new NoSuchElementException();
				}

				static Empty«type.typeName»Iterator empty«type.typeName»Iterator() {
					return INSTANCE;
				}
			}

		«ENDFOR»
		«FOR type : Type.values.filter[it != Type.BOOL]»
			«IF type == Type.OBJECT»
				final class BufferedList<A> {
			«ELSE»
				final class Buffered«type.typeName»List {
			«ENDIF»
				private final BufferedListNode head = new BufferedListNode();
				private BufferedListNode last = head;

				void append(final «type.genericName» value) {
					«IF type == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					if (last.size < 32) {
						last.values[last.size++] = value;
					} else {
						final BufferedListNode newLast = new BufferedListNode();
						last.next = newLast;
						last = newLast;
						last.values[0] = value;
						last.size = 1;
					}
				}

				«IF type == Type.OBJECT»
					Iterator<A> iterator() {
				«ELSE»
					PrimitiveIterator.Of«type.javaPrefix» iterator() {
				«ENDIF»
					return new BufferedListIterator«IF type == Type.OBJECT»<>«ENDIF»(head);
				}

				static final class BufferedListNode {
					final «type.javaName»[] values = new «type.javaName»[32];
					int size;
					BufferedListNode next;
				}

				«IF type == Type.OBJECT»
					static final class BufferedListIterator<A> implements Iterator<A> {
				«ELSE»
					static final class BufferedListIterator implements PrimitiveIterator.Of«type.javaPrefix» {
				«ENDIF»
					BufferedListNode node;
					int i;

					BufferedListIterator(final BufferedListNode node) {
						this.node = node;
					}

					@Override
					public boolean hasNext() {
						return (i < node.size);
					}

					@Override
					public «type.genericName» next«IF type != Type.OBJECT»«type.javaPrefix»«ENDIF»() {
						if (i < node.size) {
							final «type.javaName» value = node.values[i];
							«IF type == Type.OBJECT»
								node.values[i] = null;
							«ENDIF»
							i++;
							if (i == node.size && node.next != null) {
								i = 0;
								node = node.next;
							}
							return («type.genericName») value;
						} else {
							throw new NoSuchElementException();
						}
					}
				}
			}

		«ENDFOR»
		class IndexedIterableAsList<A, I extends Iterable<A> & Indexed<A> & Sized> extends AbstractList<A> implements RandomAccess {
			final I iterable;

			IndexedIterableAsList(final I iterable) {
				this.iterable = iterable;
			}

			@Override
			public A get(final int index) {
				return iterable.get(index);
			}

			@Override
			public int size() {
				return iterable.size();
			}

			@Override
			public Iterator<A> iterator() {
				return iterable.iterator();
			}

			@Override
			public Spliterator<A> spliterator() {
				return iterable.spliterator();
			}
		}
	''' }
}
