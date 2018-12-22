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

	def shortName() { type.shortName("UniqueContainerView") }
	def genericName() { type.genericName("UniqueContainerView") }
	def baseUniqueContainerViewShortName() { type.shortName("BaseUniqueContainerView") }
	def reverseUniqueContainerViewShortName() { type.shortName("ReverseUniqueContainerView") }

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
			default «type.uniqueContainerViewGenericName» view() {
				return this;
			}

			@Override
			default «genericName» reverse() {
				return new «reverseUniqueContainerViewShortName»<>(this);
			}

			static «type.paramGenericName("UniqueContainerView")» «type.shortName("SetView").firstToLowerCase»(final Set<«type.genericBoxedName»> set) {
				return «type.shortName("SetView").firstToLowerCase»(set, true);
			}

			static «type.paramGenericName("UniqueContainerView")» «type.shortName("SetView").firstToLowerCase»(final Set<«type.genericBoxedName»> set, final boolean hasKnownFixedSize) {
				requireNonNull(set);
				return new «type.shortName("Set")»As«type.uniqueContainerShortName»<>(set, hasKnownFixedSize);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			class «baseUniqueContainerViewShortName»<A, C extends UniqueContainer<A>> extends BaseContainerView<A, C> implements UniqueContainerView<A> {
		«ELSE»
			class «baseUniqueContainerViewShortName»<C extends «type.uniqueContainerShortName»> extends «type.typeName»BaseContainerView<C> implements «type.uniqueContainerViewShortName» {
		«ENDIF»

			«baseUniqueContainerViewShortName»(final C container) {
				super(container);
			}

			@Override
			public Set<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«IF type.primitive»
				@Override
				public UniqueContainerView<«type.boxedName»> asContainer() {
					return this.container.asContainer();
				}

			«ENDIF»
			«uniqueHashCode(type)»

			«uniqueEquals(type)»

			«toStr(type)»
		}

		«IF type == Type.OBJECT»
			final class «reverseUniqueContainerViewShortName»<A, C extends «genericName»> extends ReverseContainerView<A, C> implements «genericName» {
		«ELSE»
			final class «reverseUniqueContainerViewShortName»<C extends «genericName»> extends «type.typeName»ReverseContainerView<C> implements «genericName» {
		«ENDIF»

			«reverseUniqueContainerViewShortName»(final C view) {
				super(view);
			}

			@Override
			public «genericName» reverse() {
				return this.view;
			}

			«uniqueHashCode(type)»

			«uniqueEquals(type)»

			«toStr(type)»
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