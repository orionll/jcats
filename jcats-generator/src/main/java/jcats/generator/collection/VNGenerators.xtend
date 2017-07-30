package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type

final class VNGenerators {
	def static List<Generator> generators() {
		(2 .. Constants.MAX_ARITY).map[int arity | Type.values.map[generator(arity, it)]].flatten.toList;
	}

	private def static Generator generator(int arity, Type type) {
		new ClassGenerator {
			override className() { Constants.COLLECTION + "." + shortName }

			def baseName() { "V" + arity }
			def shortName() { type.shortName(baseName) }
			def genericName() { type.genericName(baseName) }
			def diamondName() { type.diamondName(baseName) }
			def factoryMethodName() { if (type == Type.OBJECT) "v" + arity else type.typeName.toLowerCase + "V" + arity }

			override sourceCode() { '''
				package «Constants.COLLECTION»;

				import java.io.Serializable;
				import java.util.ArrayList;
				«IF Type.javaUnboxedTypes.contains(type)»
					import java.util.PrimitiveIterator;
				«ELSE»
					import java.util.Iterator;
				«ENDIF»
				import java.util.HashSet;
				import java.util.NoSuchElementException;
				import java.util.Spliterator;
				import java.util.Spliterators;

				import «Constants.JCATS».*;
				import «Constants.FUNCTION».*;

				import static java.util.Objects.requireNonNull;
				«IF type == Type.OBJECT»
					import static «Constants.P».p;
				«ELSE»
					import static «Constants.COLLECTION».V«arity».v«arity»;
				«ENDIF»
				import static «Constants.JCATS».Int«type.typeName»P.*;
				«IF type != Type.OBJECT && type != Type.INT»
					import static «Constants.JCATS».«type.typeName»«type.typeName»P.*;
				«ENDIF»
				«IF arity > 2»
					import static «Constants.P»«arity».p«arity»;
				«ENDIF»
				import static «Constants.COMMON».*;

				public final class «genericName» implements «type.indexedContainerGenericName», Serializable {
					final «type.genericName» «(1 .. arity).map["a" + it].join(", ")»;

					«shortName»(«(1 .. arity).map['''final «type.genericName» a«it»'''].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
					}

					@Override
					@Deprecated
					public int size() {
						return «arity»;
					}

					@Override
					@Deprecated
					public boolean isEmpty() {
						return false;
					}

					@Override
					@Deprecated
					public boolean isNotEmpty() {
						return true;
					}

					«FOR i : 1 .. arity»
						public «type.genericName» get«i»() {
							return a«i»;
						}

					«ENDFOR»
					@Override
					public «type.genericName» get(final int index) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: return a«i»;
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«FOR i : 1 .. arity»
						public «genericName» set«i»(final «type.genericName» a«i») {
							return new «diamondName»(«(1 .. arity).map[if (type == Type.OBJECT && it == i) '''requireNonNull(a«i»)''' else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public «genericName» set(final int index, final «type.genericName» value) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: return new «diamondName»(«(1 .. arity).map[if (it == i) '''«IF type == Type.OBJECT»requireNonNull(value)«ELSE»value«ENDIF»''' else "a" + it].join(", ")»);
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«FOR i : 1 .. arity»
						public «genericName» update«i»(final «type.updateFunction» f) {
							final «type.genericName» a = f.apply(a«i»);
							return new «diamondName»(«(1 .. arity).map[if (it == i) '''«IF type == Type.OBJECT»requireNonNull(a)«ELSE»a«ENDIF»''' else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public «genericName» update(final int index, final «type.updateFunction» f) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: {
									final «type.genericName» a = f.apply(a«i»);
									return new «diamondName»(«(1 .. arity).map[if (it == i) '''«IF type == Type.OBJECT»requireNonNull(a)«ELSE»a«ENDIF»''' else "a" + it].join(", ")»);
								}
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«IF type == Type.OBJECT»
						public <B> B match(final F«arity»<«(1 .. arity).map["A, "].join»B> f) {
							final B b = f.apply(«(1 .. arity).map["a" + it].join(", ")»);
							return requireNonNull(b);
						}

						public <B> V«arity»<B> map(final F<A, B> f) {
							return v«arity»(«(1 .. arity).map["f.apply(a" + it + ")"].join(", ")»);
						}
					«ELSE»
						public <A> V«arity»<A> map(final «type.typeName»ObjectF<A> f) {
							return v«arity»(«(1 .. arity).map["f.apply(a" + it + ")"].join(", ")»);
						}
					«ENDIF»

					public «genericName» reverse() {
						return new «diamondName»(«(arity .. 1).map["a" + it].join(", ")»);
					}

					@Override
					public boolean contains(final «type.genericName» value) {
						«FOR i : 1 .. arity»
							«IF type == Type.OBJECT»
								if (value.equals(a«i»)) {
							«ELSE»
								if (value == a«i») {
							«ENDIF»
								return true;
							}
						«ENDFOR»
						return false;
					}

					«IF arity == 2»
						«IF type == Type.OBJECT»
							public P<A, A> toP() {
								return p(a1, a2);
							}
						«ELSE»
							public «type.typeName»«type.typeName»P to«type.typeName»«type.typeName»P() {
								return «type.typeName.toLowerCase»«type.typeName»P(a1, a2);
							}
						«ENDIF»
					«ELSE»
						public P«arity»<«(1 .. arity).map[type.genericBoxedName].join(", ")»> toP«arity»() {
							return p«arity»(«(1 .. arity).map["a" + it].join(", ")»);
						}
					«ENDIF»

					@Override
					public ArrayList<«type.genericBoxedName»> toArrayList() {
						final ArrayList<«type.genericBoxedName»> result = new ArrayList<>(«arity»);
						«FOR index : 1 .. arity»
							result.add(a«index»);
						«ENDFOR»
						return result;
					}

					@Override
					public HashSet<«type.genericBoxedName»> toHashSet() {
						final HashSet<«type.genericBoxedName»> result = new HashSet<>(«Math.ceil(arity / 0.75) as int»);
						«FOR index : 1 .. arity»
							result.add(a«index»);
						«ENDFOR»
						return result;
					}

					@Override
					public «type.seqGenericName» to«type.seqShortName»() {
						final «type.javaName»[] node1 = { «(1 .. arity).map["a" + it].join(", ")» };
						return new «type.diamondName("Seq1")»(node1);
					}

					@Override
					public «type.javaName»[] «type.toArrayName»() {
						return new «type.javaName»[] { «(1 .. arity).map["a" + it].join(", ")» };
					}

					«IF type == Type.OBJECT»
						@Override
						public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
							final A[] array = supplier.apply(«arity»);
							«FOR index : 1 .. arity»
								array[«index - 1»] = a«index»;
							«ENDFOR»
							return array;
						}

					«ENDIF»
					@Override
					public void foreach(final «type.effGenericName» eff) {
						«FOR index : 1 .. arity»
							eff.apply(a«index»);
						«ENDFOR»
					}

					@Override
					«IF type == Type.OBJECT»
						public void foreachWithIndex(final IntObjectEff2<A> eff) {
					«ELSE»
						public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
					«ENDIF»
						«FOR index : 1 .. arity»
							eff.apply(«index-1», a«index»);
						«ENDFOR»
					}

					@Override
					public void foreachUntil(final «type.boolFName» eff) {
						«FOR index : 1 .. arity-1»
							if (!eff.apply(a«index»)) {
								return;
							}
						«ENDFOR»
						eff.apply(a«arity»);
					}

					@Override
					public int hashCode() {
						int result = 1;
						«FOR index : 1 .. arity»
							«IF type == Type.OBJECT»
								result = 31 * result + a«index».hashCode();
							«ELSE»
								result = 31 * result + «type.genericBoxedName».hashCode(a«index»);
							«ENDIF»
						«ENDFOR»
						return result;
					}

					«equals(type, type.indexedContainerWildcardName, false)»

					public boolean isStrictlyEqualTo(final «genericName» other) {
						if (other == this) {
							return true;
						} else {
							return «IF type == Type.OBJECT»a1.equals(other.a1)«ELSE»a1 == other.a1«ENDIF»
								«FOR index : 2 .. arity»
									&& «IF type == Type.OBJECT»a«index».equals(other.a«index»)«ELSE»a«index» == other.a«index»«ENDIF»«IF index == arity»;«ENDIF»
								«ENDFOR»
						}
					}

					@Override
					public «type.iteratorGenericName» iterator() {
						return new «type.diamondName("V" + arity + "Iterator")»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					@Override
					public «type.iteratorGenericName» reverseIterator() {
						return new «type.diamondName("V" + arity + "ReverseIterator")»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					@Override
					public «type.spliteratorGenericName» spliterator() {
						return Spliterators.spliterator(iterator(), «arity», Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
					}

					«IF type == Type.OBJECT»
						public <B> V«arity»<P<A, B>> zip(final V«arity»<B> that) {
							return zipWith(that, P::p);
						}

						public <B, C> V«arity»<C> zipWith(final V«arity»<B> that, final F2<A, B, C> f) {
							requireNonNull(f);
							return new V«arity»<>(«(1 .. arity).map['''f.apply(a«it», that.a«it»)'''].join(", ")»);
						}

						public V«arity»<IntObjectP<A>> zipWithIndex() {
							return new V«arity»<>(«(1 .. arity).map['''intObjectP(«it-1», a«it»)'''].join(", ")»);
						}
					«ELSE»
						public <A> V«arity»<«type.typeName»ObjectP<A>> zip(final V«arity»<A> that) {
							return zipWith(that, «type.typeName»ObjectP::«type.typeName.firstToLowerCase»ObjectP);
						}

						public <A, B> V«arity»<B> zipWith(final V«arity»<A> that, final «type.typeName»ObjectObjectF2<A, B> f) {
							requireNonNull(f);
							return new V«arity»<>(«(1 .. arity).map['''f.apply(a«it», that.a«it»)'''].join(", ")»);
						}

						public final V«arity»<Int«type.typeName»P> zipWithIndex() {
							return new V«arity»<>(«(1 .. arity).map['''int«type.typeName»P(«it-1», a«it»)'''].join(", ")»);
						}
					«ENDIF»

					@Override
					public String toString() {
						return "«shortName»(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";
					}

					public static «type.paramGenericName(baseName)» «factoryMethodName»(«(1 .. arity).map['''final «type.genericName» a«it»'''].join(", ")») {
						«IF type == Type.OBJECT»
							«FOR i : 1 .. arity»
								requireNonNull(a«i»);
							«ENDFOR»
						«ENDIF»
						return new «diamondName»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					«javadocSynonym(factoryMethodName)»
					public static «type.paramGenericName(baseName)» of(«(1 .. arity).map['''final «type.genericName» a«it»'''].join(", ")») {
						return «factoryMethodName»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					«IF arity == 2»
						«IF type == Type.OBJECT»
							public static <A> «genericName» fromP(final P<A, A> p) {
						«ELSE»
							public static «shortName» from«type.typeName»«type.typeName»P(final «type.typeName»«type.typeName»P p) {
						«ENDIF»
							return new «diamondName»(p.get1(), p.get2());
						}
					«ELSE»
						public static «type.paramGenericName(baseName)» fromP«arity»(final P«arity»<«(1 .. arity).map[type.genericBoxedName].join(", ")»> p«arity») {
							return new «diamondName»(«(1 .. arity).map["p" + arity + ".get" + it + "()"].join(", ")»);
						}
					«ENDIF»
					«IF type == Type.OBJECT»

						«cast(#["A"], #[], #["A"])»
					«ENDIF»
				}

				final class «type.genericName("V" + arity + "Iterator")» implements «type.iteratorGenericName» {
					private final «type.genericName» «(1 .. arity).map["a" + it].join(", ")»;
					private int i;

					«type.shortName("V" + arity + "Iterator")»(«(1 .. arity).map['''final «type.genericName» a«it»'''].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
					}

					@Override
					public boolean hasNext() {
						return (i < «arity»);
					}

					@Override
					public «type.iteratorReturnType» «type.iteratorNext»() {
						switch (i) {
							«FOR i : 1 .. arity»
								case «i-1»: i++; return a«i»;
							«ENDFOR»
							default: throw new NoSuchElementException();
						}
					}
				}

				final class «type.genericName("V" + arity + "ReverseIterator")» implements «type.iteratorGenericName» {
					private final «type.genericName» «(1 .. arity).map["a" + it].join(", ")»;
					private int i;

					«type.shortName("V" + arity + "ReverseIterator")»(«(1 .. arity).map['''final «type.genericName» a«it»'''].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
						i = «arity-1»;
					}

					@Override
					public boolean hasNext() {
						return (i >= 0);
					}

					@Override
					public «type.iteratorReturnType» «type.iteratorNext»() {
						switch (i) {
							«FOR i : arity .. 1»
								case «i-1»: i--; return a«i»;
							«ENDFOR»
							default: throw new NoSuchElementException();
						}
					}
				}
			''' }
		}
	}
}