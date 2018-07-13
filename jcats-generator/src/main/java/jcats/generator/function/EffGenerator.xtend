package jcats.generator.function

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import jcats.generator.Type
import java.util.List
import jcats.generator.Generator

@FinalFieldsConstructor
final class EffGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[t | new EffGenerator(t) as Generator]
	}

	override className() {
		Constants.FUNCTION + "." + shortName
	}

	def shortName() { type.shortName("Eff") }
	def genericName() { type.genericName("Eff") }
	def paramGenericName() { type.paramGenericName("Eff") }
	def contravariantName() { type.contravariantName("Eff") }

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.Objects;
		«IF type == Type.OBJECT || type == Type.BOOLEAN»
			import java.util.function.Consumer;
		«ELSE»
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface «contravariantName» {
			void apply(final «type.genericName» value);

			«IF type == Type.OBJECT»
				default <B> Eff<B> contraMap(final F<B, A> f) {
					requireNonNull(f);
					return (final B b) -> {
						requireNonNull(b);
						final A a = requireNonNull(f.apply(b));
						apply(a);
					};
				}
			«ELSE»
				default <A> Eff<A> contraMap(final «type.typeName»F<A> f) {
					requireNonNull(f);
					return (final A a) -> apply(f.apply(requireNonNull(a)));
				}
			«ENDIF»

			«FOR primitive : Type.primitives»
				«IF type == Type.OBJECT»
					default «primitive.typeName»Eff contraMapFrom«primitive.typeName»(final «primitive.typeName»ObjectF<A> f) {
						requireNonNull(f);
						return (final «primitive.genericName» value) -> {
							final A result = requireNonNull(f.apply(value));
							apply(result);
						};
					}
				«ELSE»
					default «primitive.typeName»Eff contraMapFrom«primitive.typeName»(final «primitive.typeName»«type.typeName»F f) {
						requireNonNull(f);
						return (final «primitive.genericName» value) -> apply(f.apply(value));
					}
				«ENDIF»

			«ENDFOR»
			default Eff0 toEff0(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return () -> apply(value);
			}

			«IF type == Type.OBJECT»
				default <X extends Throwable> EffX<A, X> toEffX() {
					return (final A a) -> apply(requireNonNull(a));
				}

			«ENDIF»
			«IF type != Type.OBJECT»
				default Eff<«type.boxedName»> toEff() {
					return this::apply;
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				default Consumer<A> toConsumer() {
					return (final A a) -> apply(requireNonNull(a));
				}
			«ELSEIF type != Type.BOOLEAN»
				default «type.typeName»Consumer to«type.typeName»Consumer() {
					return this::apply;
				}
			«ELSE»
				default Consumer<Boolean> toConsumer() {
					return this::apply;
				}
			«ENDIF»

			static «paramGenericName» «shortName.firstToLowerCase»(final «genericName» eff) {
				return requireNonNull(eff);
			}

			«IF type == Type.OBJECT»
				static <A, B> Eff<A> compose(final Eff<B> eff, final F<A, B> f) {
			«ELSE»
				static <A> Eff<A> compose(final «shortName» eff, final «type.typeName»F<A> f) {
			«ENDIF»
				return eff.contraMap(f);
			}

			«FOR primitive : Type.primitives»
				«IF type == Type.OBJECT»
					static <A> «primitive.typeName»Eff composeFrom«primitive.typeName»(final Eff<A> eff, final «primitive.typeName»ObjectF<A> f) {
				«ELSE»
					static «primitive.typeName»Eff composeFrom«primitive.typeName»(final «shortName» eff, final «primitive.typeName»«type.typeName»F f) {
				«ENDIF»
					return eff.contraMapFrom«primitive.typeName»(f);
				}

			«ENDFOR»
			static <«IF type == Type.OBJECT»A, «ENDIF»X extends RuntimeException> «genericName» fail(final F0<X> f) {
				return (final «type.genericName» value) -> {
					throw f.apply();
				};
			}

			static «paramGenericName» doNothing() {
				return Objects::requireNonNull;
			}

			«IF type == Type.OBJECT»
				static <A> Eff<A> fromConsumer(final Consumer<A> c) {
					requireNonNull(c);
					return (final A a) -> c.accept(requireNonNull(a));
				}

			«ELSEIF type != Type.BOOLEAN»
				default «shortName» from«type.typeName»Consumer(final «type.typeName»Consumer c) {
					requireNonNull(c);
					return c::accept;
				}
			«ELSE»
				static «shortName» fromConsumer(final Consumer<Boolean> c) {
					requireNonNull(c);
					return c::accept;
				}
			«ENDIF»
			«IF type == Type.OBJECT»
				«cast(#["A"], #["A"], #[])»
			«ENDIF»
		}
	''' }
}