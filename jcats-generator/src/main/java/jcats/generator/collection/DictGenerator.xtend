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

	def update(String entryFunc, String defaultEntryFunc, String createNewValue, String getValue, String recursiveCall, String updateCollision) '''
		final int branch = branch(keyHash, shift);

		switch (slotType(branch, this.treeMap, this.leafMap)) {
			case VOID:
				return remap(this.treeMap, this.leafMap | branch, this.size + 1).setEntry(branch, «defaultEntryFunc»);

			case LEAF:
				final P<K, A> leaf = getEntry(branch);
				final K leafKey = leaf.get1();
				final int leafKeyHash = leafKey.hashCode();
				if (keyHash == leafKeyHash) {
					if (key.equals(leafKey)) {
						«IF !createNewValue.empty»
							«createNewValue»
						«ENDIF»
						if («getValue» == leaf.get2()) {
							return this;
						} else {
							return remap(this.treeMap, this.leafMap, this.size).setEntry(branch, «entryFunc»);
						}
					} else {
						final P[] collision = { «defaultEntryFunc», leaf };
						return remap(this.treeMap | branch, this.leafMap, this.size + 1).setCollision(branch, collision);
					}
				} else {
					final «genericName» tree = merge(leaf, leafKeyHash, «defaultEntryFunc», keyHash, shift + 5);
					return remap(this.treeMap | branch, this.leafMap ^ branch, this.size + 1).setTree(branch, tree);
				}

			case TREE:
				final «genericName» oldTree = getTree(branch);
				final «genericName» newTree = oldTree.«recursiveCall»;
				if (newTree == oldTree) {
					return this;
				} else {
					return remap(this.treeMap, this.leafMap, this.size + newTree.size - oldTree.size).setTree(branch, newTree);
				}

			case COLLISION:
				final P[] oldCollision = getCollision(branch);
				final P[] newCollision = «updateCollision»;
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
	'''

	def updateCollision(String entryFunc, String createNewValue, String getValue) '''
		for (int i = 0; i < collision.length; i++) {
			if (collision[i].get1().equals(key)) {
				«IF !createNewValue.empty»
					«createNewValue»
				«ENDIF»
				if (collision[i].get2() == «getValue») {
					return collision;
				} else {
					final P[] newCollision = new P[collision.length];
					System.arraycopy(collision, 0, newCollision, 0, collision.length);
					newCollision[i] = «entryFunc»;
					return newCollision;
				}
			}
		}
	'''

	def prependToCollision(String defaultEntryFunc) '''
		final P[] newCollision = new P[collision.length + 1];
		System.arraycopy(collision, 0, newCollision, 1, collision.length);
		newCollision[0] = «defaultEntryFunc»;
		return newCollision;
	'''

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.Map;
		import java.util.NoSuchElementException;
		import java.util.function.Consumer;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.OPTION».*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		import static «Constants.COLLECTION».HashTableCommon.*;

		public final class «shortName»<K, @Covariant A> implements KeyValue<K, A>, Serializable {
			static final «wildcardName» EMPTY = new «shortName»(0, 0, Common.«Type.OBJECT.emptyArrayName», 0);

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
				return put(key, key.hashCode(), value, 0);
			}

			public «genericName» putEntry(final P<K, A> entry) {
				requireNonNull(entry);
				return putEntry(entry.get1(), entry.get1().hashCode(), entry, 0);
			}

			public «genericName» updateValue(final K key, final F<A, A> f) {
				requireNonNull(f);
				final int keyHash = key.hashCode();
				return updateValue(key, keyHash, f, 0);
			}

			public «genericName» updateValueOrPut(final K key, final A defaultValue, final F<A, A> f) {
				requireNonNull(defaultValue);
				requireNonNull(f);
				final int keyHash = key.hashCode();
				return updateValueOrPut(key, keyHash, defaultValue, f, 0);
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

			@Override
			public P<K, A> first() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return getFirst(this);
				}
			}

			@Override
			public Option<P<K, A>> findFirst() {
				if (isEmpty()) {
					return none();
				} else {
					return some(getFirst(this));
				}
			}

			private static <K, A> P<K, A> getFirst(Dict<K, A> dict) {
				«HashTableCommonGenerator.getFirst("dict", "P<K, A>", false)»
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

			private «genericName» put(final K key, final int keyHash, final A value, final int shift) {
				«update("p(key, value)", "p(key, value)", "", "value", "put(key, keyHash, value, shift + 5)", "putToCollision(oldCollision, key, value)")»
			}

			private «genericName» putEntry(final K key, final int keyHash, final P<K, A> entry, final int shift) {
				«update("entry", "entry", "", "entry.get2()", "putEntry(key, keyHash, entry, shift + 5)", "putEntryToCollision(oldCollision, key, entry)")»
			}

			private Dict<K, A> updateValue(final K key, final int keyHash, final F<A, A> f, final int shift) {
				final int branch = branch(keyHash, shift);

				switch (slotType(branch, this.treeMap, this.leafMap)) {
					case VOID:
						return this;

					case LEAF:
						final P<K, A> leaf = getEntry(branch);
						if (key.equals(leaf.get1())) {
							final A newValue = requireNonNull(f.apply(leaf.get2()));
							if (newValue == leaf.get2()) {
								return this;
							} else {
								return new Dict<K, A>(this.treeMap, this.leafMap, this.slots.clone(), this.size).setEntry(branch, p(key, newValue));
							}
						} else {
							return this;
						}

					case TREE:
						final Dict<K, A> oldTree = getTree(branch);
						final Dict<K, A> newTree = oldTree.updateValue(key, keyHash, f, shift + 5);
						if (newTree == oldTree) {
							return this;
						} else {
							return new Dict<K, A>(this.treeMap, this.leafMap, this.slots.clone(), this.size).setTree(branch, newTree);
						}

					case COLLISION:
						final P[] oldCollision = getCollision(branch);
						final P[] newCollision = updateValueOrPutToCollision(oldCollision, key, null, f);
						if (newCollision == oldCollision) {
							return this;
						} else {
							return new Dict<K, A>(this.treeMap, this.leafMap, this.slots.clone(), this.size).setCollision(branch, newCollision);
						}

					default:
						throw new AssertionError();
				}
			}

			private «genericName» updateValueOrPut(final K key, final int keyHash, final A defaultValue, final F<A, A> f, final int shift) {
				«update("p(key, newValue)", "p(key, defaultValue)", "final A newValue = requireNonNull(f.apply(leaf.get2()));",
					"newValue", "updateValueOrPut(key, keyHash, defaultValue, f, shift + 5)", "updateValueOrPutToCollision(oldCollision, key, defaultValue, f)")»
			}

			«HashTableCommonGenerator.remove(genericName, "K", "key", "P<K, A>", "entry.get1().equals(key)", "P", false)»

			«HashTableCommonGenerator.merge(Type.OBJECT, paramGenericName, "P<K, A>", diamondName)»

			private A getFromCollision(final P[] collision, final K key) {
				for (final P<K, A> entry : collision) {
					if (entry.get1().equals(key)) {
						return entry.get2();
					}
				}
				return null;
			}

			private P[] putToCollision(final P[] collision, final K key, final A value) {
				«updateCollision("p(key, value)", "", "value")»

				«prependToCollision("p(key, value)")»
			}

			private P[] putEntryToCollision(final P[] collision, final K key, final P<K, A> entry) {
				«updateCollision("entry", "", "entry.get2()")»

				«prependToCollision("entry")»
			}

			private P[] updateValueOrPutToCollision(final P[] collision, final K key, final A defaultValue, final F<A, A> f) {
				«updateCollision("p(key, newValue)", "final A newValue = requireNonNull(f.apply((A) collision[i].get2()));", "newValue")»

				if (defaultValue == null) {
					return collision;
				} else {
					«prependToCollision("p(key, defaultValue)")»
				}
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

			private «genericName» merge(final «genericName» other, final F3<K, A, A, A> mergeFunction) {
				requireNonNull(other);
				if (isEmpty()) {
					return other;
				} else if (other.isEmpty()) {
					return this;
				} else if (size() >= other.size()) {
					«genericName» result = this;
					for (final P<K, A> p : other) {
						final K key = p.get1();
						final A value2 = p.get2();
						result = result.updateValueOrPut(key, value2, value1 -> mergeFunction.apply(key, value1, value2));
					}
					return result;
				} else {
					«genericName» result = other;
					for (final P<K, A> p : this) {
						final K key = p.get1();
						final A value1 = p.get2();
						result = result.updateValueOrPut(key, value1, value2 -> mergeFunction.apply(key, value1, value2));
					}
					return result;
				}
			}

			@Override
			@Deprecated
			public Dict<K, A> toDict() {
				return this;
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return isEmpty() ? Collections.emptyIterator() : new HashTableIterator<>(this.leafMap, this.treeMap, this.slots);
			}

			/**
			 * @deprecated «shortName» has no specified order, so this method makes no sense.
			 */
			@Deprecated
			@Override
			public Iterator<P<K, A>> reverseIterator() {
				return KeyValue.super.reverseIterator();
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				«HashTableCommonGenerator.forEach("forEach", "action", "accept", "Object", "P<K, A>", false)»
			}

			«keyValueEquals»

			«keyValueHashCode»

			«keyValueToString»

			public static «paramGenericName» empty«shortName»() {
				return («genericName») EMPTY;
			}

			public static «paramGenericName» dict(final K key, final A value) {
				return «shortName».<K, A> empty«shortName»().put(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				public static «paramGenericName» dict(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
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
				«javadocSynonym("dict")»
				public static «paramGenericName» of(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return dict(«(1..i).map["key" + it + ", value" + it].join(", ")»);
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

			@SafeVarargs
			public static «paramGenericName» merge(final F3<K, A, A, A> mergeFunction, final «genericName»... dicts) {
				requireNonNull(mergeFunction);
				if (dicts.length == 0) {
					return empty«shortName»();
				} else if (dicts.length == 1) {
					return requireNonNull(dicts[0]);
				} else {
					«genericName» dict = dicts[0];
					for (int i = 1; i < dicts.length; i++) {
						dict = dict.merge(dicts[i], mergeFunction);
					}
					return dict;
				}
			}

			@SafeVarargs
			public static «paramGenericName» mergeUnique(final «genericName»... dicts) throws IllegalStateException {
				return merge((final K key, final A value1, final A value2) -> {
					final String msg = String.format("Duplicate key %s (attempted merging values %s and %s)", key, value1, value2);
					throw new IllegalStateException(msg);
				}, dicts);
			}

			«transform(genericName)»

			public static <K, A> DictBuilder<K, A> builder() {
				return new DictBuilder<>();
			}

			«cast(#["K", "A"], #[], #["A"])»
		}
	''' }
}