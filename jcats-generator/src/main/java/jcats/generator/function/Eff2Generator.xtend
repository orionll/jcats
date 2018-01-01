package jcats.generator.function

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension com.google.common.collect.Iterables.concat

@FinalFieldsConstructor
class Eff2Generator implements InterfaceGenerator {
	val Type type1
	val Type type2

	def static List<Generator> generators() {
		Type.values.toList.map[type1 | 
			Type.values.toList.map[type2 |
				new Eff2Generator(type1, type2) as Generator
		]].concat.toList
	}

	override className() { Constants.FUNCTION + "." + shortName }

	def String shortName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"Eff2"
		} else {
			'''«type1.typeName»«type2.typeName»Eff2'''
		}
	}

	def String genericName() {
		shortName +
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"<A1, A2>"
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			"<A>"
		} else {
			""
		}
	}

	def String paramGenericName() {
		val params = 
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"<A1, A2>"
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			"<A>"
		} else {
			""
		}
		if (params.empty) shortName else params + " " + shortName + params 
	}

	def String variantName() {
		shortName +
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"<@Contravariant A1, @Contravariant A2>"
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			"<@Contravariant A>"
		} else {
			""
		}
	}

	def type1GenericName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) "A1"
		else if (type1 == Type.OBJECT) "A"
		else type1.javaName
	}

	def type2GenericName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) "A2"
		else if (type2 == Type.OBJECT) "A"
		else type2.javaName
	}	

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.BiConsumer;
		«IF type1 == Type.OBJECT && Type.javaUnboxedTypes.contains(type2)»
			import java.util.function.Obj«type2.typeName»Consumer;
		«ENDIF»

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface «variantName» {
			void apply(final «type1GenericName» value1, final «type2GenericName» value2);

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				default Eff2<A2, A1> reverse() {
			«ELSEIF type1 == Type.OBJECT || type2 == Type.OBJECT»
				default «type2.typeName»«type1.typeName»Eff2<A> reverse() {
			«ELSE»
				default «type2.typeName»«type1.typeName»Eff2 reverse() {
			«ENDIF»
				return (final «type2GenericName» value2, final «type1GenericName» value1) -> {
					«IF type2 == Type.OBJECT»
						requireNonNull(value2);
					«ENDIF»
					«IF type1 == Type.OBJECT»
						requireNonNull(value1);
					«ENDIF»
					apply(value1, value2);
				};
			}

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				default <B> Eff2<B, A2> contraMap1(final F<B, A1> f) {
					requireNonNull(f);
					return (final B value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						final A1 value = requireNonNull(f.apply(value1));
						apply(value, value2);
					};
				}

				default <B> Eff2<A1, B> contraMap2(final F<B, A2> f) {
					requireNonNull(f);
					return (final A1 value1, final B value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						final A2 value = requireNonNull(f.apply(value2));
						apply(value1, value);
					};
				}
			«ELSEIF type1 == Type.OBJECT»
				default <B> Object«type2.typeName»Eff2<B> contraMap1(final F<B, A> f) {
					requireNonNull(f);
					return (final B value1, final «type2.javaName» value2) -> {
						requireNonNull(value1);
						final A value = requireNonNull(f.apply(value1));
						apply(value, value2);
					};
				}

				default <B> Eff2<A, B> contraMap2(final «type2.typeName»F<B> f) {
					requireNonNull(f);
					return (final A value1, final B value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						final «type2.javaName» value = f.apply(value2);
						apply(value1, value);
					};
				}
			«ELSEIF type2 == Type.OBJECT»
				default <B> Eff2<B, A> contraMap1(final «type1.typeName»F<B> f) {
					requireNonNull(f);
					return (final B value1, final A value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						final «type1.javaName» value = f.apply(value1);
						apply(value, value2);
					};
				}

				default <B> «type1.typeName»ObjectEff2<B> contraMap2(final F<B, A> f) {
					requireNonNull(f);
					return (final «type1.javaName» value1, final B value2) -> {
						requireNonNull(value2);
						final A value = requireNonNull(f.apply(value2));
						apply(value1, value);
					};
				}
			«ELSE»
				default <A> Object«type2.typeName»Eff2<A> contraMap1(final «type1.typeName»F<A> f) {
					requireNonNull(f);
					return (final A value1, final «type2.javaName» value2) -> {
						requireNonNull(value1);
						final «type1.javaName» value = f.apply(value1);
						apply(value, value2);
					};
				}

				default <A> «type1.typeName»ObjectEff2<A> contraMap2(final «type2.typeName»F<A> f) {
					requireNonNull(f);
					return (final «type1.javaName» value1, final A value2) -> {
						requireNonNull(value2);
						final «type2.javaName» value = f.apply(value2);
						apply(value1, value);
					};
				}
			«ENDIF»

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				default F<A1, Eff<A2>> curry() {
					return (final A1 value1) -> {
						requireNonNull(value1);
						return (final A2 value2) -> {
							requireNonNull(value2);
							apply(value1, value2);
						};
					};
				}
			«ELSEIF type1 == Type.OBJECT»
				default F<A, «type2.typeName»Eff> curry() {
					return (final A value1) -> {
						requireNonNull(value1);
						return (final «type2.javaName» value2) -> apply(value1, value2);
					};
				}
			«ELSEIF type2 == Type.OBJECT»
				default «type1.typeName»ObjectF<Eff<A>> curry() {
					return (final «type1.javaName» value1) -> (final A value2) -> {
						requireNonNull(value2);
						apply(value1, value2);
					};
				}
			«ELSE»
				default «type1.typeName»ObjectF<«type2.typeName»Eff> curry() {
					return (final «type1.javaName» value1) -> (final «type2.javaName» value2) ->
						apply(value1, value2);
				}
			«ENDIF»
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»

				default BiConsumer<A1, A2> toBiConsumer() {
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						apply(value1, value2);
					};
				}

				static «paramGenericName» fromBiConsumer(final BiConsumer<A1, A2> consumer) {
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						consumer.accept(value1, value2);
					};
				}
			«ELSEIF type1 == Type.OBJECT && Type.javaUnboxedTypes.contains(type2)»

				default Obj«type2.typeName»Consumer<A> toObj«type2.typeName»Consumer() {
					return (final A value1, final «type2.javaName» value2) -> {
						requireNonNull(value1);
						apply(value1, value2);
					};
				}

				static «paramGenericName» fromObj«type2.typeName»Consumer(final Obj«type2.typeName»Consumer<A> consumer) {
					return (final A value1, final «type2.javaName» value2) -> {
						requireNonNull(value1);
						consumer.accept(value1, value2);
					};
				}
			«ENDIF»

			static «paramGenericName» «shortName.firstToLowerCase»(final «genericName» eff) {
				return requireNonNull(eff);
			}
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»

				«cast(#["A1", "A2"], #["A1", "A2"], #[])»
			«ELSEIF type1 == Type.OBJECT || type2 == Type.OBJECT»

				«cast(#["A"], #["A"], #[])»
			«ENDIF»
		}
	''' }
}