package jcats.generator.collection

import jcats.generator.InterfaceGenerator
import jcats.generator.Constants
import jcats.generator.Type

class KeyValueGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".KeyValue" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.function.Consumer;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface KeyValue<K, A> extends Iterable<P<K, A>>, Equatable<KeyValue<K, A>>, Sized {

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
				return (value == null) ? other.apply() : value;
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
				forEach(entry -> eff.apply(entry.get1(), entry.get2()));
			}

			default UniqueContainer<K> keys() {
				return new Keys<>(this);
			}

			default Container<A> values() {
				return new Values<>(this);
			}

			default Stream<P<K, A>> stream() {
				return StreamSupport.stream(spliterator(), false);
			}

			default Stream<P<K, A>> parallelStream() {
				return StreamSupport.stream(spliterator(), true);
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
				return keyValue.size();
			}

			@Override
			public boolean contains(final A value) {
				return keyValue.containsValue(value);
			}

			@Override
			public void foreach(final Eff<A> eff) {
				keyValue.forEach(p -> eff.apply(p.get2()));
			}

			@Override
			public void forEach(final Consumer<? super A> consumer) {
				keyValue.forEach(p -> consumer.accept(p.get2()));
			}

			@Override
			public Iterator<A> iterator() {
				return new MappedIterator<>(keyValue.iterator(), P::get2);
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
				return keyValue.size();
			}

			@Override
			public boolean contains(final K key) {
				return keyValue.containsKey(key);
			}

			@Override
			public void foreach(final Eff<K> eff) {
				keyValue.forEach(p -> eff.apply(p.get1()));
			}

			@Override
			public void forEach(final Consumer<? super K> consumer) {
				keyValue.forEach(p -> consumer.accept(p.get1()));
			}

			@Override
			public Iterator<K> iterator() {
				return new MappedIterator<>(keyValue.iterator(), P::get1);
			}

			«uniqueHashCode»

			«uniqueEquals(Type.OBJECT, "UniqueContainer")»

			@Override
			public String toString() {
				return iterableToString(this, "Keys");
			}
		}
	''' }

}