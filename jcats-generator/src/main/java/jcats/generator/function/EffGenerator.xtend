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

			static «paramGenericName» $(final «genericName» eff) {
				return requireNonNull(eff);
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