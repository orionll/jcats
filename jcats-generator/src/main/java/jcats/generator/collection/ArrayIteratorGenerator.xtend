package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ArrayIteratorGenerator implements Generator {
	override className() { Constants.ARRAY + "Iterator" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;
		
		import java.util.Iterator;
		import java.util.NoSuchElementException;

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
	''' }
}