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
		import java.util.PrimitiveIterator;
		import java.util.Spliterator;
		import java.util.function.*;
		import java.util.stream.«type.streamName»;
		import java.util.stream.Collectors;
		import java.util.stream.StreamSupport;

		import static java.util.Objects.requireNonNull;

		public final class «shortName» implements «type.streamName» {
			private final «type.streamName» stream;

			«shortName»(final «type.streamName» stream) {
				this.stream = stream;
			}

			@Override
			public «shortName» filter(final «type.typeName»Predicate predicate) {
				return new «shortName»(stream.filter(predicate));
			}

			@Override
			public «shortName» map(final «type.typeName»UnaryOperator mapper) {
				return new «shortName»(stream.map(mapper));
			}

			@Override
			public <U> Stream2<U> mapToObj(final «type.typeName»Function<? extends U> mapper) {
				return new Stream2<>(stream.mapToObj(mapper));
			}

			«IF type != Type.INT»
				@Override
				public IntStream2 mapToInt(final «type.typeName»ToIntFunction mapper) {
					return new IntStream2(stream.mapToInt(mapper));
				}

			«ENDIF»
			«IF type != Type.LONG»
				@Override
				public LongStream2 mapToLong(final «type.typeName»ToLongFunction mapper) {
					return new LongStream2(stream.mapToLong(mapper));
				}

			«ENDIF»
			«IF type != Type.DOUBLE»
				@Override
				public DoubleStream2 mapToDouble(final «type.typeName»ToDoubleFunction mapper) {
					return new DoubleStream2(stream.mapToDouble(mapper));
				}

			«ENDIF»
			@Override
			public «shortName» flatMap(final «type.typeName»Function<? extends «type.streamName»> mapper) {
				return new «shortName»(stream.flatMap(mapper));
			}

			@Override
			public «shortName» distinct() {
				return new «shortName»(stream.distinct());
			}

			@Override
			public «shortName» sorted() {
				return new «shortName»(stream.sorted());
			}

			@Override
			public «shortName» peek(final «type.typeName»Consumer action) {
				return new «shortName»(stream.peek(action));
			}

			@Override
			public «shortName» limit(final long maxSize) {
				return new «shortName»(stream.limit(maxSize));
			}

			@Override
			public «shortName» skip(final long n) {
				return new «shortName»(stream.skip(n));
			}

			@Override
			public void forEach(final «type.typeName»Consumer action) {
				stream.forEach(action);
			}

			@Override
			public void forEachOrdered(final «type.typeName»Consumer action) {
				stream.forEachOrdered(action);
			}

			@Override
			public «type.javaName»[] toArray() {
				return stream.toArray();
			}

			@Override
			public «type.javaName» reduce(final «type.javaName» identity, final «type.typeName»BinaryOperator op) {
				return stream.reduce(identity, op);
			}

			@Override
			public Optional«type.typeName» reduce(final «type.typeName»BinaryOperator op) {
				return stream.reduce(op);
			}

			@Override
			public <R> R collect(final Supplier<R> supplier, final Obj«type.typeName»Consumer<R> accumulator, final BiConsumer<R, R> combiner) {
				return stream.collect(supplier, accumulator, combiner);
			}

			@Override
			public «type.javaName» sum() {
				return stream.sum();
			}

			@Override
			public Optional«type.typeName» min() {
				return stream.min();
			}

			@Override
			public Optional«type.typeName» max() {
				return stream.max();
			}

			@Override
			public long count() {
				return stream.count();
			}

			public int size() {
				final long count = stream.count();
				if (count == (int) count) {
					return (int) count;
				} else {
					throw new IndexOutOfBoundsException("Integer overflow");
				}
			}

			@Override
			public OptionalDouble average() {
				return stream.average();
			}

			@Override
			public «type.typeName»SummaryStatistics summaryStatistics() {
				return stream.summaryStatistics();
			}

			@Override
			public boolean anyMatch(final «type.typeName»Predicate predicate) {
				return stream.anyMatch(predicate);
			}

			@Override
			public boolean allMatch(final «type.typeName»Predicate predicate) {
				return stream.allMatch(predicate);
			}

			@Override
			public boolean noneMatch(final «type.typeName»Predicate predicate) {
				return stream.noneMatch(predicate);
			}

			@Override
			public Optional«type.typeName» findFirst() {
				return stream.findFirst();
			}

			@Override
			public Optional«type.typeName» findAny() {
				return stream.findAny();
			}

			«IF type == Type.INT»
				@Override
				public LongStream2 asLongStream() {
					return new LongStream2(stream.asLongStream());
				}

			«ENDIF»
			«IF type != Type.DOUBLE»
				@Override
				public DoubleStream2 asDoubleStream() {
					return new DoubleStream2(stream.asDoubleStream());
				}

			«ENDIF»
			@Override
			public Stream2<«type.boxedName»> boxed() {
				return new Stream2<>(stream.boxed());
			}

			@Override
			public «shortName» sequential() {
				return new «shortName»(stream.sequential());
			}

			@Override
			public «shortName» parallel() {
				return new «shortName»(stream.parallel());
			}

			@Override
			public «shortName» unordered() {
				return new «shortName»(stream.unordered());
			}

			@Override
			public «shortName» onClose(final Runnable closeHandler) {
				return new «shortName»(stream.onClose(closeHandler));
			}

			@Override
			public void close() {
				stream.close();
			}

			public String joinToString() {
				return mapToObj(«type.boxedName»::toString).collect(Collectors.joining());
			}

			public String joinToStringWithSeparator(final String separator) {
				return mapToObj(«type.boxedName»::toString).collect(Collectors.joining(separator));
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return stream.iterator();
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				return stream.spliterator();
			}

			@Override
			public boolean isParallel() {
				return stream.isParallel();
			}

			public «type.seqShortName» to«type.seqShortName»() {
				final «type.seqShortName»Builder builder = «type.seqShortName».builder();
				stream.forEach(builder::append);
				return builder.build();
			}

			public «type.arrayShortName» to«type.arrayShortName»() {
				final «type.arrayShortName»Builder builder = «type.arrayShortName».builder();
				stream.forEach(builder::append);
				return builder.build();
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

			public static IntStream2 ofAll(final Iterable<Integer> iterable) {
				final Spliterator<Integer> spliterator = iterable.spliterator();
				if (spliterator instanceof Spliterator.OfInt) {
					return new IntStream2(StreamSupport.intStream((Spliterator.OfInt) spliterator, false));
				} else {
					return new IntStream2(StreamSupport.stream(spliterator, false).mapToInt(Integer::intValue));
				}
			}
		}
	''' }
}