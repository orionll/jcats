package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class SortedUniqueGenerator implements ClassGenerator {
	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "SortedUnique" }
	def genericName() { "SortedUnique<A>" }
	def diamondName() { "SortedUnique<>" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.PrintWriter;
		import java.io.StringWriter;
		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.List;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».Order.*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;

		public final class SortedUnique<@Covariant A> implements UniqueContainer<A>, Serializable {
			private static final SortedUnique<?> EMPTY =
					new SortedUnique<>(null, null, null, Ord.<Integer>ord(), 0);

			final A entry;
			final SortedUnique<A> left;
			final SortedUnique<A> right;
			private final int size;
			private final Ord<A> ord;
			private final int balance;

			private SortedUnique(final A entry, final SortedUnique<A> left, final SortedUnique<A> right, final Ord<A> ord, final int balance) {
				this.entry = entry;
				this.left = left;
				this.right = right;
				if (entry == null) {
					this.size = 0;
				} else {
					this.size = ((left == null) ? 0 : left.size) + ((right == null) ? 0 : right.size) + 1;
				}
				this.ord = ord;
				this.balance = balance;
			}

			public Ord<A> ord() {
				return this.ord;
			}

			@Override
			public boolean contains(final A key) {
				requireNonNull(key);
				if (this.entry == null) {
					return false;
				}

				SortedUnique<A> unique = this;
				while (true) {
					final Order order = this.ord.compare(key, unique.entry);
					if (order == EQ) {
						return true;
					} else if (order == LT) {
						if (unique.left == null) {
							return false;
						} else {
							unique = unique.left;
						}
					} else if (order == GT) {
						if (unique.right == null) {
							return false;
						} else {
							unique = unique.right;
						}
					} else {
						throw nullOrder(order);
					}
				}
			}

			public SortedUnique<A> put(final A key) {
				requireNonNull(key);

				if (this.entry == null) {
					return new SortedUnique<>(key, null, null, this.ord, 0);
				} else {
					return update(key, new InsertResult());
				}
			}

			private «genericName» update(final A key, final InsertResult result) {
				«AVLCommon.update(genericName, diamondName, "entry", "key", "key == this.entry", "key")»
			}

			«AVLCommon.insertAndRotateRight(genericName, diamondName)»

			«AVLCommon.insertAndRotateLeft(genericName, diamondName)»

			public SortedUnique<A> remove(final A key) {
				requireNonNull(key);
				if (this.entry == null) {
					return this;
				} else {
					final SortedUnique<A> newUnique = delete(key, new DeleteResult<>());
					if (newUnique == null) {
						return emptySortedUniqueBy(this.ord);
					} else {
						return newUnique;
					}
				}
			}

			private SortedUnique<A> delete(final A key, final DeleteResult<A> result) {
				«AVLCommon.delete(genericName, diamondName, "entry")»
			}

			«AVLCommon.deleteMaximum(genericName, diamondName, "DeleteResult<A>")»

			«AVLCommon.deleteAndRotateLeft(genericName, diamondName, "A", "DeleteResult<A>")»

			«AVLCommon.deleteAndRotateRight(genericName, diamondName, "DeleteResult<A>")»

			private static NullPointerException nullOrder(final Order order) {
				if (order == null) {
					return new NullPointerException("Ord.compare() returned null");
				} else {
					throw new AssertionError("Ord.compare() returned unexpected value: " + order);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return (this.entry == null) ? Collections.emptyIterator() : new SortedUniqueIterator<>(this);
			}

			@Override
			public Spliterator<A> spliterator() {
				if (this.entry == null) {
					return Spliterators.emptySpliterator();
				} else {
					return Spliterators.spliterator(iterator(), size(),
						Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE);
				}
			}

			@Override
			public void foreach(final Eff<A> action) {
				if (this.entry != null) {
					traverse(action);
				}
			}

			private void traverse(final Eff<A> action) {
				if (this.left != null) {
					this.left.traverse(action);
				}
				action.apply(this.entry);
				if (this.right != null) {
					this.right.traverse(action);
				}
			}

			@Override
			public int size() {
				return this.size;
			}

			int checkHeight() {
				final int leftHeight = (this.left == null) ? 0 : this.left.checkHeight();
				final int rightHeight = (this.right == null) ? 0 : this.right.checkHeight();
				if (Math.abs(rightHeight - leftHeight) <= 1) {
					return 1 + Math.max(leftHeight, rightHeight);
				} else {
					throw new AssertionError(String.format("Wrong balance for node %s: left height = %d, right height = %d",
							this.entry, leftHeight, rightHeight));
				}
			}

			«uniqueEquals(Type.OBJECT)»

			«uniqueHashCode»

			@Override
			public String toString() {
				return iterableToString(this, "SortedUnique");
			}

			public static <A extends Comparable<A>> SortedUnique<A> emptySortedUnique() {
				return (SortedUnique<A>) EMPTY;
			}

			public static <K, A> SortedUnique<A> emptySortedUniqueBy(final Ord<A> ord) {
				requireNonNull(ord);
				if (ord == Ord.ord()) {
					return (SortedUnique<A>) EMPTY;
				} else {
					return new SortedUnique<>(null, null, null, ord, 0);
				}
			}

			public static <A extends Comparable<A>> SortedUnique<A> single«shortName»(final A key) {
				return SortedUnique.<A> emptySortedUnique().put(key);
			}

			@SafeVarargs
			public static <A extends Comparable<A>> SortedUnique<A> «shortName.firstToLowerCase»(final A... keys) {
				SortedUnique<A> unique = emptySortedUnique();
				for (final A key : keys) {
					unique = unique.put(key);
				}
				return unique;
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			@SafeVarargs
			public static <A extends Comparable<A>> SortedUnique<A> of(final A... keys) {
				return «shortName.firstToLowerCase»(keys);
			}

			«cast(#["A"], #[], #["A"])»

			static final class InsertResult {
				boolean heightIncreased;
			}

			static final class DeleteResult<A> {
				A entry;
				boolean heightDecreased;
			}
		}

		final class SortedUniqueIterator<A> implements Iterator<A> {
			private final SortedUnique<A> root;
			private Stack<SortedUnique<A>> stack;

			SortedUniqueIterator(final SortedUnique<A> root) {
				this.root = root;
			}

			@Override
			public boolean hasNext() {
				return (this.stack == null || this.stack.isNotEmpty());
			}

			@Override
			public A next() {
				if (this.stack == null) {
					this.stack = Stack.nil();
					for (SortedUnique<A> unique = this.root; unique != null; unique = unique.left) {
						this.stack = this.stack.prepend(unique);
					}
				}

				final SortedUnique<A> result = this.stack.head();
				this.stack = this.stack.tail;

				if (result.right != null) {
					for (SortedUnique<A> unique = result.right; unique != null; unique = unique.left) {
						this.stack = this.stack.prepend(unique);
					}
				}

				return result.entry;
			}
		}
	''' }
}