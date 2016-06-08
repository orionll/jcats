package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.collection.Common" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.NoSuchElementException;

		import «Constants.F»;
		import «Constants.FUNCTION».IntObjectF;

		import static java.util.Objects.requireNonNull;

		final class ArrayIterator<A> implements Iterator<A> {
			private int i;
			private final Object[] array;

			ArrayIterator(final Object[] array) {
				this.array = array;
			}

			@Override
			public boolean hasNext() {
				return (i != array.length);
			}

			@Override
			public A next() {
				if (i >= array.length) {
					throw new NoSuchElementException();
				} else {
					return (A) array[i++];
				}
			}
		}

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

		final class BufferedList<A> {
			private final BufferedListNode head = new BufferedListNode();
			private BufferedListNode last = head;

			void append(final A value) {
				requireNonNull(value);
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

			Iterator<A> iterator() {
				return new BufferedListIterator<>(head);
			}

			static final class BufferedListNode {
				final Object[] values = new Object[32];
				int size;
				BufferedListNode next;
			}

			static final class BufferedListIterator<A> implements Iterator<A> {
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
				public A next() {
					if (i < node.size) {
						final Object value = node.values[i];
						node.values[i++] = null;
						if (i == node.size && node.next != null) {
							i = 0;
							node = node.next;
						}
						return (A) value;
					} else {
						throw new NoSuchElementException();
					}
				}
			}
		}
	''' }
}
