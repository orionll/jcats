package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.ClassGenerator

class DictGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "Dict" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import «Constants.EFF»2;
		import «Constants.F»;
		import «Constants.KEY_VALUE»;
		import «Constants.OPTION»;
		import «Constants.P»;
		import «Constants.SIZED»;

		import java.io.Serializable;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.Objects;
		import java.util.function.Consumer;

		import static java.util.Objects.requireNonNull;
		import static «Constants.OPTION».nullableToOption;
		import static «Constants.P».p;
		import static jcats.collection.Common.iterableToString;


		public final class Dict<K, A> implements KeyValue<K, A>, Iterable<P<K, A>>, Serializable {

			private static final Dict EMPTY = new Dict(0, 0, Array.EMPTY.array);

			static final int VOID = 0, LEAF = 1, TREE = 2, COLLISION = 3;

			private final int treeMap;
			private final int leafMap;
			private final Object[] slots;

			private Dict(final int treeMap, final int leafMap, final Object[] slots) {
				this.treeMap = treeMap;
				this.leafMap = leafMap;
				this.slots = slots;
			}

			public static <K, A> Dict<K, A> empty() {
				return EMPTY;
			}

			public boolean isEmpty() {
				return (this == EMPTY);
			}

			@Override
			public boolean containsKey(final K key) {
				return containsKey(key, key.hashCode(), 0);
			}

			@Override
			public Option<A> get(K key) {
				return nullableToOption(getOrNull(key));
			}

			public A getOrNull(final K key) {
				return get(key, key.hashCode(), 0);
			}

			public Dict<K, A> put(final K key, final A value) {
				requireNonNull(value);
				return update(key, key.hashCode(), value, 0);
			}

			public Dict<K, A> remove(final K key) {
				return remove(key, key.hashCode(), 0);
			}

			private A get(final K key, final int keyHash, final int shift) {
				final int branch = choose(keyHash, shift);

				switch (follow(branch)) {
					case VOID: return null;

					case LEAF:
						final P<K, A> entry = getEntry(branch);
						if (entry.get1().equals(key)) {
							return entry.get2();
						} else {
							return null;
						}

					case TREE: return getTree(branch).get(key, keyHash, shift + 5);
					case COLLISION: return getCollision(branch).get(key);
					default: throw new AssertionError();
				}
			}

			private int slotMap() {
				return treeMap | leafMap;
			}

			private static int choose(final int hash, final int shift) {
				return 1 << ((hash >>> shift) & 0x1F);
			}

			private int select(final int branch) {
				return Integer.bitCount((slotMap() & (branch - 1)));
			}

			private int follow(final int branch) {
				return (((leafMap & branch) != 0) ? 1 : 0) | (((treeMap & branch) != 0) ? 2 : 0);
			}

			private P<K, A> entryAt(final int index) {
				return (P<K, A>) slots[index];
			}

			private P<K, A> getEntry(final int branch) {
				return entryAt(select(branch));
			}

			private Dict<K, A> setEntry(final int branch, final P<K, A> entry) {
				slots[select(branch)] = entry;
				return this;
			}

			private Dict<K, A> treeAt(final int index) {
				return (Dict<K, A>) slots[index];
			}

			private Dict<K, A> getTree(final int branch) {
				return treeAt(select(branch));
			}

			private Dict<K, A> setTree(final int branch, final Dict<K, A> tree) {
				slots[select(branch)] = tree;
				return this;
			}

			private ListDict<K, A> collisionAt(final int index) {
				return (ListDict<K, A>) slots[index];
			}

			private ListDict<K, A> getCollision(final int branch) {
				return collisionAt(select(branch));
			}

			private Dict<K, A> setCollision(final int branch, final ListDict<K, A> dict) {
				slots[select(branch)] = dict;
				return this;
			}

			private boolean isSingle() {
				return treeMap == 0 && Integer.bitCount(leafMap) == 1;
			}

			private P<K, A> singleEntry() {
				return (P<K, A>) slots[0];
			}

			private Dict<K, A> remap(final int treeMap, final int leafMap) {
				if (this.leafMap == leafMap && this.treeMap == treeMap) {
					return new Dict<>(treeMap, leafMap, slots.clone());
				} else {
					int oldSlotMap = this.treeMap | this.leafMap;
					int newSlotMap = treeMap | leafMap;
					int i = 0;
					int j = 0;
					final int size = Integer.bitCount(newSlotMap);
					if (size == 0) {
						return empty();
					} else {
						final Object[] slots = new Object[size];
						while (newSlotMap != 0) {
							if ((oldSlotMap & newSlotMap & 1) == 1) {
								slots[j] = this.slots[i];
							}
							if ((oldSlotMap & 1) == 1) {
								i++;
							}
							if ((newSlotMap & 1) == 1) {
								j++;
							}

							oldSlotMap >>>= 1;
							newSlotMap >>>= 1;
						}
						return new Dict<>(treeMap, leafMap, slots);
					}
				}
			}

			private boolean containsKey(final K key, final int keyHash, final int shift) {
				final int branch = choose(keyHash, shift);

				switch (follow(branch)) {
					case VOID: return false;
					case LEAF: return getEntry(branch).get1().equals(key);
					case TREE: return getTree(branch).containsKey(key, keyHash, shift + 5);
					case COLLISION: return getCollision(branch).containsKey(key);
					default: throw new AssertionError();
				}
			}

			private Dict<K, A> update(final K key, final int keyHash, final A value, final int shift) {
				final int branch = choose(keyHash, shift);

				switch (follow(branch)) {
					case VOID:
						return remap(treeMap, leafMap | branch).setEntry(branch, p(key, value));

					case LEAF:
						final P<K, A> leaf = getEntry(branch);
						final K leafKey = leaf.get1();
						final int leafKeyHash = leafKey.hashCode();
						if (keyHash == leafKeyHash) {
							if (key.equals(leafKey)) {
								if (value == leaf.get2()) {
									return this;
								} else {
									return remap(treeMap, leafMap).setEntry(branch, p(key, value));
								}
							} else {
								final ListDict<K, A> listDict = new ListDict<>(p(key, value), new ListDict<>(leaf, null));
								return remap(treeMap | branch, leafMap).setCollision(branch, listDict);
							}
						} else {
							final P<K, A> entry = p(key, value);
							final Dict<K, A> tree = merge(leaf, leafKeyHash, entry, keyHash, shift + 5);
							return remap(treeMap | branch, leafMap ^ branch).setTree(branch, tree);
						}

					case TREE:
						final Dict<K, A> oldTree = getTree(branch);
						final Dict<K, A> newTree = oldTree.update(key, keyHash, value, shift + 5);
						if (newTree == oldTree) {
							return this;
						} else {
							return remap(treeMap, leafMap).setTree(branch, newTree);
						}

					case COLLISION:
						final ListDict<K, A> oldDict = getCollision(branch);
						final ListDict<K, A> newDict = oldDict.update(key, value);
						if (newDict == oldDict) {
							return this;
						} else {
							return remap(treeMap, leafMap).setCollision(branch, newDict);
						}

					default:
						throw new AssertionError();
				}
			}

			private Dict<K, A> remove(final K key, final int keyHash, final int shift) {
				final int branch = choose(keyHash, shift);

				switch (follow(branch)) {
					case VOID:
						return this;

					case LEAF:
						final P<K, A> entry = getEntry(branch);
						if (entry.get1().equals(key)) {
							return remap(treeMap, leafMap ^ branch);
						} else {
							return this;
						}

					case TREE:
						final Dict<K, A> oldTree = getTree(branch);
						final Dict<K, A> newTree = oldTree.remove(key, keyHash, shift + 5);
						if (oldTree == newTree) {
							return this;
						} else if (newTree.isEmpty()) {
							return remap(treeMap ^ branch, leafMap);
						} else if (newTree.isSingle()) {
							return remap(treeMap ^ branch, leafMap | branch).setEntry(branch, newTree.singleEntry());
						} else {
							return remap(treeMap, leafMap).setTree(branch, newTree);
						}

					case COLLISION:
						final ListDict<K, A> oldDict = getCollision(branch);
						final ListDict<K, A> newDict = oldDict.remove(key);
						if (newDict == oldDict) {
							return this;
						} else if (newDict == null) {
							return remap(treeMap ^ branch, leafMap);
						} else if (newDict.next == null) {
							return remap(treeMap ^ branch, leafMap | branch).setEntry(branch, newDict.entry);
						} else {
							return remap(treeMap, leafMap).setCollision(branch, newDict);
						}

					default:
						throw new AssertionError();
				}
			}

			private Dict<K, A> merge(final P<K, A> entry0, final int hash0, final P<K, A> entry1, final int hash1, final int shift) {
				// assume(hash0 != hash1)
				final int branch0 = choose(hash0, shift);
				final int branch1 = choose(hash1, shift);
				final int slotMap = branch0 | branch1;
				if (branch0 == branch1) {
					final Object[] slots = { merge(entry0, hash0, entry1, hash1, shift + 5) };
					return new Dict<>(slotMap, 0, slots);
				} else {
					final Object[] slots = new Object[2];
					if (((branch0 - 1) & branch1) == 0) {
						slots[0] = entry0;
						slots[1] = entry1;
					} else {
						slots[0] = entry1;
						slots[1] = entry0;
					}
					return new Dict<>(0, slotMap, slots);
				}
			}

			public Iterator<P<K, A>> iterator() {
				return new DictIterator<>(leafMap, treeMap, slots);
			}

			@Override
			public String toString() {
				return iterableToString(this, "Dict");
			}
		}

		final class DictIterator<K, A> implements Iterator<P<K, A>> {
			private int leafMap;
			private int treeMap;
			private final Object[] slots;
			private int i;
			private Iterator<P<K, A>> childIterator;

			DictIterator(int leafMap, int treeMap, final Object[] slots) {
				this.leafMap = leafMap;
				this.treeMap = treeMap;
				this.slots = slots;
			}

			@Override
			public boolean hasNext() {
				return ((treeMap | leafMap) != 0) || (childIterator != null && childIterator.hasNext());
			}

			@Override
			public P<K, A> next() {
				if (childIterator == null || !childIterator.hasNext()) {
					if (childIterator != null) {
						childIterator = null;
					}
					if ((treeMap | leafMap) == 0) {
						throw new NoSuchElementException();
					}

					int slotType;
					while ((slotType = (leafMap & 1) | (treeMap & 1) << 1) == Dict.VOID) {
						treeMap >>>= 1;
						leafMap >>>= 1;
					}

					P<K, A> next = null;
					switch (slotType) {
						case Dict.LEAF:
							next = entryAt(i++);
							break;

						case Dict.TREE:
							childIterator = treeAt(i++).iterator();
							next = childIterator.next();
							break;

						case Dict.COLLISION:
							childIterator = collisionAt(i++).iterator();
							next = childIterator.next();
							break;
					}

					treeMap >>>= 1;
					leafMap >>>= 1;

					return next;
				} else {
					return childIterator.next();
				}
			}

			private P<K, A> entryAt(final int index) {
				return (P<K, A>) slots[index];
			}

			private Dict<K, A> treeAt(final int index) {
				return (Dict<K, A>) slots[index];
			}

			private ListDict<K, A> collisionAt(final int index) {
				return (ListDict<K, A>) slots[index];
			}
		}

		/**
		 * Used when multiple keys have hash collisions.
		 */
		final class ListDict<K, A> implements Serializable {
			final P<K, A> entry;
			final ListDict<K, A> next;

			ListDict(final P<K, A> entry, final ListDict<K, A> next) {
				this.entry = entry;
				this.next = next;
			}

			boolean containsKey(final K key) {
				for (ListDict<K, A> dict = this; dict != null; dict = dict.next) {
					if (dict.entry.get1().equals(key)) {
						return true;
					}
				}
				return false;
			}

			A get(final K key) {
				for (ListDict<K, A> dict = this; dict != null; dict = dict.next) {
					if (dict.entry.get1().equals(key)) {
						return dict.entry.get2();
					}
				}
				return null;
			}

			ListDict<K, A> update(final K key, final A value) {
				ListDict<K, A> nodeToUpdate = this;
				while (nodeToUpdate != null) {
					if (nodeToUpdate.entry.get1().equals(key)) {
						break;
					}
					nodeToUpdate = nodeToUpdate.next;
				}

				if (nodeToUpdate == null) {
					return new ListDict<>(p(key, value), this);
				} else if (nodeToUpdate.entry.get2() == value) {
					return this;
				} else {
					ListDict<K, A> result = new ListDict<>(p(key, value), nodeToUpdate.next);
					for (ListDict<K, A> dict = this; dict != nodeToUpdate; dict = dict.next) {
						result = new ListDict<>(dict.entry, result);
					}
					return result;
				}
			}

			ListDict<K, A> remove(final K key) {
				ListDict<K, A> nodeToRemove = this;
				while (nodeToRemove != null) {
					if (nodeToRemove.entry.get1().equals(key)) {
						break;
					}
					nodeToRemove = nodeToRemove.next;
				}

				if (nodeToRemove == null) {
					return this;
				} else {
					ListDict<K, A> result = nodeToRemove.next;
					for (ListDict<K, A> dict = this; dict != nodeToRemove; dict = dict.next) {
						result = new ListDict<>(dict.entry, result);
					}
					return result;
				}
			}

			Iterator<P<K, A>> iterator() {
				return new ListDictIterator<>(this);
			}
		}

		final class ListDictIterator<K, A> implements Iterator<P<K, A>> {
			private ListDict<K, A> current;

			ListDictIterator(final ListDict<K, A> dict) {
				current = dict;
			}

			@Override
			public boolean hasNext() {
				return (current != null);
			}

			@Override
			public P<K, A> next() {
				final P<K, A> result = current.entry;
				current = current.next;
				return result;
			}
		}
	''' }
}