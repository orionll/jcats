package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class UniqueGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].map[new UniqueGenerator(it) as Generator].toList
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.uniqueShortName }
	def paramGenericName() { type.paramGenericName("Unique") }
	def genericName() { type.genericName("Unique") }
	def diamondName() { type.diamondName("Unique") }
	def wildcardName() { type.wildcardName("Unique") }
	def hashCode(String expr) { if (type == Type.OBJECT) expr + ".hashCode()" else type.boxedName + ".hashCode(" + expr + ")" }
	def equals(String expr1, String expr2) { if (type == Type.OBJECT) expr1 + ".equals(" + expr2 + ")" else expr1 + " == " + expr2 }

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
		import java.util.stream.Collector;
		import java.util.stream.«type.streamName»;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.COMMON».*;
		import static «Constants.COLLECTION».«type.arrayShortName».*;
		import static «Constants.COLLECTION».HashTableCommon.*;
		import static «Constants.COLLECTION».«type.seqShortName».*;

		public final class «type.covariantName("Unique")» implements «type.uniqueContainerGenericName», Serializable {
			private static final «wildcardName» EMPTY = new «diamondName»(0, 0, Common.«Type.OBJECT.emptyArrayName», «IF type.primitive»null, «ENDIF»0);

			private final int treeMap;
			private final int leafMap;
			private final Object[] slots;
			«IF type.primitive»
				private final «type.javaName»[] «type.javaName»Slots;
			«ENDIF»
			private final int size;

			private «shortName»(final int treeMap, final int leafMap, final Object[] slots, «IF type.primitive»final «type.javaName»[] «type.javaName»Slots, «ENDIF»final int size) {
				this.treeMap = treeMap;
				this.leafMap = leafMap;
				this.slots = slots;
				«IF type.primitive»
					this.«type.javaName»Slots = «type.javaName»Slots;
				«ENDIF»
				this.size = size;
			}

			@Override
			public int size() {
				return this.size;
			}

			@Override
			public boolean contains(final «type.genericName» value) {
				return get(value, «hashCode("value")», 0);
			}

			public «genericName» put(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return update(value, «hashCode("value")», 0);
			}

			public «genericName» remove(final «type.genericName» value) {
				return remove(value, «hashCode("value")», 0);
			}

			private boolean get(final «type.genericName» value, final int valueHash, final int shift) {
				final int branch = branch(valueHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID: return false;
					case LEAF: return «equals("getEntry(branch)", "value")»;
					case TREE: return getTree(branch).get(value, valueHash, shift + 5);
					case COLLISION: return getFromCollision(getCollision(branch), value);
					default: throw new AssertionError();
				}
			}

			@Override
			public «type.genericName» first() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return getFirst(this);
				}
			}

			@Override
			public «type.optionGenericName» firstOption() {
				if (isEmpty()) {
					return «type.noneName»();
				} else {
					return «type.someName»(getFirst(this));
				}
			}

			private static «type.paramGenericName» getFirst(«genericName» unique) {
				«HashTableCommonGenerator.getFirst("unique", type.genericName, type.primitive)»
			}

			private «type.genericName» entryAt(final int index) {
				«IF type == Type.OBJECT»
					return (A) this.slots[index];
				«ELSE»
					return (this.«type.javaName»Slots == null) ? («type.javaName») this.slots[index] : this.«type.javaName»Slots[index];
				«ENDIF»
			}

			private «type.genericName» getEntry(final int branch) {
				return entryAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setEntry(final int branch, final «type.genericName» entry) {
				«IF type == Type.OBJECT»
					this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = entry;
				«ELSE»
					if (this.«type.javaName»Slots == null) {
						this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = entry;
					} else {
						this.«type.javaName»Slots[arrayIndex(branch, this.treeMap, this.leafMap)] = entry;
					}
				«ENDIF»
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

			private «type.javaName»[] collisionAt(final int index) {
				return («type.javaName»[]) this.slots[index];
			}

			private «type.javaName»[] getCollision(final int branch) {
				return collisionAt(arrayIndex(branch, this.treeMap, this.leafMap));
			}

			private «genericName» setCollision(final int branch, final «type.javaName»[] collision) {
				this.slots[arrayIndex(branch, this.treeMap, this.leafMap)] = collision;
				return this;
			}

			private boolean isSingle() {
				return this.treeMap == 0 && Integer.bitCount(this.leafMap) == 1;
			}

			private «type.genericName» singleEntry() {
				«IF type == Type.OBJECT»
					return (A) this.slots[0];
				«ELSE»
					return this.«type.javaName»Slots[0];
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				«HashTableCommonGenerator.remap(shortName, genericName, diamondName)»
			«ELSE»
				private «genericName» remap(final int newTreeMap, final int newLeafMap, final int newSize) {
					if (this.leafMap == newLeafMap && this.treeMap == newTreeMap) {
						final Object[] newSlots = (this.slots == null) ? null : this.slots.clone();
						final «type.javaName»[] new«type.typeName»Slots = (this.«type.javaName»Slots == null) ? null : this.«type.javaName»Slots.clone();
						return new «diamondName»(newTreeMap, newLeafMap, newSlots, new«type.typeName»Slots, newSize);
					} else if (newSize == 0) {
						return empty«shortName»();
					} else if (newTreeMap == 0) {
						int oldSlotMap = this.treeMap | this.leafMap;
						int oldTreeMap = this.treeMap;
						int tempLeafMap = newLeafMap;
						int i = 0;
						int j = 0;
						final «type.javaName»[] new«type.typeName»Slots = new «type.javaName»[Integer.bitCount(newLeafMap)];
						while (tempLeafMap != 0) {
							if ((oldSlotMap & tempLeafMap & 1) == 1 && (oldTreeMap & 1) == 0) {
								new«type.typeName»Slots[j] = (this.«type.javaName»Slots == null) ? («type.javaName») this.slots[i] : this.«type.javaName»Slots[i];
							}
							if ((oldSlotMap & 1) == 1) {
								i++;
							}
							if ((tempLeafMap & 1) == 1) {
								j++;
							}

							oldSlotMap >>>= 1;
							oldTreeMap >>>= 1;
							tempLeafMap >>>= 1;
						}
						return new «diamondName»(0, newLeafMap, null, new«type.typeName»Slots, newSize);
					} else  {
						int oldSlotMap = this.treeMap | this.leafMap;
						int tempSlotMap = newTreeMap | newLeafMap;
						int i = 0;
						int j = 0;
						final Object[] newSlots = new Object[Integer.bitCount(tempSlotMap)];
						while (tempSlotMap != 0) {
							if ((oldSlotMap & tempSlotMap & 1) == 1) {
								newSlots[j] = (this.«type.javaName»Slots == null) ? this.slots[i] : this.«type.javaName»Slots[i];
							}
							if ((oldSlotMap & 1) == 1) {
								i++;
							}
							if ((tempSlotMap & 1) == 1) {
								j++;
							}

							oldSlotMap >>>= 1;
							tempSlotMap >>>= 1;
						}
						return new «diamondName»(newTreeMap, newLeafMap, newSlots, null, newSize);
					}
				}
			«ENDIF»

			private «genericName» update(final «type.genericName» value, final int valueHash, final int shift) {
				final int branch = branch(valueHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID:
						return remap(this.treeMap, this.leafMap | branch, this.size + 1).setEntry(branch, value);

					case LEAF:
						final «type.genericName» leaf = getEntry(branch);
						final int leafHash = «hashCode("leaf")»;
						if (valueHash == leafHash) {
							if («equals("value", "leaf")») {
								return this;
							} else {
								final «type.javaName»[] collision = { value, leaf };
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
						final «type.javaName»[] oldCollision = getCollision(branch);
						final «type.javaName»[] newCollision = updateCollision(oldCollision, value);
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

			«HashTableCommonGenerator.remove(genericName, type.genericName, "value", type.genericName, equals("entry", "value"), type.javaName, type.primitive)»

			«HashTableCommonGenerator.merge(type, paramGenericName, type.genericName, diamondName)»

			private static boolean getFromCollision(final «type.javaName»[] collision, final «type.javaName» value) {
				for (final «type.javaName» entry : collision) {
					if («equals("entry", "value")») {
						return true;
					}
				}
				return false;
			}

			private static «type.javaName»[] updateCollision(final «type.javaName»[] collision, final «type.javaName» value) {
				for (final «type.javaName» entry : collision) {
					if («equals("entry", "value")») {
						return collision;
					}
				}

				final «type.javaName»[] newCollision = new «type.javaName»[collision.length + 1];
				System.arraycopy(collision, 0, newCollision, 1, collision.length);
				newCollision[0] = value;
				return newCollision;
			}

			private static «type.javaName»[] removeFromCollision(final «type.javaName»[] collision, final «type.javaName» value) {
				for (int i = 0; i < collision.length; i++) {
					final «type.javaName» entry = collision[i];
					if («equals("entry", "value")») {
						final «type.javaName»[] newCollision = new «type.javaName»[collision.length - 1];
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
					final «type.uniqueBuilderGenericName» builder = new «type.uniqueBuilderDiamondName»(this);
					builder.putAll(iterable);
					return builder.build();
				}
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public «IF type == Type.OBJECT»final «ENDIF»«genericName» putValues(final «type.genericName»... values) {
				«genericName» unique = this;
				for (final «type.genericName» value : values) {
					unique = unique.put(value);
				}
				return unique;
			}

			@Override
			public «type.arrayGenericName» to«type.arrayShortName»() {
				if (isEmpty()) {
					return empty«type.arrayShortName»();
				} else if (this.treeMap == 0) {
					return new «type.arrayDiamondName»(this.«IF type == Type.OBJECT»slots«ELSE»«type.javaName»Slots«ENDIF»);
				} else {
					return «type.uniqueContainerShortName».super.to«type.arrayShortName»();
				}
			}

			@Override
			public «type.seqGenericName» to«type.seqShortName»() {
				if (isEmpty()) {
					return empty«type.seqShortName»();
				} else if (this.treeMap == 0) {
					return new «type.diamondName("Seq1")»(this.«IF type == Type.OBJECT»slots«ELSE»«type.javaName»Slots«ENDIF»);
				} else {
					return «type.uniqueContainerShortName».super.to«type.seqShortName»();
				}
			}

			@Deprecated
			@Override
			public «genericName» to«shortName»() {
				return this;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				if (isEmpty()) {
					return «type.emptyIterator»;
				} else if (this.treeMap == 0) {
					return new «type.diamondName("ArrayIterator")»(this.«IF type == Type.OBJECT»slots«ELSE»«type.javaName»Slots«ENDIF»);
				} else {
					return new «type.iteratorDiamondName("HashTable")»(this.leafMap, this.treeMap, this.slots);
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				«HashTableCommonGenerator.forEach("foreach", "eff", "apply", type.javaName, type.genericName, type.primitive)»
			}

			«uniqueEquals(type)»

			«uniqueHashCode(type)»

			«toStr(type)»

			public static «paramGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«genericName») «ENDIF»EMPTY;
			}

			public static «paramGenericName» single«shortName»(final «type.genericName» value) {
				return «IF type == Type.OBJECT»«shortName».<A> «ENDIF»empty«shortName»().put(value);
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» «shortName.firstToLowerCase»(final «type.genericName»... values) {
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
			public static <A> «genericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			public static «paramGenericName» ofAll(final Iterable<«type.genericBoxedName»> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof «type.containerWildcardName») {
					return ((«type.containerGenericName») iterable).to«shortName»();
				} else {
					final «type.uniqueBuilderGenericName» builder = builder();
					builder.putAll(iterable);
					return builder.build();
				}
			}

			«fillUntil(type, paramGenericName, type.uniqueBuilderGenericName, "put")»

			public static «paramGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				requireNonNull(iterator);
				final «type.uniqueBuilderGenericName» builder = builder();
				builder.putIterator(iterator);
				return builder.build();
			}

			public static «paramGenericName» from«type.streamName»(final «type.streamGenericName» stream) {
				final «type.uniqueBuilderGenericName» builder = builder();
				builder.put«type.streamName»(stream);
				return builder.build();
			}

			public static «type.paramGenericName("UniqueBuilder")» builder() {
				return new «type.uniqueBuilderDiamondName»();
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»Collector<«type.genericBoxedName», ?, «genericName»> collector() {
				«IF type == Type.OBJECT»
					return Collector.<«type.genericBoxedName», «type.uniqueBuilderGenericName», «genericName»> of(
				«ELSE»
					return Collector.of(
				«ENDIF»
						«shortName»::builder, «type.uniqueBuilderShortName»::put, «type.uniqueBuilderShortName»::merge, «type.uniqueBuilderShortName»::build);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
		«IF type.primitive»

			«HashTableCommonGenerator.iterator(type)»
		«ENDIF»
	''' }
}