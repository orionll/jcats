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
		«IF type.primitive»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.stream.«type.streamName»;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».Order.*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		«IF type.javaUnboxedType»
			import static «Constants.JCATS».«type.optionShortName».*;
		«ENDIF»
		«IF type.primitive»
			import static «Constants.JCATS».«type.ordShortName».*;
		«ENDIF»
		import static «Constants.STACK».*;

		public final class «type.covariantName(baseName)» implements «type.uniqueContainerGenericName», Serializable {

			«IF type == Type.OBJECT»
				private static final «wildcardName» EMPTY = new «diamondName»(null, null, null, Ord.<Integer>ord(), 0);
			«ELSE»
				private static final «shortName» EMPTY = new «shortName»(«type.ordShortName.firstToLowerCase»());
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
					final Order order = this.ord.compare(value, unique.entry);
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
					return new NullPointerException("Ord.compare() returned null");
				} else {
					throw new AssertionError("Ord.compare() returned unexpected value: " + order);
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
					«genericName» result = this;
					«IF type.isJavaUnboxedType»
						final «type.iteratorGenericName» iterator = «type.getIterator("iterable.iterator()")»;
						while (iterator.hasNext()) {
							result = result.put(iterator.«type.iteratorNext»());
						}
					«ELSE»
						for (final «type.genericName» value : iterable) {
							result = result.put(value);
						}
					«ENDIF»
					return result;
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return isEmpty() ? «type.emptyIterator» : new «type.iteratorDiamondName(baseName)»(this);
			}

			@Override
			public int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			@Override
			public void foreach(final «type.effGenericName» action) {
				if (isNotEmpty()) {
					traverse(action);
				}
			}

			private void traverse(final «type.effGenericName» action) {
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
					if (ord == Ord.ord()) {
						return («genericName») EMPTY;
					} else {
						return new «diamondName»(null, null, null, ord, 0«IF type.primitive», true«ENDIF»);
					}
				«ELSE»
					if (ord == «type.ordShortName».«type.ordShortName.firstToLowerCase»()) {
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
					«genericName» result = empty«shortName»();
					«IF type.isJavaUnboxedType»
						final «type.iteratorGenericName» iterator = «type.getIterator("iterable.iterator()")»;
						while (iterator.hasNext()) {
							result = result.put(iterator.«type.iteratorNext»());
						}
					«ELSE»
						for (final «type.genericName» value : iterable) {
							result = result.put(value);
						}
					«ENDIF»
					return result;
				}
			}

			public static «paramComparableGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				«genericName» result = empty«shortName»();
				«IF type.isJavaUnboxedType»
					final «type.iteratorGenericName» primitiveIterator = «type.getIterator("iterator")»;
					while (primitiveIterator.hasNext()) {
						result = result.put(primitiveIterator.«type.iteratorNext»());
					}
				«ELSE»
					while (iterator.hasNext()) {
						result = result.put(iterator.next());
					}
				«ENDIF»
				return result;
			}
			«IF type == Type.OBJECT»

				public static «paramComparableGenericName» from«type.streamName»(final «type.streamGenericName» stream) {
					return stream.reduce(emptySortedUnique(), SortedUnique::put, SortedUnique::merge);
				}

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
	''' }
}