package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.collection.Common" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.NoSuchElementException;

		import jcats.function.F;

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
	''' }
}
