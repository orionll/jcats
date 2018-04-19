package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator
import jcats.generator.Type

final class KeyValueGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".KeyValue" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Collections;
		import java.util.Iterator;
		import java.util.HashSet;
		import java.util.Map;
		import java.util.Map.Entry;
		import java.util.Set;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.BiConsumer;
		import java.util.function.Consumer;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.EITHER».*;
		import static «Constants.P».*;

		public interface KeyValue<K, @Covariant A> extends Iterable<P<K, A>>, Equatable<KeyValue<K, A>>, Sized {

			default Option<A> get(final K key) {
				return Option.fromNullable(getOrNull(key));
			}

			default A getOr(final K key, final A other) {
				requireNonNull(other);
				final A value = getOrNull(key);
				return (value == null) ? other : value;
			}

			default A getOrElse(final K key, final F0<A> other) {
				requireNonNull(other);
				final A value = getOrNull(key);
				return (value == null) ? requireNonNull(other.apply()) : value;
			}

			default <X> Either<X, A> getOrError(final K key, final F0<X> error) {
				requireNonNull(error);
				final A value = getOrNull(key);
				return (value == null) ? left(requireNonNull(error.apply())) : right(value);
			}

			default <X extends Throwable> A getOrThrow(final K key, final F0<X> f) throws X {
				requireNonNull(f);
				final A value = getOrNull(key);
				if (value == null) {
					throw f.apply();
				} else {
					return value;
				}
			}

			A getOrNull(final K key);

			default boolean containsKey(final K key) {
				return (getOrNull(key) != null);
			}

			default boolean containsValue(final A value) {
				requireNonNull(value);
				for (final P<K, A> entry : this) {
					if (entry.get2().equals(value)) {
						return true;
					}
				}
				return false;
			}

			default void foreach(final Eff2<K, A> eff) {
				requireNonNull(eff);
				forEach((final P<K, A> entry) -> eff.apply(entry.get1(), entry.get2()));
			}

			default UniqueContainer<K> keys() {
				return new Keys<>(this);
			}

			default Container<A> values() {
				return new Values<>(this);
			}

			default UniqueContainer<P<K, A>> asUniqueContainer() {
				return new KeyValueAsUniqueContainer<>(this);
			}

			default Map<K, A> asMap() {
				return new KeyValueAsMap<>(this);
			}

			default int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE;
			}

			@Override
			default Spliterator<P<K, A>> spliterator() {
				if (isEmpty()) {
					return Spliterators.emptySpliterator();
				} else if (hasFixedSize()) {
					return Spliterators.spliterator(iterator(), size(), spliteratorCharacteristics());
				} else {
					return Spliterators.spliteratorUnknownSize(iterator(), spliteratorCharacteristics());
				}
			}

			default Stream2<P<K, A>> stream() {
				return new Stream2<>(StreamSupport.stream(spliterator(), false));
			}

			default Stream2<P<K, A>> parallelStream() {
				return new Stream2<>(StreamSupport.stream(spliterator(), true));
			}

			/**
			 * «equalsDeprecatedJavaDoc»
			 */
			@Override
			@Deprecated
			boolean equals(final Object other);

			static <K, A> KeyValue<K, A> asKeyValue(final Map<K, A> map) {
				return new MapAsKeyValue<>(map);
			}

			«cast(#["K", "A"], #[], #["A"])»
		}

		final class Values<A> implements Container<A> {
			private final KeyValue<?, A> keyValue;

			Values(final KeyValue<?, A> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean hasFixedSize() {
				return this.keyValue.hasFixedSize();
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
			public boolean contains(final A value) {
				return this.keyValue.containsValue(value);
			}

			@Override
			public void foreach(final Eff<A> eff) {
				this.keyValue.forEach((final P<?, A> p) -> eff.apply(p.get2()));
			}

			@Override
			public void forEach(final Consumer<? super A> consumer) {
				this.keyValue.forEach((final P<?, A> p) -> consumer.accept(p.get2()));
			}

			@Override
			public Iterator<A> iterator() {
				return new MappedIterator<>(this.keyValue.iterator(), P::get2);
			}

			@Override
			public int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			@Override
			public String toString() {
				return iterableToString(this, "Values");
			}
		}

		final class Keys<K> implements UniqueContainer<K> {
			private final KeyValue<K, ?> keyValue;

			Keys(final KeyValue<K, ?> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean hasFixedSize() {
				return this.keyValue.hasFixedSize();
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
			public boolean contains(final K key) {
				return this.keyValue.containsKey(key);
			}

			@Override
			public void foreach(final Eff<K> eff) {
				this.keyValue.forEach((final P<K, ?> p) -> eff.apply(p.get1()));
			}

			@Override
			public void forEach(final Consumer<? super K> consumer) {
				this.keyValue.forEach((final P<K, ?> p) -> consumer.accept(p.get1()));
			}

			@Override
			public Iterator<K> iterator() {
				return new MappedIterator<>(this.keyValue.iterator(), P::get1);
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.keyValue.spliteratorCharacteristics();
			}

			«uniqueHashCode(Type.OBJECT)»

			«uniqueEquals(Type.OBJECT)»

			@Override
			public String toString() {
				return iterableToString(this, "Keys");
			}
		}

		final class KeyValueAsUniqueContainer<K, A> implements UniqueContainer<P<K, A>> {
			private final KeyValue<K, A> keyValue;
		
			KeyValueAsUniqueContainer(final KeyValue<K, A> keyValue) {
				this.keyValue = keyValue;
			}
		
			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean hasFixedSize() {
				return this.keyValue.hasFixedSize();
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
			public boolean contains(final P<K, A> p) {
				requireNonNull(p);
				return p.get2().equals(this.keyValue.getOrNull(p.get1()));
			}
		
			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				this.keyValue.forEach(action);
			}
		
			@Override
			public void foreach(final Eff<P<K, A>> eff) {
				this.keyValue.forEach(eff.toConsumer());
			}
		
			@Override
			public Iterator<P<K, A>> iterator() {
				return this.keyValue.iterator();
			}

			@Override
			public int spliteratorCharacteristics() {
				return this.keyValue.spliteratorCharacteristics();
			}

			@Override
			public Spliterator<P<K, A>> spliterator() {
				return this.keyValue.spliterator();
			}
		
			«uniqueHashCode(Type.OBJECT)»

			«uniqueEquals(Type.OBJECT)»
		
			@Override
			public String toString() {
				return this.keyValue.toString();
			}
		}

		final class KeyValueAsMap<K, A> extends AbstractImmutableMap<K, A> {
			private final KeyValue<K, A> keyValue;

			KeyValueAsMap(final KeyValue<K, A> keyValue) {
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
			public boolean containsKey(final Object key) {
				return (key != null) && this.keyValue.containsKey((K) key);
			}

			@Override
			public boolean containsValue(final Object value) {
				return (value != null) && this.keyValue.containsValue((A) value);
			}

			@Override
			public A get(final Object key) {
				if (key == null) {
					return null;
				} else {
					return this.keyValue.getOrNull((K) key);
				}
			}

			@Override
			public A getOrDefault(final Object key, final A defaultValue) {
				if (key == null) {
					return defaultValue;
				} else {
					final A value = this.keyValue.getOrNull((K) key);
					return (value == null) ? defaultValue : value;
				}
			}

			@Override
			public Set<Entry<K, A>> entrySet() {
				return new KeyValueEntrySet<>(this.keyValue);
			}

			@Override
			public Set<K> keySet() {
				return this.keyValue.keys().asCollection();
			}

			@Override
			public Collection<A> values() {
				return this.keyValue.values().asCollection();
			}

			@Override
			public void forEach(final BiConsumer<? super K, ? super A> action) {
				this.keyValue.forEach((final P<K, A> entry) -> action.accept(entry.get1(), entry.get2()));
			}
		}

		final class MapAsKeyValue<K, A> implements KeyValue<K, A> {
			private final Map<K, A> map;

			MapAsKeyValue(final Map<K, A> map) {
				this.map = map;
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
			public boolean hasFixedSize() {
				return false;
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

		final class KeyValueEntrySet<K, A> extends AbstractImmutableSet<Entry<K, A>> {
			private final KeyValue<K, A> keyValue;

			KeyValueEntrySet(final KeyValue<K, A> keyValue) {
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
			public boolean contains(final Object obj) {
				if (obj instanceof Entry) {
					final Entry<?, ?> entry = (Entry<?, ?>) obj;
					final Object key = entry.getKey();
					if (key == null) {
						return false;
					} else {
						final Object value = entry.getValue();
						return (value != null) && value.equals(this.keyValue.getOrNull((K) key));
					}
				} else {
					return false;
				}
			}

			@Override
			public Iterator<Entry<K, A>> iterator() {
				return new MappedIterator<>(this.keyValue.iterator(), P::toEntry);
			}

			@Override
			public Spliterator<Entry<K, A>> spliterator() {
				if (isEmpty()) {
					return Spliterators.emptySpliterator();
				} else {
					return Spliterators.spliterator(this, Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE);
				}
			}

			@Override
			public void forEach(final Consumer<? super Entry<K, A>> action) {
				this.keyValue.forEach((final P<K, A> p) -> action.accept(p.toEntry()));
			}
		}
	''' }

}