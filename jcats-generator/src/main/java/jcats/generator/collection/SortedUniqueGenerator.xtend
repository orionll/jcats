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

		public final class «type.covariantName(baseName)» implements «type.sortedUniqueContainerGenericName», Serializable {

			«IF type == Type.OBJECT»
				static final «wildcardName» EMPTY = new «diamondName»(null, null, null, Ord.<Integer>asc(), 0);
			«ELSE»
				static final «shortName» EMPTY = new «shortName»(«type.asc»());
			«ENDIF»

			final «type.genericName» entry;
			final «genericName» left;
			final «genericName» right;
			private final int size;
			private final «type.ordGenericName» ord;
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

			«AVLCommon.deleteMaximum(genericName, diamondName, deleteResultGenericName)»

			«AVLCommon.deleteAndRotateLeft(genericName, diamondName, type.genericName, deleteResultGenericName)»

			«AVLCommon.deleteAndRotateRight(genericName, diamondName, deleteResultGenericName)»

			private static NullPointerException nullOrder(final Order order) {
				if (order == null) {
					return new NullPointerException("Ord.order() returned null");
				} else {
					throw new AssertionError("Ord.order() returned unexpected value: " + order);
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

			private void traverse(final «type.effGenericName» eff) {
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

			@Override
			public String toString() {
				return iterableToString(this, "«shortName»");
			}

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
	''' }
}