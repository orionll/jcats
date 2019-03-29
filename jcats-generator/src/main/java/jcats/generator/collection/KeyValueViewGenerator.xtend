package jcats.generator.collection

import jcats.generator.InterfaceGenerator
import jcats.generator.Constants

final class KeyValueViewGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".KeyValueView" }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.HashMap;
		import java.util.Iterator;
		import java.util.Map;
		import java.util.Map.Entry;
		import java.util.Spliterator;
		import java.util.function.Consumer;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.OPTION».*;
		import static «Constants.P».*;
		import static «Constants.COMMON».*;

		public interface KeyValueView<K, @Covariant A> extends KeyValue<K, A> {

			@Override
			@Deprecated
			default KeyValueView<K, A> view() {
				return this;
			}

			default KeyValue<K, A> unview() {
				return this;
			}

			@Override
			default boolean isEmpty() {
				return !iterator().hasNext();
			}

			@Override
			default boolean isNotEmpty() {
				return iterator().hasNext();
			}

			default KeyValueView<K, A> filterKeys(final BooleanF<K> predicate) {
				return new FilteredKeyValueView<>(unview(), predicate);
			}

			static <K, A> KeyValueView<K, A> mapView(final Map<K, A> map) {
				return mapView(map, true);
			}

			static <K, A> KeyValueView<K, A> mapView(final Map<K, A> map, final boolean hasKnownFixedSize) {
				requireNonNull(map);
				return new MapAsKeyValue<>(map, hasKnownFixedSize);
			}

			«cast(#["K", "A"], #[], #["A"])»
		}

		class BaseKeyValueView<K, A, KV extends KeyValue<K, A>> implements KeyValueView<K, A> {
			final KV keyValue;

			BaseKeyValueView(final KV keyValue) {
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
			public P<K, A> first() {
				return this.keyValue.first();
			}

			@Override
			public Option<P<K, A>> firstOption() {
				return this.keyValue.firstOption();
			}

			@Override
			public K firstKey() {
				return this.keyValue.firstKey();
			}

			@Override
			public Option<K> firstKeyOption() {
				return this.keyValue.firstKeyOption();
			}

			@Override
			public void foreach(final Eff2<K, A> eff) {
				this.keyValue.foreach(eff);
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				this.keyValue.forEach(action);
			}

			@Override
			public UniqueContainerView<K> keys() {
				return this.keyValue.keys();
			}

			@Override
			public ContainerView<A> values() {
				return this.keyValue.values();
			}

			@Override
			public UniqueContainerView<P<K, A>> asUniqueContainer() {
				return this.keyValue.asUniqueContainer();
			}

			@Override
			public Dict<K, A> toDict() {
				return this.keyValue.toDict();
			}

			@Override
			public Map<K, A> asMap() {
				return this.keyValue.asMap();
			}

			@Override
			public HashMap<K, A> toHashMap() {
				return this.keyValue.toHashMap();
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return this.keyValue.iterator();
			}

			@Override
			public Iterator<P<K, A>> reverseIterator() {
				return this.keyValue.reverseIterator();
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.keyValue.spliteratorCharacteristics();
			}

			@Override
			public Spliterator<P<K, A>> spliterator() {
				return this.keyValue.spliterator();
			}

			@Override
			public Stream2<P<K, A>> stream() {
				return this.keyValue.stream();
			}

			@Override
			public Stream2<P<K, A>> parallelStream() {
				return this.keyValue.parallelStream();
			}

			@Override
			public int hashCode() {
				return this.keyValue.hashCode();
			}

			@Override
			@SuppressWarnings("deprecation")
			public boolean equals(final Object obj) {
				return this.keyValue.equals(obj);
			}

			@Override
			public String toString() {
				return this.keyValue.toString();
			}

			@Override
			public KeyValue<K, A> unview() {
				return this.keyValue;
			}
		}

		final class FilteredKeyValueView<K, A> implements KeyValueView<K, A> {
			private final KeyValue<K, A> keyValue;
			private final BooleanF<K> predicate;

			FilteredKeyValueView(final KeyValue<K, A> keyValue, final BooleanF<K> predicate) {
				this.keyValue = keyValue;
				this.predicate = predicate;
			}

			@Override
			public int size() {
				return iterableSize(this);
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public A getOrNull(final K key) {
				if (this.predicate.apply(key)) {
					return this.keyValue.getOrNull(key);
				} else {
					return null;
				}
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return new FilteredIterator<>(this.keyValue.iterator(), this.predicate.contraMap(P::get1));
			}

			@Override
			public void foreach(final Eff2<K, A> eff) {
				this.keyValue.foreach((final K key, final A value) -> {
					if (this.predicate.apply(key)) {
						eff.apply(key, value);
					}
				});
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				this.keyValue.forEach((final P<K, A> entry) -> {
					if (this.predicate.apply(entry.get1())) {
						action.accept(entry);
					}
				});
			}

			«keyValueEquals»

			«keyValueHashCode»

			«keyValueToString»
		}

		class MapAsKeyValue<K, A, M extends Map<K, A>> implements KeyValueView<K, A> {
			final M map;
			final boolean fixedSize;

			MapAsKeyValue(final M map, final boolean fixedSize) {
				this.map = map;
				this.fixedSize = fixedSize;
			}

			@Override
			public A getOrNull(final K key) {
				if (this.map.containsKey(key)) {
					return requireNonNull(this.map.get(key));
				} else {
					return null;
				}
			}

			@Override
			public boolean containsKey(final K key) {
				requireNonNull(key);
				return this.map.containsKey(key);
			}

			@Override
			public boolean containsValue(final A value) {
				requireNonNull(value);
				return this.map.containsValue(value);
			}

			@Override
			public int size() {
				return this.map.size();
			}

			@Override
			public boolean isEmpty() {
				return this.map.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return !this.map.isEmpty();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.fixedSize;
			}

			@Override
			public P<K, A> first() {
				return P.fromEntry(this.map.entrySet().iterator().next());
			}

			@Override
			public Option<P<K, A>> firstOption() {
				final Iterator<Entry<K, A>> iterator = this.map.entrySet().iterator();
				if (iterator.hasNext()) {
					return some(P.fromEntry(iterator.next()));
				} else {
					return none();
				}
			}

			@Override
			public K firstKey() {
				return requireNonNull(this.map.keySet().iterator().next());
			}

			@Override
			public Option<K> firstKeyOption() {
				final Iterator<K> iterator = this.map.keySet().iterator();
				if (iterator.hasNext()) {
					return some(iterator.next());
				} else {
					return none();
				}
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return new MappedIterator<>(this.map.entrySet().iterator(),
						(final Entry<K, A> entry) -> p(entry.getKey(), entry.getValue()));
			}

			@Override
			public Spliterator<P<K, A>> spliterator() {
				return new MappedSpliterator<>(this.map.entrySet().spliterator(),
						(final Entry<K, A> entry) -> p(entry.getKey(), entry.getValue()));
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				this.map.forEach((final K key, final A value) -> action.accept(p(key ,value)));
			}

			@Override
			public void foreach(final Eff2<K, A> eff) {
				this.map.forEach(eff::apply);
			}

			@Override
			public UniqueContainerView<K> keys() {
				return new SetAsUniqueContainer<>(requireNonNull(this.map.keySet()), this.fixedSize);
			}

			@Override
			public ContainerView<A> values() {
				return new CollectionAsContainer<>(requireNonNull(this.map.values()), this.fixedSize);
			}

			@Override
			public Stream2<P<K, A>> stream() {
				return Stream2.from(this.map.entrySet().stream().map(P::fromEntry));
			}

			@Override
			public Stream2<P<K, A>> parallelStream() {
				return Stream2.from(this.map.entrySet().parallelStream().map(P::fromEntry));
			}

			@Override
			public Map<K, A> asMap() {
				return Collections.unmodifiableMap(this.map);
			}

			«keyValueHashCode»

			«keyValueEquals»

			@Override
			public String toString() {
				return this.map.toString();
			}
		}
	'''
}