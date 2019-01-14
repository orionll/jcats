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
		import static «Constants.P».*;
		import static «Constants.COMMON».*;

		public interface KeyValueView<K, @Covariant A> extends KeyValue<K, A> {

			@Override
			@Deprecated
			default KeyValueView<K, A> view() {
				return this;
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
			public boolean equals(final Object obj) {
				return this.keyValue.equals(obj);
			}

			@Override
			public String toString() {
				return this.keyValue.toString();
			}
		}

		class MapAsKeyValue<K, A, M extends Map<K, A>> implements KeyValueView<K, A> {
			final M map;
			private final boolean fixedSize;

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