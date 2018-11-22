package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SortedUniqueGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].map[new SortedUniqueGenerator(it) as Generator].toList
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def baseName() { "SortedUnique" }
	def shortName() { type.sortedUniqueShortName }
	def genericName() { type.sortedUniqueGenericName }
	def diamondName() { type.diamondName(baseName) }
	def wildcardName() { type.wildcardName(baseName) }
	def deleteResultGenericName() { "DeleteResult" + (if (type == Type.OBJECT) "<A>" else "") }
	def deleteResultDiamondName() { "DeleteResult" + (if (type == Type.OBJECT) "<>" else "") }
	def paramGenericName() { type.paramGenericName(baseName) }
	def paramComparableGenericName() { if (type == Type.OBJECT) "<A extends Comparable<A>> " + genericName else genericName }
	def slicedSortedUniqueViewShortName() { type.shortName("SlicedSortedUniqueView") }
	def slicedSortedUniqueViewDiamondName() { type.diamondName("SlicedSortedUniqueView") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		«IF type == Type.OBJECT»
			import java.util.Collections;
		«ENDIF»
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		«IF type.primitive»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.TreeSet;
		import java.util.stream.Collector;
		import java.util.stream.«type.streamName»;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».Order.*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.JCATS».«type.ordShortName».*;
		import static «Constants.STACK».*;
		import static «Constants.COLLECTION».«type.sortedUniqueShortName».*;

		public final class «type.covariantName(baseName)» implements «type.sortedUniqueContainerGenericName», Serializable {

			«IF type == Type.OBJECT»
				static final «wildcardName» EMPTY = new «diamondName»(null, null, null, Ord.<Integer>asc(), 0);
			«ELSE»
				static final «shortName» EMPTY = new «shortName»(«type.asc»());
			«ENDIF»

			final «type.genericName» entry;
			final «genericName» left;
			final «genericName» right;
			final int size;
			final «type.ordGenericName» ord;
			private final int balance;

			«IF type == Type.OBJECT»
				private «shortName»(final «type.genericName» entry, final «genericName» left, final «genericName» right,
						final «type.ordGenericName» ord, final int balance) {
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
			«ELSE»
				private «shortName»(final «type.genericName» entry, final «genericName» left, final «genericName» right,
						final «type.ordGenericName» ord, final int balance) {
					this.entry = entry;
					this.left = left;
					this.right = right;
					this.size = ((left == null) ? 0 : left.size) + ((right == null) ? 0 : right.size) + 1;
					this.ord = ord;
					this.balance = balance;
				}

				private «shortName»(final «type.ordGenericName» ord) {
					this.entry = «type.defaultValue»;
					this.left = null;
					this.right = null;
					this.size = 0;
					this.ord = ord;
					this.balance = 0;
				}
			«ENDIF»

			@Override
			public «type.ordGenericName» ord() {
				return this.ord;
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (isEmpty()) {
					return false;
				}

				«genericName» unique = this;
				while (true) {
					final Order order = this.ord.order(value, unique.entry);
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

			public «genericName» put(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (isEmpty()) {
					return new «diamondName»(value, null, null, this.ord, 0);
				} else {
					return update(value, new InsertResult());
				}
			}

			private «genericName» update(final «type.genericName» value, final InsertResult result) {
				«AVLCommon.update(genericName, diamondName, "value", "entry", "value", "value == this.entry", "value")»
			}

			«AVLCommon.insertAndRotateRight(genericName, diamondName)»

			«AVLCommon.insertAndRotateLeft(genericName, diamondName)»

			public «genericName» remove(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (isEmpty()) {
					return this;
				} else {
					final «genericName» newUnique = delete(value, new «deleteResultDiamondName»());
					if (newUnique == null) {
						return empty«shortName»By(this.ord);
					} else {
						return newUnique;
					}
				}
			}

			private «genericName» delete(final «type.genericName» value, final «deleteResultGenericName» result) {
				«AVLCommon.delete(genericName, diamondName, "value", "entry")»
			}

			«AVLCommon.deleteMinimum(genericName, diamondName, deleteResultGenericName)»

			«AVLCommon.deleteMaximum(genericName, diamondName, deleteResultGenericName)»

			«AVLCommon.deleteAndRotateLeft(genericName, diamondName, type.genericName, deleteResultGenericName)»

			«AVLCommon.deleteAndRotateRight(genericName, diamondName, deleteResultGenericName)»

			static NullPointerException nullOrder(final Order order) {
				if (order == null) {
					return new NullPointerException("«type.ordShortName».order() returned null");
				} else {
					throw new AssertionError("«type.ordShortName».order() returned unexpected value: " + order);
				}
			}

			public «genericName» merge(final «genericName» other) {
				requireNonNull(other);
				if (isEmpty()) {
					return other;
				} else if (other.isEmpty()) {
					return this;
				} else {
					«genericName» result;
					final «genericName» from;
					if (size() >= other.size()) {
						result = this;
						from = other;
					} else {
						result = other;
						from = this;
					}
					for (final «type.genericName» value : from) {
						result = result.put(value);
					}
					return result;
				}
			}

			public «genericName» putAll(final Iterable<«type.genericBoxedName»> iterable) {
				if (iterable instanceof «wildcardName») {
					return merge((«genericName») iterable);
				} else {
					final «type.sortedUniqueBuilderGenericName» builder = new «type.sortedUniqueBuilderDiamondName»(this);
					builder.putAll(iterable);
					return builder.build();
				}
			}

			@Override
			public «type.genericName» head() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					«genericName» unique = this;
					while (unique.left != null) {
						unique = unique.left;
					}
					return unique.entry;
				}
			}

			@Override
			public «type.genericName» last() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					«genericName» unique = this;
					while (unique.right != null) {
						unique = unique.right;
					}
					return unique.entry;
				}
			}

			@Override
			public «type.optionGenericName» lastOption() throws NoSuchElementException {
				if (isEmpty()) {
					return «type.noneName»();
				} else {
					return «type.someName»(last());
				}
			}

			public «genericName» init() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					final «genericName» newUnique = deleteMaximum(new «deleteResultDiamondName»());
					if (newUnique == null) {
						return empty«shortName»By(this.ord);
					} else {
						return newUnique;
					}
				}
			}

			public «genericName» tail() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					final «genericName» newUnique = deleteMinimum(new «deleteResultDiamondName»());
					if (newUnique == null) {
						return empty«shortName»By(this.ord);
					} else {
						return newUnique;
					}
				}
			}

			public «genericName» reverse() {
				final «type.sortedUniqueBuilderGenericName» builder = new «type.sortedUniqueBuilderDiamondName»(this.ord.reverse());
				builder.putAll(this);
				return builder.build();
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return isEmpty() ? «type.emptyIterator» : new «type.iteratorDiamondName(baseName)»(this);
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				return isEmpty() ? «type.emptyIterator» : new «type.diamondName(baseName + "ReverseIterator")»(this);
			}

			@Override
			public int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				if (isNotEmpty()) {
					traverse(eff);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				if (isNotEmpty()) {
					return traverseUntil(eff);
				} else {
					return true;
				}
			}

			void traverse(final «type.effGenericName» eff) {
				if (this.left != null) {
					this.left.traverse(eff);
				}
				eff.apply(this.entry);
				if (this.right != null) {
					this.right.traverse(eff);
				}
			}

			private boolean traverseUntil(final «type.boolFName» action) {
				if (this.left != null) {
					if (!this.left.traverseUntil(action)) {
						return false;
					}
				}
				if (!action.apply(this.entry)) {
					return false;
				}
				if (this.right != null) {
					if (!this.right.traverseUntil(action)) {
						return false;
					}
				}
				return true;
			}

			@Override
			public int size() {
				return this.size;
			}

			public TreeSet<«type.genericBoxedName»> toTreeSet() {
				final TreeSet<«type.genericBoxedName»> set = new TreeSet<>(this.ord);
				foreach(set::add);
				return set;
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» view() {
				return new «type.diamondName("SortedUniqueView")»(this);
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

			«uniqueEquals(type)»

			«uniqueHashCode(type)»

			«toStr(type, shortName, false)»

			public static «paramComparableGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«genericName») «ENDIF»EMPTY;
			}

			public static «paramGenericName» empty«shortName»By(final «type.ordGenericName» ord) {
				requireNonNull(ord);
				«IF type == Type.OBJECT»
					if (ord == asc()) {
						return («genericName») EMPTY;
					} else {
						return new «diamondName»(null, null, null, ord, 0«IF type.primitive», true«ENDIF»);
					}
				«ELSE»
					if (ord == «type.asc»()) {
						return EMPTY;
					} else {
						return new «diamondName»(ord);
					}
				«ENDIF»
			}

			public static «paramComparableGenericName» single«shortName»(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return «shortName».<A> empty«shortName»().put(value);
				«ELSE»
					return empty«shortName»().put(value);
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramComparableGenericName» «shortName.firstToLowerCase»(final «type.genericName»... values) {
				«genericName» unique = empty«shortName»();
				for (final «type.genericName» value : values) {
					unique = unique.put(value);
				}
				return unique;
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramComparableGenericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			public static «paramComparableGenericName» ofAll(final Iterable<«type.genericBoxedName»> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof «wildcardName») {
					return («genericName») iterable;
				} else {
					final «type.sortedUniqueBuilderGenericName» builder = builder();
					builder.putAll(iterable);
					return builder.build();
				}
			}

			«fillUntil(type, paramComparableGenericName, type.sortedUniqueBuilderGenericName, "put")»

			public static «paramComparableGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				requireNonNull(iterator);
				final «type.sortedUniqueBuilderGenericName» builder = builder();
				builder.putIterator(iterator);
				return builder.build();
			}

			public static «paramComparableGenericName» from«type.streamName»(final «type.streamGenericName» stream) {
				final «type.sortedUniqueBuilderGenericName» builder = builder();
				builder.put«type.streamName»(stream);
				return builder.build();
			}

			public static «IF type == Type.OBJECT»<A extends Comparable<A>> «ENDIF»«type.sortedUniqueBuilderGenericName» builder() {
				return new «type.diamondName("SortedUniqueBuilder")»();
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»«type.sortedUniqueBuilderGenericName» builderBy(final «type.ordGenericName» ord) {
				return new «type.diamondName("SortedUniqueBuilder")»(ord);
			}

			public static «IF type == Type.OBJECT»<A extends Comparable<A>> «ENDIF»Collector<«type.genericBoxedName», ?, «genericName»> collector() {
				«IF type == Type.OBJECT»
					return Collector.<«type.genericBoxedName», «type.sortedUniqueBuilderGenericName», «genericName»> of(
				«ELSE»
					return Collector.of(
				«ENDIF»
						«shortName»::builder, «type.sortedUniqueBuilderShortName»::put, «type.sortedUniqueBuilderShortName»::merge, «type.sortedUniqueBuilderShortName»::build);
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»Collector<«type.genericBoxedName», ?, «genericName»> collectorBy(final «type.ordGenericName» ord) {
				return Collector.of(
						() -> builderBy(ord), «type.sortedUniqueBuilderShortName»::put, «type.sortedUniqueBuilderShortName»::merge, «type.sortedUniqueBuilderShortName»::build);
			}

			«IF type == Type.OBJECT»
				«cast(#["A"], #[], #["A"])»

			«ENDIF»
			static final class InsertResult {
				boolean heightIncreased;
			}

			static final class «deleteResultGenericName» {
				«type.genericName» entry;
				boolean heightDecreased;
			}
		}

		final class «type.iteratorGenericName(baseName)» implements «type.iteratorGenericName» {
			private final «genericName» root;
			private Stack<«genericName»> stack;

			«type.iteratorShortName(baseName)»(final «genericName» root) {
				this.root = root;
			}

			@Override
			public boolean hasNext() {
				return (this.stack == null || this.stack.isNotEmpty());
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (this.stack == null) {
					this.stack = emptyStack();
					for («genericName» unique = this.root; unique != null; unique = unique.left) {
						this.stack = this.stack.prepend(unique);
					}
				}

				final «genericName» result = this.stack.head();
				this.stack = this.stack.tail;

				if (result.right != null) {
					for («genericName» unique = result.right; unique != null; unique = unique.left) {
						this.stack = this.stack.prepend(unique);
					}
				}

				return result.entry;
			}
		}

		final class «type.genericName(baseName + "ReverseIterator")» implements «type.iteratorGenericName» {
			private final «genericName» root;
			private Stack<«genericName»> stack;

			«type.shortName(baseName + "ReverseIterator")»(final «genericName» root) {
				this.root = root;
			}

			@Override
			public boolean hasNext() {
				return (this.stack == null || this.stack.isNotEmpty());
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (this.stack == null) {
					this.stack = emptyStack();
					for («genericName» unique = this.root; unique != null; unique = unique.right) {
						this.stack = this.stack.prepend(unique);
					}
				}

				final «genericName» result = this.stack.head();
				this.stack = this.stack.tail;

				if (result.left != null) {
					for («genericName» unique = result.left; unique != null; unique = unique.right) {
						this.stack = this.stack.prepend(unique);
					}
				}

				return result.entry;
			}
		}

		final class «type.genericName("SortedUniqueView")» extends «type.shortName("BaseSortedUniqueContainerView")»<«IF type == Type.OBJECT»A, «ENDIF»«genericName»> {

			«shortName»View(final «genericName» container) {
				super(container);
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» slice(final «type.genericName» from, final «type.genericName» to) {
				«slicedSortedUniqueViewShortName».checkRange(this.container.ord, from, to);
				return new «slicedSortedUniqueViewDiamondName»(this.container, from, to);
			}

			«toStr(type, type.sortedUniqueViewShortName, false)»
		}

		final class «type.genericName("SlicedSortedUniqueView")» implements «type.sortedUniqueContainerViewGenericName» {

			private final «genericName» root;
			private final «type.genericName» from;
			private final «type.genericName» to;

			«slicedSortedUniqueViewShortName»(final «genericName» root, final «type.genericName» from, final «type.genericName» to) {
				this.root = root;
				this.from = from;
				this.to = to;
			}

			@Override
			public «type.ordGenericName» ord() {
				return this.root.ord;
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				if (this.root.isNotEmpty()) {
					traverse(this.root, eff);
				}
			}

			private void traverse(final «genericName» unique, final «type.effGenericName» eff) {
				final Order fromOrder = this.root.ord.order(this.from, unique.entry);
				final Order toOrder = this.root.ord.order(this.to, unique.entry);
				if (fromOrder == LT) {
					if (toOrder == LT) {
						if (unique.left != null) {
							traverse(unique.left, eff);
						}
					} else if (toOrder == EQ) {
						if (unique.left != null) {
							traverseFrom(unique.left, eff);
						}
						eff.apply(unique.entry);
					} else if (toOrder == GT) {
						if (unique.left != null) {
							traverseFrom(unique.left, eff);
						}
						eff.apply(unique.entry);
						if (unique.right != null) {
							traverseTo(unique.right, eff);
						}
					} else {
						throw «shortName».nullOrder(toOrder);
					}
				} else if (fromOrder == EQ) {
					if (toOrder == EQ) {
						eff.apply(unique.entry);
					} else if (toOrder == GT) {
						eff.apply(unique.entry);
						if (unique.right != null) {
							traverseTo(unique.right, eff);
						}
					} else if (toOrder == LT) {
						throw new IllegalArgumentException("from == entry && entry > to");
					} else {
						throw «shortName».nullOrder(toOrder);
					}
				} else if (fromOrder == GT) {
					if (toOrder == GT) {
						if (unique.right != null) {
							traverse(unique.right, eff);
						}
					} else if (toOrder == LT) {
						throw new IllegalArgumentException("from > entry && entry > to");
					} else if (toOrder == EQ) {
						throw new IllegalArgumentException("from > entry && entry == to");
					} else {
						throw «shortName».nullOrder(toOrder);
					}
				} else {
					throw «shortName».nullOrder(fromOrder);
				}
			}

			private void traverseFrom(final «genericName» unique, final «type.effGenericName» eff) {
				final Order order = this.root.ord.order(this.from, unique.entry);
				if (order == LT) {
					if (unique.left != null) {
						traverseFrom(unique.left, eff);
					}
					eff.apply(unique.entry);
					if (unique.right != null) {
						unique.right.traverse(eff);
					}
				} else if (order == EQ) {
					eff.apply(unique.entry);
					if (unique.right != null) {
						unique.right.traverse(eff);
					}
				} else if (order == GT) {
					if (unique.right != null) {
						traverseFrom(unique.right, eff);
					}
				} else {
					throw «shortName».nullOrder(order);
				}
			}

			private void traverseTo(final «genericName» unique, final «type.effGenericName» eff) {
				final Order order = this.root.ord.order(this.to, unique.entry);
				if (order == LT) {
					if (unique.left != null) {
						traverseTo(unique.left, eff);
					}
				} else if (order == EQ) {
					if (unique.left != null) {
						unique.left.traverse(eff);
					}
					eff.apply(unique.entry);
				} else if (order == GT) {
					if (unique.left != null) {
						unique.left.traverse(eff);
					}
					eff.apply(unique.entry);
					if (unique.right != null) {
						traverseTo(unique.right, eff);
					}
				} else {
					throw «shortName».nullOrder(order);
				}
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» slice(final «type.genericName» from2, final «type.genericName» to2) {
				checkRange(this.root.ord, from2, to2);
				final «type.genericName» newFrom = this.root.ord.max(this.from, from2);
				final «type.genericName» newTo = this.root.ord.min(this.to, to2);
				if (this.root.ord.greater(newFrom, newTo)) {
					return new «type.sortedUniqueViewDiamondName»(empty«shortName»By(this.root.ord));
				} else {
					return new «slicedSortedUniqueViewDiamondName»(this.root, newFrom, newTo);
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return this.root.isEmpty() ? «type.emptyIterator» : new «type.iteratorDiamondName("SlicedSortedUnique")»(this.root, this.from, this.to);
			}

			«uniqueEquals(type)»

			«uniqueHashCode(type)»

			«toStr(type, slicedSortedUniqueViewShortName, false)»

			static «IF type == Type.OBJECT»<A> «ENDIF»void checkRange(final «type.ordGenericName» ord, final «type.genericName» from, final «type.genericName» to) {
				«IF type == Type.OBJECT»
					requireNonNull(from);
					requireNonNull(to);
				«ENDIF»
				if (ord.greater(from, to)) {
					throw new IllegalArgumentException("from > to");
				}
			}
		}

		final class «type.iteratorGenericName("SlicedSortedUnique")» implements «type.iteratorGenericName» {
			private final «genericName» end;
			private Stack<«genericName»> stack;

			«type.iteratorShortName("SlicedSortedUnique")»(final «genericName» root, final «type.genericName» from, final «type.genericName» to) {
				final Stack<«genericName»> start = getStart(root, from);
				if (start == null || root.ord.greater(start.head.entry, to)) {
					this.stack = null;
					this.end = null;
				} else {
					this.stack = start;
					this.end = getEnd(root, to);
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»Stack<«genericName»> getStart(«genericName» unique, final «type.genericName» from) {
				final «type.ordGenericName» ord = unique.ord;
				Stack<«genericName»> minGreater = null;
				Stack<«genericName»> stack = emptyStack();
				while (true) {
					final Order order = ord.order(from, unique.entry);
					if (order == EQ) {
						return stack.prepend(unique);
					} else if (order == LT) {
						if (unique.left == null) {
							return stack.prepend(unique);
						} else {
							stack = stack.prepend(unique);
							minGreater = stack;
							unique = unique.left;
						}
					} else if (order == GT) {
						if (unique.right == null) {
							return minGreater;
						} else {
							unique = unique.right;
						}
					}
				}
			}

			private static «paramGenericName» getEnd(«genericName» unique, final «type.genericName» to) {
				final «type.ordGenericName» ord = unique.ord;
				«genericName» maxLess = null;
				while (true) {
					final Order order = ord.order(to, unique.entry);
					if (order == EQ) {
						return unique;
					} else if (order == LT) {
						if (unique.left == null) {
							return maxLess;
						} else {
							unique = unique.left;
						}
					} else if (order == GT) {
						if (unique.right == null) {
							return unique;
						} else {
							maxLess = unique;
							unique = unique.right;
						}
					} else {
						throw SortedUnique.nullOrder(order);
					}
				}
			}

			@Override
			public boolean hasNext() {
				return (this.stack != null && this.stack.isNotEmpty());
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (this.stack == null) {
					throw new NoSuchElementException();
				}

				final «genericName» result = this.stack.head;
				if (result == this.end) {
					this.stack = null;
				} else {
					this.stack = this.stack.tail;

					if (result.right != null) {
						for («genericName» unique = result.right; unique != null; unique = unique.left) {
							this.stack = this.stack.prepend(unique);
						}
					}
				}

				return result.entry;
			}
		}
	''' }
}