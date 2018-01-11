package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.ClassGenerator
import jcats.generator.Type

class DictGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "Dict" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.P».p;
		import static jcats.collection.Common.*;


		public final class Dict<K, @Covariant A> implements KeyValue<K, A>, Serializable {
			private static final Dict<?, ?> EMPTY = new Dict(0, 0, Common.«Type.OBJECT.emptyArrayName», 0);

			static final int VOID = 0, LEAF = 1, TREE = 2, COLLISION = 3;

			private final int treeMap;
			private final int leafMap;
			private final Object[] slots;
			private final int size;

			private Dict(final int treeMap, final int leafMap, final Object[] slots, final int size) {
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
					case COLLISION: return getFromCollision(getCollision(branch), key);
					default: throw new AssertionError();
				}
			}

			private int slotMap() {
				return this.treeMap | this.leafMap;
			}

			private static int choose(final int hash, final int shift) {
				return 1 << ((hash >>> shift) & 0x1F);
			}

			private int select(final int branch) {
				return Integer.bitCount((slotMap() & (branch - 1)));
			}

			private int follow(final int branch) {
				return (((this.leafMap & branch) != 0) ? 1 : 0) | (((this.treeMap & branch) != 0) ? 2 : 0);
			}

			private P<K, A> entryAt(final int index) {
				return (P<K, A>) this.slots[index];
			}

			private P<K, A> getEntry(final int branch) {
				return entryAt(select(branch));
			}

			private Dict<K, A> setEntry(final int branch, final P<K, A> entry) {
				this.slots[select(branch)] = entry;
				return this;
			}

			private Dict<K, A> treeAt(final int index) {
				return (Dict<K, A>) this.slots[index];
			}

			private Dict<K, A> getTree(final int branch) {
				return treeAt(select(branch));
			}

			private Dict<K, A> setTree(final int branch, final Dict<K, A> tree) {
				this.slots[select(branch)] = tree;
				return this;
			}

			private P[] collisionAt(final int index) {
				return (P[]) this.slots[index];
			}

			private P[] getCollision(final int branch) {
				return collisionAt(select(branch));
			}

			private Dict<K, A> setCollision(final int branch, final P[] collision) {
				this.slots[select(branch)] = collision;
				return this;
			}

			private boolean isSingle() {
				return this.treeMap == 0 && Integer.bitCount(this.leafMap) == 1;
			}

			private P<K, A> singleEntry() {
				return (P<K, A>) this.slots[0];
			}

			private Dict<K, A> remap(final int treeMap, final int leafMap, final int size) {
				if (this.leafMap == leafMap && this.treeMap == treeMap) {
					return new Dict<>(treeMap, leafMap, this.slots.clone(), size);
				} else if (size == 0) {
					return emptyDict();
				} else  {
					int oldSlotMap = this.treeMap | this.leafMap;
					int newSlotMap = treeMap | leafMap;
					int i = 0;
					int j = 0;
					final Object[] slots = new Object[Integer.bitCount(newSlotMap)];
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
					return new Dict<>(treeMap, leafMap, slots, size);
				}
			}

			private Dict<K, A> update(final K key, final int keyHash, final A value, final int shift) {
				final int branch = choose(keyHash, shift);

				switch (follow(branch)) {
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
							final Dict<K, A> tree = merge(leaf, leafKeyHash, entry, keyHash, shift + 5);
							return remap(this.treeMap | branch, this.leafMap ^ branch, this.size + 1).setTree(branch, tree);
						}

					case TREE:
						final Dict<K, A> oldTree = getTree(branch);
						final Dict<K, A> newTree = oldTree.update(key, keyHash, value, shift + 5);
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

			private Dict<K, A> remove(final K key, final int keyHash, final int shift) {
				final int branch = choose(keyHash, shift);

				switch (follow(branch)) {
					case VOID:
						return this;

					case LEAF:
						final P<K, A> entry = getEntry(branch);
						if (entry.get1().equals(key)) {
							return remap(this.treeMap, this.leafMap ^ branch, this.size - 1);
						} else {
							return this;
						}

					case TREE:
						final Dict<K, A> oldTree = getTree(branch);
						final Dict<K, A> newTree = oldTree.remove(key, keyHash, shift + 5);
						if (oldTree == newTree) {
							return this;
						} else if (newTree.isEmpty()) {
							return remap(this.treeMap ^ branch, this.leafMap, this.size - 1);
						} else if (newTree.isSingle()) {
							return remap(this.treeMap ^ branch, this.leafMap | branch, this.size + 1 - oldTree.size).setEntry(branch, newTree.singleEntry());
						} else {
							return remap(this.treeMap, this.leafMap, this.size + newTree.size - oldTree.size).setTree(branch, newTree);
						}

					case COLLISION:
						final P[] oldCollision = getCollision(branch);
						final P[] newCollision = removeFromCollision(oldCollision, key);
						if (newCollision == oldCollision) {
							return this;
						} else if (newCollision.length == 1) {
							return remap(this.treeMap ^ branch, this.leafMap | branch, this.size - 1).setEntry(branch, newCollision[0]);
						} else {
							return remap(this.treeMap, this.leafMap, this.size - 1).setCollision(branch, newCollision);
						}

					default:
						throw new AssertionError();
				}
			}

			private static <K, A> Dict<K, A> merge(final P<K, A> entry0, final int hash0, final P<K, A> entry1, final int hash1, final int shift) {
				// assume(hash0 != hash1)
				final int branch0 = choose(hash0, shift);
				final int branch1 = choose(hash1, shift);
				final int slotMap = branch0 | branch1;
				if (branch0 == branch1) {
					final Object[] slots = { merge(entry0, hash0, entry1, hash1, shift + 5) };
					return new Dict<>(slotMap, 0, slots, 2);
				} else {
					final Object[] slots = new Object[2];
					if (((branch0 - 1) & branch1) == 0) {
						slots[0] = entry0;
						slots[1] = entry1;
					} else {
						slots[0] = entry1;
						slots[1] = entry0;
					}
					return new Dict<>(0, slotMap, slots, 2);
				}
			}

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
				return new DictIterator<>(this.leafMap, this.treeMap, this.slots);
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				requireNonNull(action);
				int i = 0;
				int treeMap = this.treeMap;
				int leafMap = this.leafMap;
				while ((treeMap | leafMap) != 0) {
					switch ((leafMap & 1 | (treeMap & 1) << 1)) {
						case VOID: break;
						case LEAF: action.accept(entryAt(i++)); break;
						case TREE: treeAt(i++).forEach(action); break;
						case COLLISION:
							for (final P<K, A> entry : collisionAt(i++)) {
								action.accept(entry);
							}
							break;
					}
					treeMap >>>= 1;
					leafMap >>>= 1;
				}
			}

			«keyValueEquals»

			«keyValueHashCode»

			@Override
			public String toString() {
				return iterableToString(this, "Dict");
			}

			public static <K, A> Dict<K, A> emptyDict() {
				return (Dict<K, A>) EMPTY;
			}

			public static <K, A> Dict<K, A> dict(final K key, final A value) {
				return Dict.<K, A> emptyDict().put(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				public static <K, A> Dict<K, A> dict«i»(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return Dict.<K, A> emptyDict()
						«FOR j : 1 .. i»
							.put(key«j», value«j»)«IF j == i»;«ENDIF»
						«ENDFOR»
				}

			«ENDFOR»
			«javadocSynonym("emptyDict")»
			public static <K, A> Dict<K, A> of() {
				return emptyDict();
			}

			«javadocSynonym("dict")»
			public static <K, A> Dict<K, A> of(final K key, final A value) {
				return dict(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				«javadocSynonym("dict" + i)»
				public static <K, A> Dict<K, A> of(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return dict«i»(«(1..i).map["key" + it + ", value" + it].join(", ")»);
				}

			«ENDFOR»
			@SafeVarargs
			public static <K, A> Dict<K, A> ofEntries(final P<K, A>... entries) {
				Dict<K, A> dict = emptyDict();
				for (final P<K, A> entry : entries) {
					dict = dict.put(entry.get1(), entry.get2());
				}
				return dict;
			}

			«cast(#["K", "A"], #[], #["A"])»
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
				return ((this.treeMap | this.leafMap) != 0) || (this.childIterator != null && this.childIterator.hasNext());
			}

			@Override
			public P<K, A> next() {
				if (this.childIterator == null || !this.childIterator.hasNext()) {
					if (this.childIterator != null) {
						this.childIterator = null;
					}
					if ((this.treeMap | this.leafMap) == 0) {
						throw new NoSuchElementException();
					}

					int slotType;
					while ((slotType = (this.leafMap & 1) | (this.treeMap & 1) << 1) == Dict.VOID) {
						this.treeMap >>>= 1;
						this.leafMap >>>= 1;
					}

					P<K, A> next = null;
					switch (slotType) {
						case Dict.LEAF:
							next = entryAt(this.i++);
							break;

						case Dict.TREE:
							this.childIterator = treeAt(this.i++).iterator();
							next = this.childIterator.next();
							break;

						case Dict.COLLISION:
							this.childIterator = new ArrayIterator<>(collisionAt(this.i++));
							next = this.childIterator.next();
							break;
					}

					this.treeMap >>>= 1;
					this.leafMap >>>= 1;

					return next;
				} else {
					return this.childIterator.next();
				}
			}

			private P<K, A> entryAt(final int index) {
				return (P<K, A>) this.slots[index];
			}

			private Dict<K, A> treeAt(final int index) {
				return (Dict<K, A>) this.slots[index];
			}

			private P[] collisionAt(final int index) {
				return (P[]) this.slots[index];
			}
		}
	''' }
}