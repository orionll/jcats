package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class ListBuilderGenerator implements ClassGenerator {
	override className() { Constants.LIST + "Builder" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import static «Constants.LIST».nil;
		import static «Constants.LIST».singleList;

		public final class ListBuilder<A> {
			private List<A> start = nil();
			private List<A> tail;
			private boolean exported;

			public ListBuilder<A> append(final A value) {
				if (exported) {
					copy();
				}

				final List<A> t = singleList(value);

				if (tail == null) {
					start = t;
				} else {
					tail.tail = t;
				}

				tail = t;
				return this;
			}

			ListBuilder<A> appendList(List<A> list) {
				while (list.isNotEmpty()) {
					append(list.head);
					list = list.tail;
				}
				return this;
			}

			public ListBuilder<A> appendAll(final Iterable<A> iterable) {
				for (final A value : iterable) {
					append(value);
				}
				return this;
			}

			public boolean isEmpty() {
				return start.isEmpty();
			}

			public List<A> build() {
				exported = !start.isEmpty();
				return start;
			}

			public List<A> prependToList(final List<A> list) {
				if (isEmpty()) {
					return list;
				} else {
					if (exported) {
						copy();
					}

					tail.tail = list;
					return build();
				}
			}

			private void copy() {
				List<A> s = start;
				final List<A> t = tail;
				start = nil();
				tail = null;
				exported = false;
				while (s != t) {
					append(s.head);
					s = s.tail;
				}

				if (t != null) {
					append(t.head);
				}
			}
		}
	''' }
}