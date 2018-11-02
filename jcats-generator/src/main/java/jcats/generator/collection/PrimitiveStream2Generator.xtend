package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class PrimitiveStream2Generator implements ClassGenerator {
	package val Type type

	def static List<Generator> generators() {
		Type.javaUnboxedTypes.toList.map[new PrimitiveStream2Generator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.streamName + "2" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.«type.typeName»SummaryStatistics;
		import java.util.OptionalDouble;
		«IF type != Type.DOUBLE»
			import java.util.Optional«type.typeName»;
		«ENDIF»
		import java.util.Iterator;
		import java.util.PrimitiveIterator;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.*;
		import java.util.stream.«type.streamName»;
		import java.util.stream.Collectors;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.ordShortName».*;

		public final class «shortName» implements «type.streamName» {
			private final «type.streamName» stream;

			«shortName»(final «type.streamName» stream) {
				this.stream = stream;
			}

			@Override
			public «shortName» filter(final «type.typeName»Predicate predicate) {
				return new «shortName»(this.stream.filter(predicate));
			}

			@Override
			public «shortName» map(final «type.typeName»UnaryOperator mapper) {
				return new «shortName»(this.stream.map(mapper));
			}

			@Override
			public <U> Stream2<U> mapToObj(final «type.typeName»Function<? extends U> mapper) {
				return new Stream2<>(this.stream.mapToObj(mapper));
			}

			«IF type != Type.INT»
				@Override
				public IntStream2 mapToInt(final «type.typeName»ToIntFunction mapper) {
					return new IntStream2(this.stream.mapToInt(mapper));
				}

			«ENDIF»
			«IF type != Type.LONG»
				@Override
				public LongStream2 mapToLong(final «type.typeName»ToLongFunction mapper) {
					return new LongStream2(this.stream.mapToLong(mapper));
				}

			«ENDIF»
			«IF type != Type.DOUBLE»
				@Override
				public DoubleStream2 mapToDouble(final «type.typeName»ToDoubleFunction mapper) {
					return new DoubleStream2(this.stream.mapToDouble(mapper));
				}

			«ENDIF»
			@Override
			public «shortName» flatMap(final «type.typeName»Function<? extends «type.streamName»> mapper) {
				return new «shortName»(this.stream.flatMap(mapper));
			}

			@Override
			public «shortName» distinct() {
				return new «shortName»(this.stream.distinct());
			}

			@Override
			public «shortName» sorted() {
				return new «shortName»(this.stream.sorted());
			}

			@Override
			public «shortName» peek(final «type.typeName»Consumer action) {
				return new «shortName»(this.stream.peek(action));
			}

			@Override
			public «shortName» limit(final long maxSize) {
				return new «shortName»(this.stream.limit(maxSize));
			}

			@Override
			public «shortName» skip(final long n) {
				return new «shortName»(this.stream.skip(n));
			}

			@Override
			public void forEach(final «type.typeName»Consumer action) {
				this.stream.forEach(action);
			}

			@Override
			public void forEachOrdered(final «type.typeName»Consumer action) {
				this.stream.forEachOrdered(action);
			}

			@Override
			public «type.javaName»[] toArray() {
				return this.stream.toArray();
			}

			@Override
			public «type.javaName» reduce(final «type.javaName» identity, final «type.typeName»BinaryOperator op) {
				return this.stream.reduce(identity, op);
			}

			@Override
			public Optional«type.typeName» reduce(final «type.typeName»BinaryOperator op) {
				return this.stream.reduce(op);
			}

			@Override
			public <R> R collect(final Supplier<R> supplier, final Obj«type.typeName»Consumer<R> accumulator, final BiConsumer<R, R> combiner) {
				return this.stream.collect(supplier, accumulator, combiner);
			}

			@Override
			public «type.javaName» sum() {
				return this.stream.sum();
			}

			«IF type == Type.INT»
				public long sumToLong() {
					return this.stream.sum();
				}

			«ENDIF»
			@Override
			public Optional«type.typeName» max() {
				return this.stream.max();
			}

			@Override
			public Optional«type.typeName» min() {
				return this.stream.min();
			}

			public «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
				return «type.optionShortName».fromOptional«type.typeName»(reduce(ord::max));
			}

			public «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
				return «type.optionShortName».fromOptional«type.typeName»(reduce(ord::min));
			}

			public <A extends Comparable<A>> «type.optionGenericName» maxBy(final «type.typeName»ObjectF<A> f) {
				return maxByOrd(by(f));
			}

			«FOR to : Type.primitives»
				public «type.optionGenericName» maxBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
					return maxByOrd(by«to.typeName»(f));
				}

			«ENDFOR»
			public <A extends Comparable<A>> «type.optionGenericName» minBy(final «type.typeName»ObjectF<A> f) {
				return minByOrd(by(f));
			}

			«FOR to : Type.primitives»
				public «type.optionGenericName» minBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
					return minByOrd(by«to.typeName»(f));
				}

			«ENDFOR»
			@Override
			public long count() {
				return this.stream.count();
			}

			public int size() throws SizeOverflowException {
				final long count = this.stream.count();
				if (count == (int) count) {
					return (int) count;
				} else {
					throw new SizeOverflowException();
				}
			}

			@Override
			public OptionalDouble average() {
				return this.stream.average();
			}

			@Override
			public «type.typeName»SummaryStatistics summaryStatistics() {
				return this.stream.summaryStatistics();
			}

			@Override
			public boolean anyMatch(final «type.typeName»Predicate predicate) {
				return this.stream.anyMatch(predicate);
			}

			@Override
			public boolean allMatch(final «type.typeName»Predicate predicate) {
				return this.stream.allMatch(predicate);
			}

			@Override
			public boolean noneMatch(final «type.typeName»Predicate predicate) {
				return this.stream.noneMatch(predicate);
			}

			@Override
			public Optional«type.typeName» findFirst() {
				return this.stream.findFirst();
			}

			@Override
			public Optional«type.typeName» findAny() {
				return this.stream.findAny();
			}

			public boolean contains(final «type.javaName» value) {
				return anyMatch(i -> i == value);
			}

			«IF type == Type.INT»
				@Override
				public LongStream2 asLongStream() {
					return new LongStream2(this.stream.asLongStream());
				}

			«ENDIF»
			«IF type != Type.DOUBLE»
				@Override
				public DoubleStream2 asDoubleStream() {
					return new DoubleStream2(this.stream.asDoubleStream());
				}

			«ENDIF»
			@Override
			public Stream2<«type.boxedName»> boxed() {
				return new Stream2<>(this.stream.boxed());
			}

			@Override
			public «shortName» sequential() {
				return new «shortName»(this.stream.sequential());
			}

			@Override
			public «shortName» parallel() {
				return new «shortName»(this.stream.parallel());
			}

			@Override
			public «shortName» unordered() {
				return new «shortName»(this.stream.unordered());
			}

			@Override
			public «shortName» onClose(final Runnable closeHandler) {
				return new «shortName»(this.stream.onClose(closeHandler));
			}

			@Override
			public void close() {
				this.stream.close();
			}

			public String joinToString() {
				return this.stream.mapToObj(«type.boxedName»::toString).collect(Collectors.joining());
			}

			public String joinToStringWithSeparator(final String separator) {
				return this.stream.mapToObj(«type.boxedName»::toString).collect(Collectors.joining(separator));
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return this.stream.iterator();
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				return this.stream.spliterator();
			}

			@Override
			public boolean isParallel() {
				return this.stream.isParallel();
			}

			public «type.seqShortName» to«type.seqShortName»() {
				return this.stream.collect(«type.seqShortName»::builder, «type.seqShortName»Builder::append, «type.seqShortName»Builder::appendSeqBuilder).build();
			}

			public «type.arrayShortName» to«type.arrayShortName»() {
				return this.stream.collect(«type.arrayShortName»::builder, «type.arrayShortName»Builder::append, «type.arrayShortName»Builder::appendArrayBuilder).build();
			}

			public static «shortName» from(final «type.streamName» stream) {
				requireNonNull(stream);
				return new «shortName»(stream);
			}

			public static «shortName» «shortName.firstToLowerCase»(final «type.javaName»... values) {
				return new «shortName»(«type.streamName».of(values));
			}

			«javadocSynonym('''«shortName.firstToLowerCase»''')»
			public static «shortName» of(final «type.javaName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			public static «shortName» ofAll(final Iterable<«type.boxedName»> iterable) {
				return fromSpliterator(iterable.spliterator());
			}

			public static «shortName» fromIterator(final Iterator<«type.boxedName»> iterator) {
				if (iterator instanceof «type.iteratorGenericName») {
					final «type.spliteratorGenericName» spliterator = Spliterators.spliteratorUnknownSize((«type.iteratorGenericName») iterator, Spliterator.ORDERED);
					return new «shortName»(StreamSupport.«type.streamName.firstToLowerCase»(spliterator, false));
				} else {
					final Spliterator<«type.boxedName»> spliterator = Spliterators.spliteratorUnknownSize(iterator, Spliterator.ORDERED);
					return new «shortName»(StreamSupport.stream(spliterator, false).mapTo«type.typeName»(«type.boxedName»::«type.javaName»Value));
				}
			}

			public static «shortName» fromSpliterator(final Spliterator<«type.boxedName»> spliterator) {
				if (spliterator instanceof «type.spliteratorGenericName») {
					return new «shortName»(StreamSupport.«type.streamName.firstToLowerCase»((«type.spliteratorGenericName») spliterator, false));
				} else {
					return new «shortName»(StreamSupport.stream(spliterator, false).mapTo«type.typeName»(«type.boxedName»::«type.javaName»Value));
				}
			}

			public static «shortName» fromStream(final Stream<«type.boxedName»> stream) {
				return new «shortName»(stream.mapTo«type.typeName»(«type.boxedName»::intValue));
			}
			«IF type.integral»

				public static «shortName» range(final «type.javaName» startInclusive, final «type.javaName» endExclusive) {
					return new «shortName»(«type.streamName».range(startInclusive, endExclusive));
				}

				public static «shortName» rangeClosed(final «type.javaName» startInclusive, final «type.javaName» endInclusive) {
					return new «shortName»(«type.streamName».rangeClosed(startInclusive, endInclusive));
				}
			«ENDIF»
		}
	''' }
}