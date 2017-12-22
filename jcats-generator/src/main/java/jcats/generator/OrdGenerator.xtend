package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OrdGenerator implements ClassGenerator {
	val Type type
		
	override className() { Constants.JCATS + "." + shortName }

	def shortName() { type.ordShortName }
	def genericName() { type.ordGenericName }

	def static List<Generator> generators() {
		Type.values.toList.map[new OrdGenerator(it) as Generator]
	}

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Comparator;

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface «type.contravariantName("Ord")» {

			Order compare(final «type.genericName» x, final «type.genericName» y);

			default boolean less(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return compare(x, y).equals(Order.LT);
			}

			default boolean greater(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return compare(x, y).equals(Order.GT);
			}

			default boolean eq(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return compare(x, y).equals(Order.EQ);
			}

			default «type.genericName» min(final «type.genericName» x, final «type.genericName» y) {
				return less(x, y) ? x : y;
			}

			default «type.genericName» max(final «type.genericName» x, final «type.genericName» y) {
				return greater(x, y) ? x : y;
			}

			default «genericName» reverse() {
				«IF type == Type.OBJECT»
					return (final «type.genericName» x, final «type.genericName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return compare(x, y).reverse();
					};
				«ELSE»
					return (final «type.genericName» x, final «type.genericName» y) ->
						compare(x, y).reverse();
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				default <B> Ord<B> contraMap(final F<B, A> f) {
					requireNonNull(f);
					return (final B b1, final B b2) -> {
						requireNonNull(b1);
						requireNonNull(b2);
						final A a1 = requireNonNull(f.apply(b1));
						final A a2 = requireNonNull(f.apply(b2));
						return requireNonNull(compare(a1, a2));
					};
				}
			«ELSE»
				default <A> Ord<A> contraMap(final «type.typeName»F<A> f) {
					requireNonNull(f);
					return (final A a1, final A a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						final «type.javaName» value1 = f.apply(a1);
						final «type.javaName» value2 = f.apply(a2);
						return requireNonNull(compare(value1, value2));
					};
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «t.ordGenericName» contraMapFrom«t.typeName»(final «t.typeName»ObjectF<A> f) {
						requireNonNull(f);
						return (final «t.javaName» value1, final «t.javaName» value2) -> {
							final A a1 = requireNonNull(f.apply(value1));
							final A a2 = requireNonNull(f.apply(value2));
							return requireNonNull(compare(a1, a2));
						};
					}
				«ELSE»
					default «t.ordGenericName» contraMapFrom«t.typeName»(final «t.typeName»«type.typeName»F f) {
						requireNonNull(f);
						return (final «t.javaName» value1, final «t.javaName» value2) -> {
							final «type.javaName» result1 = f.apply(value1);
							final «type.javaName» result2 = f.apply(value2);
							return requireNonNull(compare(result1, result2));
						};
					}
				«ENDIF»

			«ENDFOR»
			default «genericName» then(final «genericName» ord) {
				requireNonNull(ord);
				return (final «type.genericName» x, final «type.genericName» y) -> {
					«IF type == Type.OBJECT»
						requireNonNull(x);
						requireNonNull(y);
					«ENDIF»
					final Order order = compare(x, y);
					if (order.equals(Order.EQ)) {
						return ord.compare(x, y);
					} else {
						return order;
					}
				};
			}

			«IF type == Type.OBJECT»
				default <B extends Comparable<B>> «genericName» thenBy(final F<A, B> f) {
					return then(by(f));
				}
			«ELSE»
				default <A extends Comparable<A>> «genericName» thenBy(final «type.typeName»ObjectF<A> f) {
					return then(by(f));
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «genericName» thenBy«t.typeName»(final «t.typeName»F<A> f) {
						return then(by«t.typeName»(f));
					}
				«ELSE»
					default «genericName» thenBy«t.typeName»(final «type.typeName»«t.typeName»F f) {
						return then(by«t.typeName»(f));
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <B extends Comparable<B>> Ord<A> thenByReverse(final F<A, B> f) {
					return then(byReverse(f));
				}
			«ELSE»
				default <A extends Comparable<A>> «genericName» thenByReverse(final «type.typeName»ObjectF<A> f) {
					return then(byReverse(f));
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «genericName» thenBy«t.typeName»Reverse(final «t.typeName»F<A> f) {
						return then(by«t.typeName»Reverse(f));
					}
				«ELSE»
					default «genericName» thenBy«t.typeName»Reverse(final «type.typeName»«t.typeName»F f) {
						return then(by«t.typeName»Reverse(f));
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				default <B> «genericName» thenByOrd(final F<A, B> f, final Ord<B> ord) {
					return then(ord.contraMap(f));
				}
			«ELSE»
				default <A> «genericName» thenByOrd(final «type.typeName»ObjectF<A> f, final Ord<A> ord) {
					return then(ord.contraMapFrom«type.typeName»(f));
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «genericName» thenBy«t.typeName»Ord(final «t.typeName»F<A> f, final «t.ordGenericName» ord) {
						return then(ord.contraMap(f));
					}
				«ELSE»
					default «genericName» thenBy«t.typeName»Ord(final «type.typeName»«t.typeName»F f, final «t.ordGenericName» ord) {
						return then(ord.contraMapFrom«type.typeName»(f));
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				default F2<A, A, Order> toF() {
					return (final «type.genericName» x, final «type.genericName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return requireNonNull(compare(x, y));
					};
				}
			«ELSE»
				default «type.typeName»«type.typeName»ObjectF2<Order> toF() {
					return (final «type.genericName» x, final «type.genericName» y) ->
						requireNonNull(compare(x, y));
				}
			«ENDIF»

			default Comparator<«type.genericBoxedName»> toComparator() {
				«IF type == Type.OBJECT»
					return (final «type.genericBoxedName» x, final «type.genericBoxedName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return compare(x, y).toInt();
					};
				«ELSE»
					return (final «type.genericBoxedName» x, final «type.genericBoxedName» y) ->
						compare(x, y).toInt();
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				static <A> Ord<A> fromF(final F2<A, A, Order> f2) {
					requireNonNull(f2);
					return (final «type.genericName» x, final «type.genericName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return requireNonNull(f2.apply(x, y));
					};
				}
			«ELSE»
				static «genericName» fromF(final «type.typeName»«type.typeName»ObjectF2<Order> f2) {
					requireNonNull(f2);
					return (final «type.genericName» x, final «type.genericName» y) ->
						requireNonNull(f2.apply(x, y));
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A> Ord<A> fromComparator(final Comparator<A> comparator) {
					requireNonNull(comparator);
					return (final «type.genericName» x, final «type.genericName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return Order.fromInt(comparator.compare(x, y));
					};
				}
			«ELSE»
				static «genericName» fromComparator(final Comparator<«type.genericBoxedName»> comparator) {
					requireNonNull(comparator);
					return (final «type.genericName» x, final «type.genericName» y) -> 
						Order.fromInt(comparator.compare(x, y));
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A extends Comparable<A>> «genericName» ord() {
					return (Ord) NaturalOrd.INSTANCE;
				}
			«ELSE»
				static «genericName» «shortName.firstToLowerCase»() {
					return «type.typeName»NaturalOrd.INSTANCE;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A extends Comparable<A>> «genericName» reverseOrd() {
					return (Ord) ReverseOrd.INSTANCE;
				}
			«ELSE»
				static «genericName» «type.typeName.firstToLowerCase»ReverseOrd() {
					return «type.typeName»ReverseOrd.INSTANCE;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A, B extends Comparable<B>> «genericName» by(final F<A, B> f) {
					return Ord.<B>ord().contraMap(f);
				}
			«ELSE»
				static <A extends Comparable<A>> «genericName» by(final «type.typeName»ObjectF<A> f) {
					return Ord.<A>ord().contraMapFrom«type.typeName»(f);
				}
			«ENDIF»
			
			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					static <A> «genericName» by«t.typeName»(final «t.typeName»F<A> f) {
						return «t.ordShortName».«t.ordShortName.firstToLowerCase»().contraMap(f);
					}
				«ELSE»
					static «genericName» by«t.typeName»(final «type.typeName»«t.typeName»F f) {
						return «t.ordShortName».«t.ordShortName.firstToLowerCase»().contraMapFrom«type.typeName»(f);
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				static <A, B extends Comparable<B>> Ord<A> byReverse(final F<A, B> f) {
					return Ord.<B>reverseOrd().contraMap(f);
				}
			«ELSE»
				static <A extends Comparable<A>> «genericName» byReverse(final «type.typeName»ObjectF<A> f) {
					return Ord.<A>reverseOrd().contraMapFrom«type.typeName»(f);
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					static <A> «genericName» by«t.typeName»Reverse(final «t.typeName»F<A> f) {
						return «t.ordShortName».«t.typeName.firstToLowerCase»ReverseOrd().contraMap(f);
					}
				«ELSE»
					static «genericName» by«t.typeName»Reverse(final «type.typeName»«t.typeName»F f) {
						return «t.ordShortName».«t.typeName.firstToLowerCase»ReverseOrd().contraMapFrom«type.typeName»(f);
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				static <A, B> «genericName» byOrd(final F<A, B> f, final Ord<B> ord) {
					return ord.contraMap(f);
				}
			«ELSE»
				static <A> «genericName» byOrd(final «type.typeName»ObjectF<A> f, final Ord<A> ord) {
					return ord.contraMapFrom«type.typeName»(f);
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					static <A> Ord<A> by«t.ordShortName»(final «t.typeName»F<A> f, final «t.ordGenericName» ord) {
						return ord.contraMap(f);
					}
				«ELSE»
					static «genericName» by«t.ordShortName»(final «type.typeName»«t.typeName»F f, final «t.ordGenericName» ord) {
						return ord.contraMapFrom«type.typeName»(f);
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»

				«cast(#["A"], #["A"], #[])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			final class NaturalOrd implements Ord<Comparable<Object>>, Serializable {
				static final NaturalOrd INSTANCE = new NaturalOrd();

				@Override
				public Order compare(final Comparable<Object> x, final Comparable<Object> y) {
					requireNonNull(x);
					requireNonNull(y);
					return Order.fromInt(x.compareTo(y));
				}

				@Override
				public Comparator<Comparable<Object>> toComparator() {
					return Comparator.naturalOrder();
				}

				@Override
				public Ord<Comparable<Object>> reverse() {
					return ReverseOrd.INSTANCE;
				}
			}
		«ELSE»
			final class «type.typeName»NaturalOrd implements «genericName», Serializable {
				static final «type.typeName»NaturalOrd INSTANCE = new «type.typeName»NaturalOrd();

				@Override
				public Order compare(final «type.javaName» x, final «type.javaName» y) {
					return Order.fromInt(«type.boxedName».compare(x, y));
				}

				@Override
				public Comparator<«type.genericBoxedName»> toComparator() {
					return Comparator.naturalOrder();
				}

				@Override
				public «genericName» reverse() {
					return «type.typeName»ReverseOrd.INSTANCE;
				}
			}
		«ENDIF»

		«IF type == Type.OBJECT»
			final class ReverseOrd implements Ord<Comparable<Object>>, Serializable {
				static final ReverseOrd INSTANCE = new ReverseOrd();

				@Override
				public Order compare(final Comparable<Object> x, final Comparable<Object> y) {
					requireNonNull(x);
					requireNonNull(y);
					return Order.fromInt(y.compareTo(x));
				}

				@Override
				public Comparator<Comparable<Object>> toComparator() {
					return Comparator.reverseOrder();
				}

				@Override
				public Ord<Comparable<Object>> reverse() {
					return NaturalOrd.INSTANCE;
				}
			}
		«ELSE»
			final class «type.typeName»ReverseOrd implements «genericName», Serializable {
				static final «type.typeName»ReverseOrd INSTANCE = new «type.typeName»ReverseOrd();

				@Override
				public Order compare(final «type.javaName» x, final «type.javaName» y) {
					return Order.fromInt(«type.boxedName».compare(y, x));
				}

				@Override
				public Comparator<«type.genericBoxedName»> toComparator() {
					return Comparator.reverseOrder();
				}

				@Override
				public «genericName» reverse() {
					return «type.typeName»NaturalOrd.INSTANCE;
				}
			}
		«ENDIF»
	''' }
}