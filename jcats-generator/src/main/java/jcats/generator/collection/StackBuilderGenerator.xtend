package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class StackBuilderGenerator implements ClassGenerator {
	override className() { Constants.STACK + "Builder" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import static «Constants.STACK».nil;
		import static «Constants.STACK».singleStack;

		public final class StackBuilder<A> {
			private Stack<A> start = nil();
			private Stack<A> tail;
			private boolean exported;

			StackBuilder() {}

			public StackBuilder<A> append(final A value) {
				if (exported) {
					copy();
				}

				final Stack<A> t = singleStack(value);

				if (tail == null) {
					start = t;
				} else {
					tail.tail = t;
				}

				tail = t;
				return this;
			}

			StackBuilder<A> appendStack(Stack<A> stack) {
				while (stack.isNotEmpty()) {
					append(stack.head);
					stack = stack.tail;
				}
				return this;
			}

			public StackBuilder<A> appendAll(final Iterable<A> iterable) {
				iterable.forEach(this::append);
				return this;
			}

			public boolean isEmpty() {
				return start.isEmpty();
			}

			public Stack<A> build() {
				exported = !start.isEmpty();
				return start;
			}

			public Stack<A> prependToStack(final Stack<A> stack) {
				if (isEmpty()) {
					return stack;
				} else {
					if (exported) {
						copy();
					}

					tail.tail = stack;
					return build();
				}
			}

			private void copy() {
				Stack<A> s = start;
				final Stack<A> t = tail;
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