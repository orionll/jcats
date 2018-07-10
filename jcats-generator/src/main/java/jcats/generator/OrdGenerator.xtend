package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OrdGenerator implements InterfaceGenerator {
	val Type type
		
	override className() { Constants.JCATS + "." + shortName }

	def shortName() { type.ordShortName }
	def genericName() { type.ordGenericName }
	def kind(boolean natural) { if (natural) "Natural" else "Reverse" }

	def static List<Generator> generators() {
		Type.values.toList.map[new OrdGenerator(it) as Generator]
	}

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Comparator;
		import java.util.function.Consumer;

		import «Constants.COLLECTION».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.ORDER».*;
		import static «Constants.JCATS».«type.optionShortName».*;

		@FunctionalInterface
		public interface «type.contravariantName("Ord")» extends Comparator<«type.genericBoxedName»> {

			Order order(final «type.genericName» x, final «type.genericName» y);

			/**
			 * @deprecated Use {@link #order} instead
			 */
			@Override
			@Deprecated
			default int compare(final «type.genericBoxedName» x, final «type.genericBoxedName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return order(x, y).toInt();
			}

			default boolean less(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return order(x, y).equals(LT);
			}

			default boolean lessOrEqual(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return !order(x, y).equals(GT);
			}

			default boolean greater(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return order(x, y).equals(GT);
			}

			default boolean greaterOrEqual(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return !order(x, y).equals(LT);
			}

			default boolean equal(final «type.genericName» x, final «type.genericName» y) {
				«IF type == Type.OBJECT»
					requireNonNull(x);
					requireNonNull(y);
				«ENDIF»
				return order(x, y).equals(EQ);
			}

			default «type.genericName» min(final «type.genericName» value1, final «type.genericName» value2) {
				«IF type == Type.OBJECT»
					requireNonNull(value1);
					requireNonNull(value2);
				«ENDIF»
				if (order(value1, value2).equals(GT)) {
					return value2;
				} else {
					return value1;
				}
			}

			«FOR i : 3 .. Constants.MAX_ARITY»
				default «type.genericName» min(«(1..i).map['''final «type.genericName» value«it»'''].join(", ")») {
					«type.genericName» min = min(value1, value2);
					«FOR j : 3 .. i»
						min = min(min, value«j»);
					«ENDFOR»
					return min;
				}

			«ENDFOR»
			default «type.genericName» min(«(1..Constants.MAX_ARITY+1).map['''final «type.genericName» value«it»'''].join(", ")», final «type.genericName»... values) {
				«type.genericName» min = min(value1, value2);
				«FOR j : 3 .. Constants.MAX_ARITY+1»
					min = min(min, value«j»);
				«ENDFOR»
				for (final «type.genericName» value : values) {
					min = min(min, value);
				}
				return min;
			}

			default «type.optionGenericName» arrayMin(final «type.genericName»[] values) {
				if (values.length == 0) {
					return «type.noneName»();
				} else {
					«type.genericName» min = «type.requireNonNull("values[0]")»;
					for (int i = 1; i < values.length; i++) {
						final «type.genericName» value = «type.requireNonNull("values[i]")»;
						min = «type.requireNonNull("min(min, value)")»;
					}
					return «type.someName»(min);
				}
			}

			default «type.optionGenericName» allMin(final Iterable<«type.genericBoxedName»> iterable) {
				if (iterable instanceof «type.containerWildcardName») {
					return ((«type.containerGenericName») iterable).min«IF type.primitive»ByOrd«ENDIF»(this);
				} else {
					final «type.genericName("MinCollector")» collector = new «type.diamondName("MinCollector")»(this);
					iterable.forEach(collector);
					«IF type == Type.OBJECT»
						return Option.fromNullable(collector.min);
					«ELSE»
						if (collector.nonEmpty) {
							return «type.someName»(collector.min);
						} else {
							return «type.noneName»();
						}
					«ENDIF»
				}
			}

			default «type.genericName» max(final «type.genericName» value1, final «type.genericName» value2) {
				«IF type == Type.OBJECT»
					requireNonNull(value1);
					requireNonNull(value2);
				«ENDIF»
				if (order(value1, value2).equals(LT)) {
					return value2;
				} else {
					return value1;
				}
			}

			«FOR i : 3 .. Constants.MAX_ARITY»
				default «type.genericName» max(«(1..i).map['''final «type.genericName» value«it»'''].join(", ")») {
					«type.genericName» max = max(value1, value2);
					«FOR j : 3 .. i»
						max = max(max, value«j»);
					«ENDFOR»
					return max;
				}

			«ENDFOR»
			default «type.genericName» max(«(1..Constants.MAX_ARITY+1).map['''final «type.genericName» value«it»'''].join(", ")», final «type.genericName»... values) {
				«type.genericName» max = max(value1, value2);
				«FOR j : 3 .. Constants.MAX_ARITY+1»
					max = max(max, value«j»);
				«ENDFOR»
				for (final «type.genericName» value : values) {
					max = max(max, value);
				}
				return max;
			}

			default «type.optionGenericName» arrayMax(final «type.genericName»[] values) {
				if (values.length == 0) {
					return «type.noneName»();
				} else {
					«type.genericName» max = «type.requireNonNull("values[0]")»;
					for (int i = 1; i < values.length; i++) {
						final «type.genericName» value = «type.requireNonNull("values[i]")»;
						max = «type.requireNonNull("max(max, value)")»;
					}
					return «type.someName»(max);
				}
			}

			default «type.optionGenericName» allMax(final Iterable<«type.genericBoxedName»> iterable) {
				if (iterable instanceof «type.containerWildcardName») {
					return ((«type.containerGenericName») iterable).max«IF type.primitive»ByOrd«ENDIF»(this);
				} else {
					final «type.genericName("MaxCollector")» collector = new «type.diamondName("MaxCollector")»(this);
					iterable.forEach(collector);
					«IF type == Type.OBJECT»
						return Option.fromNullable(collector.max);
					«ELSE»
						if (collector.nonEmpty) {
							return «type.someName»(collector.max);
						} else {
							return «type.noneName»();
						}
					«ENDIF»
				}
			}

			default «genericName» reverse() {
				«IF type == Type.OBJECT»
					return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return order(x, y).reverse();
					};
				«ELSE»
					return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) ->
						order(x, y).reverse();
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				default <B> Ord<B> contraMap(final F<B, A> f) {
					requireNonNull(f);
					return (Ord<B> & Serializable) (final B b1, final B b2) -> {
						requireNonNull(b1);
						requireNonNull(b2);
						final A a1 = requireNonNull(f.apply(b1));
						final A a2 = requireNonNull(f.apply(b2));
						return requireNonNull(order(a1, a2));
					};
				}
			«ELSE»
				default <A> Ord<A> contraMap(final «type.typeName»F<A> f) {
					requireNonNull(f);
					return (Ord<A> & Serializable) (final A a1, final A a2) -> {
						requireNonNull(a1);
						requireNonNull(a2);
						final «type.javaName» value1 = f.apply(a1);
						final «type.javaName» value2 = f.apply(a2);
						return requireNonNull(order(value1, value2));
					};
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					default «t.ordGenericName» contraMapFrom«t.typeName»(final «t.typeName»ObjectF<A> f) {
						requireNonNull(f);
						return («t.ordGenericName» & Serializable) (final «t.javaName» value1, final «t.javaName» value2) -> {
							final A a1 = requireNonNull(f.apply(value1));
							final A a2 = requireNonNull(f.apply(value2));
							return requireNonNull(order(a1, a2));
						};
					}
				«ELSE»
					default «t.ordGenericName» contraMapFrom«t.typeName»(final «t.typeName»«type.typeName»F f) {
						requireNonNull(f);
						return («t.ordGenericName» & Serializable) (final «t.javaName» value1, final «t.javaName» value2) -> {
							final «type.javaName» result1 = f.apply(value1);
							final «type.javaName» result2 = f.apply(value2);
							return requireNonNull(order(result1, result2));
						};
					}
				«ENDIF»

			«ENDFOR»
			default «genericName» then(final «genericName» ord) {
				requireNonNull(ord);
				return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) -> {
					«IF type == Type.OBJECT»
						requireNonNull(x);
						requireNonNull(y);
					«ENDIF»
					final Order order = order(x, y);
					if (order.equals(EQ)) {
						return ord.order(x, y);
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
						return requireNonNull(order(x, y));
					};
				}
			«ELSE»
				default «type.typeName»«type.typeName»ObjectF2<Order> toF() {
					return (final «type.genericName» x, final «type.genericName» y) ->
						requireNonNull(order(x, y));
				}
			«ENDIF»

			default Comparator<«type.genericBoxedName»> toComparator() {
				«IF type == Type.OBJECT»
					return (Comparator<«type.genericBoxedName»> & Serializable) (final «type.genericBoxedName» x, final «type.genericBoxedName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return order(x, y).toInt();
					};
				«ELSE»
					return (Comparator<«type.genericBoxedName»> & Serializable) (final «type.genericBoxedName» x, final «type.genericBoxedName» y) ->
						order(x, y).toInt();
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				static <A> Ord<A> ord(final Ord<A> ord) {
					return requireNonNull(ord);
				}
			«ELSE»
				static «genericName» «shortName.firstToLowerCase»(final «genericName» ord) {
					return requireNonNull(ord);
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A> Ord<A> fromF(final F2<A, A, Order> f2) {
					requireNonNull(f2);
					return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) -> {
						requireNonNull(x);
						requireNonNull(y);
						return requireNonNull(f2.apply(x, y));
					};
				}
			«ELSE»
				static «genericName» fromF(final «type.typeName»«type.typeName»ObjectF2<Order> f2) {
					requireNonNull(f2);
					return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) ->
						requireNonNull(f2.apply(x, y));
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A> Ord<A> fromComparator(final Comparator<A> comparator) {
					requireNonNull(comparator);
					if (comparator instanceof Ord<?>) {
						return (Ord<A>) comparator;
					} else if (comparator == Comparator.naturalOrder()) {
						return (Ord<A>) asc();
					} else if (comparator == Comparator.reverseOrder()) {
						return (Ord<A>) desc();
					} else {
						return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) -> {
							requireNonNull(x);
							requireNonNull(y);
							return Order.fromInt(comparator.compare(x, y));
						};
					}
				}
			«ELSE»
				static «genericName» fromComparator(final Comparator<«type.genericBoxedName»> comparator) {
					requireNonNull(comparator);
					if (comparator instanceof «shortName») {
						return («genericName») comparator;
					} else {
						return («genericName» & Serializable) (final «type.genericName» x, final «type.genericName» y) ->
							Order.fromInt(comparator.compare(x, y));
					}
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				«javadocSynonym("naturalOrd")»
				static <A extends Comparable<A>> «genericName» «type.asc»() {
					return (Ord) NaturalOrd.INSTANCE;
				}
			«ELSE»
				static «genericName» «type.asc»() {
					return «type.typeName»NaturalOrd.INSTANCE;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				«javadocSynonym("reverseOrd")»
				static <A extends Comparable<A>> «genericName» «type.desc»() {
					return (Ord) ReverseOrd.INSTANCE;
				}
			«ELSE»
				static «genericName» «type.desc»() {
					return «type.typeName»ReverseOrd.INSTANCE;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				static <A extends Comparable<A>> «genericName» naturalOrd() {
					return (Ord) NaturalOrd.INSTANCE;
				}

				static <A extends Comparable<A>> «genericName» reverseOrd() {
					return (Ord) ReverseOrd.INSTANCE;
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				static <A, B extends Comparable<B>> «genericName» by(final F<A, B> f) {
					return Ord.<B>asc().contraMap(f);
				}
			«ELSE»
				static <A extends Comparable<A>> «genericName» by(final «type.typeName»ObjectF<A> f) {
					return Ord.<A>asc().contraMapFrom«type.typeName»(f);
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					static <A> «genericName» by«t.typeName»(final «t.typeName»F<A> f) {
						return «t.ordShortName».«t.asc»().contraMap(f);
					}
				«ELSE»
					static «genericName» by«t.typeName»(final «type.typeName»«t.typeName»F f) {
						return «t.ordShortName».«t.asc»().contraMapFrom«type.typeName»(f);
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				static <A, B extends Comparable<B>> Ord<A> byReverse(final F<A, B> f) {
					return Ord.<B>desc().contraMap(f);
				}
			«ELSE»
				static <A extends Comparable<A>> «genericName» byReverse(final «type.typeName»ObjectF<A> f) {
					return Ord.<A>desc().contraMapFrom«type.typeName»(f);
				}
			«ENDIF»

			«FOR t : Type.primitives»
				«IF type == Type.OBJECT»
					static <A> «genericName» by«t.typeName»Reverse(final «t.typeName»F<A> f) {
						return «t.ordShortName».«t.desc»().contraMap(f);
					}
				«ELSE»
					static «genericName» by«t.typeName»Reverse(final «type.typeName»«t.typeName»F f) {
						return «t.ordShortName».«t.desc»().contraMapFrom«type.typeName»(f);
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
				public Order order(final Comparable<Object> x, final Comparable<Object> y) {
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
				public Order order(final «type.javaName» x, final «type.javaName» y) {
					return Order.fromInt(«type.boxedName».compare(x, y));
				}

				«IF type.javaUnboxedType»
					@Override
					public «type.genericName» max(final «type.genericName» value1, final «type.genericName» value2) {
						return «type.genericBoxedName».max(value1, value2);
					}

					@Override
					public «type.genericName» min(final «type.genericName» value1, final «type.genericName» value2) {
						return «type.genericBoxedName».min(value1, value2);
					}

				«ENDIF»
				«IF type.floatingPoint»
					@Override
					public <A> Ord<A> contraMap(final «type.typeName»F<A> f) {
						requireNonNull(f);
						return new ContraMapped«type.typeName»NaturalOrd<>(f);
					}

					«FOR from : Type.primitives»
						@Override
						public «from.typeName»Ord contraMapFrom«from.typeName»(final «from.typeName»«type.typeName»F f) {
							requireNonNull(f);
							return new ContraMapped«from.typeName»«type.typeName»NaturalOrd(f);
						}

					«ENDFOR»
				«ENDIF»
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
				public Order order(final Comparable<Object> x, final Comparable<Object> y) {
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
				public Order order(final «type.javaName» x, final «type.javaName» y) {
					return Order.fromInt(«type.boxedName».compare(y, x));
				}

				«IF type.javaUnboxedType»
					@Override
					public «type.genericName» min(final «type.genericName» value1, final «type.genericName» value2) {
						return «type.genericBoxedName».max(value1, value2);
					}

					@Override
					public «type.genericName» max(final «type.genericName» value1, final «type.genericName» value2) {
						return «type.genericBoxedName».min(value1, value2);
					}

				«ENDIF»
				«IF type.floatingPoint»
					@Override
					public <A> Ord<A> contraMap(final «type.typeName»F<A> f) {
						requireNonNull(f);
						return new ContraMapped«type.typeName»ReverseOrd<>(f);
					}

					«FOR from : Type.primitives»
						@Override
						public «from.typeName»Ord contraMapFrom«from.typeName»(final «from.typeName»«type.typeName»F f) {
							requireNonNull(f);
							return new ContraMapped«from.typeName»«type.typeName»ReverseOrd(f);
						}

					«ENDFOR»
				«ENDIF»
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
		«IF type.floatingPoint»
			«FOR natural : #[true, false]»
				«FOR from : Type.values»
					«IF from == Type.OBJECT»
						final class ContraMapped«type.typeName»«kind(natural)»Ord<A> implements Ord<A>, Serializable {
							private final «type.typeName»F<A> f;

							ContraMapped«type.typeName»«kind(natural)»Ord(final «type.typeName»F<A> f) {
								this.f = f;
							}
					«ELSE»
						final class ContraMapped«from.typeName»«type.typeName»«kind(natural)»Ord implements «from.typeName»Ord, Serializable {
							private final «from.typeName»«type.typeName»F f;

							ContraMapped«from.typeName»«type.typeName»«kind(natural)»Ord(final «from.typeName»«type.typeName»F f) {
								this.f = f;
							}
					«ENDIF»

						@Override
						public Order order(final «from.genericName» x, final «from.genericName» y) {
							«IF from == Type.OBJECT»
								requireNonNull(x);
								requireNonNull(y);
							«ENDIF»
							final double value1 = this.f.apply(x);
							final double value2 = this.f.apply(y);
							return «type.typeName»«kind(natural)»Ord.INSTANCE.order(value1, value2);
						}

						@Override
						public «from.genericName» «if (natural) "min" else "max"»(final «from.genericName» x, final «from.genericName» y) {
							«IF from == Type.OBJECT»
								requireNonNull(x);
								requireNonNull(y);
							«ENDIF»
							final double value1 = this.f.apply(x);
							final double value2 = this.f.apply(y);
							if (Double.isNaN(value1)) {
								return x;
							} else if (Double.isNaN(value2)) {
								return y;
							} else {
								return Double.compare(value1, value2) <= 0 ? x : y;
							}
						}
					}

				«ENDFOR»
			«ENDFOR»
		«ELSE»

		«ENDIF»
		«IF type == Type.OBJECT»
			final class MinCollector<A> implements Consumer<A> {
				A min;
				private final Ord<A> ord;

				MinCollector(final Ord<A> ord) {
					this.ord = ord;
				}

				@Override
				public void accept(final A value) {
					requireNonNull(value);
					if (this.min == null) {
						this.min = value;
					} else {
						this.min = requireNonNull(this.ord.min(this.min, value));
					}
				}
			}

			final class MaxCollector<A> implements Consumer<A> {
				A max;
				private final Ord<A> ord;

				MaxCollector(final Ord<A> ord) {
					this.ord = ord;
				}

				@Override
				public void accept(final A value) {
					requireNonNull(value);
					if (this.max == null) {
						this.max = value;
					} else {
						this.max = requireNonNull(this.ord.max(this.max, value));
					}
				}
			}
		«ELSE»
			final class «type.typeName»MinCollector implements Consumer<«type.boxedName»> {
				«type.javaName» min;
				boolean nonEmpty;
				private final «genericName» ord;

				«type.typeName»MinCollector(final «genericName» ord) {
					this.ord = ord;
				}

				@Override
				public void accept(final «type.boxedName» value) {
					if (this.nonEmpty) {
						this.min = this.ord.min(this.min, value);
					} else {
						this.min = value;
						this.nonEmpty = true;
					}
				}
			}

			final class «type.typeName»MaxCollector implements Consumer<«type.boxedName»> {
				«type.javaName» max;
				boolean nonEmpty;
				private final «genericName» ord;

				«type.typeName»MaxCollector(final «genericName» ord) {
					this.ord = ord;
				}

				@Override
				public void accept(final «type.boxedName» value) {
					if (this.nonEmpty) {
						this.max = this.ord.max(this.max, value);
					} else {
						this.max = value;
						this.nonEmpty = true;
					}
				}
			}
		«ENDIF»
	''' }
}