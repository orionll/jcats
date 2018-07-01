package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants

final class UniqueBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".UniqueBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import «Constants.SIZED»;

		import static «Constants.COLLECTION».Unique.emptyUnique;

		public final class UniqueBuilder<A> implements Sized {

			private Unique<A> unique;

			UniqueBuilder() {
				this.unique = emptyUnique();
			}

			public UniqueBuilder<A> put(final A value) {
				this.unique = this.unique.put(value);
				return this;
			}

			public UniqueBuilder<A> merge(final UniqueBuilder<A> other) {
				this.unique = this.unique.merge(other.unique);
				return this;
			}

			@Override
			public int size() {
				return this.unique.size();
			}

			@Override
			public boolean hasFixedSize() {
				return false;
			}

			public Unique<A> build() {
				return this.unique;
			}
		}
	''' }
}