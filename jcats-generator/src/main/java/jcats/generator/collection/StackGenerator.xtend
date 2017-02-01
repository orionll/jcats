package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class StackGenerator implements ClassGenerator {
	override className() { Constants.STACK }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.Spliterator;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.FUNCTION».BoolF;
		import «Constants.F»;
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		import «Constants.EQUATABLE»;
		import «Constants.OPTION»;
		import «Constants.ORD»;
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static java.util.Spliterators.spliteratorUnknownSize;
		import static «Constants.F».id;
		import static «Constants.OPTION».none;
		import static «Constants.OPTION».some;
		import static «Constants.P».p;
		import static «Constants.COMMON».iterableToString;
		import static «Constants.COMMON».iterableHashCode;


		public final class Stack<A> implements Iterable<A>, Equatable<Stack<A>>, Serializable {
			private static final Stack NIL = new Stack(null, null);

			final A head;
			Stack<A> tail;

			private Stack(final A head, final Stack<A> tail) {
				this.head = head;
				this.tail = tail;
			}

			/**
			 * O(size)
			 */
			public int size() {
				int len = 0;
				Stack<A> stack = this;
				while (stack.isNotEmpty()) {
					if (len == Integer.MAX_VALUE) {
						throw new IndexOutOfBoundsException("Size overflow");
					}
					stack = stack.tail;
					len++;
				}
				return len;
			}

			/**
			 * O(1)
			 */
			public boolean isEmpty() {
				return (this == NIL);
			}

			/**
			 * O(1)
			 */
			public boolean isNotEmpty() {
				return (this != NIL);
			}

			/**
			 * O(1)
			 */
			public A head() {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return head;
				}
			}

			/**
			 * O(1)
			 */
			public Stack<A> tail() {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return tail;
				}
			}

			/**
			 * O(1)
			 */
			public Option<A> headOption() {
				return isEmpty() ? none() : some(head);
			}

			/**
			 * O(1)
			 */
			public Stack<A> prepend(final A value) {
				return new Stack<>(requireNonNull(value), this);
			}

			/**
			 * O(size)
			 */
			public Stack<A> append(final A value) {
				final StackBuilder<A> builder = new StackBuilder<>();
				builder.appendStack(this);
				builder.append(value);
				return builder.build();
			}

			/**
			 * O(size)
			 */
			public Stack<A> concat(final Stack<A> suffix) {
				requireNonNull(suffix);
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					final StackBuilder<A> builder = new StackBuilder<>();
					builder.appendStack(this);
					return builder.prependToStack(suffix);
				}
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public Stack<A> appendAll(final Iterable<A> suffix) {
				if (suffix instanceof Stack) {
					return concat((Stack<A>) suffix);
				} else {
					final StackBuilder<A> builder = new StackBuilder<>();
					builder.appendStack(this);
					builder.appendAll(suffix);
					return builder.build();
				}
			}

			/**
			 * O(prefix.size)
			 */
			public Stack<A> prependAll(final Iterable<A> prefix) {
				final StackBuilder<A> builder = new StackBuilder<>();
				builder.appendAll(prefix);
				return builder.prependToStack(this);
			}

			/**
			 * O(size)
			 */
			public <B> Stack<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return nil();
				} else if (f == F.id()) {
					return (Stack<B>) this;
				} else {
					final StackBuilder<B> builder = new StackBuilder<>();
					Stack<A> stack = this;
					while (stack.isNotEmpty()) {
						builder.append(f.apply(stack.head));
						stack = stack.tail;
					}
					return builder.build();
				}
			}

			public <B> Stack<B> flatMap(final F<A, Stack<B>> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return nil();
				} else {
					final StackBuilder<B> builder = new StackBuilder<>();
					Stack<A> stack = this;
					while (stack.isNotEmpty()) {
						builder.appendStack(f.apply(stack.head));
						stack = stack.tail;
					}
					return builder.build();
				}
			}

			public Stack<A> filter(final BoolF<A> predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return nil();
				} else {
					final StackBuilder<A> builder = new StackBuilder<>();
					Stack<A> stack = this;
					while (stack.isNotEmpty()) {
						if (predicate.apply(stack.head)) {
							builder.append(stack.head);
						}
						stack = stack.tail;
					}
					return builder.build();
				}
			}

			public Stack<A> take(final int n) {
				if (isEmpty() || n <= 0) {
					return nil();
				} else {
					final StackBuilder<A> builder = new StackBuilder<>();
					Stack<A> stack = this;
					int i = 0;
					while (!stack.isEmpty() && i < n) {
						builder.append(stack.head);
						stack = stack.tail;
						i++;
					}
					return builder.build();
				}
			}

			public boolean contains(final A value) {
				requireNonNull(value);
				Stack<A> stack = this;
				while (stack.isNotEmpty()) {
					if (stack.head.equals(value)) {
						return true;
					}
					stack = stack.tail;
				}
				return false;
			}

			public Stack<A> sortBy(final Ord<A> ord) {
				throw new UnsupportedOperationException("Stack.sortBy");
			}

			public static <A> Stack<A> nil() {
				return NIL;
			}

			public static <A> Stack<A> singleStack(final A value) {
				return new Stack<>(requireNonNull(value), nil());
			}

			@SafeVarargs
			public static <A> Stack<A> stack(final A... values) {
				Stack<A> stack = nil();
				for (int i = values.length - 1; i >= 0; i--) {
					stack = new Stack<>(requireNonNull(values[i]), stack);
				}
				return stack;
			}

			/**
			 * Synonym for {@link #stack}
			 */
			@SafeVarargs
			public static <A> Stack<A> of(final A... values) {
				return stack(values);
			}

			public static <A> Stack<A> fromIterable(final Iterable<A> values) {
				return new StackBuilder<A>().appendAll(values).build();
			}

			«join»

			@Override
			public Iterator<A> iterator() {
				return isEmpty() ? emptyIterator() : new StackIterator<>(this);
			}

			@Override
			public Spliterator<A> spliterator() {
				return isEmpty() ? emptySpliterator() : spliteratorUnknownSize(iterator(),  Spliterator.ORDERED | Spliterator.IMMUTABLE);
			}

			«stream(Type.OBJECT)»

			«parallelStream(Type.OBJECT)»

			«hashcode»

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof Stack<?>) {
					Stack<?> stack1 = this;
					Stack<?> stack2 = (Stack<?>) obj;
					while (stack1.isNotEmpty()) {
						if (stack2.isEmpty() || !stack1.head.equals(stack2.head)) {
							return false;
						}
						stack1 = stack1.tail;
						stack2 = stack2.tail;
					}
					return stack2.isEmpty();
				} else {
					return false;
				}
			}

			«toStr»

			«zip»

			«zipWith»

			/**
			 * O(size)
			 */
			public Stack<P<A, Integer>> zipWithIndex() {
				if (isEmpty()) {
					return nil();
				} else {
					final StackBuilder<P<A, Integer>> builder = new StackBuilder<>();
					Stack<A> stack = this;
					int index = 0;
					while (stack.isNotEmpty()) {
						builder.append(p(stack.head(), index));
						stack = stack.tail;
						if (index == Integer.MAX_VALUE && !stack.isEmpty()) {
							throw new IndexOutOfBoundsException("Index overflow");
						}
						index++;
					}
					return builder.build();
				}
			}

			«zipN»
			«zipWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["stack" + it + ".isEmpty()"].join(" || ")») {
					return nil();
				} else {
					«FOR i : 1 .. arity»
						Stack<A«i»> i«i» = stack«i»;
					«ENDFOR»
					final StackBuilder<B> builder = new StackBuilder<>();
					while («(1 .. arity).map["!i" + it + ".isEmpty()"].join(" && ")») {
						builder.append(f.apply(«(1 .. arity).map["i" + it + ".head"].join(", ")»));
						«FOR i : 1 .. arity»
							i«i» = i«i».tail;
						«ENDFOR»
					}
					return builder.build();
				}
			''']»
			«productN»
			«productWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["stack" + it + ".isEmpty()"].join(" || ")») {
					return nil();
				} else {
					final StackBuilder<B> builder = new StackBuilder<>();
					«FOR i : 1 .. arity»
						«(1 ..< i).map["\t"].join»for (final A«i» a«i» : stack«i») {
					«ENDFOR»
						«(1 ..< arity).map["\t"].join»builder.append(requireNonNull(f.apply(«(1 .. arity).map["a" + it].join(", ")»)));
					«FOR i : 1 .. arity»
						«(1 ..< arity - i + 1).map["\t"].join»}
					«ENDFOR»
					return builder.build();
				}
			''']»
			«cast(#["A"], #[], #["A"])»

			public static <A> StackBuilder<A> builder() {
				return new StackBuilder<>();
			}
		}

		final class StackIterator<A> implements Iterator<A> {
			private Stack<A> stack;

			StackIterator(final Stack<A> stack) {
				this.stack = stack;
			}

			@Override
			public boolean hasNext() {
				return stack.isNotEmpty();
			}

			@Override
			public A next() {
				if (stack.isEmpty()) {
					throw new NoSuchElementException();
				} else {
					final A result = stack.head;
					stack = stack.tail;
					return result;
				}
			}
		}
	''' }
}
