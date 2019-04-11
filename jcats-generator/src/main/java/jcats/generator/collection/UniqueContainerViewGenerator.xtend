package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class UniqueContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].toList.map[new UniqueContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.uniqueContainerViewShortName }
	def genericName() { type.uniqueContainerViewGenericName }
	def paramGenericName() { type.paramGenericName("UniqueContainerView") }
	def baseShortName() { type.shortName("BaseUniqueContainerView") }
	def reverseShortName() { type.shortName("ReverseUniqueContainerView") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Set;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;

		public interface «type.covariantName("UniqueContainerView")» extends «type.containerViewGenericName», «type.uniqueContainerGenericName» {

			@Override
			@Deprecated
			default «genericName» view() {
				return this;
			}

			@Override
			default «type.uniqueContainerGenericName» unview() {
				return this;
			}

			static «paramGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(«type.uniqueContainerViewGenericName») «ENDIF»«baseShortName».EMPTY;
			}

			static «paramGenericName» «type.shortName("SetView").firstToLowerCase»(final Set<«type.genericBoxedName»> set) {
				return «type.shortName("SetView").firstToLowerCase»(set, true);
			}

			static «paramGenericName» «type.shortName("SetView").firstToLowerCase»(final Set<«type.genericBoxedName»> set, final boolean hasKnownFixedSize) {
				requireNonNull(set);
				return new «type.shortName("Set")»As«type.uniqueContainerShortName»<>(set, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			class «baseShortName»<A, C extends UniqueContainer<A>> extends BaseContainerView<A, C> implements UniqueContainerView<A> {
		«ELSE»
			class «baseShortName»<C extends «type.uniqueContainerShortName»> extends «type.typeName»BaseContainerView<C> implements «type.uniqueContainerViewShortName» {
		«ENDIF»
			static final «baseShortName»<«IF type == Type.OBJECT»?, «ENDIF»?> EMPTY = new «baseShortName»<>(«type.uniqueShortName».EMPTY);

			«baseShortName»(final C container) {
				super(container);
			}

			@Override
			public Set<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«IF type.primitive»
				@Override
				public UniqueContainerView<«type.boxedName»> boxed() {
					return this.container.boxed();
				}

			«ENDIF»
			@Override
			public int hashCode() {
				return this.container.hashCode();
			}

			@Override
			@SuppressWarnings("deprecation")
			public boolean equals(final Object obj) {
				return this.container.equals(obj);
			}

			@Override
			public «type.uniqueContainerGenericName» unview() {
				return this.container;
			}
		}

		«IF type == Type.OBJECT»
			class SetAsUniqueContainer<C extends Set<A>, A> extends CollectionAsContainer<C, A> implements UniqueContainerView<A> {
		«ELSE»
			class «type.typeName»SetAs«type.typeName»UniqueContainer<C extends Set<«type.boxedName»>> extends «type.typeName»CollectionAs«type.typeName»Container<C> implements «type.uniqueContainerViewGenericName» {
		«ENDIF»

			«type.shortName("Set")»As«type.uniqueContainerShortName»(final C set, final boolean fixedSize) {
				super(set, fixedSize);
			}

			@Override
			public Set<«type.genericBoxedName»> asCollection() {
				return Collections.unmodifiableSet(this.collection);
			}

			«uniqueHashCode(type)»

			«uniqueEquals(type)»
		}
	'''
}