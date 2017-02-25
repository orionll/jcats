package jcats.generator

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.Common" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;


		«FOR type : Type.javaUnboxedTypes»
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
		«FOR type : Type.javaUnboxedTypes»

			final class «type.typeName»SingletonIterator implements «type.iteratorGenericName» {
				private final «type.genericName» value;
				private boolean hasNext = true;

				«type.typeName»SingletonIterator(final «type.genericName» value) {
					this.value = value;
				}

				@Override
				public boolean hasNext() {
					return hasNext;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (hasNext) {
						hasNext = false;
						return value;
					} else {
						throw new NoSuchElementException();
					}
				}
			}
		«ENDFOR»
	''' }
}
