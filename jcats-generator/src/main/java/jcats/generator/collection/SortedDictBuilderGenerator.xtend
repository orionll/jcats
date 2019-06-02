package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class SortedDictBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".SortedDictBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.Map;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static «Constants.COLLECTION».SortedDict.*;
		import static «Constants.COMMON».*;

		public final class SortedDictBuilder<K, A> implements Sized {

			private SortedDict<K, A> dict;

			SortedDictBuilder() {
				this.dict = (SortedDict<K, A>) emptySortedDict();
			}

			SortedDictBuilder(final SortedDict<K, A> dict) {
				this.dict = dict;
			}

			SortedDictBuilder(final Ord<K> ord) {
				this.dict = emptySortedDictBy(ord);
			}

			public SortedDictBuilder<K, A> put(final K key, final A value) {
				this.dict = this.dict.put(key, value);
				return this;
			}

			SortedDictBuilder<K, A> updateValueOrPut(final K key, final A defaultValue, final F<A, A> f) {
				this.dict = this.dict.updateValueOrPut(key, defaultValue, f);
				return this;
			}

			public SortedDictBuilder<K, A> putEntry(final P<K, A> entry) {
				this.dict = this.dict.putEntry(entry);
				return this;
			}

			@SafeVarargs
			public final SortedDictBuilder<K, A> putEntries(final P<K, A>... entries) {
				for (final P<K, A> entry : entries) {
					putEntry(entry);
				}
				return this;
			}

			public SortedDictBuilder<K, A> putAll(final Iterable<P<K, A>> entries) {
				if (entries instanceof Container<?>) {
					((Container<P<K, A>>) entries).foreach(this::putEntry);
				} else {
					entries.forEach(this::putEntry);
				}
				return this;
			}

			public SortedDictBuilder<K, A> putIterator(final Iterator<P<K, A>> entries) {
				entries.forEachRemaining(this::putEntry);
				return this;
			}

			public SortedDictBuilder<K, A> putStream(final Stream<P<K, A>> stream) {
				«streamForEach("P<K, A>", "putEntry", false)»
				return this;
			}

			public SortedDictBuilder<K, A> putMap(final Map<K, A> map) {
				map.forEach(this::put);
				return this;
			}

			@Override
			public int size() {
				return this.dict.size();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			public SortedDict<K, A> build() {
				return this.dict;
			}

			«keyValueToString("this.dict")»
		}
	''' }
}