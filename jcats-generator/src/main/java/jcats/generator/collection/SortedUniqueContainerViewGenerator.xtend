package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class SortedUniqueContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].toList.map[new SortedUniqueContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("SortedUniqueContainerView") }
	def genericName() { type.genericName("SortedUniqueContainerView") }
	def baseSortedUniqueContainerViewShortName() { type.shortName("BaseSortedUniqueContainerView") }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.SortedSet;

		import «Constants.JCATS».*;

		«IF type == Type.OBJECT»
			import static java.util.Objects.requireNonNull;
		«ENDIF»
		import static «Constants.COMMON».*;

		public interface «type.covariantName("SortedUniqueContainerView")» extends «type.uniqueContainerViewGenericName», «type.sortedUniqueContainerGenericName» {

			«genericName» slice(final «type.genericName» from, final boolean fromInclusive, final «type.genericName» to, final boolean toInclusive);

			«genericName» sliceFrom(final «type.genericName» from, final boolean inclusive);

			«genericName» sliceTo(final «type.genericName» to, final boolean inclusive);

			@Override
			@Deprecated
			default «type.sortedUniqueContainerViewGenericName» view() {
				return this;
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			abstract class «baseSortedUniqueContainerViewShortName»<A, C extends SortedUniqueContainer<A>> extends BaseUniqueContainerView<A, C> implements SortedUniqueContainerView<A> {
		«ELSE»
			abstract class «baseSortedUniqueContainerViewShortName»<C extends «type.sortedUniqueContainerShortName»> extends «type.typeName»BaseUniqueContainerView<C> implements «type.sortedUniqueContainerViewShortName» {
		«ENDIF»

			«baseSortedUniqueContainerViewShortName»(final C container) {
				super(container);
			}

			@Override
			public «type.ordGenericName» ord() {
				return this.container.ord();
			}

			@Override
			public «type.genericName» last() {
				return this.container.last();
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return this.container.lastOption();
			}

			@Override
			public SortedSet<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«IF type.primitive»
				@Override
				public SortedUniqueContainerView<«type.boxedName»> asContainer() {
					return this.container.asContainer();
				}

			«ENDIF»
			«toStr(type, baseSortedUniqueContainerViewShortName, false)»
		}
	''' }
}