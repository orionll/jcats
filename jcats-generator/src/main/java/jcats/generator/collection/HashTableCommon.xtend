package jcats.generator.collection

final class HashTableCommon {

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
			final int branch = choose(«key»Hash, shift);

			switch (follow(branch)) {
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
			final int branch0 = choose(hash0, shift);
			final int branch1 = choose(hash1, shift);
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

	def static iteratorNext(String entryType) { '''
		@Override
		public «entryType» next() {
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

				«entryType» next = null;
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
	''' }
}