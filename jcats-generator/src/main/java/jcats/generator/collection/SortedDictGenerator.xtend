package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class SortedDictGenerator implements ClassGenerator {
	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "SortedDict" }
	def genericName() { "SortedDict<K, A>" }
	def diamondName() { "SortedDict<>" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.PrintWriter;
		import java.io.StringWriter;
		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Collections;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.List;
		import java.util.Map;
		import java.util.Map.Entry;
		import java.util.SortedMap;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».Order.*;
		import static «Constants.JCATS».Ord.*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		import static «Constants.STACK».*;

		public final class SortedDict<K, @Covariant A> implements KeyValue<K, A>, Serializable {
			private static final SortedDict<?, ?> EMPTY =
					new SortedDict<>(null, null, null, Ord.<Integer>asc(), 0);

			final P<K, A> entry;
			final SortedDict<K, A> left;
			final SortedDict<K, A> right;
			private final int size;
			private final Ord<K> ord;
			private final int balance;

			private SortedDict(final P<K, A> entry, final SortedDict<K, A> left, final SortedDict<K, A> right, final Ord<K> ord, final int balance) {
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

			public Ord<K> ord() {
				return this.ord;
			}

			@Override
			public A getOrNull(final K key) {
				requireNonNull(key);
				if (this.entry == null) {
					return null;
				}

				SortedDict<K, A> dict = this;
				while (true) {
					final Order order = this.ord.order(key, dict.entry.get1());
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

			public SortedDict<K, A> put(final K key, final A value) {
				requireNonNull(key);
				requireNonNull(value);

				if (this.entry == null) {
					return new SortedDict<>(p(key, value), null, null, this.ord, 0);
				} else {
					return update(key, value, new InsertResult());
				}
			}

			private «genericName» update(final K key, final A value, final InsertResult result) {
				«AVLCommon.update(genericName, diamondName, "key", "entry.get1()", "p(key, value)",
					"key == this.entry.get1() && value == this.entry.get2()", "key, value")»
			}

			«AVLCommon.insertAndRotateRight(genericName, diamondName)»

			«AVLCommon.insertAndRotateLeft(genericName, diamondName)»

			public SortedDict<K, A> remove(final K key) {
				requireNonNull(key);
				if (this.entry == null) {
					return this;
				} else {
					final SortedDict<K, A> newDict = delete(key, new DeleteResult<>());
					if (newDict == null) {
						return emptySortedDictBy(this.ord);
					} else {
						return newDict;
					}
				}
			}

			private SortedDict<K, A> delete(final K key, final DeleteResult<K, A> result) {
				«AVLCommon.delete(genericName, diamondName, "key", "entry.get1()")»
			}

			«AVLCommon.deleteMaximum(genericName, diamondName, "DeleteResult<K, A>")»

			«AVLCommon.deleteAndRotateLeft(genericName, diamondName, "P<K, A>", "DeleteResult<K, A>")»

			«AVLCommon.deleteAndRotateRight(genericName, diamondName, "DeleteResult<K, A>")»

			private static NullPointerException nullOrder(final Order order) {
				if (order == null) {
					return new NullPointerException("Ord.order() returned null");
				} else {
					throw new AssertionError("Ord.order() returned unexpected value: " + order);
				}
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return (this.entry == null) ? Collections.emptyIterator() : new SortedDictIterator<>(this);
			}

			@Override
			public int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				if (this.entry != null) {
					traverse(action);
				}
			}

			private void traverse(final Consumer<? super P<K, A>> action) {
				if (this.left != null) {
					this.left.traverse(action);
				}
				action.accept(this.entry);
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

			private static <K, A> String printNode(final SortedDict<K, A> root) {
				final int maxLevel = maxLevel(root);

				StringWriter sw = new StringWriter();
				try (PrintWriter writer = new PrintWriter(sw)) {
					writer.println();
					printNodeInternal(writer, Collections.singletonList(root), 1, maxLevel);
				}
				return sw.toString();
			}

			private static <K, A> void printNodeInternal(final PrintWriter writer, final List<SortedDict<K, A>> nodes, final int level, final int maxLevel) {
				if (nodes.isEmpty() || isAllElementsNull(nodes)) {
					return;
				}

				final int floor = maxLevel - level;
				final int endgeLines = (int) Math.pow(2, (Math.max(floor - 1, 0)));
				final int firstSpaces = (int) Math.pow(2, (floor)) - 1;
				final int betweenSpaces = (int) Math.pow(2, (floor + 1)) - 1;

				printWhitespaces(writer, firstSpaces);

				final List<SortedDict<K, A>> newNodes = new ArrayList<>();
				for (final SortedDict<K, A> node : nodes) {
					if (node != null) {
						writer.print(node.entry == null ? "null" : node.entry.get1());
						newNodes.add(node.left);
						newNodes.add(node.right);
					} else {
						newNodes.add(null);
						newNodes.add(null);
						writer.print(" ");
					}

					printWhitespaces(writer, betweenSpaces);
				}
				writer.println("");

				for (int i = 1; i <= endgeLines; i++) {
					for (final SortedDict<K, A> node : nodes) {
						printWhitespaces(writer, firstSpaces - i);
						if (node == null) {
							printWhitespaces(writer, endgeLines + endgeLines + i + 1);
							continue;
						}

						if (node.left != null)
							writer.print("/");
						else
							printWhitespaces(writer, 1);

						printWhitespaces(writer, i + i - 1);

						if (node.right != null)
							writer.print("\\");
						else
							printWhitespaces(writer, 1);

						printWhitespaces(writer, endgeLines + endgeLines - i);
					}

					writer.println("");
				}

				printNodeInternal(writer, newNodes, level + 1, maxLevel);
			}

			private static void printWhitespaces(final PrintWriter writer, final int count) {
				for (int i = 0; i < count; i++) {
					writer.print(" ");
				}
			}

			private static <K, A> int maxLevel(final SortedDict<K, A> node) {
				if (node == null || node.entry == null)
					return 0;

				return Math.max(maxLevel(node.left), maxLevel(node.right)) + 1;
			}

			private static <T> boolean isAllElementsNull(final List<T> list) {
				for (final Object object : list) {
					if (object != null)
						return false;
				}

				return true;
			}

			«keyValueEquals»

			«keyValueHashCode»

			@Override
			public String toString() {
				return iterableToString(this, "SortedDict");
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> emptySortedDict() {
				return (SortedDict<K, A>) EMPTY;
			}

			public static <K, A> SortedDict<K, A> emptySortedDictBy(final Ord<K> ord) {
				requireNonNull(ord);
				if (ord == asc()) {
					return (SortedDict<K, A>) EMPTY;
				} else {
					return new SortedDict<>(null, null, null, ord, 0);
				}
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> sortedDict(final K key, final A value) {
				return SortedDict.<K, A> emptySortedDict().put(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				public static <K extends Comparable<K>, A> SortedDict<K, A> sortedDict(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return SortedDict.<K, A> emptySortedDict()
						«FOR j : 1 .. i»
							.put(key«j», value«j»)«IF j == i»;«ENDIF»
						«ENDFOR»
				}

			«ENDFOR»
			«javadocSynonym("emptySortedDict")»
			public static <K extends Comparable<K>, A> SortedDict<K, A> of() {
				return emptySortedDict();
			}

			«javadocSynonym("sortedDict")»
			public static <K extends Comparable<K>, A> SortedDict<K, A> of(final K key, final A value) {
				return sortedDict(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				«javadocSynonym("sortedDict")»
				public static <K extends Comparable<K>, A> SortedDict<K, A> of(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return sortedDict(«(1..i).map["key" + it + ", value" + it].join(", ")»);
				}

			«ENDFOR»
			@SafeVarargs
			public static <K extends Comparable<K>, A> SortedDict<K, A> ofEntries(final P<K, A>... entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putEntries(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> ofAll(final Iterable<P<K, A>> entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putAll(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> fromIterator(final Iterator<P<K, A>> entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putIterator(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> fromStream(final Stream<P<K, A>> entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putStream(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> fromMap(final Map<K, A> map) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putMap(map);
				return builder.build();
			}

			public static <K, A> SortedDict<K, A> fromSortedMap(final SortedMap<K, A> map) {
				final Comparator<? super K> comparator = map.comparator();
				final SortedDictBuilder<K, A> builder;
				if (comparator == null) {
					builder = (SortedDictBuilder<K, A>) builder();
				} else {
					builder = builderBy(Ord.cast(Ord.fromComparator(comparator)));
				}
				builder.putMap(map);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDictBuilder<K, A> builder() {
				return new SortedDictBuilder<>();
			}

			public static <K, A> SortedDictBuilder<K, A> builderBy(final Ord<K> ord) {
				return new SortedDictBuilder<>(ord);
			}

			«cast(#["K", "A"], #[], #["A"])»

			static final class InsertResult {
				boolean heightIncreased;
			}

			static final class DeleteResult<K, A> {
				P<K, A> entry;
				boolean heightDecreased;
			}
		}

		final class SortedDictIterator<K, A> implements Iterator<P<K, A>> {
			private final SortedDict<K, A> root;
			private Stack<SortedDict<K, A>> stack;

			SortedDictIterator(final SortedDict<K, A> root) {
				this.root = root;
			}

			@Override
			public boolean hasNext() {
				return (this.stack == null || this.stack.isNotEmpty());
			}

			@Override
			public P<K, A> next() {
				if (this.stack == null) {
					this.stack = emptyStack();
					for (SortedDict<K, A> dict = this.root; dict != null; dict = dict.left) {
						this.stack = this.stack.prepend(dict);
					}
				}

				final SortedDict<K, A> result = this.stack.head();
				this.stack = this.stack.tail;

				if (result.right != null) {
					for (SortedDict<K, A> dict = result.right; dict != null; dict = dict.left) {
						this.stack = this.stack.prepend(dict);
					}
				}

				return result.entry;
			}
		}
	''' }
}