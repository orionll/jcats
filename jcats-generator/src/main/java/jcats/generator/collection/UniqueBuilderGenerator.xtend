package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class UniqueBuilderGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].map[new UniqueBuilderGenerator(it) as Generator].toList
	}

	override className() { Constants.COLLECTION + "." + shortName }
	def shortName() { type.uniqueBuilderShortName }
	def genericName() { type.uniqueBuilderGenericName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»
		import java.util.stream.«type.streamName»;

		import «Constants.SIZED»;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COLLECTION».«type.uniqueShortName».empty«type.uniqueShortName»;
		import static «Constants.COMMON».*;

		public final class «genericName» implements Sized {

			private «type.uniqueGenericName» unique;

			«shortName»() {
				this.unique = empty«type.uniqueShortName»();
			}

			«shortName»(final «type.uniqueGenericName» unique) {
				this.unique = unique;
			}

			public «genericName» put(final «type.genericName» value) {
				this.unique = this.unique.put(value);
				return this;
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public final «genericName» putValues(final «type.genericName»... values) {
				for (final «type.genericName» value : values) {
					put(value);
				}
				return this;
			}

			public «genericName» putAll(final Iterable<«type.genericBoxedName»> iterable) {
				«IF type.javaUnboxedType»
					if (iterable instanceof «type.containerShortName») {
						((«type.containerShortName») iterable).foreach(this::put);
					} else {
						putIterator(iterable.iterator());
					}
				«ELSE»
					if (iterable instanceof «type.containerWildcardName») {
						((«type.containerGenericName») iterable).foreach(this::put);
					} else {
						iterable.forEach(this::put);
					}
				«ENDIF»
				return this;
			}

			public «genericName» putIterator(final Iterator<«type.genericBoxedName»> iterator) {
				«IF type.javaUnboxedType»
					«type.typeName»Iterator.getIterator(iterator).forEachRemaining((«type.typeName»Consumer) this::put);
				«ELSE»
					iterator.forEachRemaining(this::put);
				«ENDIF»
				return this;
			}

			public «genericName» put«type.streamName»(final «type.streamGenericName» stream) {
				«streamForEach(type.genericJavaUnboxedName, "put", false)»
				return this;
			}

			«genericName» merge(final «genericName» other) {
				this.unique = this.unique.merge(other.unique);
				return this;
			}

			@Override
			public int size() {
				return this.unique.size();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			public «type.uniqueGenericName» build() {
				return this.unique;
			}

			«toStr(type, "this.unique")»

			«transform(genericName)»
		}
	''' }
}