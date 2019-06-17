package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension com.google.common.collect.Iterables.concat

@FinalFieldsConstructor
class PGenerator implements ClassGenerator {
	val Type type1
	val Type type2

	def static List<Generator> generators() {
		Type.values.toList.map[type1 |
			Type.values.toList.map[type2 | new PGenerator(type1, type2) as Generator]]
			.concat.toList
	}

	override className() { Constants.JCATS + "." + shortName }

	def String shortName() { '''«IF type1 != Type.OBJECT || type2 != Type.OBJECT»«type1.typeName»«type2.typeName»«ENDIF»P''' }

	def genericName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"P<A1, A2>"
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			shortName + "<A>"
		} else {
			shortName
		}
	}

	def covariantName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"P<@Covariant A1, @Covariant A2>"
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			shortName + "<@Covariant A>"
		} else {
			shortName
		}
	}

	def paramGenericName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			'''<A1, A2> «genericName»'''
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			'''<A> «genericName»'''
		} else {
			shortName
		}
	}

	def diamondName() {
		if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			'''«shortName»<>'''
		} else {
			shortName
		}
	}

	def wildcardName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			'''«shortName»<?, ?>'''
		} else if (type1 == Type.OBJECT || type2 == Type.OBJECT) {
			'''«shortName»<?>'''
		} else {
			shortName
		}
	}

	def type1Name() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"A1"
		} else if (type1 == Type.OBJECT) {
			"A"
		} else {
			type1.javaName
		}
	}

	def type2Name() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"A2"
		} else if (type2 == Type.OBJECT) {
			"A"
		} else {
			type2.javaName
		}
	}

	def type1BoxedName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"A1"
		} else if (type1 == Type.OBJECT) {
			"A"
		} else {
			type1.genericBoxedName
		}
	}

	def type2BoxedName() {
		if (type1 == Type.OBJECT && type2 == Type.OBJECT) {
			"A2"
		} else if (type2 == Type.OBJECT) {
			"A"
		} else {
			type2.genericBoxedName
		}
	}

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Map.Entry;
		import java.util.AbstractMap.SimpleImmutableEntry;

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF type1 != Type.OBJECT || type2 != Type.OBJECT»
			import static «Constants.P».p;
		«ENDIF»

		public final class «covariantName» implements Equatable<«genericName»>, Serializable {
			private final «type1Name» a1;
			private final «type2Name» a2;

			«shortName»(final «type1Name» a1, final «type2Name» a2) {
				this.a1 = a1;
				this.a2 = a2;
			}

			public «type1Name» get1() {
				return this.a1;
			}

			public «type2Name» get2() {
				return this.a2;
			}

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public <B> P<B, A2> set1(final B value) {
			«ELSEIF type2 == Type.OBJECT»
				public <B> P<B, A> set1(final B value) {
			«ELSE»
				public <B> Object«type2.typeName»P<B> set1(final B value) {
			«ENDIF»
				«IF type2 == Type.OBJECT»
					return new P<>(requireNonNull(value), this.a2);
				«ELSE»
					return new Object«type2.typeName»P<>(requireNonNull(value), this.a2);
				«ENDIF»
			}

			«FOR to : Type.primitives»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					public «to.typeName»ObjectP<A2> set1To«to.typeName»(final «to.genericName» value) {
				«ELSEIF type2 == Type.OBJECT»
					public «to.typeName»ObjectP<A> set1To«to.typeName»(final «to.genericName» value) {
				«ELSE»
					public «to.typeName»«type2.typeName»P set1To«to.typeName»(final «to.genericName» value) {
				«ENDIF»
					return new «to.typeName»«type2.typeName»P«IF type2 == Type.OBJECT»<>«ENDIF»(value, this.a2);
				}

			«ENDFOR»
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public <B> P<A1, B> set2(final B value) {
			«ELSEIF type1 == Type.OBJECT»
				public <B> P<A, B> set2(final B value) {
			«ELSE»
				public <B> «type1.typeName»ObjectP<B> set2(final B value) {
			«ENDIF»
				«IF type1 == Type.OBJECT»
					return new P<>(this.a1, requireNonNull(value));
				«ELSE»
					return new «type1.typeName»ObjectP<>(this.a1, requireNonNull(value));
				«ENDIF»
			}

			«FOR to : Type.primitives»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					public Object«to.typeName»P<A1> set2To«to.typeName»(final «to.genericName» value) {
				«ELSEIF type1 == Type.OBJECT»
					public Object«to.typeName»P<A> set2To«to.typeName»(final «to.genericName» value) {
				«ELSE»
					public «type1.typeName»«to.typeName»P set2To«to.typeName»(final «to.genericName» value) {
				«ENDIF»
					return new «type1.typeName»«to.typeName»P«IF type1 == Type.OBJECT»<>«ENDIF»(this.a1, value);
				}

			«ENDFOR»
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public <B> B match(final F2<A1, A2, B>  f) {
					final B b = f.apply(this.a1, this.a2);
					return requireNonNull(b);
				}
			«ELSEIF type1 == Type.OBJECT && type2 != Type.OBJECT»
				public <B> B match(final Object«type2.typeName»ObjectF2<A, B>  f) {
					final B b = f.apply(this.a1, this.a2);
					return requireNonNull(b);
				}
			«ELSEIF type1 != Type.OBJECT && type2 == Type.OBJECT»
				public <B> B match(final «type1.typeName»ObjectObjectF2<A, B>  f) {
					final B b = f.apply(this.a1, this.a2);
					return requireNonNull(b);
				}
			«ELSE»
				public <A> A match(final «type1.typeName»«type2.typeName»ObjectF2<A>  f) {
					final A a = f.apply(this.a1, this.a2);
					return requireNonNull(a);
				}
			«ENDIF»
			«FOR to : Type.primitives»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					public «to.genericName» matchTo«to.typeName»(final «to.typeName»F2<A1, A2>  f) {
				«ELSEIF type1 == Type.OBJECT && type2 != Type.OBJECT»
					public «to.genericName» matchTo«to.typeName»(final Object«type2.typeName»«to.typeName»F2<A>  f) {
				«ELSEIF type1 != Type.OBJECT && type2 == Type.OBJECT»
					public «to.genericName» matchTo«to.typeName»(final «type1.typeName»Object«to.typeName»F2<A>  f) {
				«ELSE»
					public «to.genericName» matchTo«to.typeName»(final «type1.typeName»«type2.typeName»«to.typeName»F2  f) {
				«ENDIF»
					return f.apply(this.a1, this.a2);
				}

			«ENDFOR»
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public <B> P<B, A2> map1(final F<A1, B> f) {
			«ELSEIF type2 == Type.OBJECT»
				public <B> P<B, A> map1(final «type1.typeName»ObjectF<B> f) {
			«ELSEIF type1 == Type.OBJECT»
				public <B> Object«type2.typeName»P<B> map1(final F<A, B> f) {
			«ELSE»
				public <B> Object«type2.typeName»P<B> map1(final «type1.typeName»ObjectF<B> f) {
			«ENDIF»
				final B value = f.apply(this.a1);
				«IF type2 == Type.OBJECT»
					return new P<>(requireNonNull(value), this.a2);
				«ELSE»
					return new Object«type2.typeName»P<>(requireNonNull(value), this.a2);
				«ENDIF»
			}

			«FOR to : Type.primitives»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					public «to.typeName»ObjectP<A2> map1To«to.typeName»(final «to.typeName»F<A1> f) {
				«ELSEIF type2 == Type.OBJECT»
					public «to.typeName»ObjectP<A> map1To«to.typeName»(final «type1.typeName»«to.typeName»F f) {
				«ELSEIF type1 == Type.OBJECT»
					public «to.typeName»«type2.typeName»P map1To«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «to.typeName»«type2.typeName»P map1To«to.typeName»(final «type1.typeName»«to.typeName»F f) {
				«ENDIF»
					final «to.genericName» value = f.apply(this.a1);
					return new «to.typeName»«type2.typeName»P«IF type2 == Type.OBJECT»<>«ENDIF»(value, this.a2);
				}

			«ENDFOR»
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public <B> P<A1, B> map2(final F<A2, B> f) {
			«ELSEIF type1 == Type.OBJECT»
				public <B> P<A, B> map2(final «type2.typeName»ObjectF<B> f) {
			«ELSEIF type2 == Type.OBJECT»
				public <B> «type1.typeName»ObjectP<B> map2(final F<A, B> f) {
			«ELSE»
				public <B> «type1.typeName»ObjectP<B> map2(final «type2.typeName»ObjectF<B> f) {
			«ENDIF»
				final B value = f.apply(this.a2);
				«IF type1 == Type.OBJECT»
					return new P<>(this.a1, requireNonNull(value));
				«ELSE»
					return new «type1.typeName»ObjectP<>(this.a1, requireNonNull(value));
				«ENDIF»
			}

			«FOR to : Type.primitives»
				«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
					public Object«to.typeName»P<A1> map2To«to.typeName»(final «to.typeName»F<A2> f) {
				«ELSEIF type1 == Type.OBJECT»
					public Object«to.typeName»P<A> map2To«to.typeName»(final «type2.typeName»«to.typeName»F f) {
				«ELSEIF type2 == Type.OBJECT»
					public «type1.typeName»«to.typeName»P map2To«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type1.typeName»«to.typeName»P map2To«to.typeName»(final «type2.typeName»«to.typeName»F f) {
				«ENDIF»
					final «to.genericName» value = f.apply(this.a2);
					return new «type1.typeName»«to.typeName»P«IF type1 == Type.OBJECT»<>«ENDIF»(this.a1, value);
				}

			«ENDFOR»
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public P<A2, A1> reverse() {
					return new P<>(this.a2, this.a1);
			«ELSEIF type1 == Type.OBJECT || type2 == Type.OBJECT»
				public «type2.typeName»«type1.typeName»P<A> reverse() {
					return new «type2.typeName»«type1.typeName»P<>(this.a2, this.a1);
			«ELSE»
				public «type2.typeName»«type1.typeName»P reverse() {
					return new «type2.typeName»«type1.typeName»P(this.a2, this.a1);
			«ENDIF»
			}

			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»
				public <B1, B2> P<B1, B2> biMap(final F<A1, B1> f1, final F<A2, B2> f2) {
			«ELSEIF type1 == Type.OBJECT»
				public <B1, B2> P<B1, B2> biMap(final F<A, B1> f1, final «type2.typeName»ObjectF<B2> f2) {
			«ELSEIF type2 == Type.OBJECT»
				public <B1, B2> P<B1, B2> biMap(final «type1.typeName»ObjectF<B1> f1, final F<A, B2> f2) {
			«ELSE»
				public <B1, B2> P<B1, B2> biMap(final «type1.typeName»ObjectF<B1> f1, final «type2.typeName»ObjectF<B2> f2) {
			«ENDIF»
				return p(f1.apply(this.a1), f2.apply(this.a2));
			}

			public Entry<«type1BoxedName», «type2BoxedName»> toEntry() {
				return new SimpleImmutableEntry<>(this.a1, this.a2);
			}

			@Override
			public int hashCode() {
				final int hashCode1 = «IF type1 == Type.OBJECT»this.a1.hashCode()«ELSE»«type1.boxedName».hashCode(this.a1)«ENDIF»;
				final int hashCode2 = «IF type2 == Type.OBJECT»this.a2.hashCode()«ELSE»«type2.boxedName».hashCode(this.a2)«ENDIF»;
				return hashCode1 ^ hashCode2;
			}

			/**
			 * «equalsDeprecatedJavaDoc»
			 */
			@Override
			@Deprecated
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «wildcardName») {
					final «wildcardName» p = («wildcardName») obj;
					«IF type1 == Type.OBJECT»
						return this.a1.equals(p.a1)
					«ELSE»
						return (this.a1 == p.a1)
					«ENDIF»
						«IF type2 == Type.OBJECT»
							&& this.a2.equals(p.a2);
						«ELSE»
							&& (this.a2 == p.a2);
						«ENDIF»
				} else {
					return false;
				}
			}

			@Override
			public String toString() {
				return "(" + this.a1 + ", " + this.a2 + ")";
			}

			«transform(genericName)»

			public static «paramGenericName» «shortName.firstToLowerCase»(final «type1Name» a1, final «type2Name» a2) {
				«IF type1 == Type.OBJECT»
					requireNonNull(a1);
				«ENDIF»
				«IF type2 == Type.OBJECT»
					requireNonNull(a2);
				«ENDIF»
				return new «diamondName»(a1, a2);
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			public static «paramGenericName» of(final «type1Name» a1, final «type2Name» a2) {
				return «shortName.firstToLowerCase»(a1, a2);
			}

			public static «paramGenericName» fromEntry(final Entry<«type1BoxedName», «type2BoxedName»> entry) {
				return «shortName.firstToLowerCase»(entry.getKey(), entry.getValue());
			}
			«IF type1 == Type.OBJECT && type2 == Type.OBJECT»

				«cast(#["A1", "A2"], #[], #["A1", "A2"])»
			«ELSEIF type1 == Type.OBJECT || type2 == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}