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

	def shortName() { type.shortName("F0") }
	def lowerCaseName() { shortName.firstToLowerCase }
	def genericName() { type.genericName("F0") }
	def paramGenericName() { type.paramGenericName("F0") }
	def valueName() { type.shortName("Value").firstToLowerCase }

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		«IF type == Type.OBJECT»
			import java.util.function.Supplier;
		«ELSE»
			import java.util.function.«type.typeName»Supplier;
		«ENDIF»

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		@FunctionalInterface
		public interface «type.covariantName("F0")» {
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
				default <B> F<B, A> toF() {
					return (final B b) -> {
						requireNonNull(b);
						return requireNonNull(apply());
					};
				}
			«ELSE»
				default <A> «type.typeName»F<A> toF() {
					return (final A a) -> {
						requireNonNull(a);
						return apply();
					};
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «t.typeName»ObjectF<A> to«t.typeName»ObjectF() {
						return (final «t.javaName» __) -> requireNonNull(apply());
					}
				«ELSE»
					default «t.typeName»«type.typeName»F to«t.typeName»«type.typeName»F() {
						return (final «t.javaName» __) -> apply();
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <X extends Throwable> F0X<A, X> toF0X() {
					return this::apply;
				}

			«ENDIF»
			default Eff0 toEff0() {
				return this::apply;
			}

			«IF type == Type.OBJECT»
				default Supplier<A> toSupplier() {
					return () -> requireNonNull(apply());
				}
			«ELSE»
				default «type.typeName»Supplier to«type.typeName»Supplier() {
					return this::apply;
				}
			«ENDIF»

			static «paramGenericName» «valueName»(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return () -> value;
			}

			«javadocSynonym(valueName)»
			static «paramGenericName» of(final «type.genericName» value) {
				return «valueName»(value);
			}

			static «paramGenericName» «lowerCaseName»(final «genericName» f) {
				return requireNonNull(f);
			}

			static «type.paramGenericName("F0")» lazy(final «genericName» f) {
				return new Lazy«type.diamondName("F0")»(f);
			}

			«IF type == Type.OBJECT»
				static <A> A run(final «genericName» f) {
					return requireNonNull(f.apply());
			«ELSE»
				static «type.genericName» «type.typeName.firstToLowerCase»Run(final «genericName» f) {
					return f.apply();
			«ENDIF»
			}

			static <«IF type == Type.OBJECT»A, «ENDIF»X extends RuntimeException> «genericName» fail(final F0<X> f) {
				requireNonNull(f);
				return () -> {
					throw f.apply();
				};
			}

			static «paramGenericName» join(final F0<«genericName»> f) {
				requireNonNull(f);
				return () -> «type.requireNonNull("f.apply().apply()")»;
			}

			«IF type == Type.OBJECT»
				static <A> F0<A> fromSupplier(final Supplier<A> s) {
					return () -> requireNonNull(s.get());
				}
			«ELSE»
				static «shortName» from«type.typeName»Supplier(final «type.typeName»Supplier s) {
					return s::getAs«type.typeName»;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				«FOR i : 2 .. Constants.MAX_ARITY»
					static <«(1..i).map['''A«it», '''].join»B> F0<B> map«i»(«(1..i).map['''final F0<A«it»> f«it», '''].join»final F«i»<«(1..i).map['''A«it», '''].join»B> f) {
						«FOR j : 1 .. i»
							requireNonNull(f«j»);
						«ENDFOR»
						requireNonNull(f);
						return () -> {
							«FOR j : 1 .. i»
								final A«j» a«j» = requireNonNull(f«j».apply());
							«ENDFOR»
							return requireNonNull(f.apply(«(1..i).map['''a«it»'''].join(", ")»));
						};
					}

				«ENDFOR»
			«ELSE»
				static <A, B> F0<B> map2(final «shortName» f1, final F0<A> f2, final «type.typeName»ObjectObjectF2<A, B> f) {
					requireNonNull(f1);
					requireNonNull(f2);
					requireNonNull(f);
					return () -> {
						final «type.javaName» value = f1.apply();
						final A a = requireNonNull(f2.apply());
						return requireNonNull(f.apply(value, a));
					};
				}
			«ENDIF»
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class Lazy«genericName» implements «genericName» {
			private final «genericName» f;
			«IF type == Type.OBJECT»
				private volatile «type.genericName» value;
			«ELSE»
				private volatile boolean initialized;
				private «type.genericName» value;
			«ENDIF»

			Lazy«shortName»(final «genericName» f) {
				this.f = requireNonNull(f);
			}

			@Override
			public «type.genericName» apply() {
				«IF type == Type.OBJECT»
					if (this.value == null) {
						synchronized (this) {
							if (this.value == null) {
								final A a = requireNonNull(this.f.apply());
								this.value = a;
								return a;
							}
						}
					}
					return this.value;
				«ELSE»
					if (!this.initialized) {
						synchronized (this) {
							if (!this.initialized) {
								final «type.genericName» a = «type.requireNonNull("this.f.apply()")»;
								this.value = a;
								this.initialized = true;
								return a;
							}
						}
					}
					return this.value;
				«ENDIF»
			}
		}
	''' }
}