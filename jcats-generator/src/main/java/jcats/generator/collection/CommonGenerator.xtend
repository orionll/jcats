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

		«FOR type : Type.values»
			import jcats.«IF type != Type.OBJECT»«type.typeName»«ENDIF»Indexed;
		«ENDFOR»
		import jcats.Sized;
		import «Constants.F»;
		«FOR arity : 2 .. Constants.MAX_FUNCTIONS_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		«FOR type : Type.primitives»
			import «Constants.FUNCTION».«type.typeName»ObjectF;
			import «Constants.FUNCTION».«type.typeName»F;
			«FOR toType : Type.primitives»
				import «Constants.FUNCTION».«type.typeName»«toType.typeName»F;
			«ENDFOR»
		«ENDFOR»

		import static java.util.Objects.requireNonNull;

		«FOR type : Type.values»
			final class «IF type == Type.OBJECT»ArrayIterator<A>«ELSE»«type.typeName»ArrayIterator«ENDIF» implements «type.iteratorGenericName» {
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
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					return «type.genericCast»array[i++];
				}
			}

		«ENDFOR»
		«FOR type : Type.values»
			final class Reversed«IF type == Type.OBJECT»ArrayIterator<A>«ELSE»«type.typeName»ArrayIterator«ENDIF» implements «type.iteratorGenericName» {
				private int i;
				private final «type.javaName»[] array;

				Reversed«IF type != Type.OBJECT»«type.typeName»«ENDIF»ArrayIterator(final «type.javaName»[] array) {
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
		«FOR type : Type.values»
			«IF type == Type.OBJECT»
				class IndexedIterableAsList<A, I extends Iterable<A> & Indexed<A> & Sized> extends AbstractList<A> implements RandomAccess {
			«ELSE»
				class «type.typeName»IndexedIterableAsList<I extends Iterable<«type.boxedName»> & «type.typeName»Indexed & Sized> extends AbstractList<«type.boxedName»> implements RandomAccess {
			«ENDIF»
				final I iterable;

				«IF type != Type.OBJECT»«type.typeName»«ENDIF»IndexedIterableAsList(final I iterable) {
					this.iterable = iterable;
				}

				@Override
				public «type.genericBoxedName» get(final int index) {
					return iterable.get(index);
				}

				@Override
				public int size() {
					return iterable.size();
				}

				@Override
				public Iterator<«type.genericBoxedName»> iterator() {
					return iterable.iterator();
				}

				@Override
				public Spliterator<«type.genericBoxedName»> spliterator() {
					return iterable.spliterator();
				}
			}

		«ENDFOR»
	''' }
}
