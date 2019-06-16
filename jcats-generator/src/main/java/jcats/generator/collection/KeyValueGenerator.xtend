package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator
import jcats.generator.Type

final class KeyValueGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".KeyValue" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Collection;
		import java.util.Iterator;
		import java.util.HashMap;
		import java.util.Map;
		import java.util.Map.Entry;
		import java.util.NoSuchElementException;
		import java.util.Set;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.BiConsumer;
		import java.util.function.Consumer;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.EITHER».*;
		import static «Constants.OPTION».*;
		import static «Constants.COMMON».*;
		import static «Constants.COLLECTION».KeyValueView.*;

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
				return (value == null) ? left(error.apply()) : right(value);
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

			A getOrNull(K key);

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

			default void ifContainsKey(final K key, final Eff<A> eff) {
				requireNonNull(eff);
				final A value = getOrNull(key);
				if (value != null) {
					eff.apply(value);
				}
			}

			default void ifNotContainsKey(final K key, final Eff0 eff) {
				requireNonNull(eff);
				final A value = getOrNull(key);
				if (value == null) {
					eff.apply();
				}
			}

			default void ifContainsKeyOrElse(final K key, final Eff<A> ifContains, final Eff0 ifNotContains) {
				requireNonNull(ifContains);
				requireNonNull(ifNotContains);
				final A value = getOrNull(key);
				if (value == null) {
					ifNotContains.apply();
				} else {
					ifContains.apply(value);
				}
			}

			default P<K, A> first() throws NoSuchElementException {
				return iterator().next();
			}

			default Option<P<K, A>> findFirst() {
				final Iterator<P<K, A>> iterator = iterator();
				if (iterator.hasNext()) {
					return some(iterator.next());
				} else {
					return none();
				}
			}

			default K firstKey() throws NoSuchElementException {
				return first().get1();
			}

			default Option<K> findFirstKey() {
				return findFirst().map(P::get1);
			}

			default void foreach(final Eff2<K, A> eff) {
				requireNonNull(eff);
				forEach((final P<K, A> entry) -> eff.apply(entry.get1(), entry.get2()));
			}

			default UniqueContainerView<K> keys() {
				return new Keys<>(this);
			}

			default ContainerView<A> values() {
				return new Values<>(this);
			}

			default UniqueContainerView<P<K, A>> asUniqueContainer() {
				return new KeyValueAsUniqueContainer<>(this);
			}

			default Dict<K, A> toDict() {
				final DictBuilder<K, A> builder = Dict.builder();
				forEach(builder::putEntry);
				return builder.build();
			}

			default Map<K, A> asMap() {
				return new KeyValueAsMap<>(this);
			}

			default HashMap<K, A> toHashMap() {
				return new HashMap<>(asMap());
			}

			default Iterator<P<K, A>> reverseIterator() {
				return asUniqueContainer().toArray().reverseIterator();
			}

			default int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE;
			}

			@Override
			default Spliterator<P<K, A>> spliterator() {
				if (hasKnownFixedSize()) {
					return Spliterators.spliterator(iterator(), size(), spliteratorCharacteristics());
				} else {
					return Spliterators.spliteratorUnknownSize(iterator(), spliteratorCharacteristics());
				}
			}

			default KeyValueView<K, A> view() {
				if (hasKnownFixedSize() && isEmpty()) {
					return emptyKeyValueView();
				} else {
					return new BaseKeyValueView<>(this);
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
			boolean equals(Object other);

			«cast(#["K", "A"], #[], #["A"])»
		}

		class Values<A, KV extends KeyValue<?, A>> implements ContainerView<A> {
			final KV keyValue;

			Values(final KV keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.keyValue.hasKnownFixedSize();
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
			public A first() {
				return this.keyValue.first().get2();
			}

			@Override
			public Option<A> findFirst() {
				return this.keyValue.findFirst().map(P::get2);
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

			«toStr»
		}

		class Keys<K, KV extends KeyValue<K, ?>> implements UniqueContainerView<K> {
			final KV keyValue;

			Keys(final KV keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.keyValue.hasKnownFixedSize();
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
			public K first() {
				return this.keyValue.firstKey();
			}

			@Override
			public Option<K> findFirst() {
				return this.keyValue.findFirstKey();
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

			«toStr»
		}

		class KeyValueAsUniqueContainer<K, A, KV extends KeyValue<K, A>> implements UniqueContainerView<P<K, A>> {
			final KV keyValue;

			KeyValueAsUniqueContainer(final KV keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return this.keyValue.size();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.keyValue.hasKnownFixedSize();
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
			public P<K, A> first() {
				return this.keyValue.first();
			}

			@Override
			public Option<P<K, A>> findFirst() {
				return this.keyValue.findFirst();
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

			@Override
			public Stream2<P<K, A>> stream() {
				return this.keyValue.stream();
			}

			@Override
			public Stream2<P<K, A>> parallelStream() {
				return this.keyValue.parallelStream();
			}

			«uniqueHashCode(Type.OBJECT)»

			«uniqueEquals(Type.OBJECT)»

			«toStr»
		}

		class KeyValueAsMap<K, A, KV extends KeyValue<K, A>> extends AbstractImmutableMap<K, A> {
			final KV keyValue;

			KeyValueAsMap(final KV keyValue) {
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

			@Override
			public String toString() {
				return this.keyValue.toString();
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
				return Spliterators.spliterator(this, this.keyValue.spliteratorCharacteristics());
			}

			@Override
			public void forEach(final Consumer<? super Entry<K, A>> action) {
				this.keyValue.forEach((final P<K, A> p) -> action.accept(p.toEntry()));
			}
		}
	''' }

}