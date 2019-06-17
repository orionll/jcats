package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SortedUniqueBuilderGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].toList.map[new SortedUniqueBuilderGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }
	def shortName() { type.sortedUniqueBuilderShortName }
	def genericName() { type.sortedUniqueBuilderGenericName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»
		import java.util.stream.«type.streamName»;

		import «Constants.SIZED»;
		import «Constants.JCATS».«type.ordShortName»;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COLLECTION».«type.sortedUniqueShortName».empty«type.sortedUniqueShortName»By;
		import static «Constants.COMMON».*;

		public final class «genericName» implements Sized {

			private «type.sortedUniqueGenericName» unique;

			«shortName»() {
				this.unique = «IF type == Type.OBJECT»(«type.sortedUniqueGenericName») «ENDIF»«type.sortedUniqueShortName».EMPTY;
			}

			«shortName»(final «type.sortedUniqueGenericName» unique) {
				this.unique = unique;
			}

			«shortName»(final «type.ordGenericName» ord) {
				this.unique = empty«type.sortedUniqueShortName»By(ord);
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

			public «type.sortedUniqueGenericName» build() {
				return this.unique;
			}

			«toStr(type, "this.unique")»

			«transform(genericName)»
		}
	''' }
}