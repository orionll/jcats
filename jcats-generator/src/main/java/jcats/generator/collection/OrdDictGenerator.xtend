package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

class OrdDictGenerator implements ClassGenerator {
	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "OrdDict" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Iterator;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static jcats.Order.*;
		import static jcats.P.p;
		import static jcats.collection.Common.*;

		public final class OrdDict<K, A> implements KeyValue<K, A> {
			static final boolean RED = false;
			static final boolean BLACK = true;

			final P<K, A> entry;
			final OrdDict<K, A> left;
			final OrdDict<K, A> right;
			final Ord<K> ord;
			final boolean color;

			OrdDict(final P<K, A> entry, final OrdDict<K, A> left, final OrdDict<K, A> right, final Ord<K> ord, final boolean color) {
				this.entry = entry;
				this.left = left;
				this.right = right;
				this.ord = ord;
				this.color = color;
			}

			public static <K, A> OrdDict<K, A> emptyOrdDict(final Ord<K> ord) {
				return new OrdDict<>(null, null, null, ord, BLACK);
			}

			@Override
			public A getOrNull(final K key) {
				requireNonNull(key);
				if (entry == null) {
					return null;
				}

				OrdDict<K, A> dict = this;
				while (true) {
					final Order order = ord.compare(key, dict.entry.get1());
					if (order == EQ) {
						return dict.entry.get2();
					} else if (order == LT) {
						if (dict.left == null) {
							return null;
						} else {
							dict = dict.left;
						}
					} else if (order == GT) {
						if (dict.right == null) {
							return null;
						} else {
							dict = dict.right;
						}
					} else {
						throw nullOrder(order);
					}
				}
			}

			public OrdDict<K, A> put(final K key, final A value) {
				requireNonNull(key);
				requireNonNull(value);

				if (entry == null) {
					// The color of the root node does not matter
					return new OrdDict<>(p(key, value), null, null, ord, BLACK);
				} else {
					return update(key, value);
				}
			}

			private OrdDict<K, A> update(final K key, final A value) {
				final Order order = ord.compare(key, entry.get1());
				if (order == EQ) {
					if (key == entry.get1() && value == entry.get2()) {
						return this;
					} else {
						return new OrdDict<>(p(key, value), left, right, ord, color);
					}
				} else if (order == LT) {
					if (left == null) {
						assert right == null; // Right is null because the tree is left-leaning
						final OrdDict<K, A> newLeft = new OrdDict<>(p(key, value), null, null, ord, RED);
						return new OrdDict<>(entry, newLeft, null, ord, color);
					} else {
						final OrdDict<K, A> newLeft = left.update(key, value);
						if (newLeft == left) {
							return this;
						} else if (newLeft.color == RED && newLeft.left != null && newLeft.left.color == RED) {
							final OrdDict<K, A> newNewLeft = new OrdDict<>(newLeft.left.entry, newLeft.left.left, newLeft.left.right, ord, BLACK);
							final OrdDict<K, A> newRight = new OrdDict<>(entry, newLeft.right, right, ord, BLACK);
							return new OrdDict<>(newLeft.entry, newNewLeft, newRight, ord, RED);
						} else {
							return new OrdDict<>(entry, newLeft, right, ord, color);
						}
					}
				} else if (order == GT) {
					if (right == null) {
						if (left == null) {
							final OrdDict<K, A> newLeft = new OrdDict<>(entry, null, null, ord, RED);
							return new OrdDict<>(p(key, value), newLeft, null, ord, color);
						} else {
							assert left.color == RED; // The left node is red or otherwise the corresponding 2-3 tree is unbalanced
							final OrdDict<K, A> newLeft = new OrdDict<>(left.entry, left.left, left.right, ord, BLACK);
							final OrdDict<K, A> newRight = new OrdDict<>(p(key, value), null, null, ord, BLACK);
							return new OrdDict<>(entry, newLeft, newRight, ord, RED);
						}
					} else {
						final OrdDict<K, A> newRight = right.update(key, value);
						if (newRight == right) {
							return this;
						} else if (left.color == RED && newRight.color == RED) {
							final OrdDict<K, A> newLeft = new OrdDict<>(left.entry, left.left, left.right, ord, BLACK);
							final OrdDict<K, A> newNewRight = new OrdDict<>(newRight.entry, newRight.left, newRight.right, ord, BLACK);
							return new OrdDict<>(entry, newLeft, newNewRight, ord, RED);
						} else if (left.color == BLACK && newRight.color == RED) {
							final OrdDict<K, A> newLeft = new OrdDict<>(entry, left, newRight.left, ord, RED);
							return new OrdDict<>(newRight.entry, newLeft, newRight.right, ord, color);
						} else {
							return new OrdDict<>(entry, left, newRight, ord, color);
						}
					}
				} else {
					throw nullOrder(order);
				}
			}

			private static NullPointerException nullOrder(final Order order) {
				if (order == null) {
					return new NullPointerException("Ord.compare() returned null");
				} else {
					throw new AssertionError("Ord.compare() returned unexpected value");
				}
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return (entry == null) ? Collections.emptyIterator() : new OrdDictIterator<>(this);
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				if (entry != null) {
					traverse(action);
				}
			}

			private void traverse(final Consumer<? super P<K, A>> action) {
				if (left != null) {
					left.traverse(action);
				}
				action.accept(entry);
				if (right != null) {
					right.traverse(action);
				}
			}

			@Override
			public int size() {
				throw new UnsupportedOperationException();
			}

			public void print() {
				if (entry != null) {
					print("");
				}
			}

			private void print(final String prefix) {
				System.out.println(prefix + entry + (color == RED ? " (Red)" : " (Black)"));
				if (left != null) {
					left.print(prefix + "  ");
				}
				if (right != null) {
					right.print(prefix + "  ");
				}
			}

			«keyValueEquals»

			«keyValueHashCode»

			@Override
			public String toString() {
				return iterableToString(this, "OrdDict");
			}

			«cast(#["K", "A"], #[], #["A"])»
		}

		final class OrdDictIterator<K, A> implements Iterator<P<K, A>> {
			private final OrdDict<K, A> root;
			private Stack<OrdDict<K, A>> stack;

			OrdDictIterator(final OrdDict<K, A> root) {
				this.root = root;
			}

			@Override
			public boolean hasNext() {
				return (stack == null || !stack.isEmpty());
			}

			@Override
			public P<K, A> next() {
				if (stack == null) {
					stack = Stack.nil();
					for (OrdDict<K, A> dict = root; dict != null; dict = dict.left) {
						stack = stack.prepend(dict);
					}
				}

				final OrdDict<K, A> result = stack.head();
				stack = stack.tail;

				if (result.right != null) {
					for (OrdDict<K, A> dict = result.right; dict != null; dict = dict.left) {
						stack = stack.prepend(dict);
					}
				}

				return result.entry;
			}
		}
	''' }
}