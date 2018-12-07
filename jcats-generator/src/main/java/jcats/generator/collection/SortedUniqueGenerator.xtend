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
				static final «wildcardName» EMPTY_REVERSED = new «diamondName»(null, null, null, Ord.<Integer>desc(), 0);
			«ELSE»
				static final «shortName» EMPTY = new «shortName»(«type.asc»());
				static final «shortName» EMPTY_REVERSED = new «shortName»(«type.desc»());
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
				} else {
					return search(this, value);
				}
			}

			static «IF type == Type.OBJECT»<A> «ENDIF»boolean search(«genericName» unique, final «type.genericName» value) {
				final «type.ordGenericName» ord = unique.ord;
				while (true) {
					final Order order = ord.order(value, unique.entry);
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
			public «type.genericName» first() throws NoSuchElementException {
				«AVLCommon.firstOrLast(genericName, "unique", "entry", "left")»
			}

			@Override
			public «type.genericName» last() throws NoSuchElementException {
				«AVLCommon.firstOrLast(genericName, "unique", "entry", "right")»
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
				«AVLCommon.initOrTail(genericName, shortName, deleteResultDiamondName, "deleteMaximum")»
			}

			public «genericName» tail() throws NoSuchElementException {
				«AVLCommon.initOrTail(genericName, shortName, deleteResultDiamondName, "deleteMinimum")»
			}

			public «genericName» reverse() {
				final «type.sortedUniqueBuilderGenericName» builder = new «type.sortedUniqueBuilderDiamondName»(this.ord.reversed());
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

			«toStr(type)»

			public static «paramComparableGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«genericName») «ENDIF»EMPTY;
			}

			public static «paramGenericName» empty«shortName»By(final «type.ordGenericName» ord) {
				requireNonNull(ord);
				«IF type == Type.OBJECT»
					if (ord == asc()) {
						return («genericName») EMPTY;
					} else if (ord == desc()) {
						return («genericName») EMPTY_REVERSED;
					} else {
						return new «diamondName»(null, null, null, ord, 0«IF type.primitive», true«ENDIF»);
					}
				«ELSE»
					if (ord == «type.asc»()) {
						return EMPTY;
					} else if (ord == «type.desc»()) {
						return EMPTY_REVERSED;
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
			«AVLCommon.iterator(genericName, "unique", type.iteratorShortName(baseName), type.iteratorReturnType, type.iteratorNext, false)»
		}

		final class «type.iteratorGenericName(baseName + "Reverse")» implements «type.iteratorGenericName» {
			«AVLCommon.iterator(genericName, "unique", type.iteratorShortName(baseName + "Reverse"), type.iteratorReturnType, type.iteratorNext, true)»
		}

		final class «type.genericName("SortedUniqueView")» extends «type.shortName("BaseSortedUniqueContainerView")»<«IF type == Type.OBJECT»A, «ENDIF»«genericName»> {

			«shortName»View(final «genericName» container) {
				super(container);
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» slice(final «type.genericName» from, final boolean fromInclusive, final «type.genericName» to, final boolean toInclusive) {
				«slicedSortedUniqueViewShortName».checkRange(this.container.ord, from, to);
				return new «slicedSortedUniqueViewDiamondName»(this.container, from, true, fromInclusive, to, true, toInclusive);
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» sliceFrom(final «type.genericName» from, final boolean inclusive) {
				return new «slicedSortedUniqueViewDiamondName»(this.container, from, true, inclusive, «type.defaultValue», false, false);
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» sliceTo(final «type.genericName» to, final boolean inclusive) {
				return new «slicedSortedUniqueViewDiamondName»(this.container, «type.defaultValue», false, false, to, true, inclusive);
			}

			«toStr(type)»
		}

		final class «type.genericName("SlicedSortedUniqueView")» implements «type.sortedUniqueContainerViewGenericName» {

			private final «genericName» root;
			private final «type.genericName» from;
			private final boolean hasFrom;
			private final boolean fromInclusive;
			private final «type.genericName» to;
			private final boolean hasTo;
			private final boolean toInclusive;

			«slicedSortedUniqueViewShortName»(final «genericName» root,
				final «type.genericName» from, final boolean hasFrom, final boolean fromInclusive,
				final «type.genericName» to, final boolean hasTo, final boolean toInclusive) {
				this.root = root;
				this.from = from;
				this.hasFrom = hasFrom;
				this.fromInclusive = fromInclusive;
				this.to = to;
				this.hasTo = hasTo;
				this.toInclusive = toInclusive;
			}

			@Override
			public boolean hasFixedSize() {
				return false;
			}

			@Override
			public «type.ordGenericName» ord() {
				return this.root.ord;
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				if (this.root.isNotEmpty()) {
					if (this.hasFrom) {
						if (this.hasTo) {
							traverse(this.root, eff);
						} else {
							traverseFrom(this.root, eff);
						}
					} else {
						traverseTo(this.root, eff);
					}
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
						if (this.toInclusive) {
							eff.apply(unique.entry);
						}
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
						if (this.fromInclusive && this.toInclusive) {
							eff.apply(unique.entry);
						}
					} else if (toOrder == GT) {
						if (this.fromInclusive) {
							eff.apply(unique.entry);
						}
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
					if (this.fromInclusive) {
						eff.apply(unique.entry);
					}
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
					if (this.toInclusive) {
						eff.apply(unique.entry);
					}
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
			public boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (this.root.isEmpty()) {
					return false;
				} else if (this.hasFrom &&
						(this.fromInclusive && this.root.ord.less(value, this.from) ||
						!this.fromInclusive && this.root.ord.lessOrEqual(value, this.from))) {
					return false;
				} else if (this.hasTo &&
						(this.toInclusive && this.root.ord.greater(value, this.to) ||
						!this.toInclusive && this.root.ord.greaterOrEqual(value, this.to))) {
					return false;
				} else {
					return «shortName».search(this.root, value);
				}
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» slice(final «type.genericName» from2, final boolean from2Inclusive, final «type.genericName» to2, final boolean to2Inclusive) {
				checkRange(this.root.ord, from2, to2);
				return slice(from2, true, from2Inclusive, to2, true, to2Inclusive);
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» sliceFrom(final «type.genericName» from2, final boolean inclusive2) {
				return slice(from2, true, inclusive2, «type.defaultValue», false, false);
			}

			@Override
			public «type.sortedUniqueContainerViewGenericName» sliceTo(final «type.genericName» to2, final boolean inclusive2) {
				return slice(«type.defaultValue», false, false, to2, true, inclusive2);
			}

			private «type.sortedUniqueContainerViewGenericName» slice(final «type.genericName» from2, final boolean hasFrom2, final boolean from2Inclusive,
				final «type.genericName» to2, final boolean hasTo2, final boolean to2Inclusive) {
				final «type.genericName» newFrom;
				final boolean newFromInclusive;
				if (this.hasFrom) {
					if (hasFrom2) {
						final Order fromOrder = this.root.ord.order(this.from, from2);
						if (fromOrder == LT) {
							newFrom = from2;
							newFromInclusive = from2Inclusive;
						} else if (fromOrder == EQ) {
							newFrom = from2;
							newFromInclusive = this.fromInclusive && from2Inclusive;
						} else if (fromOrder == GT) {
							newFrom = this.from;
							newFromInclusive = this.fromInclusive;
						} else {
							throw SortedUnique.nullOrder(fromOrder);
						}
					} else {
						newFrom = this.from;
						newFromInclusive = this.fromInclusive;
					}
				} else {
					newFrom = from2;
					newFromInclusive = from2Inclusive;
				}

				final «type.genericName» newTo;
				final boolean newToInclusive;
				if (this.hasTo) {
					if (hasTo2) {
						final Order toOrder = this.root.ord.order(this.to, to2);
						if (toOrder == LT) {
							newTo = this.to;
							newToInclusive = this.toInclusive;
						} else if (toOrder == EQ) {
							newTo = to2;
							newToInclusive = this.toInclusive && to2Inclusive;
						} else if (toOrder == GT) {
							newTo = to2;
							newToInclusive = to2Inclusive;
						} else {
							throw SortedUnique.nullOrder(toOrder);
						}
					} else {
						newTo = this.to;
						newToInclusive = this.toInclusive;
					}
				} else {
					newTo = to2;
					newToInclusive = to2Inclusive;
				}

				final boolean newHasFrom = this.hasFrom || hasFrom2;
				final boolean newHasTo = this.hasTo || hasTo2;
				if (newHasFrom && newHasTo && this.root.ord.greater(newFrom, newTo)) {
					return new «type.sortedUniqueViewDiamondName»(empty«shortName»By(this.root.ord));
				} else {
					return new «slicedSortedUniqueViewDiamondName»(this.root, newFrom, newHasFrom, newFromInclusive, newTo, newHasTo, newToInclusive);
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				if (this.root.isEmpty()) {
					return «type.emptyIterator»;
				} else {
					return new «type.iteratorDiamondName("Sliced" + baseName)»(this.root, this.from, this.hasFrom, this.fromInclusive, this.to, this.hasTo, this.toInclusive);
				}
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				if (this.root.isEmpty()) {
					return «type.emptyIterator»;
				} else {
					return new «type.iteratorDiamondName("Sliced" + baseName + "Reverse")»(this.root, this.from, this.hasFrom, this.fromInclusive, this.to, this.hasTo, this.toInclusive);
				}
			}

			«uniqueEquals(type)»

			«uniqueHashCode(type)»

			«toStr(type)»

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

		final class «type.iteratorGenericName("Sliced" + baseName)» implements «type.iteratorGenericName» {
			«AVLCommon.slicedIterator(genericName, "unique", type.iteratorShortName("Sliced" + baseName), type.genericName, "entry", "<A> ", type.ordGenericName, type.iteratorReturnType, type.iteratorNext, false)»
		}

		final class «type.iteratorGenericName("Sliced" + baseName + "Reverse")» implements «type.iteratorGenericName» {
			«AVLCommon.slicedIterator(genericName, "unique", type.iteratorShortName("Sliced" + baseName + "Reverse"), type.genericName, "entry", "<A> ", type.ordGenericName, type.iteratorReturnType, type.iteratorNext, true)»
		}
	''' }
}