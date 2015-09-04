package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ListIteratorGenerator implements Generator {
	override className() { Constants.LIST + "Iterator" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;
		
		import java.util.Iterator;
		import java.util.NoSuchElementException;

		final class ListIterator<A> implements Iterator<A> {
			private List<A> list;

			ListIterator(final List<A> list) {
				this.list = list;
			}

			@Override
			public boolean hasNext() {
				return list.isNotEmpty();
			}

			@Override
			public A next() {
				if (list.isEmpty()) {
					throw new NoSuchElementException();
				} else {
					final A result = list.head;
					list = list.tail;
					return result;
				}
			}
		}
	''' }
}