package jcats.generator.function

import java.util.List
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension com.google.common.collect.Iterables.concat
import jcats.generator.Constants

@FinalFieldsConstructor
class F2Generator implements InterfaceGenerator {
	val Type type1
	val Type type2
	val Type returnType

	def static List<Generator> generators() {
		(0 ..< Type.values.size).map[i1 | 
			(0 ..< Type.values.size).map[i2 |
				Type.values.toList.map[resultType |
					new F2Generator(Type.values.get(i1), Type.values.get(i2), resultType) as Generator
		]]].concat.concat.toList
	}

	override className() { Constants.FUNCTION + "." + shortName }

	def String shortName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			if (returnType == Type.OBJECT) "F2" else returnType.typeName + "F2"
		} else {
			'''«type1.typeName»«type2.typeName»«returnType.typeName»F2'''
		}
	}
	
	def typeParams(boolean annotations) {
		val params =
		if (returnType == Type.OBJECT) {
			if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
				"<@Contravariant A1, @Contravariant A2, @Covariant B>"
			} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				"<@Contravariant A, @Covariant B>"
			} else {
				"<@Covariant A>"
			}
		} else {
			if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
				"<@Contravariant A1, @Contravariant A2>"
			} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				"<@Contravariant A>"
			} else {
				""
			}
		}
		if (annotations) {
			params
		} else {
			params.replaceAll("@Contravariant ", "").replaceAll("@Covariant ", "")
		}
	}

	def variantName() {
		shortName + typeParams(true)
	}

	def genericName() {
		shortName + typeParams(false)
	}

	def paramGenericName() {
		val params = typeParams(false)
		if (params.empty) genericName else params + " " + genericName
	}

	def returnTypeGenericName() {
		if (returnType == Type.OBJECT) {
			if (type1 == Type.OBJECT || type2 == Type.OBJECT) "B" else "A"
		} else {
			returnType.javaName
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

	def mapReturnType() {
		if (returnType == Type.OBJECT) {
			if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
				"<C> F2<A1, A2, C>"
			} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				'''<C> «shortName»<A, C>'''
			} else {
				'''<B> «shortName»<B>'''
			}
		} else {
			if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
				"<B> F2<A1, A2, B>"
			} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				'''<B> «type1.typeName»«type2.typeName»«Type.OBJECT.typeName»F2<A, B>'''
			} else {
				'''<A> «type1.typeName»«type2.typeName»«Type.OBJECT.typeName»F2<A>'''
			}
		}
	}

	def mapFunction() {
		if (returnType == Type.OBJECT) {
			if (type1 == Type.OBJECT || type2 == Type.OBJECT) "F<B, C>" else "F<A, B>"
		} else {
			if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				'''«returnType.typeName»ObjectF<B>'''
			} else {
				'''«returnType.typeName»ObjectF<A>'''
			}
		}
	}

	def alwaysName() {
		shortName.replaceAll("F2", "Always").firstToLowerCase
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;
		
		«IF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.OBJECT»
			import java.util.function.BiFunction;
			import java.util.function.BinaryOperator;
		«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && Type.javaUnboxedTypes.contains(returnType)»
			import java.util.function.To«returnType.typeName»BiFunction;
		«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.BOOLEAN»
			import java.util.function.BiPredicate;
		«ELSEIF type1 == type2 && returnType == type2 && Type.javaUnboxedTypes.contains(returnType)»
			import java.util.function.«returnType.typeName»BinaryOperator;
		«ENDIF»

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface «variantName» {

			«returnTypeGenericName» apply(final «type1GenericName» value1, final «type2GenericName» value2);

			default «mapReturnType» map(final «mapFunction» f) {
				requireNonNull(f);
				return (final «type1GenericName» value1, final «type2GenericName» value2) -> {
					«IF type1 == Type.OBJECT»
						requireNonNull(value1);
					«ENDIF»
					«IF type2 == Type.OBJECT»
						requireNonNull(value2);
					«ENDIF»
					«IF returnType == Type.OBJECT»
						final «returnTypeGenericName» value = requireNonNull(apply(value1, value2));
					«ELSE»
						final «returnTypeGenericName» value = apply(value1, value2);
					«ENDIF»
					return requireNonNull(f.apply(value));
				};
			}

			«IF returnType == Type.OBJECT»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default <C> F2<C, A2, B> contraMap1(final F<C, A1> f) {
						requireNonNull(f);
						return (final C value1, final A2 value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final A1 value = requireNonNull(f.apply(value1));
							return requireNonNull(apply(value, value2));
						};
					}

					default <C> F2<A1, C, B> contraMap2(final F<C, A2> f) {
						requireNonNull(f);
						return (final A1 value1, final C value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final A2 value = requireNonNull(f.apply(value2));
							return requireNonNull(apply(value1, value));
						};
					}
				«ELSEIF type1 == Type.OBJECT»
					default <C> Object«type2.typeName»ObjectF2<C, B> contraMap1(final F<C, A> f) {
						requireNonNull(f);
						return (final C value1, final «type2.javaName» value2) -> {
							requireNonNull(value1);
							final A value = requireNonNull(f.apply(value1));
							return requireNonNull(apply(value, value2));
						};
					}

					default <C> F2<A, C, B> contraMap2(final «type2.typeName»F<C> f) {
						requireNonNull(f);
						return (final A value1, final C value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final «type2.javaName» value = f.apply(value2);
							return requireNonNull(apply(value1, value));
						};
					}
				«ELSEIF type2 == Type.OBJECT»
					default <C> F2<C, A, B> contraMap1(final «type1.typeName»F<C> f) {
						requireNonNull(f);
						return (final C value1, final A value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final «type1.javaName» value = f.apply(value1);
							return requireNonNull(apply(value, value2));
						};
					}

					default <C> «type1.typeName»ObjectObjectF2<C, B> contraMap2(final F<C, A> f) {
						requireNonNull(f);
						return (final «type1.javaName» value1, final C value2) -> {
							requireNonNull(value2);
							final A value = requireNonNull(f.apply(value2));
							return requireNonNull(apply(value1, value));
						};
					}
				«ELSE»
					default <B> Object«type2.typeName»ObjectF2<B, A> contraMap1(final «type1.typeName»F<B> f) {
						requireNonNull(f);
						return (final B value1, final «type2.javaName» value2) -> {
							requireNonNull(value1);
							final «type1.javaName» value = f.apply(value1);
							return requireNonNull(apply(value, value2));
						};
					}

					default <B> «type1.typeName»ObjectObjectF2<B, A> contraMap2(final «type2.typeName»F<B> f) {
						requireNonNull(f);
						return (final «type1.javaName» value1, final B value2) -> {
							requireNonNull(value2);
							final «type2.javaName» value = f.apply(value2);
							return requireNonNull(apply(value1, value));
						};
					}
				«ENDIF»
			«ELSE»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default <B> «returnType.typeName»F2<B, A2> contraMap1(final F<B, A1> f) {
						requireNonNull(f);
						return (final B value1, final A2 value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final A1 value = requireNonNull(f.apply(value1));
							return apply(value, value2);
						};
					}

					default <B> «returnType.typeName»F2<A1, B> contraMap2(final F<B, A2> f) {
						requireNonNull(f);
						return (final A1 value1, final B value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final A2 value = requireNonNull(f.apply(value2));
							return apply(value1, value);
						};
					}
				«ELSEIF type1 == Type.OBJECT»
					default <B> Object«type2.typeName»«returnType.typeName»F2<B> contraMap1(final F<B, A> f) {
						requireNonNull(f);
						return (final B value1, final «type2.javaName» value2) -> {
							requireNonNull(value1);
							final A value = requireNonNull(f.apply(value1));
							return apply(value, value2);
						};
					}

					default <B> «returnType.typeName»F2<A, B> contraMap2(final «type2.typeName»F<B> f) {
						requireNonNull(f);
						return (final A value1, final B value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final «type2.javaName» value = f.apply(value2);
							return apply(value1, value);
						};
					}
				«ELSEIF type2 == Type.OBJECT»
					default <B> «returnType.typeName»F2<B, A> contraMap1(final «type1.typeName»F<B> f) {
						requireNonNull(f);
						return (final B value1, final A value2) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							final «type1.javaName» value = f.apply(value1);
							return apply(value, value2);
						};
					}

					default <B> «type1.typeName»Object«returnType.typeName»F2<B> contraMap2(final F<B, A> f) {
						requireNonNull(f);
						return (final «type1.javaName» value1, final B value2) -> {
							requireNonNull(value2);
							final A value = requireNonNull(f.apply(value2));
							return apply(value1, value);
						};
					}
				«ELSE»
					default <A> Object«type2.typeName»«returnType.typeName»F2<A> contraMap1(final «type1.typeName»F<A> f) {
						requireNonNull(f);
						return (final A value1, final «type2.javaName» value2) -> {
							requireNonNull(value1);
							final «type1.javaName» value = f.apply(value1);
							return apply(value, value2);
						};
					}

					default <A> «type1.typeName»Object«returnType.typeName»F2<A> contraMap2(final «type2.typeName»F<A> f) {
						requireNonNull(f);
						return (final «type1.javaName» value1, final A value2) -> {
							requireNonNull(value2);
							final «type2.javaName» value = f.apply(value2);
							return apply(value1, value);
						};
					}
				«ENDIF»
			«ENDIF»

			«IF returnType == Type.OBJECT»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default F<A1, F<A2, B>> curry() {
						return (final A1 value1) -> {
							requireNonNull(value1);
							return (final A2 value2) -> {
								requireNonNull(value2);
								return requireNonNull(apply(value1, value2));
							};
						};
					}
				«ELSEIF type1 == Type.OBJECT»
					default F<A, «type2.typeName»ObjectF<B>> curry() {
						return (final A value1) -> {
							requireNonNull(value1);
							return (final «type2.javaName» value2) -> requireNonNull(apply(value1, value2));
						};
					}
				«ELSEIF type2 == Type.OBJECT»
					default «type1.typeName»ObjectF<F<A, B>> curry() {
						return (final «type1.javaName» value1) -> (final A value2) -> {
							requireNonNull(value2);
							return requireNonNull(apply(value1, value2));
						};
					}
				«ELSE»
					default «type1.typeName»ObjectF<«type2.typeName»ObjectF<A>> curry() {
						return (final «type1.javaName» value1) -> (final «type2.javaName» value2) ->
							requireNonNull(apply(value1, value2));
					}
				«ENDIF»
			«ELSE»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default F<A1, «returnType.typeName»F<A2>> curry() {
						return (final A1 value1) -> {
							requireNonNull(value1);
							return (final A2 value2) -> {
								requireNonNull(value2);
								return apply(value1, value2);
							};
						};
					}
				«ELSEIF type1 == Type.OBJECT»
					default F<A, «type2.typeName»«returnType.typeName»F> curry() {
						return (final A value1) -> {
							requireNonNull(value1);
							return (final «type2.javaName» value2) -> apply(value1, value2);
						};
					}
				«ELSEIF type2 == Type.OBJECT»
					default «type1.typeName»ObjectF<«returnType.typeName»F<A>> curry() {
						return (final «type1.javaName» value1) -> (final A value2) -> {
							requireNonNull(value2);
							return apply(value1, value2);
						};
					}
				«ELSE»
					default «type1.typeName»ObjectF<«type2.typeName»«returnType.typeName»F> curry() {
						return (final «type1.javaName» value1) -> (final «type2.javaName» value2) ->
							apply(value1, value2);
					}
				«ENDIF»
			«ENDIF»

			«IF returnType == Type.OBJECT»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default F2<A2, A1, B> reverse() {
						return (final A2 value2, final A1 value1) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							return requireNonNull(apply(value1, value2));
						};
					}
				«ELSEIF type1 == Type.OBJECT»
					default «type2.typeName»ObjectObjectF2<A, B> reverse() {
						return (final «type2.javaName» value2, final A value1) -> {
							requireNonNull(value1);
							return apply(value1, value2);
						};
					}
				«ELSEIF type2 == Type.OBJECT»
					default Object«type1.typeName»ObjectF2<A, B> reverse() {
						return (final A value2, final «type1.javaName» value1) -> {
							requireNonNull(value2);
							return apply(value1, value2);
						};
					}
				«ELSE»
					default «type2.typeName»«type1.typeName»«returnType.typeName»F2<A> reverse() {
						return (final «type2.javaName» value2, final «type1.javaName» value1) -> requireNonNull(apply(value1, value2));
					}
				«ENDIF»
			«ELSE»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default «returnType.typeName»F2<A2, A1> reverse() {
						return (final A2 value2, final A1 value1) -> {
							requireNonNull(value1);
							requireNonNull(value2);
							return apply(value1, value2);
						};
					}
				«ELSEIF type1 == Type.OBJECT»
					default «type2.typeName»Object«returnType.typeName»F2<A> reverse() {
						return (final «type2.javaName» value2, final A value1) -> {
							requireNonNull(value1);
							return apply(value1, value2);
						};
					}
				«ELSEIF type2 == Type.OBJECT»
					default Object«type1.typeName»«returnType.typeName»F2<A> reverse() {
						return (final A value2, «type1.javaName» value1) -> {
							requireNonNull(value2);
							return apply(value1, value2);
						};
					}
				«ELSE»
					default «type2.typeName»«type1.typeName»«returnType.typeName»F2 reverse() {
						return (final «type2.javaName» value2, final «type1.javaName» value1) -> apply(value1, value2);
					}
				«ENDIF»
			«ENDIF»

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.OBJECT»
				default BiFunction<A1, A2, B> toBiFunction() {
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return requireNonNull(apply(value1, value2));
					};
				}

				static <A> BinaryOperator<A> toBinaryOperator(final F2<A, A, A> f) {
					requireNonNull(f);
					return (final A value1, final A value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return requireNonNull(f.apply(value1, value2));
					};
				}

				static <A1, A2, B> F2<A1, A2, B> fromBiFunction(final BiFunction<A1, A2, B> f) {
					requireNonNull(f);
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return requireNonNull(f.apply(value1, value2));
					};
				}

			«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && Type.javaUnboxedTypes.contains(returnType)»
				default To«returnType.typeName»BiFunction<A1, A2> toTo«returnType.typeName»BiFunction() {
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return apply(value1, value2);
					};
				}

				static <A1, A2> «returnType.typeName»F2<A1, A2> fromTo«returnType.typeName»BiFunction(final To«returnType.typeName»BiFunction<A1, A2> f) {
					requireNonNull(f);
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return f.applyAs«returnType.typeName»(value1, value2);
					};
				}

			«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.BOOLEAN»
				default BiPredicate<A1, A2> toBiPredicate() {
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return apply(value1, value2);
					};
				}

				static <A1, A2> «returnType.typeName»F2<A1, A2> fromBiPredicate(final BiPredicate<A1, A2> p) {
					requireNonNull(p);
					return (final A1 value1, final A2 value2) -> {
						requireNonNull(value1);
						requireNonNull(value2);
						return p.test(value1, value2);
					};
				}

			«ELSEIF type1 == type2 && returnType == type2 && Type.javaUnboxedTypes.contains(returnType)»
				default «returnType.typeName»BinaryOperator to«returnType.typeName»BinaryOperator() {
					return this::apply;
				}

				static «type1.typeName»«type1.typeName»«type1.typeName»F2 from«returnType.typeName»BinaryOperator(final «returnType.typeName»BinaryOperator op) {
					return op::applyAs«returnType.typeName»;
				}

			«ENDIF»
			static «paramGenericName» «alwaysName»(final «returnTypeGenericName» value) {
				«IF returnType != Type.OBJECT && type1 != Type.OBJECT && type2 != Type.OBJECT»
					return (final «type1GenericName» value1, final «type2GenericName» value2) -> value;
				«ELSE»
					«IF returnType == Type.OBJECT»
						requireNonNull(value);
					«ENDIF»
					return (final «type1GenericName» value1, final «type2GenericName» value2) -> {
						«IF type1 == Type.OBJECT»
							requireNonNull(value1);
						«ENDIF»
						«IF type2 == Type.OBJECT»
							requireNonNull(value2);
						«ENDIF»
						return value;
					};
				«ENDIF»
			}

			«javadocSynonym(alwaysName)»
			static «paramGenericName» of(final «returnTypeGenericName» value) {
				return «alwaysName»(value);
			}

			static «paramGenericName» «shortName.firstToLowerCase»(final «genericName» f) {
				return requireNonNull(f);
			}
			«IF returnType == Type.OBJECT»

				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					«cast(#["A1", "A2", "B"], #["A1", "A2"], #["B"])»
				«ELSEIF type1 == Type.OBJECT || type2 == Type.OBJECT»
					«cast(#["A", "B"], #["A"], #["B"])»
				«ELSE»
					«cast(#["A"], #[], #["A"])»
				«ENDIF»
			«ELSE»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»

					«cast(#["A1", "A2"], #["A1", "A2"], #[])»
				«ELSEIF type1 == Type.OBJECT || type2 == Type.OBJECT»

					«cast(#["A"], #["A"], #[])»
				«ENDIF»
			«ENDIF»
		}
	''' }
}