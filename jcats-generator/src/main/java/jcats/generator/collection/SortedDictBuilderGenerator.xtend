package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class SortedDictBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".SortedDictBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.Map;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;

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

			public SortedDictBuilder<K, A> putEntry(final  P<K, A> entry) {
				return put(entry.get1(), entry.get2());
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
			public boolean hasFixedSize() {
				return false;
			}

			public SortedDict<K, A> build() {
				return this.dict;
			}

			«toStr(Type.OBJECT, "SortedDictBuilder", false, "this.dict")»
		}
	''' }
}