package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.ClassGenerator
import jcats.generator.Type

class DictGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "Dict" }
	def paramGenericName() { "<K, A> Dict<K, A>" }
	def genericName() { "Dict<K, A>" }
	def diamondName() { "Dict<>" }
	def wildcardName() { "Dict<?, ?>" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.Map;
		import java.util.Map.Entry;
		import java.util.NoSuchElementException;
		import java.util.function.Consumer;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.P».p;
		import static jcats.collection.Common.*;
		import static «Constants.COLLECTION».HashTableCommon.*;

		public final class «shortName»<K, @Covariant A> implements KeyValue<K, A>, Serializable {
			private static final «wildcardName» EMPTY = new «shortName»(0, 0, Common.«Type.OBJECT.emptyArrayName», 0);

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
			public A getOrNull(final K key) {
				return get(key, key.hashCode(), 0);
			}

			public «genericName» put(final K key, final A value) {
				requireNonNull(value);
				return update(key, key.hashCode(), value, 0);
			}

			public «genericName» remove(final K key) {
				return remove(key, key.hashCode(), 0);
			}

			private A get(final K key, final int keyHash, final int shift) {
				final int branch = branch(keyHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID: return null;

					case LEAF:
						final P<K, A> entry = getEntry(branch);
						if (entry.get1().equals(key)) {
							return entry.get2();
						} else {
							return null;
						}

					case TREE: return getTree(branch).get(key, keyHash, shift + 5);
					case COLLISION: return getFromCollision(getCollision(branch), key);
					default: throw new AssertionError();
				}
			}

			private P<K, A> entryAt(final int index) {
				return (P<K, A>) this.slots[index];
			}

			private P<K, A> getEntry(final int branch) {
				return entryAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setEntry(final int branch, final P<K, A> entry) {
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

			private P[] collisionAt(final int index) {
				return (P[]) this.slots[index];
			}

			private P[] getCollision(final int branch) {
				return collisionAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setCollision(final int branch, final P[] collision) {
				this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = collision;
				return this;
			}

			private boolean isSingle() {
				return this.treeMap == 0 && Integer.bitCount(this.leafMap) == 1;
			}

			private P<K, A> singleEntry() {
				return (P<K, A>) this.slots[0];
			}

			«HashTableCommonGenerator.remap(shortName, genericName, diamondName)»

			private «genericName» update(final K key, final int keyHash, final A value, final int shift) {
				final int branch = branch(keyHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID:
						return remap(this.treeMap, this.leafMap | branch, this.size + 1).setEntry(branch, p(key, value));

					case LEAF:
						final P<K, A> leaf = getEntry(branch);
						final K leafKey = leaf.get1();
						final int leafKeyHash = leafKey.hashCode();
						if (keyHash == leafKeyHash) {
							if (key.equals(leafKey)) {
								if (value == leaf.get2()) {
									return this;
								} else {
									return remap(this.treeMap, this.leafMap, this.size).setEntry(branch, p(key, value));
								}
							} else {
								final P[] collision = { p(key, value), leaf };
								return remap(this.treeMap | branch, this.leafMap, this.size + 1).setCollision(branch, collision);
							}
						} else {
							final P<K, A> entry = p(key, value);
							final «genericName» tree = merge(leaf, leafKeyHash, entry, keyHash, shift + 5);
							return remap(this.treeMap | branch, this.leafMap ^ branch, this.size + 1).setTree(branch, tree);
						}

					case TREE:
						final «genericName» oldTree = getTree(branch);
						final «genericName» newTree = oldTree.update(key, keyHash, value, shift + 5);
						if (newTree == oldTree) {
							return this;
						} else {
							return remap(this.treeMap, this.leafMap, this.size + newTree.size - oldTree.size).setTree(branch, newTree);
						}

					case COLLISION:
						final P[] oldCollision = getCollision(branch);
						final P[] newCollision = updateCollision(oldCollision, key, value);
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

			«HashTableCommonGenerator.remove(genericName, "K", "key", "P<K, A>", "entry.get1().equals(key)", "P")»

			«HashTableCommonGenerator.merge(paramGenericName, "P<K, A>", diamondName)»

			private A getFromCollision(final P[] collision, final K key) {
				for (final P<K, A> entry : collision) {
					if (entry.get1().equals(key)) {
						return entry.get2();
					}
				}
				return null;
			}

			private P[] updateCollision(final P[] collision, final K key, final A value) {
				for (int i = 0; i < collision.length; i++) {
					final P<K, A> entry = collision[i];
					if (entry.get1().equals(key)) {
						if (entry.get2() == value) {
							return collision;
						} else {
							final P[] newCollision = new P[collision.length];
							System.arraycopy(collision, 0, newCollision, 0, collision.length);
							newCollision[i] = p(key, value);
							return newCollision;
						}
					}
				}

				final P[] newCollision = new P[collision.length + 1];
				System.arraycopy(collision, 0, newCollision, 1, collision.length);
				newCollision[0] = p(key, value);
				return newCollision;
			}

			private P[] removeFromCollision(final P[] collision, final K key) {
				for (int i = 0; i < collision.length; i++) {
					final P<K, A> entry = collision[i];
					if (entry.get1().equals(key)) {
						final P[] newCollision = new P[collision.length - 1];
						System.arraycopy(collision, 0, newCollision, 0, i);
						System.arraycopy(collision, i + 1, newCollision, i, newCollision.length - i);
						return newCollision;
					}
				}
				return collision;
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return isEmpty() ? Collections.emptyIterator() : new HashTableIterator<>(this.leafMap, this.treeMap, this.slots);
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				«HashTableCommonGenerator.forEach("forEach", "action", "accept", "P", "P<K, A>")»
			}

			«keyValueEquals»

			«keyValueHashCode»

			@Override
			public String toString() {
				return iterableToString(this, "«shortName»");
			}

			public static «paramGenericName» empty«shortName»() {
				return («genericName») EMPTY;
			}

			public static «paramGenericName» dict(final K key, final A value) {
				return «shortName».<K, A> empty«shortName»().put(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				public static «paramGenericName» dict«i»(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return «shortName».<K, A> empty«shortName»()
						«FOR j : 1 .. i»
							.put(key«j», value«j»)«IF j == i»;«ENDIF»
						«ENDFOR»
				}

			«ENDFOR»
			«javadocSynonym('''empty«shortName»''')»
			public static «paramGenericName» of() {
				return empty«shortName»();
			}

			«javadocSynonym("dict")»
			public static «paramGenericName» of(final K key, final A value) {
				return dict(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				«javadocSynonym("dict" + i)»
				public static «paramGenericName» of(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return dict«i»(«(1..i).map["key" + it + ", value" + it].join(", ")»);
				}

			«ENDFOR»
			@SafeVarargs
			public static «paramGenericName» ofEntries(final P<K, A>... entries) {
				final DictBuilder<K, A> builder = builder();
				builder.putEntries(entries);
				return builder.build();
			}

			public static «paramGenericName» ofAll(final Iterable<P<K, A>> entries) {
				final DictBuilder<K, A> builder = builder();
				builder.putAll(entries);
				return builder.build();
			}

			public static «paramGenericName» fromIterator(final Iterator<P<K, A>> entries) {
				final DictBuilder<K, A> builder = builder();
				builder.putIterator(entries);
				return builder.build();
			}

			public static «paramGenericName» fromStream(final Stream<P<K, A>> entries) {
				final DictBuilder<K, A> builder = builder();
				builder.putStream(entries);
				return builder.build();
			}

			public static «paramGenericName» fromMap(final Map<K, A> map) {
				final DictBuilder<K, A> builder = builder();
				builder.putMap(map);
				return builder.build();
			}

			public static <K, A> DictBuilder<K, A> builder() {
				return new DictBuilder<>();
			}

			«cast(#["K", "A"], #[], #["A"])»
		}
	''' }
}