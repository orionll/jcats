package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class DictBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".DictBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.Map;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COLLECTION».Dict.emptyDict;
		import static «Constants.COMMON».*;

		public final class DictBuilder<K, A> implements Sized {

			private Dict<K, A> dict;

			DictBuilder() {
				this.dict = emptyDict();
			}

			DictBuilder(final Dict<K, A> dict) {
				this.dict = dict;
			}

			public DictBuilder<K, A> put(final K key, final A value) {
				this.dict = this.dict.put(key, value);
				return this;
			}

			DictBuilder<K, A> updateValueOrPut(final K key, final A defaultValue, final F<A, A> f) {
				this.dict = this.dict.updateValueOrPut(key, defaultValue, f);
				return this;
			}

			public DictBuilder<K, A> putEntry(final P<K, A> entry) {
				this.dict = this.dict.putEntry(entry);
				return this;
			}

			@SafeVarargs
			public final DictBuilder<K, A> putEntries(final P<K, A>... entries) {
				for (final P<K, A> entry : entries) {
					putEntry(entry);
				}
				return this;
			}

			public DictBuilder<K, A> putAll(final Iterable<P<K, A>> entries) {
				if (entries instanceof Container<?>) {
					((Container<P<K, A>>) entries).foreach(this::putEntry);
				} else {
					entries.forEach(this::putEntry);
				}
				return this;
			}

			public DictBuilder<K, A> putIterator(final Iterator<P<K, A>> entries) {
				entries.forEachRemaining(this::putEntry);
				return this;
			}

			public DictBuilder<K, A> putStream(final Stream<P<K, A>> stream) {
				«streamForEach("P<K, A>", "putEntry", false)»
				return this;
			}

			public DictBuilder<K, A> putMap(final Map<K, A> map) {
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

			public Dict<K, A> build() {
				return this.dict;
			}

			«keyValueToString("this.dict")»

			«transform("DictBuilder<K, A>")»
		}
	''' }
}