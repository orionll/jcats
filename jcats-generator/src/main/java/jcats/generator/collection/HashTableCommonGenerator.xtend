package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class HashTableCommonGenerator implements ClassGenerator {

	override className() { "jcats.collection.HashTableCommon" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.NoSuchElementException;

		final class HashTableCommon {

			static final int VOID = 0b00;
			static final int LEAF = 0b01;
			static final int TREE = 0b10;
			static final int COLLISION = 0b11;

			private HashTableCommon() {
			}

			static int branch(final int hash, final int shift) {
				return 1 << ((hash >>> shift) & 0b11111);
			}

			static int arrayIndex(final int branch, final int treeMap, final int leafMap) {
				return Integer.bitCount(((treeMap | leafMap) & (branch - 1)));
			}

			static int slotType(final int branch, final int treeMap, final int leafMap) {
				return (((leafMap & branch) != 0) ? 1 : 0) | (((treeMap & branch) != 0) ? 2 : 0);
			}
		}

		final class HashTableIterator<A> implements Iterator<A> {
			private int leafMap;
			private int treeMap;
			private final Object[] slots;
			private int i;
			private Iterator<A> childIterator;

			HashTableIterator(final int leafMap, final int treeMap, final Object[] slots) {
				this.leafMap = leafMap;
				this.treeMap = treeMap;
				this.slots = slots;
			}

			@Override
			public boolean hasNext() {
				return ((this.treeMap | this.leafMap) != 0) || (this.childIterator != null && this.childIterator.hasNext());
			}

			@Override
			public A next() {
				if (this.childIterator == null || !this.childIterator.hasNext()) {
					if (this.childIterator != null) {
						this.childIterator = null;
					}
					if ((this.treeMap | this.leafMap) == 0) {
						throw new NoSuchElementException();
					}

					int slotType;
					while ((slotType = (this.leafMap & 1) | (this.treeMap & 1) << 1) == HashTableCommon.VOID) {
						this.treeMap >>>= 1;
						this.leafMap >>>= 1;
					}

					A next = null;
					switch (slotType) {
						case HashTableCommon.LEAF:
							next = entryAt(this.i++);
							break;

						case HashTableCommon.TREE:
							this.childIterator = treeAt(this.i++).iterator();
							next = this.childIterator.next();
							break;

						case HashTableCommon.COLLISION:
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

			private A entryAt(final int index) {
				return (A) this.slots[index];
			}

			private Iterable<A> treeAt(final int index) {
				return (Iterable<A>) this.slots[index];
			}

			private Object[] collisionAt(final int index) {
				return (Object[]) this.slots[index];
			}
		}
	''' }

	def static remap(String shortName, String genericName, String diamondName) { '''
		private «genericName» remap(final int treeMap, final int leafMap, final int size) {
			if (this.leafMap == leafMap && this.treeMap == treeMap) {
				return new «diamondName»(treeMap, leafMap, this.slots.clone(), size);
			} else if (size == 0) {
				return empty«shortName»();
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
				return new «diamondName»(treeMap, leafMap, slots, size);
			}
		}
	''' }

	def static remove(String genericName, String keyType, String key, String entryType, String keyTest, String rawType) { '''
		private «genericName» remove(final «keyType» «key», final int «key»Hash, final int shift) {
			final int branch = branch(«key»Hash, shift);

			switch (slotType(branch, this.treeMap, this.leafMap)) {
				case VOID:
					return this;

				case LEAF:
					final «entryType» entry = getEntry(branch);
					if («keyTest») {
						return remap(this.treeMap, this.leafMap ^ branch, this.size - 1);
					} else {
						return this;
					}

				case TREE:
					final «genericName» oldTree = getTree(branch);
					final «genericName» newTree = oldTree.remove(«key», «key»Hash, shift + 5);
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
					final «rawType»[] oldCollision = getCollision(branch);
					final «rawType»[] newCollision = removeFromCollision(oldCollision, «key»);
					if (newCollision == oldCollision) {
						return this;
					} else if (newCollision.length == 1) {
						return remap(this.treeMap ^ branch, this.leafMap | branch, this.size - 1).setEntry(branch, («entryType») newCollision[0]);
					} else {
						return remap(this.treeMap, this.leafMap, this.size - 1).setCollision(branch, newCollision);
					}

				default:
					throw new AssertionError();
			}
		}
	''' }

	def static merge(String paramGenericName, String entryName, String diamondName) { '''
		private static «paramGenericName» merge(final «entryName» entry0, final int hash0, final «entryName» entry1, final int hash1, final int shift) {
			// assume(hash0 != hash1)
			final int branch0 = branch(hash0, shift);
			final int branch1 = branch(hash1, shift);
			final int slotMap = branch0 | branch1;
			if (branch0 == branch1) {
				final Object[] slots = { merge(entry0, hash0, entry1, hash1, shift + 5) };
				return new «diamondName»(slotMap, 0, slots, 2);
			} else {
				final Object[] slots = new Object[2];
				if (((branch0 - 1) & branch1) == 0) {
					slots[0] = entry0;
					slots[1] = entry1;
				} else {
					slots[0] = entry1;
					slots[1] = entry0;
				}
				return new «diamondName»(0, slotMap, slots, 2);
			}
		}
	''' }

	def static forEach(String name, String actionName, String actionFunc, String rawType, String entryType) { '''
		requireNonNull(«actionName»);
		int i = 0;
		int treeMap = this.treeMap;
		int leafMap = this.leafMap;
		while ((treeMap | leafMap) != 0) {
			switch ((leafMap & 1 | (treeMap & 1) << 1)) {
				case VOID: break;
				case LEAF: «actionName».«actionFunc»(entryAt(i++)); break;
				case TREE: treeAt(i++).«name»(«actionName»); break;
				case COLLISION:
					for (final «rawType» entry : collisionAt(i++)) {
						«actionName».«actionFunc»((«entryType») entry);
					}
					break;
			}
			treeMap >>>= 1;
			leafMap >>>= 1;
		}
	''' }

	def static getFirst(String name, String entryType) '''
		while (true) {
			if («name».leafMap == 0) {
				«name» = «name».treeAt(0);
			} else {
				int i = 0;
				int treeMap = «name».treeMap;
				int leafMap = «name».leafMap;
				while (true) {
					switch ((leafMap & 1 | (treeMap & 1) << 1)) {
						case VOID: break;
						case LEAF: return «name».entryAt(i);
						case COLLISION: return («entryType») «name».collisionAt(i)[0];
						default: i++;
					}
					treeMap >>>= 1;
					leafMap >>>= 1;
				}
			}
		}
	'''
}