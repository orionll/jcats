package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class UniqueBuilderGenerator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".UniqueBuilder" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		import java.util.stream.Stream;

		import «Constants.SIZED»;

		import static «Constants.COLLECTION».Unique.emptyUnique;
		import static «Constants.COMMON».*;

		public final class UniqueBuilder<A> implements Sized {

			private Unique<A> unique;

			UniqueBuilder() {
				this.unique = emptyUnique();
			}

			UniqueBuilder(final Unique<A> unique) {
				this.unique = unique;
			}

			public UniqueBuilder<A> put(final A value) {
				this.unique = this.unique.put(value);
				return this;
			}

			@SafeVarargs
			public final UniqueBuilder<A> putValues(final A... values) {
				for (final A value : values) {
					put(value);
				}
				return this;
			}

			public UniqueBuilder<A> putAll(final Iterable<A> iterable) {
				if (iterable instanceof Container<?>) {
					((Container<A>) iterable).foreach(this::put);
				} else {
					iterable.forEach(this::put);
				}
				return this;
			}

			public UniqueBuilder<A> putIterator(final Iterator<A> iterator) {
				iterator.forEachRemaining(this::put);
				return this;
			}

			public UniqueBuilder<A> putStream(final Stream<A> stream) {
				«streamForEach("A", "put", false)»
				return this;
			}

			UniqueBuilder<A> merge(final UniqueBuilder<A> other) {
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

			«toStr(Type.OBJECT, "UniqueBuilder", false, "this.unique")»
		}
	''' }
}