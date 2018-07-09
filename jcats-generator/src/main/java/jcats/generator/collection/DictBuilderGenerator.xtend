package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class DictBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".DictBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import «Constants.SIZED»;

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

			@Override
			public int size() {
				return this.dict.size();
			}

			@Override
			public boolean hasFixedSize() {
				return false;
			}

			public Dict<K, A> build() {
				return this.dict;
			}

			«toStr(Type.OBJECT, "DictBuilder", false, "this.dict")»
		}
	''' }
}