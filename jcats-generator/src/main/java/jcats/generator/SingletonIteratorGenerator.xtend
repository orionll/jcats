package jcats.generator

final class SingletonIteratorGenerator implements ClassGenerator {
	override className() { Constants.JCATS + ".SingletonIterator" }
	
	override sourceCode() { '''
		package «Constants.JCATS»;
		
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		
		final class SingletonIterator<A> implements Iterator<A> {
			private A a;

			SingletonIterator(final A a) {
				this.a = a;
			}

			@Override
			public boolean hasNext() {
				return (a != null);
			}

			@Override
			public A next() {
				if (a == null) {
					throw new NoSuchElementException();
				} else {
					final A n = a;
					a = null;
					return n;
				}
			}
		}
	''' }
}