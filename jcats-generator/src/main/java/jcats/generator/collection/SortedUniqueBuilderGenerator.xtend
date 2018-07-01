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

		import «Constants.SIZED»;
		import «Constants.JCATS».«type.ordShortName»;

		import static «Constants.COLLECTION».«type.sortedUniqueShortName».empty«type.sortedUniqueShortName»By;

		public final class «genericName» implements Sized {

			private «type.sortedUniqueGenericName» unique;

			«shortName»() {
				this.unique = «IF type == Type.OBJECT»(«type.sortedUniqueGenericName») «ENDIF»«type.sortedUniqueShortName».EMPTY;
			}

			«shortName»(final «type.ordGenericName» ord) {
				this.unique = empty«type.sortedUniqueShortName»By(ord);
			}

			public «genericName» put(final «type.genericName» value) {
				this.unique = this.unique.put(value);
				return this;
			}

			public «genericName» merge(final «genericName» other) {
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

			public «type.sortedUniqueGenericName» build() {
				return this.unique;
			}
		}
	''' }
}