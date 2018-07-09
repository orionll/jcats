package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class SortedDictBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".SortedDictBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import «Constants.SIZED»;

		import static «Constants.COLLECTION».SortedDict.emptySortedDict;
		import static «Constants.COMMON».*;

		public final class SortedDictBuilder<K, A> implements Sized {

			private SortedDict<K, A> dict;

			SortedDictBuilder() {
				this.dict = (SortedDict<K, A>) emptySortedDict();
			}

			SortedDictBuilder(final SortedDict<K, A> dict) {
				this.dict = dict;
			}

			public SortedDictBuilder<K, A> put(final K key, final A value) {
				this.dict = this.dict.put(key, value);
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