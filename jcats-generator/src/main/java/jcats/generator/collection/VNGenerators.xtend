package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.PNGenerators

final class VNGenerators {
	def static List<Generator> generators() {
		(2 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	private def static Generator generator(int arity) {
		new ClassGenerator {
			override className() { Constants.V + arity }

			override sourceCode() { '''
				package «Constants.COLLECTION»;

				import java.io.Serializable;
				import java.util.ArrayList;
				import java.util.Iterator;
				import java.util.HashSet;
				import java.util.NoSuchElementException;
				import java.util.Spliterator;
				import java.util.Spliterators;

				import «Constants.JCATS».*;
				import «Constants.FUNCTION».*;

				import static java.util.Objects.requireNonNull;
				import static «Constants.P».p;
				«IF arity > 2»
					import static «Constants.P»«arity».p«arity»;
				«ENDIF»

				public final class V«arity»<A> implements Container<A>, Equatable<V«arity»<A>>, Indexed<A>, Serializable {
					private final A «(1 .. arity).map["a" + it].join(", ")»;

					private V«arity»(«(1 .. arity).map["final A a" + it].join(", ")») {
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
						public A get«i»() {
							return a«i»;
						}

					«ENDFOR»
					@Override
					public A get(final int index) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: return a«i»;
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«FOR i : 1 .. arity»
						public V«arity»<A> set«i»(final A a«i») {
							return new V«arity»<>(«(1 .. arity).map[if (it == i) '''requireNonNull(a«i»)''' else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public V«arity»<A> set(final int index, final A value) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: return new V«arity»<>(«(1 .. arity).map[if (it == i) '''requireNonNull(value)''' else "a" + it].join(", ")»);
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«FOR i : 1 .. arity»
						public V«arity»<A> update«i»(final F<A, A> f) {
							final A a = f.apply(a«i»);
							return new V«arity»<>(«(1 .. arity).map[if (it == i) "requireNonNull(a)" else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public V«arity»<A> update(final int index, final F<A, A> f) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: {
									final A a = f.apply(a«i»);
									return new V«arity»<>(«(1 .. arity).map[if (it == i) "requireNonNull(a)" else "a" + it].join(", ")»);
								}
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					public <B> B match(final F«arity»<«(1 .. arity).map["A, "].join»B> f) {
						final B b = f.apply(«(1 .. arity).map["a" + it].join(", ")»);
						return requireNonNull(b);
					}

					public <B> V«arity»<B> map(final F<A, B> f) {
						return v«arity»(«(1 .. arity).map["f.apply(a" + it + ")"].join(", ")»);
					}

					public V«arity»<A> reverse() {
						return new V«arity»<>(«(arity .. 1).map["a" + it].join(", ")»);
					}

					@Override
					public boolean contains(final A value) {
						requireNonNull(value);
						«FOR i : 1 .. arity»
							if (a«i».equals(value)) {
								return true;
							}
						«ENDFOR»
						return false;
					}

					public «PNGenerators.shortName(arity)»<«(1 .. arity).map["A"].join(", ")»> toP«if (arity == 2) "" else arity»() {
						return «PNGenerators.shortName(arity).toLowerCase»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					@Override
					public ArrayList<A> toArrayList() {
						final ArrayList<A> result = new ArrayList<>(«arity»);
						«FOR index : 1 .. arity»
							result.add(a«index»);
						«ENDFOR»
						return result;
					}

					@Override
					public HashSet<A> toHashSet() {
						final HashSet<A> result = new HashSet<>(«Math.ceil(arity / 0.75) as int»);
						«FOR index : 1 .. arity»
							result.add(a«index»);
						«ENDFOR»
						return result;
					}

					@Override
					public Seq<A> toSeq() {
						final Object[] node1 = { «(1 .. arity).map["a" + it].join(", ")» };
						return new Seq1<>(node1);
					}

					@Override
					public Object[] toObjectArray() {
						return new Object[] { «(1 .. arity).map["a" + it].join(", ")» };
					}

					@Override
					public int hashCode() {
						int result = 1;
						«FOR index : 1 .. arity»
							result = 31 * result + a«index».hashCode();
						«ENDFOR»
						return result;
					}

					@Override
					public boolean equals(final Object obj) {
						if (obj == this) {
							return true;
						} else if (obj instanceof V«arity»<?>) {
							final V«arity»<?> v«arity» = (V«arity»<?>) obj;
							return a1.equals(v«arity».a1)
								«FOR index : 2 .. arity»
									&& a«index».equals(v«arity».a«index»)«IF index == arity»;«ENDIF»
								«ENDFOR»
						} else {
							return false;
						}
					}

					@Override
					public Iterator<A> iterator() {
						return new V«arity»Iterator<>(«(1 .. arity).map["a" + it].join(", ")»);
					}

					@Override
					public Spliterator<A> spliterator() {
						return Spliterators.spliterator(iterator(), «arity», Spliterator.ORDERED | Spliterator.IMMUTABLE);
					}

					«zip(false)»

					«zipWith(false)»

					public V«arity»<P<A, Integer>> zipWithIndex() {
						return new V«arity»<>(«(1 .. arity).map["p(a" + it + ", " + (it-1) + ")"].join(", ")»);
					}

					@Override
					public String toString() {
						return "V«arity»(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";
					}

					public static <A> V«arity»<A> v«arity»(«(1 .. arity).map["final A a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							requireNonNull(a«i»);
						«ENDFOR»
						return new V«arity»<>(«(1 .. arity).map["a" + it].join(", ")»);
					}

					/**
					 * Synonym for {@link #v«arity»}
					 */
					public static <A> V«arity»<A> of(«(1 .. arity).map["final A a" + it].join(", ")») {
						return v«arity»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					public static <A> V«arity»<A> fromP«if (arity == 2) "" else arity»(final «PNGenerators.shortName(arity)»<«(1 .. arity).map["A"].join(", ")»> p«arity») {
						return new V«arity»<>(«(1 .. arity).map["p" + arity + ".get" + it + "()"].join(", ")»);
					}

					«zipN(false)»
					«zipWithN(false)[i | '''
						«FOR j : 1 .. arity»
							final B b«j» = requireNonNull(f.apply(«(1 .. i).map['''v«it».a«j»'''].join(", ")»));
						«ENDFOR»
						return new V«arity»<>(«(1 .. arity).map["b" + it].join(", ")»);
					''']»
					«cast(#["A"], #[], #["A"])»
				}

				final class V«arity»Iterator<A> implements Iterator<A> {
					private final A «(1 .. arity).map["a" + it].join(", ")»;
					private int i;

					V«arity»Iterator(«(1 .. arity).map["final A a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
					}

					@Override
					public boolean hasNext() {
						return (i < «arity»);
					}

					@Override
					public A next() {
						switch (i) {
							«FOR i : 1 .. arity»
								case «i-1»: i++; return a«i»;
							«ENDFOR»
							default: throw new NoSuchElementException();
						}
					}
				}
			''' }
		}
	}
}