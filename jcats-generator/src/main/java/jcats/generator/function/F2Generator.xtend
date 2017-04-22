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

	def genericName() {
		shortName +
		if (returnType == Type.OBJECT) {
			if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
				"<A1, A2, B>"
			} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				"<A, B>"
			} else {
				"<A>"
			}
		} else {
			if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
				"<A1, A2>"
			} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
				"<A>"
			} else {
				""
			}
		}
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

	override sourceCode() { '''
		package «Constants.FUNCTION»;
		
		«IF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.OBJECT»
			import java.util.function.BiFunction;
			import java.util.function.BinaryOperator;
		«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && Type.javaUnboxedTypes.contains(returnType)»
			import java.util.function.To«returnType.javaPrefix»BiFunction;
		«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.BOOL»
			import java.util.function.BiPredicate;
		«ELSEIF type1 == type2 && returnType == type2 && Type.javaUnboxedTypes.contains(returnType)»
			import java.util.function.«returnType.javaPrefix»BinaryOperator;
		«ENDIF»

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface «genericName» {

			«returnTypeGenericName» apply(final «type1GenericName» value1, final «type2GenericName» value2);

			default «mapReturnType» map(final «mapFunction» f) {
				requireNonNull(f);
				return (final «type1GenericName» a1, final «type2GenericName» a2) -> {
					«IF type1 == Type.OBJECT»
						requireNonNull(a1);
					«ENDIF»
					«IF type2 == Type.OBJECT»
						requireNonNull(a2);
					«ENDIF»
					«IF returnType == Type.OBJECT»
						final «returnTypeGenericName» value = requireNonNull(apply(a1, a2));
					«ELSE»
						final «returnTypeGenericName» value = apply(a1, a2);
					«ENDIF»
					return requireNonNull(f.apply(value));
				};
			}

			«IF returnType == Type.OBJECT»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default F2<A2, A1, B> reverse() {
						return (final A2 a2, final A1 a1) -> {
							requireNonNull(a1);
							requireNonNull(a2);
							return requireNonNull(apply(a1, a2));
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
						return (final «type2.javaName» a2, final «type1.javaName» a1) -> requireNonNull(apply(a1, a2));
					}
				«ENDIF»
			«ELSE»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					default «returnType.typeName»F2<A2, A1> reverse() {
						return (final A2 a2, final A1 a1) -> {
							requireNonNull(a1);
							requireNonNull(a2);
							return apply(a1, a2);
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
						return (final «type2.javaName» a2, final «type1.javaName» a1) -> apply(a1, a2);
					}
				«ENDIF»
			«ENDIF»

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.OBJECT»
				default BiFunction<A1, A2, B> toBiFunction() {
					return (final A1 a1, final A2 a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return requireNonNull(apply(a1, a2));
					};
				}

				static <A> BinaryOperator<A> toBinaryOperator(final F2<A, A, A> f) {
					requireNonNull(f);
					return (final A a1, final A a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return requireNonNull(f.apply(a1, a2));
					};
				}

				static <A1, A2, B> F2<A1, A2, B> fromBiFunction(final BiFunction<A1, A2, B> f) {
					requireNonNull(f);
					return (final A1 a1, final A2 a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return requireNonNull(f.apply(a1, a2));
					};
				}

			«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && Type.javaUnboxedTypes.contains(returnType)»
				default To«returnType.javaPrefix»BiFunction<A1, A2> toTo«returnType.javaPrefix»BiFunction() {
					return (final A1 a1, final A2 a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return apply(a1, a2);
					};
				}

				static <A1, A2> «returnType.typeName»F2<A1, A2> fromTo«returnType.javaPrefix»BiFunction(final To«returnType.javaPrefix»BiFunction<A1, A2> f) {
					requireNonNull(f);
					return (final A1 a1, final A2 a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return f.applyAs«returnType.javaPrefix»(a1, a2);
					};
				}
			«ELSEIF type1 == Type.OBJECT && type2 == Type.OBJECT && returnType == Type.BOOL»
				default BiPredicate<A1, A2> toBiPredicate() {
					return (final A1 a1, final A2 a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return apply(a1, a2);
					};
				}

				static <A1, A2> «returnType.typeName»F2<A1, A2> fromBiPredicate(final BiPredicate<A1, A2> p) {
					requireNonNull(p);
					return (final A1 a1, final A2 a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						return p.test(a1, a2);
					};
				}

			«ELSEIF type1 == type2 && returnType == type2 && Type.javaUnboxedTypes.contains(returnType)»
				default «returnType.javaPrefix»BinaryOperator to«returnType.javaPrefix»BinaryOperator() {
					return this::apply;
				}

				static «type1.typeName»«type1.typeName»«type1.typeName»F2 from«returnType.javaPrefix»BinaryOperator(final «returnType.javaPrefix»BinaryOperator op) {
					return op::applyAs«returnType.javaPrefix»;
				}
			«ENDIF»
		}
	''' }
}