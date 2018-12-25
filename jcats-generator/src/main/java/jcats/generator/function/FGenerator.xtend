package jcats.generator.function

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class FGenerator implements InterfaceGenerator {
	val Type from
	val Type to

	def static List<Generator> generators() {
		Type.values.toList.map[from | Type.values.toList.map[to | new FGenerator(from, to) as Generator]].flatten.toList
	}

	override className() {
		Constants.FUNCTION + "." + shortName
	}

	def shortName() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"F"
		} else if (from == Type.OBJECT) {
			to.typeName + "F"
		} else {
			from.typeName + to.typeName + "F"
		}
	}

	def typeParams() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"<A, B>"
		} else if (from == Type.OBJECT || to == Type.OBJECT) {
			"<A>"
		} else {
			""
		}
	}

	def genericName() {
		shortName + typeParams
	}

	def paramGenericName() {
		if (typeParams.empty) {
			genericName
		} else {
			typeParams + " " + genericName
		}
	}

	def alwaysName() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"always"
		} else if (from == Type.OBJECT) {
			to.typeName.firstToLowerCase + "Always"
		} else {
			from.typeName.firstToLowerCase + to.typeName + "Always"
		}
	} 

	def variantTypeParams() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"<@Contravariant A, @Covariant B>"
		} else if (from == Type.OBJECT) {
			"<@Contravariant A>"
		} else if (to == Type.OBJECT) {
			"<@Covariant A>"
		} else {
			""
		}
	}

	def fromName() {
		if (from == Type.OBJECT) "A" else from.javaName
	}

	def toName() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"B"
		} else if (to == Type.OBJECT) {
			"A"
		} else {
			to.javaName
		}
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		«IF from == Type.OBJECT && to == Type.OBJECT»
			import java.util.function.Function;
		«ELSEIF from != Type.BOOLEAN && to == Type.OBJECT»
			import java.util.function.«from.typeName»Function;
		«ELSEIF from == Type.OBJECT && to != Type.BOOLEAN»
			import java.util.function.To«to.typeName»Function;
		«ELSEIF from == Type.BOOLEAN && to == Type.OBJECT»
			import java.util.function.Function;
		«ELSEIF from == Type.OBJECT && to == Type.BOOLEAN»
			import java.util.function.Predicate;
		«ELSEIF from == to && to != Type.BOOLEAN»
			import java.util.function.«from.typeName»UnaryOperator;
		«ELSEIF from == Type.BOOLEAN && to == Type.BOOLEAN»
			import java.util.function.UnaryOperator;
			import java.util.function.Predicate;
		«ELSEIF to == Type.BOOLEAN»
			import java.util.function.«from.typeName»Predicate;
		«ELSEIF from != Type.BOOLEAN && to != Type.BOOLEAN»
			import java.util.function.«from.typeName»To«to.typeName»Function;
		«ELSEIF from == Type.BOOLEAN»
			import java.util.function.To«to.typeName»Function;
		«ENDIF»

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		@FunctionalInterface
		public interface «shortName»«variantTypeParams» {

			«toName» apply(«fromName» value);

			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C> F<A, C> map(final F<B, C> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						final B b = requireNonNull(apply(a));
						return requireNonNull(f.apply(b));
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B> «shortName»<B> map(final F<A, B> f) {
					requireNonNull(f);
					return (final «from.javaName» value) -> {
						final A a = requireNonNull(apply(value));
						return requireNonNull(f.apply(a));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B> F<A, B> map(final «to.typeName»ObjectF<B> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						final «toName» value = apply(a);
						return requireNonNull(f.apply(value));
					};
				}
			«ELSE»
				default <A> «from.typeName»ObjectF<A> map(final «to.typeName»ObjectF<A> f) {
					requireNonNull(f);
					return (final «from.javaName» value) -> {
						final «toName» result = apply(value);
						return requireNonNull(f.apply(result));
					};
				}
			«ENDIF»

			«IF to == Type.BOOLEAN»
				default «shortName»«typeParams» negate() {
					«IF from == Type.OBJECT»
						return (final «from.genericName» value) -> {
							requireNonNull(value);
							return !apply(value);
						};
					«ELSE»
						return (final «from.javaName» value) -> !apply(value);
					«ENDIF»
				}

			«ENDIF»
			«FOR primitive : Type.primitives»
				«IF from == Type.OBJECT && to == Type.OBJECT»
					default «primitive.typeName»F<A> mapTo«primitive.typeName»(final «primitive.typeName»F<B> f) {
						requireNonNull(f);
						return (final A a) -> {
							requireNonNull(a);
							final B b = requireNonNull(apply(a));
							return f.apply(b);
						};
					}
				«ELSEIF to == Type.OBJECT»
					default «from.typeName»«primitive.typeName»F mapTo«primitive.typeName»(final «primitive.typeName»F<A> f) {
						requireNonNull(f);
						return (final «from.javaName» value) -> {
							final A a = requireNonNull(apply(value));
							return f.apply(a);
						};
					}
				«ELSEIF from == Type.OBJECT»
					default «primitive.typeName»F<A> mapTo«primitive.typeName»(final «to.typeName»«primitive.typeName»F f) {
						requireNonNull(f);
						return (final A a) -> {
							requireNonNull(a);
							final «toName» value = apply(a);
							return f.apply(value);
						};
					}
				«ELSE»
					default «from.typeName»«primitive.typeName»F mapTo«primitive.typeName»(final «to.typeName»«primitive.typeName»F f) {
						requireNonNull(f);
						return (final «from.javaName» value) -> {
							final «toName» result = apply(value);
							return f.apply(result);
						};
					}
				«ENDIF»

			«ENDFOR»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C> F<C, B> contraMap(final F<C, A> f) {
					requireNonNull(f);
					return (final C c) -> {
						requireNonNull(c);
						final A a = requireNonNull(f.apply(c));
						return requireNonNull(apply(a));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B> «to.typeName»F<B> contraMap(final F<B, A> f) {
					requireNonNull(f);
					return (final B b) -> {
						requireNonNull(b);
						final A a = requireNonNull(f.apply(b));
						return apply(a);
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B> F<B, A> contraMap(final «from.typeName»F<B> f) {
					requireNonNull(f);
					return (final B b) -> {
						requireNonNull(b);
						final «fromName» value = f.apply(b);
						return requireNonNull(apply(value));
					};
				}
			«ELSE»
				default <A> «to.typeName»F<A> contraMap(final «from.typeName»F<A> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						final «fromName» value = f.apply(a);
						return apply(value);
					};
				}
			«ENDIF»

			«FOR primitive : Type.primitives»
				«IF from == Type.OBJECT && to == Type.OBJECT»
					default «primitive.typeName»ObjectF<B> contraMapFrom«primitive.typeName»(final «primitive.typeName»ObjectF<A> f) {
						requireNonNull(f);
						return (final «primitive.genericName» value) -> {
							final A a = requireNonNull(f.apply(value));
							return requireNonNull(apply(a));
						};
					}
				«ELSEIF to == Type.OBJECT»
					default «primitive.typeName»ObjectF<A> contraMapFrom«primitive.typeName»(final «primitive.typeName»«from.typeName»F f) {
						requireNonNull(f);
						return (final «primitive.genericName» value) -> {
							final «from.genericName» result = f.apply(value);
							return requireNonNull(apply(result));
						};
					}
				«ELSEIF from == Type.OBJECT»
					default «primitive.typeName»«to.typeName»F contraMapFrom«primitive.typeName»(final «primitive.typeName»ObjectF<A> f) {
						requireNonNull(f);
						return (final «primitive.genericName» value) -> {
							final A a = requireNonNull(f.apply(value));
							return apply(a);
						};
					}
				«ELSE»
					default «primitive.typeName»«to.typeName»F contraMapFrom«primitive.typeName»(final «primitive.typeName»«from.typeName»F f) {
						requireNonNull(f);
						return (final «primitive.genericName» value) -> {
							final «from.genericName» result = f.apply(value);
							return apply(result);
						};
					}
				«ENDIF»

			«ENDFOR»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C, D> F<C, D> diMap(final F<C, A> f, final F<B, D> g) {
					requireNonNull(f);
					requireNonNull(g);
					return (final C c) -> {
						requireNonNull(c);
						final A a = requireNonNull(f.apply(c));
						final B b = requireNonNull(apply(a));
						return requireNonNull(g.apply(b));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B, C> F<B, C> diMap(final F<B, A> f, final «to.typeName»ObjectF<C> g) {
					requireNonNull(f);
					requireNonNull(g);
					return (final B b) -> {
						requireNonNull(b);
						final A a = requireNonNull(f.apply(b));
						final «toName» value = apply(a);
						return requireNonNull(g.apply(value));
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B, C> F<B, C> diMap(final «from.typeName»F<B> f, final F<A, C> g) {
					requireNonNull(f);
					requireNonNull(g);
					return (final B b) -> {
						requireNonNull(b);
						final «fromName» value = f.apply(b);
						final A a = requireNonNull(apply(value));
						return requireNonNull(g.apply(a));
					};
				}
			«ELSE»
				default <A, B> F<A, B> diMap(final «from.typeName»F<A> f, final «to.typeName»ObjectF<B> g) {
					requireNonNull(f);
					requireNonNull(g);
					return (final A a) -> {
						requireNonNull(a);
						final «fromName» value = f.apply(a);
						final «toName» result = apply(value);
						return requireNonNull(g.apply(result));
					};
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C> F<A, C> flatMap(final F<B, F<A, C>> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						final B b = requireNonNull(apply(a));
						return requireNonNull(f.apply(b).apply(a));
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B> «shortName»<B> flatMap(final F<A, «shortName»<B>> f) {
					requireNonNull(f);
					return (final «from.javaName» value) -> {
						final A a = requireNonNull(apply(value));
						return requireNonNull(f.apply(a).apply(value));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B> F<A, B> flatMap(final «to.typeName»ObjectF<F<A, B>> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						final «toName» value = apply(a);
						return requireNonNull(f.apply(value).apply(a));
					};
				}
			«ELSE»
				default <A> «from.typeName»ObjectF<A> flatMap(final «to.typeName»ObjectF<«from.typeName»ObjectF<A>> f) {
					requireNonNull(f);
					return (final «from.javaName» value) -> {
						final «toName» result = apply(value);
						return requireNonNull(f.apply(result).apply(value));
					};
				}
			«ENDIF»

			«IF to == Type.OBJECT»
				default F0<«toName»> toF0(final «fromName» value) {
					«IF from == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					return () -> requireNonNull(apply(value));
				}
			«ELSE»
				default «to.typeName»F0 to«to.typeName»F0(final «fromName» value) {
					return () -> «to.requireNonNull("apply(value)")»;
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <X extends Throwable> FX<A, B, X> toFX() {
					return (final A a) -> apply(requireNonNull(a));
				}

			«ENDIF»
			«IF from != Type.OBJECT && to == Type.OBJECT»
				default F<«from.boxedName», A> toF() {
					return (final «from.boxedName» value) -> {
						final A result = apply(value);
						return requireNonNull(result);
					};
				}

			«ELSEIF from == Type.OBJECT && to != Type.OBJECT»
				default F<A, «to.boxedName»> toF() {
					return (final A value) -> apply(requireNonNull(value));
				}

			«ELSEIF from != Type.OBJECT && to != Type.OBJECT»
				default «from.typeName»ObjectF<«to.boxedName»> to«from.typeName»ObjectF() {
					return this::apply;
				}

				default «to.typeName»F<«from.boxedName»> to«to.typeName»F() {
					return this::apply;
				}

				default F<«from.boxedName», «to.boxedName»> toF() {
					return this::apply;
				}

			«ENDIF»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				default Function<A, B> toFunction() {
					return (final A a) -> {
						requireNonNull(a);
						return requireNonNull(apply(a));
					};
				}
			«ELSEIF from != Type.BOOLEAN && to == Type.OBJECT»
				default «from.typeName»Function<A> to«from.typeName»Function() {
					return (final «from.javaName» value) -> requireNonNull(apply(value));
				}
			«ELSEIF from == Type.BOOLEAN && to == Type.OBJECT»
				default Function<Boolean, A> toFunction() {
					return (final Boolean value) -> {
						requireNonNull(value);
						return requireNonNull(apply(value));
					};
				}
			«ELSEIF from == Type.OBJECT && to != Type.BOOLEAN»
				default To«to.typeName»Function<A> toTo«to.typeName»Function() {
					return (final A a) -> apply(requireNonNull(a));
				}
			«ELSEIF from == Type.OBJECT && to == Type.BOOLEAN»
				default Predicate<A> toPredicate() {
					return (final A a) -> {
						requireNonNull(a);
						return apply(a);
					};
				}
			«ELSEIF from == to && to != Type.BOOLEAN»
				default «from.typeName»UnaryOperator to«from.typeName»UnaryOperator() {
					return this::apply;
				}
			«ELSEIF from == Type.BOOLEAN && to == Type.BOOLEAN»
				default UnaryOperator<Boolean> toUnaryOperator() {
					return this::apply;
				}

				default Predicate<Boolean> toPredicate() {
					return this::apply;
				}
			«ELSEIF to == Type.BOOLEAN»
				default «from.typeName»Predicate to«from.typeName»Predicate() {
					return this::apply;
				}
			«ELSEIF from != Type.BOOLEAN && to != Type.BOOLEAN»
				default «from.typeName»To«to.typeName»Function to«from.typeName»To«to.typeName»Function() {
					return this::apply;
				}
			«ELSEIF from == Type.BOOLEAN»
				default To«to.typeName»Function<Boolean> toTo«to.typeName»Function() {
					return this::apply;
				}
			«ENDIF»

			«IF from == Type.OBJECT»
				default Eff<A> toEff() {
					return (final A a) -> apply(requireNonNull(a));
				}

			«ELSE»
				default «from.typeName»Eff to«from.typeName»Eff() {
					return this::apply;
				}

			«ENDIF»
			«IF from == to»
				«IF from == Type.OBJECT»
					static <A> F<A, A> id() {
						return (F<A, A>) Fs.ID;
					}

				«ELSE»
					static «shortName» id() {
						return Fs.«from.typeName.toUpperCase»_ID;
					}

				«ENDIF»
			«ENDIF»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				static <A, B, C> F<A, C> andThen(final «shortName»«typeParams» f, final F<B, C> g) {
			«ELSEIF to == Type.OBJECT»
				static <A, B> «shortName»<B> andThen(final «shortName»«typeParams» f, final F<A, B> g) {
			«ELSEIF from == Type.OBJECT»
				static <A, B> F<A, B> andThen(final «shortName»«typeParams» f, final «to.typeName»ObjectF<B> g) {
			«ELSE»
				static <A> «from.typeName»ObjectF<A> andThen(final «shortName»«typeParams» f, final «to.typeName»ObjectF<A> g) {
			«ENDIF»
				return f.map(g);
			}

			«FOR type : Type.primitives»
				«IF from == Type.OBJECT && to == Type.OBJECT»
					static <A, B> «type.typeName»F<A> andThenTo«type.typeName»(final «shortName»«typeParams» f, final «type.typeName»F<B> g) {
				«ELSEIF to == Type.OBJECT»
					static <A> «from.typeName»«type.typeName»F andThenTo«type.typeName»(final «shortName»«typeParams» f, final «type.typeName»F<A> g) {
				«ELSEIF from == Type.OBJECT»
					static <A> «type.typeName»F<A> andThenTo«type.typeName»(final «shortName»«typeParams» f, final «to.typeName»«type.typeName»F g) {
				«ELSE»
					static «from.typeName»«type.typeName»F andThenTo«type.typeName»(final «shortName»«typeParams» f, final «to.typeName»«type.typeName»F g) {
				«ENDIF»
					return f.mapTo«type.typeName»(g);
				}

			«ENDFOR»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				static <A, B, C> F<A, C> compose(final F<B, C> f, final «shortName»«typeParams» g) {
			«ELSEIF to == Type.OBJECT»
				static <A, B> F<A, B> compose(final «shortName»<B> f, final «from.typeName»F<A> g) {
			«ELSEIF from == Type.OBJECT»
				static <A, B> «to.typeName»F<A> compose(final «shortName»<B> f, final F<A, B> g) {
			«ELSE»
				static <A> «to.typeName»F<A> compose(final «shortName» f, final «from.typeName»F<A> g) {
			«ENDIF»
				return f.contraMap(g);
			}

			«FOR type : Type.primitives»
				«IF from == Type.OBJECT && to == Type.OBJECT»
					static <A, B> «type.typeName»ObjectF<B> composeFrom«type.typeName»(final F<A, B> f, final «type.typeName»ObjectF<A> g) {
				«ELSEIF to == Type.OBJECT»
					static <A> «type.typeName»ObjectF<A> composeFrom«type.typeName»(final «shortName»<A> f, final «type.typeName»«from.typeName»F g) {
				«ELSEIF from == Type.OBJECT»
					static <A> «type.typeName»«to.typeName»F composeFrom«type.typeName»(final «shortName»<A> f, final «type.typeName»ObjectF<A> g) {
				«ELSE»
					static «type.typeName»«to.typeName»F composeFrom«type.typeName»(final «shortName» f, final «type.typeName»«from.typeName»F g) {
				«ENDIF»
					return f.contraMapFrom«type.typeName»(g);
				}

			«ENDFOR»
			static «paramGenericName» «alwaysName»(final «toName» value) {
				«IF from == Type.OBJECT && to == Type.OBJECT»
					requireNonNull(value);
					return (final A a) -> {
						requireNonNull(a);
						return value;
					};
				«ELSEIF to == Type.OBJECT»
					requireNonNull(value);
					return (final «from.javaName» __) -> value;
				«ELSEIF from == Type.OBJECT»
					return (final A a) -> {
						requireNonNull(a);
						return value;
					};
				«ELSE»
					return (final «from.javaName» __) -> value;
				«ENDIF»
			}

			«IF to == Type.BOOLEAN»
				static «paramGenericName» not(final «genericName» f) {
					return f.negate();
				}

				static «paramGenericName» and(final «genericName» f1, final «genericName» f2) {
					requireNonNull(f1);
					requireNonNull(f2);
					«IF from == Type.OBJECT»
						return (final «from.genericName» value) -> {
							requireNonNull(value);
							return f1.apply(value) && f2.apply(value);
						};
					«ELSE»
						return (final «from.genericName» value) -> f1.apply(value) && f2.apply(value);
					«ENDIF»
				}

				static «paramGenericName» or(final «genericName» f1, final «genericName» f2) {
					requireNonNull(f1);
					requireNonNull(f2);
					«IF from == Type.OBJECT»
						return (final «from.genericName» value) -> {
							requireNonNull(value);
							return f1.apply(value) || f2.apply(value);
						};
					«ELSE»
						return (final «from.genericName» value) -> f1.apply(value) || f2.apply(value);
					«ENDIF»
				}

				«IF from == Type.OBJECT»
					static «paramGenericName» isNull() {
						return (final A value) -> (value == null);
					}

					static «paramGenericName» isNotNull() {
						return (final A value) -> (value != null);
					}

					static <A> BooleanF<A> isEqualTo(final A other) {
						requireNonNull(other);
						return (final A value) -> value.equals(other);
					}

					static <A> BooleanF<A> isNotEqualTo(final A other) {
						requireNonNull(other);
						return (final A value) -> !value.equals(other);
					}

					static <A, B extends A> BooleanF<A> isInstanceOf(final Class<B> clazz) {
						requireNonNull(clazz);
						return (final A value) -> clazz.isInstance(requireNonNull(value));
					}

					static <A> BooleanF<A> referenceEquals(final A other) {
						requireNonNull(other);
						return (final A value) -> (requireNonNull(value) == other);
					}
				«ELSE»
					static «paramGenericName» isEqualTo«from.typeName»(final «from.javaName» other) {
						return (final «from.javaName» value) -> value == other;
					}

					static «paramGenericName» isNotEqualTo«from.typeName»(final «from.javaName» other) {
						return (final «from.javaName» value) -> value != other;
					}
				«ENDIF»

			«ENDIF»
			«javadocSynonym(alwaysName)»
			static «paramGenericName» of(final «toName» value) {
				return «alwaysName»(value);
			}

			static «paramGenericName» «shortName.firstToLowerCase»(final «genericName» f) {
				return requireNonNull(f);
			}

			static <«IF from == Type.OBJECT && to == Type.OBJECT»A, B, «ELSEIF from == Type.OBJECT || to == Type.OBJECT»A, «ENDIF»X extends RuntimeException> «genericName» fail(final F0<X> f) {
				requireNonNull(f);
				return (final «from.genericName» value) -> {
					«IF from == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					throw f.apply();
				};
			}

			static <«IF from == Type.OBJECT && to == Type.OBJECT»A, B, «ELSEIF from == Type.OBJECT || to == Type.OBJECT»A, «ENDIF»C, X extends RuntimeException> «genericName» failWithArg(final F<C, X> f, final C arg) {
				requireNonNull(f);
				requireNonNull(arg);
				return (final «from.genericName» value) -> {
					«IF from == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					throw f.apply(arg);
				};
			}

			«IF from == Type.OBJECT && to == Type.OBJECT»
				«joinMultiple(#["A"], "B")»
			«ELSEIF to == Type.OBJECT»
				«join»
			«ELSEIF from == Type.OBJECT»
				static <A> «shortName»<A> join(final F<A, «shortName»<A>> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						return f.apply(a).apply(a);
					};
				}
			«ELSE»
				static «shortName» join(final «from.typeName»ObjectF<«shortName»> f) {
					requireNonNull(f);
					return (final «from.javaName» value) -> f.apply(value).apply(value);
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				static <A, B> F<A, B> fromFunction(final Function<A, B> f) {
					requireNonNull(f);
					return (final A a) -> {
						requireNonNull(a);
						return requireNonNull(f.apply(a));
					};
				}

			«ELSEIF from != Type.BOOLEAN && to == Type.OBJECT»
				static <A> «shortName»<A> from«from.typeName»Function(final «from.typeName»Function<A> f) {
					requireNonNull(f);
					return (final «from.javaName» value) -> requireNonNull(f.apply(value));
				}

			«ELSEIF from == Type.BOOLEAN && to == Type.OBJECT»
				static <A> «shortName»<A> fromFunction(final Function<Boolean, A> f) {
					requireNonNull(f);
					return (final boolean value) -> requireNonNull(f.apply(value));
				}

			«ELSEIF from == Type.OBJECT && to != Type.BOOLEAN»
				static <A> «shortName»<A> fromTo«to.typeName»Function(final To«to.typeName»Function<A> f) {
					requireNonNull(f);
					return (final A a) -> f.applyAs«to.typeName»(requireNonNull(a));
				}

			«ELSEIF from == Type.OBJECT && to == Type.BOOLEAN»
				static <A> «shortName»<A> fromPredicate(final Predicate<A> p) {
					requireNonNull(p);
					return (final A a) -> p.test(requireNonNull(a));
				}

			«ELSEIF from == to && to != Type.BOOLEAN»
				static «shortName» from«from.typeName»UnaryOperator(final «from.typeName»UnaryOperator op) {
					requireNonNull(op);
					return op::applyAs«from.typeName»;
				}
			«ELSEIF from == Type.BOOLEAN && to == Type.BOOLEAN»
				static «shortName» fromUnaryOperator(final UnaryOperator<Boolean> op) {
					requireNonNull(op);
					return op::apply;
				}

				static «shortName» fromPredicate(final Predicate<Boolean> p) {
					requireNonNull(p);
					return p::test;
				}
			«ELSEIF to == Type.BOOLEAN»
				static «shortName» from«from.typeName»Predicate(final «from.typeName»Predicate p) {
					requireNonNull(p);
					return p::test;
				}
			«ELSEIF from != Type.BOOLEAN && to != Type.BOOLEAN»
				static «shortName» from«from.typeName»To«to.typeName»Function(final «from.typeName»To«to.typeName»Function f) {
					requireNonNull(f);
					return f::applyAs«to.typeName»;
				}
			«ELSEIF from == Type.BOOLEAN»
				static «shortName» fromTo«to.typeName»Function(final To«to.typeName»Function<Boolean> f) {
					requireNonNull(f);
					return f::applyAs«to.typeName»;
				}
			«ENDIF»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				«cast(#["A", "B"], #["A"], #["B"])»
			«ELSEIF from == Type.OBJECT»
				«cast(#["A"], #["A"], #[])»
			«ELSEIF to == Type.OBJECT»
				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}