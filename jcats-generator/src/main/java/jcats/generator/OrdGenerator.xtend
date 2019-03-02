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

	def minOrMax(boolean min) {
		val minOrMax = if (min) "min" else "max"
		val order = if (min) "GT" else "LT"
		'''
		default «type.genericName» «minOrMax»(final «type.genericName» value1, final «type.genericName» value2) {
			«IF type == Type.OBJECT»
				requireNonNull(value1);
				requireNonNull(value2);
			«ENDIF»
			if (order(value1, value2).equals(«order»)) {
				return value2;
			} else {
				return value1;
			}
		}
	''' }

	def minOrMaxN(int i, boolean min) {
		val minOrMax = if (min) "min" else "max"
		'''
		default «type.genericName» «minOrMax»(«(1..i).map['''final «type.genericName» value«it»'''].join(", ")») {
			«type.genericName» «minOrMax» = «minOrMax»(value1, value2);
			«FOR j : 3 .. i»
				«minOrMax» = «minOrMax»(«minOrMax», value«j»);
			«ENDFOR»
			return «minOrMax»;
		}
	''' }

	def minOrMaxMany(boolean min) {
		val minOrMax = if (min) "min" else "max"
		'''
		default «type.genericName» «minOrMax»(«(1..Constants.MAX_ARITY+1).map['''final «type.genericName» value«it»'''].join(", ")», final «type.genericName»... values) {
			«type.genericName» «minOrMax» = «minOrMax»(value1, value2);
			«FOR j : 3 .. Constants.MAX_ARITY+1»
				«minOrMax» = «minOrMax»(«minOrMax», value«j»);
			«ENDFOR»
			for (final «type.genericName» value : values) {
				«minOrMax» = «minOrMax»(«minOrMax», value);
			}
			return «minOrMax»;
		}
	''' }

	def minOrMaxBy2(boolean min) {
		val minOrMax = if (min) "min" else "max"
		val order = if (min) "GT" else "LT"
		'''
		«IF type == Type.OBJECT»
			default <B> B «minOrMax»By(final F<B, A> f, final B value1, final B value2) {
		«ELSE»
			default <A> A «minOrMax»By(final «type.typeName»F<A> f, final A value1, final A value2) {
		«ENDIF»
			requireNonNull(value1);
			requireNonNull(value2);
			final «type.genericName» result1 = «type.requireNonNull("f.apply(value1)")»;
			final «type.genericName» result2 = «type.requireNonNull("f.apply(value2)")»;
			if (order(result1, result2).equals(«order»)) {
				return value2;
			} else {
				return value1;
			}
		}
	''' }

	def minOrMaxByN(int i, boolean min) {
		val minOrMax = if (min) "min" else "max"
		val order = if (min) "GT" else "LT"
		'''
		«IF type == Type.OBJECT»
			default <B> B «minOrMax»By(final F<B, A> f, «(1..i).map['''final B value«it»'''].join(", ")») {
		«ELSE»
			default <A> A «minOrMax»By(final «type.typeName»F<A> f, «(1..i).map['''final A value«it»'''].join(", ")») {
		«ENDIF»
			«FOR j : 1 .. i»
				requireNonNull(value«j»);
			«ENDFOR»
			«IF type == Type.OBJECT»
				B «minOrMax»By = value1;
				A «minOrMax» = requireNonNull(f.apply(value1));
			«ELSE»
				A «minOrMax»By = value1;
				«type.genericName» «minOrMax» = f.apply(value1);
			«ENDIF»
			«FOR j : 2 .. i»
				«IF j == 2»«type.genericName» «ENDIF»result = «type.requireNonNull('''f.apply(value«j»)''')»;
				if (order(«minOrMax», result).equals(«order»)) {
					«minOrMax»By = value«j»;
					«IF j != i»
						«minOrMax» = result;
					«ENDIF»
				}
			«ENDFOR»
			return «minOrMax»By;
		}
	''' }

	def minOrMaxByMany(boolean min) {
		val minOrMax = if (min) "min" else "max"
		val order = if (min) "GT" else "LT"
		'''
			«IF type == Type.OBJECT»
				default <B> B «minOrMax»By(final F<B, A> f, «(1..Constants.MAX_ARITY+1).map['''final B value«it»'''].join(", ")», final B... values) {
			«ELSE»
				default <A> A «minOrMax»By(final «type.typeName»F<A> f, «(1..Constants.MAX_ARITY+1).map['''final A value«it»'''].join(", ")», final A... values) {
			«ENDIF»
				«FOR j : 1 .. Constants.MAX_ARITY+1»
					requireNonNull(value«j»);
				«ENDFOR»
				«IF type == Type.OBJECT»
					B «minOrMax»By = value1;
					A «minOrMax» = requireNonNull(f.apply(value1));
				«ELSE»
					A «minOrMax»By = value1;
					«type.genericName» «minOrMax» = f.apply(value1);
				«ENDIF»
				«FOR j : 2 .. Constants.MAX_ARITY+1»
					«IF j == 2»«type.genericName» «ENDIF»result = «type.requireNonNull('''f.apply(value«j»)''')»;
					if (order(«minOrMax», result).equals(«order»)) {
						«minOrMax»By = value«j»;
						«minOrMax» = result;
					}
				«ENDFOR»
				for (final «IF type == Type.OBJECT»B«ELSE»A«ENDIF» value : values) {
					result = «type.requireNonNull("f.apply(value)")»;
					if (order(«minOrMax», result).equals(«order»)) {
						«minOrMax»By = value;
						«minOrMax» = result;
					}
				}
				return «minOrMax»By;
			}
	''' }

	def arrayMinOrMax(boolean min) {
		val minOrMax = if (min) "min" else "max"
		'''
		default «type.optionGenericName» array«IF min»Min«ELSE»Max«ENDIF»(final «type.genericName»[] values) {
			if (values.length == 0) {
				return «type.noneName»();
			} else {
				«type.genericName» «minOrMax» = «type.requireNonNull("values[0]")»;
				for (int i = 1; i < values.length; i++) {
					final «type.genericName» value = «type.requireNonNull("values[i]")»;
					«minOrMax» = «type.requireNonNull('''«minOrMax»(«minOrMax», value)''')»;
				}
				return «type.someName»(«minOrMax»);
			}
		}
	''' }

	def allMinOrMax(boolean min) {
		val minOrMax = if (min) "min" else "max"
		'''
		default «type.optionGenericName» all«IF min»Min«ELSE»Max«ENDIF»(final Iterable<«type.genericBoxedName»> iterable) {
			if (iterable instanceof «type.containerWildcardName») {
				return ((«type.containerGenericName») iterable).«minOrMax»«IF type.primitive»ByOrd«ENDIF»(this);
			} else {
				final «type.genericName((if (min) "Min" else "Max") + "Collector")» collector = new «type.diamondName((if (min) "Min" else "Max") + "Collector")»(this);
				iterable.forEach(collector);
				«IF type == Type.OBJECT»
					return Option.fromNullable(collector.«minOrMax»);
				«ELSE»
					if (collector.nonEmpty) {
						return «type.someName»(collector.«minOrMax»);
					} else {
						return «type.noneName»();
					}
				«ENDIF»
			}
		}
	''' }

	def minOrMaxCollector(boolean min) {
		val minOrMax = if (min) "min" else "max"
		'''
		final class «IF min»Min«ELSE»Max«ENDIF»Collector<A> implements Consumer<A> {
			A «minOrMax»;
			private final Ord<A> ord;

			«IF min»Min«ELSE»Max«ENDIF»Collector(final Ord<A> ord) {
				this.ord = ord;
			}

			@Override
			public void accept(final A value) {
				requireNonNull(value);
				if (this.«minOrMax» == null) {
					this.«minOrMax» = value;
				} else {
					this.«minOrMax» = requireNonNull(this.ord.«minOrMax»(this.«minOrMax», value));
				}
			}
		}
	''' }

	def primitiveMinOrMaxCollector(boolean min) {
		val minOrMax = if (min) "min" else "max"
		'''
		final class «type.typeName»«IF min»Min«ELSE»Max«ENDIF»Collector implements Consumer<«type.boxedName»> {
			«type.javaName» «minOrMax»;
			boolean nonEmpty;
			private final «genericName» ord;

			«type.typeName»«IF min»Min«ELSE»Max«ENDIF»Collector(final «genericName» ord) {
				this.ord = ord;
			}

			@Override
			public void accept(final «type.boxedName» value) {
				if (this.nonEmpty) {
					this.«minOrMax» = this.ord.«minOrMax»(this.«minOrMax», value);
				} else {
					this.«minOrMax» = value;
					this.nonEmpty = true;
				}
			}
		}
	''' }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Comparator;
		import java.util.function.Consumer;

		import «Constants.COLLECTION».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.ORD».*;
		import static «Constants.ORDER».*;
		import static «Constants.JCATS».«type.optionShortName».*;

		@FunctionalInterface
		public interface «type.contravariantName("Ord")» extends Comparator<«type.genericBoxedName»> {

			Order order(«type.genericName» x, «type.genericName» y);

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

			«minOrMax(true)»

			«FOR i : 3 .. Constants.MAX_ARITY»
				«minOrMaxN(i, true)»

			«ENDFOR»
			«minOrMaxMany(true)»

			«minOrMaxBy2(true)»

			«FOR i : 3 .. Constants.MAX_ARITY»
				«minOrMaxByN(i, true)»

			«ENDFOR»
			«minOrMaxByMany(true)»

			«arrayMinOrMax(true)»

			«allMinOrMax(true)»

			«minOrMax(false)»

			«FOR i : 3 .. Constants.MAX_ARITY»
				«minOrMaxN(i, false)»

			«ENDFOR»
			«minOrMaxMany(false)»

			«minOrMaxBy2(false)»

			«FOR i : 3 .. Constants.MAX_ARITY»
				«minOrMaxByN(i, false)»

			«ENDFOR»
			«minOrMaxByMany(false)»

			«arrayMinOrMax(false)»

			«allMinOrMax(false)»

			@Override
			default «genericName» reversed() {
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

				default Ord<«type.boxedName»> toOrd() {
					return (Ord<«type.boxedName»> & Serializable) (final «type.boxedName» x, final «type.boxedName» y) ->
							requireNonNull(order(x, y));
				}
			«ENDIF»

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

			static «type.paramGenericName("Ord")» allEqual() {
				return «IF type == Type.OBJECT»(«genericName») «ENDIF»«type.shortName("AllEqualOrd")».INSTANCE;
			}
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
				public Ord<Comparable<Object>> reversed() {
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
						«IF type.floatingPoint»
							return («type.genericBoxedName».compare(value1, value2) > 0) ? value1 : value2;
						«ELSE»
							return «type.genericBoxedName».max(value1, value2);
						«ENDIF»
					}

					@Override
					public «type.genericName» min(final «type.genericName» value1, final «type.genericName» value2) {
						«IF type.floatingPoint»
							return («type.genericBoxedName».compare(value1, value2) < 0) ? value1 : value2;
						«ELSE»
							return «type.genericBoxedName».min(value1, value2);
						«ENDIF»
					}

				«ENDIF»
				@Override
				public «genericName» reversed() {
					return «type.typeName»ReverseOrd.INSTANCE;
				}

				@Override
				public Ord<«type.boxedName»> toOrd() {
					return asc();
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
				public Ord<Comparable<Object>> reversed() {
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
						«IF type.floatingPoint»
							return («type.genericBoxedName».compare(value1, value2) > 0) ? value1 : value2;
						«ELSE»
							return «type.genericBoxedName».max(value1, value2);
						«ENDIF»
					}

					@Override
					public «type.genericName» max(final «type.genericName» value1, final «type.genericName» value2) {
						«IF type.floatingPoint»
							return («type.genericBoxedName».compare(value1, value2) < 0) ? value1 : value2;
						«ELSE»
							return «type.genericBoxedName».min(value1, value2);
						«ENDIF»
					}

				«ENDIF»
				@Override
				public «genericName» reversed() {
					return «type.typeName»NaturalOrd.INSTANCE;
				}

				@Override
				public Ord<«type.boxedName»> toOrd() {
					return desc();
				}
			}
		«ENDIF»

		final class «type.shortName("AllEqualOrd")» implements «shortName»«IF type == Type.OBJECT»<Object>«ENDIF», Serializable {
			static final «type.shortName("AllEqualOrd")» INSTANCE = new «type.shortName("AllEqualOrd")»();

			@Override
			public Order order(final «type.javaName» x, final «type.javaName» y) {
				return EQ;
			}

			@Override
			public «shortName»«IF type == Type.OBJECT»<Object>«ENDIF» reversed() {
				return this;
			}
		}

		«IF type == Type.OBJECT»
			«minOrMaxCollector(true)»

			«minOrMaxCollector(false)»
		«ELSE»
			«primitiveMinOrMaxCollector(true)»

			«primitiveMinOrMaxCollector(false)»
		«ENDIF»
	''' }
}