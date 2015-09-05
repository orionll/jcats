package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ArrayBuilderGenerator implements Generator {
	override className() { Constants.ARRAY + "Builder" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Iterator;

		import static «Constants.ARRAY».emptyArray;
		import static «Constants.ARRAY».singleArray;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;

		public final class ArrayBuilder<A> {
			private ArrayList<A> builder;

			public ArrayBuilder<A> append(final A value) {
				requireNonNull(value);
				if (builder == null) {
					builder = new ArrayList<>();
				}
				builder.add(value);
				return this;
			}

			/**
			 * O(array.size)
			 */
			public ArrayBuilder<A> appendArray(final Array<A> array) {
				if (array.isNotEmpty()) {
					if (builder == null) {
						builder = new ArrayList<>();
					}
					builder.addAll(new ArrayWrapper<>(array.array));
				}
				return this;
			}

			/**
			 * O(iterable.size)
			 */
			public ArrayBuilder<A> appendAll(final Iterable<A> iterable) {
				if (iterable instanceof Array) {
					return appendArray((Array<A>) iterable);
				}

				if (iterable instanceof Collection) {
					final Collection<A> col = (Collection<A>) iterable;
					if (!col.isEmpty()) {
						appendSized(iterable, col.size());
					}
				} else if (iterable instanceof Sized) {
					final Sized sized = (Sized) iterable;
					if (sized.isNotEmpty()) {
						appendSized(iterable, sized.size());
					}
				} else {
					for (final A value : iterable) {
						requireNonNull(value);
						if (builder == null) {
							builder = new ArrayList<>();
						}
						builder.add(value);
					}
				}

				return this;
			}

			private void appendSized(final Iterable<A> iterable, final int iterableSize) {
				if (builder == null) {
					builder = new ArrayList<>();
				}
				builder.ensureCapacity(builder.size() + iterableSize);

				for (final A value : iterable) {
					builder.add(requireNonNull(value));
				}
			}

			public boolean isEmpty() {
				return (builder == null);
			}

			public Array<A> toArray() {
				return isEmpty() ? emptyArray() : new Array<>(builder.toArray());
			}

			private Iterator<A> iterator() {
				return isEmpty() ? emptyIterator() : builder.iterator();
			}

			«toString("ArrayBuilder")»
		}
	''' }
}