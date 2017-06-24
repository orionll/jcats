package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.List
import jcats.generator.Generator

@FinalFieldsConstructor
final class F0Generator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new F0Generator(it) as Generator]
	}

	override className() {
		Constants.FUNCTION + "." + shortName
	}

	def shortName() {
		if (type == Type.OBJECT) {
			"F0"
		} else {
			type.typeName + "F0"
		}
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		«IF type == Type.OBJECT»
			import java.util.function.Supplier;
		«ELSE»
			import java.util.function.«type.typeName»Supplier;
		«ENDIF»
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		@FunctionalInterface
		public interface «shortName»«if (type == Type.OBJECT) "<A>" else ""» {
			«type.genericName» apply();

			«IF type == Type.OBJECT»
				default <B> F0<B> map(final F<A, B> f) {
					requireNonNull(f);
					return () -> {
						final A a = requireNonNull(apply());
						return requireNonNull(f.apply(a));
					};
				}
			«ELSE»
				default <A> F0<A> map(final «type.typeName»ObjectF<A> f) {
					requireNonNull(f);
					return () -> {
						final «type.genericName» value = apply();
						return requireNonNull(f.apply(value));
					};
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				«FOR primitive : Type.values.filter[it != Type.OBJECT]»
					default «primitive.typeName»F0 mapTo«primitive.typeName»(final «primitive.typeName»F<A> f) {
						requireNonNull(f);
						return () -> {
							final A a = requireNonNull(apply());
							return f.apply(a);
						};
					}

				«ENDFOR»
			«ELSE»
				«FOR primitive : Type.values.filter[it != Type.OBJECT]»
					default «primitive.typeName»F0 mapTo«primitive.typeName»(final «type.typeName»«primitive.typeName»F f) {
						requireNonNull(f);
						return () -> {
							final «type.genericName» value = apply();
							return f.apply(value);
						};
					}

				«ENDFOR»
			«ENDIF»
			«IF type == Type.OBJECT»
				default <B> F0<B> flatMap(final F<A, F0<B>> f) {
					requireNonNull(f);
					return () -> {
						final A a = requireNonNull(apply());
						return requireNonNull(f.apply(a).apply());
					};
				}
			«ELSE»
				default <A> F0<A> flatMap(final «type.typeName»ObjectF<F0<A>> f) {
					requireNonNull(f);
					return () -> {
						final «type.genericName» value = apply();
						return requireNonNull(f.apply(value).apply());
					};
				}
			«ENDIF»

			«IF type != Type.OBJECT»
				default F0<«type.boxedName»> toF0() {
					return this::apply;
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				default <B> F<B, A> toConstF() {
					return (final B b) -> {
						requireNonNull(b);
						return requireNonNull(apply());
					};
				}
			«ELSE»
				default <A> «type.typeName»F<A> toConstF() {
					return (final A a) -> {
						requireNonNull(a);
						return apply();
					};
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «t.typeName»ObjectF<A> toConst«t.typeName»ObjectF() {
						return (final «t.javaName» __) -> requireNonNull(apply());
					}
				«ELSE»
					default «t.typeName»«type.typeName»F toConst«t.typeName»«type.typeName»F() {
						return (final «t.javaName» __) -> apply();
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				default Supplier<A> toSupplier() {
					return () -> requireNonNull(apply());
				}
			«ELSE»
				default «type.typeName»Supplier to«type.typeName»Supplier() {
					return this::apply;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A> F0<A> value(final A a) {
					requireNonNull(a);
					return () -> a;
				}

				/**
				 * Synonym for {@link #value}
				 */
				static <A> F0<A> of(final A a) {
					return value(a);
				}
			«ELSE»
				static «shortName» «type.typeName.firstToLowerCase»Value(final «type.genericName» value) {
					return () -> value;
				}

				/**
				 * Synonym for {@link #«type.typeName.firstToLowerCase»Value}
				 */
				static «shortName» of(final «type.genericName» value) {
					return «type.typeName.firstToLowerCase»Value(value);
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				«join»
			«ELSE»
				static «shortName» join(final F0<«shortName»> f) {
					requireNonNull(f);
					return () -> f.apply().apply();
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A> F0<A> fromSupplier(final Supplier<A> s) {
					requireNonNull(s);
					return () -> requireNonNull(s.get());
				}

			«ELSE»
				static «shortName» from«type.typeName»Supplier(final «type.typeName»Supplier s) {
					requireNonNull(s);
					return s::getAs«type.typeName»;
				}
			«ENDIF»
			«IF type == Type.OBJECT»
				«productN»
				«productWithN[arity | '''
					requireNonNull(f);
					return () -> {
						«FOR i : 1 .. arity»
							final A«i» a«i» = requireNonNull(f«i».apply());
						«ENDFOR»
						return requireNonNull(f.apply(«(1 .. arity).map["a" + it].join(", ")»));
					};
				''']»
				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}