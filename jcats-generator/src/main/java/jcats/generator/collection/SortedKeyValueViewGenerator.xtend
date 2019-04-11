package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class SortedKeyValueViewGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".SortedKeyValueView" }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.NavigableMap;
		import java.util.Set;
		import java.util.SortedMap;
		import java.util.SortedSet;
		import java.util.TreeMap;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.ORD».*;
		import static «Constants.OPTION».*;
		import static «Constants.P».*;
		import static «Constants.COMMON».*;

		public interface SortedKeyValueView<K, @Covariant A> extends KeyValueView<K, A>, SortedKeyValue<K, A> {

			SortedKeyValueView<K, A> slice(K from, boolean fromInclusive, K to, boolean toInclusive);

			SortedKeyValueView<K, A> sliceFrom(K from, boolean inclusive);

			SortedKeyValueView<K, A> sliceTo(K to, boolean inclusive);

			@Override
			@Deprecated
			default SortedKeyValueView<K, A> view() {
				return this;
			}

			@Override
			default SortedKeyValue<K, A> unview() {
				return this;
			}

			default SortedKeyValueView<K, A> reverse() {
				return new ReverseSortedKeyValueView<>(unview());
			}

			static <K extends Comparable<K>, A> SortedKeyValueView<K, A> emptySortedKeyValueView() {
				return (SortedKeyValueView<K, A>) SortedDictView.EMPTY;
			}

			static <K, A> SortedKeyValueView<K, A> sortedMapView(final SortedMap<K, A> map) {
				return sortedMapView(map, true);
			}

			static <K, A> SortedKeyValueView<K, A> sortedMapView(final SortedMap<K, A> map, final boolean hasKnownFixedSize) {
				requireNonNull(map);
				return new SortedMapAsSortedKeyValue<>(map, hasKnownFixedSize);
			}

			«cast(#["K", "A"], #[], #["A"])»
		}

		abstract class BaseSortedKeyValueView<K, A, KV extends SortedKeyValue<K, A>> extends BaseKeyValueView<K, A, KV> implements SortedKeyValueView<K, A> {

			BaseSortedKeyValueView(final KV keyValue) {
				super(keyValue);
			}

			@Override
			public Ord<K> ord() {
				return this.keyValue.ord();
			}

			@Override
			public P<K, A> last() {
				return this.keyValue.last();
			}

			@Override
			public Option<P<K, A>> lastOption() {
				return this.keyValue.lastOption();
			}

			@Override
			public K lastKey() {
				return this.keyValue.lastKey();
			}

			@Override
			public Option<K> lastKeyOption() {
				return this.keyValue.lastKeyOption();
			}

			@Override
			public SortedUniqueContainerView<K> keys() {
				return this.keyValue.keys();
			}

			@Override
			public OrderedContainerView<A> values() {
				return this.keyValue.values();
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> asUniqueContainer() {
				return this.keyValue.asUniqueContainer();
			}

			@Override
			public SortedDict<K, A> toSortedDict() {
				return this.keyValue.toSortedDict();
			}

			@Override
			public TreeMap<K, A> toTreeMap() {
				return this.keyValue.toTreeMap();
			}

			@Override
			public SortedMap<K, A> asMap() {
				return this.keyValue.asMap();
			}

			@Override
			public SortedKeyValue<K, A> unview() {
				return this.keyValue;
			}
		}

		final class ReverseSortedKeyValueView<K, A> implements SortedKeyValueView<K, A> {
			private final SortedKeyValue<K, A> keyValue;

			ReverseSortedKeyValueView(final SortedKeyValue<K, A> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean isEmpty() {
				return this.keyValue.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return this.keyValue.isNotEmpty();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.keyValue.hasKnownFixedSize();
			}

			@Override
			public Option<A> get(final K key) {
				return this.keyValue.get(key);
			}

			@Override
			public A getOr(final K key, final A other) {
				return this.keyValue.getOr(key, other);
			}

			@Override
			public A getOrElse(final K key, final F0<A> other) {
				return this.keyValue.getOrElse(key, other);
			}

			@Override
			public <X> Either<X, A> getOrError(final K key, final F0<X> error) {
				return this.keyValue.getOrError(key, error);
			}

			@Override
			public <X extends Throwable> A getOrThrow(final K key, final F0<X> f) throws X {
				return this.keyValue.getOrThrow(key, f);
			}

			@Override
			public A getOrNull(final K key) {
				return this.keyValue.getOrNull(key);
			}

			@Override
			public boolean containsKey(final K key) {
				return this.keyValue.containsKey(key);
			}

			@Override
			public boolean containsValue(final A value) {
				return this.keyValue.containsValue(value);
			}

			@Override
			public void ifContainsKey(final K key, final Eff<A> eff) {
				this.keyValue.ifContainsKey(key, eff);
			}

			@Override
			public void ifNotContainsKey(final K key, final Eff0 eff) {
				this.keyValue.ifNotContainsKey(key, eff);
			}

			@Override
			public void ifContainsKeyOrElse(final K key, final Eff<A> ifContains, final Eff0 ifNotContains) {
				this.keyValue.ifContainsKeyOrElse(key, ifContains, ifNotContains);
			}

			@Override
			public Ord<K> ord() {
				return this.keyValue.ord().reversed();
			}

			@Override
			public P<K, A> first() {
				return this.keyValue.last();
			}

			@Override
			public Option<P<K, A>> firstOption() {
				return this.keyValue.lastOption();
			}

			@Override
			public P<K, A> last() {
				return this.keyValue.first();
			}

			@Override
			public Option<P<K, A>> lastOption() {
				return this.keyValue.firstOption();
			}

			@Override
			public K firstKey() {
				return this.keyValue.lastKey();
			}

			@Override
			public Option<K> firstKeyOption() {
				return this.keyValue.lastKeyOption();
			}

			@Override
			public K lastKey() {
				return this.keyValue.firstKey();
			}

			@Override
			public Option<K> lastKeyOption() {
				return this.keyValue.firstKeyOption();
			}

			@Override
			public SortedUniqueContainerView<K> keys() {
				return this.keyValue.keys().reverse();
			}

			@Override
			public OrderedContainerView<A> values() {
				return this.keyValue.values().reverse();
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> asUniqueContainer() {
				return this.keyValue.asUniqueContainer().reverse();
			}

			@Override
			public SortedKeyValueView<K, A> slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				return new ReverseSortedKeyValueView<>(this.keyValue.view().slice(to, toInclusive, from, fromInclusive));
			}

			@Override
			public SortedKeyValueView<K, A> sliceFrom(final K from, final boolean inclusive) {
				return new ReverseSortedKeyValueView<>(this.keyValue.view().sliceTo(from, inclusive));
			}

			@Override
			public SortedKeyValueView<K, A> sliceTo(final K to, final boolean inclusive) {
				return new ReverseSortedKeyValueView<>(this.keyValue.view().sliceFrom(to, inclusive));
			}

			@Override
			public SortedKeyValueView<K, A> reverse() {
				return this.keyValue.view();
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return this.keyValue.reverseIterator();
			}

			@Override
			public Iterator<P<K, A>> reverseIterator() {
				return this.keyValue.iterator();
			}

			@Override
			public int hashCode() {
				return this.keyValue.hashCode();
			}

			@Override
			public boolean equals(final Object obj) {
				return this.keyValue.equals(obj);
			}

			@Override
			public String toString() {
				return iterableToString(this);
			}
		}

		final class SortedMapAsSortedKeyValue<K, A> extends MapAsKeyValue<K, A, SortedMap<K, A>> implements SortedKeyValueView<K, A> {

			SortedMapAsSortedKeyValue(final SortedMap<K, A> map, final boolean fixedSize) {
				super(map, fixedSize);
			}

			@Override
			public Ord<K> ord() {
				final Comparator<K> comparator = (Comparator<K>) this.map.comparator();
				if (comparator == null) {
					return (Ord<K>) asc();
				} else {
					return Ord.fromComparator(comparator);
				}
			}

			@Override
			public P<K, A> first() {
				final K key = this.map.firstKey();
				final A value = this.map.get(key);
				return p(key, value);
			}

			@Override
			public Option<P<K, A>> firstOption() {
				if (this.map.isEmpty()) {
					return none();
				} else {
					return some(first());
				}
			}

			@Override
			public P<K, A> last() {
				final K key = this.map.lastKey();
				final A value = this.map.get(key);
				return p(key, value);
			}

			@Override
			public Option<P<K, A>> lastOption() {
				if (this.map.isEmpty()) {
					return none();
				} else {
					return some(last());
				}
			}

			@Override
			public K firstKey() {
				return requireNonNull(this.map.firstKey());
			}

			@Override
			public Option<K> firstKeyOption() {
				if (this.map.isEmpty()) {
					return none();
				} else {
					return some(this.map.firstKey());
				}
			}

			@Override
			public K lastKey() {
				return requireNonNull(this.map.lastKey());
			}

			@Override
			public Option<K> lastKeyOption() {
				if (this.map.isEmpty()) {
					return none();
				} else {
					return some(this.map.lastKey());
				}
			}

			@Override
			public SortedUniqueContainerView<K> keys() {
				final Set<K> keySet = requireNonNull(this.map.keySet());
				if (keySet instanceof SortedSet<?>) {
					return new SortedSetAsSortedUniqueContainer<>((SortedSet<K>) keySet, this.fixedSize);
				} else {
					return SortedKeyValueView.super.keys();
				}
			}

			@Override
			public OrderedContainerView<A> values() {
				return new CollectionAsOrderedContainer<>(requireNonNull(this.map.values()), this.fixedSize);
			}

			@Override
			public SortedKeyValueView<K, A> slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				requireNonNull(from);
				requireNonNull(to);
				final SortedMap<K, A> subMap;
				if (fromInclusive && !toInclusive) {
					subMap = this.map.subMap(from, to);
				} else {
					subMap = ((NavigableMap<K, A>) this.map).subMap(from, fromInclusive, to, toInclusive);
				}
				return new SortedMapAsSortedKeyValue<>(subMap, hasKnownFixedSize());
			}

			@Override
			public SortedKeyValueView<K, A> sliceFrom(final K from, final boolean inclusive) {
				requireNonNull(from);
				final SortedMap<K, A> tailMap;
				if (inclusive) {
					tailMap = this.map.tailMap(from);
				} else {
					tailMap = ((NavigableMap<K, A>) this.map).tailMap(from, inclusive);
				}
				return new SortedMapAsSortedKeyValue<>(tailMap, hasKnownFixedSize());
			}

			@Override
			public SortedKeyValueView<K, A> sliceTo(final K to, final boolean inclusive) {
				requireNonNull(to);
				final SortedMap<K, A> headMap;
				if (inclusive) {
					headMap = ((NavigableMap<K, A>) this.map).headMap(to, inclusive);
				} else {
					headMap = this.map.headMap(to);
				}
				return new SortedMapAsSortedKeyValue<>(headMap, hasKnownFixedSize());
			}

			@Override
			public SortedMap<K, A> asMap() {
				return Collections.unmodifiableSortedMap(this.map);
			}
		}
	'''
}