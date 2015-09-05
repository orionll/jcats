package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ArrayWrapperGenerator implements Generator {
	override className() { Constants.ARRAY + "Wrapper" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;
		
		import java.util.AbstractList;
		import java.util.RandomAccess;

		final class ArrayWrapper<A> extends AbstractList<A> implements RandomAccess {
			private final Object[] array;

			ArrayWrapper(final Object[] array) {
				this.array = array;
			}

			@Override
			public int size() {
				return array.length;
			}

			@Override
			public A get(final int index) {
				return (A) array[index];
			}

			@Override
			public Object[] toArray() {
				return array;
			}
		}
	''' }
}