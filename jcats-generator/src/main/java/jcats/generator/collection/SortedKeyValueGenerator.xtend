package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class SortedKeyValueGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".SortedKeyValue" }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.SortedMap;
		import java.util.Spliterator;
		import java.util.TreeMap;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		public interface SortedKeyValue<K, @Covariant A> extends KeyValue<K, A> {

			Ord<K> ord();

			default P<K, A> first() throws NoSuchElementException {
				return iterator().next();
			}

			default P<K, A> last() throws NoSuchElementException {
				return reverseIterator().next();
			}

			default K firstKey() throws NoSuchElementException {
				return first().get1();
			}

			default K lastKey() throws NoSuchElementException {
				return last().get1();
			}

			@Override
			default SortedUniqueContainerView<K> keys() {
				return new SortedKeys<>(this);
			}

			@Override
			default OrderedContainerView<A> values() {
				return new SortedValues<>(this);
			}

			@Override
			default SortedUniqueContainerView<P<K, A>> asUniqueContainer() {
				return new SortedKeyValueAsSortedUniqueContainer<>(this);
			}

			@Override
			SortedKeyValueView<K, A> view();

			default TreeMap<K, A> toTreeMap() {
				final TreeMap<K, A> map = new TreeMap<>(ord());
				foreach(map::put);
				return map;
			}

			@Override
			default SortedMap<K, A> asMap() {
				return new SortedKeyValueAsSortedMap<>(this);
			}

			@Override
			default int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			«cast(#["K", "A"], #[], #["A"])»
		}


		final class SortedValues<A> extends Values<A, SortedKeyValue<?, A>> implements OrderedContainerView<A> {

			SortedValues(final SortedKeyValue<?, A> keyValue) {
				super(keyValue);
			}

			@Override
			public A first() {
				return this.keyValue.first().get2();
			}

			@Override
			public A last() {
				return this.keyValue.last().get2();
			}

			@Override
			public Iterator<A> reverseIterator() {
				return new MappedIterator<>(this.keyValue.reverseIterator(), P::get2);
			}
		}

		final class SortedKeys<K> extends Keys<K, SortedKeyValue<K, ?>> implements SortedUniqueContainerView<K> {

			SortedKeys(final SortedKeyValue<K, ?> keyValue) {
				super(keyValue);
			}

			@Override
			public Ord<K> ord() {
				return this.keyValue.ord();
			}

			@Override
			public K first() {
				return this.keyValue.first().get1();
			}

			@Override
			public K last() {
				return this.keyValue.last().get1();
			}

			@Override
			public Iterator<K> reverseIterator() {
				return new MappedIterator<>(this.keyValue.reverseIterator(), P::get1);
			}

			@Override
			public SortedUniqueContainerView<K> slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				return new SortedKeys<>(this.keyValue.view().slice(from, fromInclusive, to, toInclusive));
			}

			@Override
			public SortedUniqueContainerView<K> sliceFrom(final K from, final boolean inclusive) {
				return new SortedKeys<>(this.keyValue.view().sliceFrom(from, inclusive));
			}

			@Override
			public SortedUniqueContainerView<K> sliceTo(final K to, final boolean inclusive) {
				return new SortedKeys<>(this.keyValue.view().sliceTo(to, inclusive));
			}
		}

		final class SortedKeyValueAsSortedUniqueContainer<K, A> extends KeyValueAsUniqueContainer<K, A, SortedKeyValue<K, A>> implements SortedUniqueContainerView<P<K, A>> {

			SortedKeyValueAsSortedUniqueContainer(final SortedKeyValue<K, A> keyValue) {
				super(keyValue);
			}

			@Override
			public Iterator<P<K, A>> reverseIterator() {
				return this.keyValue.reverseIterator();
			}

			@Override
			public Ord<P<K, A>> ord() {
				return this.keyValue.ord().contraMap(P::get1);
			}

			@Override
			public P<K, A> first() {
				return this.keyValue.first();
			}

			@Override
			public P<K, A> last() {
				return this.keyValue.last();
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> slice(final P<K, A> from, final boolean fromInclusive, final P<K, A> to, final boolean toInclusive) {
				return new SortedKeyValueAsSortedUniqueContainer<>(this.keyValue.view().slice(from.get1(), fromInclusive, to.get1(), toInclusive));
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> sliceFrom(final P<K, A> from, final boolean inclusive) {
				return new SortedKeyValueAsSortedUniqueContainer<>(this.keyValue.view().sliceFrom(from.get1(), inclusive));
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> sliceTo(final P<K, A> to, final boolean inclusive) {
				return new SortedKeyValueAsSortedUniqueContainer<>(this.keyValue.view().sliceTo(to.get1(), inclusive));
			}
		}

		final class SortedKeyValueAsSortedMap<K, A> extends KeyValueAsMap<K, A, SortedKeyValue<K, A>> implements SortedMap<K, A> {

			SortedKeyValueAsSortedMap(final SortedKeyValue<K, A> keyValue) {
				super(keyValue);
			}

			@Override
			public Comparator<? super K> comparator() {
				return this.keyValue.ord();
			}

			@Override
			public K firstKey() {
				return this.keyValue.firstKey();
			}

			@Override
			public K lastKey() {
				return this.keyValue.lastKey();
			}

			@Override
			public SortedMap<K, A> subMap(final K fromKey, final K toKey) {
				return new SortedKeyValueAsSortedMap<>(this.keyValue.view().slice(fromKey, true, toKey, false));
			}

			@Override
			public SortedMap<K, A> headMap(final K toKey) {
				return new SortedKeyValueAsSortedMap<>(this.keyValue.view().sliceTo(toKey, false));
			}

			@Override
			public SortedMap<K, A> tailMap(final K fromKey) {
				return new SortedKeyValueAsSortedMap<>(this.keyValue.view().sliceFrom(fromKey, true));
			}
		}
	'''
}