package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class UniqueGenerator implements ClassGenerator {
	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "Unique" }
	def paramGenericName() { "<A> Unique<A>" }
	def genericName() { "Unique<A>" }
	def diamondName() { "Unique<>" }
	def wildcardName() { "Unique<?>" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.stream.Collector;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».Order.*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		import static «Constants.COLLECTION».HashTableCommon.*;

		public final class «shortName»<@Covariant A> implements UniqueContainer<A>, Serializable {
			private static final «wildcardName» EMPTY = new «diamondName»(0, 0, Common.«Type.OBJECT.emptyArrayName», 0);

			private final int treeMap;
			private final int leafMap;
			private final Object[] slots;
			private final int size;

			private «shortName»(final int treeMap, final int leafMap, final Object[] slots, final int size) {
				this.treeMap = treeMap;
				this.leafMap = leafMap;
				this.slots = slots;
				this.size = size;
			}

			@Override
			public int size() {
				return this.size;
			}

			@Override
			public boolean contains(final A value) {
				return get(value, value.hashCode(), 0);
			}

			public «genericName» put(final A value) {
				requireNonNull(value);
				return update(value, value.hashCode(), 0);
			}

			public «genericName» remove(final A value) {
				return remove(value, value.hashCode(), 0);
			}

			private boolean get(final A value, final int valueHash, final int shift) {
				final int branch = branch(valueHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID: return false;
					case LEAF: return getEntry(branch).equals(value);
					case TREE: return getTree(branch).get(value, valueHash, shift + 5);
					case COLLISION: return getFromCollision(getCollision(branch), value);
					default: throw new AssertionError();
				}
			}

			private A entryAt(final int index) {
				return (A) this.slots[index];
			}

			private A getEntry(final int branch) {
				return entryAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setEntry(final int branch, final A entry) {
				this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = entry;
				return this;
			}

			private «genericName» treeAt(final int index) {
				return («genericName») this.slots[index];
			}

			private «genericName» getTree(final int branch) {
				return treeAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setTree(final int branch, final «genericName» tree) {
				this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = tree;
				return this;
			}

			private Object[] collisionAt(final int index) {
				return (Object[]) this.slots[index];
			}

			private Object[] getCollision(final int branch) {
				return collisionAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setCollision(final int branch, final Object[] collision) {
				this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = collision;
				return this;
			}

			private boolean isSingle() {
				return this.treeMap == 0 && Integer.bitCount(this.leafMap) == 1;
			}

			private A singleEntry() {
				return (A) this.slots[0];
			}

			«HashTableCommonGenerator.remap(shortName, genericName, diamondName)»

			private «genericName» update(final A value, final int valueHash, final int shift) {
				final int branch = branch(valueHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID:
						return remap(this.treeMap, this.leafMap | branch, this.size + 1).setEntry(branch, value);

					case LEAF:
						final A leaf = getEntry(branch);
						final int leafHash = leaf.hashCode();
						if (valueHash == leafHash) {
							if (value.equals(leaf)) {
								return this;
							} else {
								final Object[] collision = { value, leaf };
								return remap(this.treeMap | branch, this.leafMap, this.size + 1).setCollision(branch, collision);
							}
						} else {
							final «genericName» tree = merge(leaf, leafHash, value, valueHash, shift + 5);
							return remap(this.treeMap | branch, this.leafMap ^ branch, this.size + 1).setTree(branch, tree);
						}

					case TREE:
						final «genericName» oldTree = getTree(branch);
						final «genericName» newTree = oldTree.update(value, valueHash, shift + 5);
						if (newTree == oldTree) {
							return this;
						} else {
							return remap(this.treeMap, this.leafMap, this.size + newTree.size - oldTree.size).setTree(branch, newTree);
						}

					case COLLISION:
						final Object[] oldCollision = getCollision(branch);
						final Object[] newCollision = updateCollision(oldCollision, value);
						if (newCollision == oldCollision) {
							return this;
						} else if (newCollision.length > oldCollision.length) {
							return remap(this.treeMap, this.leafMap, this.size + 1).setCollision(branch, newCollision);
						} else {
							return remap(this.treeMap, this.leafMap, this.size).setCollision(branch, newCollision);
						}

					default:
						throw new AssertionError();
				}
			}

			«HashTableCommonGenerator.remove(genericName, "A", "value", "A", "entry.equals(value)", "Object")»

			«HashTableCommonGenerator.merge(paramGenericName, "A", diamondName)»

			private boolean getFromCollision(final Object[] collision, final A value) {
				for (final Object entry : collision) {
					if (entry.equals(value)) {
						return true;
					}
				}
				return false;
			}

			private Object[] updateCollision(final Object[] collision, final A value) {
				for (int i = 0; i < collision.length; i++) {
					final A entry = (A) collision[i];
					if (entry.equals(value)) {
						return collision;
					}
				}

				final Object[] newCollision = new Object[collision.length + 1];
				System.arraycopy(collision, 0, newCollision, 1, collision.length);
				newCollision[0] = value;
				return newCollision;
			}

			private Object[] removeFromCollision(final Object[] collision, final A value) {
				for (int i = 0; i < collision.length; i++) {
					final A entry = (A) collision[i];
					if (entry.equals(value)) {
						final Object[] newCollision = new Object[collision.length - 1];
						System.arraycopy(collision, 0, newCollision, 0, i);
						System.arraycopy(collision, i + 1, newCollision, i, newCollision.length - i);
						return newCollision;
					}
				}
				return collision;
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
					for (final A value : from) {
						result = result.put(value);
					}
					return result;
				}
			}

			public «genericName» putAll(final Iterable<A> iterable) {
				if (iterable instanceof «wildcardName») {
					return merge((«genericName») iterable);
				} else {
					final UniqueBuilder<A> builder = new UniqueBuilder<>(this);
					builder.putAll(iterable);
					return builder.build();
				}
			}

			@Deprecated
			@Override
			public «genericName» toUnique() {
				return this;
			}

			@Override
			public Iterator<A> iterator() {
				return isEmpty() ? Collections.emptyIterator() : new HashTableIterator<>(this.leafMap, this.treeMap, this.slots);
			}

			/**
			 * @deprecated «shortName» has no specified order, so this method makes no sense.
			 */
			@Deprecated
			@Override
			public Iterator<A> reverseIterator() {
				return UniqueContainer.super.reverseIterator();
			}

			@Override
			public void foreach(final Eff<A> eff) {
				«HashTableCommonGenerator.forEach("foreach", "eff", "apply", "Object", "A")»
			}

			«uniqueEquals(Type.OBJECT)»

			«uniqueHashCode(Type.OBJECT)»

			@Override
			public String toString() {
				return iterableToString(this, "«shortName»");
			}

			public static «paramGenericName» empty«shortName»() {
				return («genericName») EMPTY;
			}

			public static «paramGenericName» single«shortName»(final A value) {
				return «shortName».<A> empty«shortName»().put(value);
			}

			@SafeVarargs
			public static «paramGenericName» «shortName.firstToLowerCase»(final A... values) {
				«genericName» unique = empty«shortName»();
				for (final A value : values) {
					unique = unique.put(value);
				}
				return unique;
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			@SafeVarargs
			public static <A> «genericName» of(final A... values) {
				return «shortName.firstToLowerCase»(values);
			}

			public static «paramGenericName» ofAll(final Iterable<A> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof Container<?>) {
					return ((Container<A>) iterable).toUnique();
				} else {
					final UniqueBuilder<A> builder = builder();
					builder.putAll(iterable);
					return builder.build();
				}
			}

			«fillUntil(Type.OBJECT, paramGenericName, "UniqueBuilder<A>", "put")»

			public static «paramGenericName» fromIterator(final Iterator<A> iterator) {
				final UniqueBuilder<A> builder = builder();
				builder.putIterator(iterator);
				return builder.build();
			}

			public static «paramGenericName» fromStream(final Stream<A> stream) {
				final UniqueBuilder<A> builder = builder();
				builder.putStream(stream);
				return builder.build();
			}

			public static <A> UniqueBuilder<A> builder() {
				return new UniqueBuilder<>();
			}

			public static <A> Collector<A, ?, Unique<A>> collector() {
				return Collector.<A, UniqueBuilder<A>, Unique<A>> of(
						Unique::builder, UniqueBuilder::put, UniqueBuilder::merge, UniqueBuilder::build);
			}

			«cast(#["A"], #[], #["A"])»
		}
	''' }
}