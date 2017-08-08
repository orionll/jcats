package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class Stream2Generator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".Stream2" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Comparator;
		import java.util.HashSet;
		import java.util.Iterator;
		import java.util.Optional;
		import java.util.Spliterator;
		import java.util.function.*;
		import java.util.stream.Collector;
		import java.util.stream.DoubleStream;
		import java.util.stream.IntStream;
		import java.util.stream.LongStream;
		import java.util.stream.Stream;

		import static java.util.Objects.requireNonNull;

		public final class Stream2<A> implements Stream<A>, Iterable<A> {
			private final Stream<A> stream;

			Stream2(final Stream<A> stream) {
				this.stream = stream;
			}

			public Stream<A> stream() {
				return stream;
			}

			@Override
			public Stream2<A> filter(final Predicate<? super A> predicate) {
				return new Stream2<>(stream.filter(predicate));
			}

			@Override
			public <R> Stream2<R> map(final Function<? super A, ? extends R> mapper) {
				return new Stream2<>(stream.map(mapper));
			}

			«FOR type : Type.javaUnboxedTypes»
				@Override
				public «type.typeName»Stream2 mapTo«type.typeName»(final To«type.typeName»Function<? super A> mapper) {
					return new «type.typeName»Stream2(stream.mapTo«type.typeName»(mapper));
				}

			«ENDFOR»
			@Override
			public <R> Stream2<R> flatMap(final Function<? super A, ? extends Stream<? extends R>> mapper) {
				return new Stream2<>(stream.flatMap(mapper));
			}

			«FOR type : Type.javaUnboxedTypes»
				@Override
				public «type.typeName»Stream2 flatMapTo«type.typeName»(final Function<? super A, ? extends «type.typeName»Stream> mapper) {
					return new «type.typeName»Stream2(stream.flatMapTo«type.typeName»(mapper));
				}

			«ENDFOR»
			@Override
			public Stream2<A> distinct() {
				return new Stream2<>(stream.distinct());
			}

			@Override
			public Stream2<A> sorted() {
				return new Stream2<>(stream.sorted());
			}

			@Override
			public Stream2<A> sorted(final Comparator<? super A> comparator) {
				return new Stream2<>(stream.sorted(comparator));
			}

			@Override
			public Stream2<A> peek(final Consumer<? super A> action) {
				return new Stream2<>(stream.peek(action));
			}

			@Override
			public Stream2<A> limit(final long maxSize) {
				return new Stream2<>(stream.limit(maxSize));
			}

			@Override
			public Stream2<A> skip(final long n) {
				return new Stream2<>(stream.skip(n));
			}

			@Override
			public void forEach(final Consumer<? super A> action) {
				stream.forEach(action);
			}

			@Override
			public void forEachOrdered(final Consumer<? super A> action) {
				stream.forEachOrdered(action);
			}

			@Override
			public Object[] toArray() {
				return stream.toArray();
			}

			@Override
			public <A1> A1[] toArray(final IntFunction<A1[]> generator) {
				return stream.toArray(generator);
			}

			@Override
			public A reduce(final A identity, final BinaryOperator<A> accumulator) {
				return stream.reduce(identity, accumulator);
			}

			@Override
			public Optional<A> reduce(final BinaryOperator<A> accumulator) {
				return stream.reduce(accumulator);
			}

			@Override
			public <U> U reduce(final U identity, final BiFunction<U, ? super A, U> accumulator, final BinaryOperator<U> combiner) {
				return stream.reduce(identity, accumulator, combiner);
			}

			@Override
			public <R> R collect(final Supplier<R> supplier, final BiConsumer<R, ? super A> accumulator, final BiConsumer<R, R> combiner) {
				return stream.collect(supplier, accumulator, combiner);
			}

			@Override
			public <R, A1> R collect(final Collector<? super A, A1, R> collector) {
				return stream.collect(collector);
			}

			@Override
			public Optional<A> min(final Comparator<? super A> comparator) {
				return stream.min(comparator);
			}

			@Override
			public Optional<A> max(final Comparator<? super A> comparator) {
				return stream.max(comparator);
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
			public boolean anyMatch(final Predicate<? super A> predicate) {
				return stream.anyMatch(predicate);
			}

			@Override
			public boolean allMatch(final Predicate<? super A> predicate) {
				return stream.allMatch(predicate);
			}

			@Override
			public boolean noneMatch(final Predicate<? super A> predicate) {
				return stream.noneMatch(predicate);
			}

			@Override
			public Optional<A> findFirst() {
				return stream.findFirst();
			}

			@Override
			public Optional<A> findAny() {
				return stream.findAny();
			}

			@Override
			public Iterator<A> iterator() {
				return stream.iterator();
			}

			@Override
			public Spliterator<A> spliterator() {
				return stream.spliterator();
			}

			@Override
			public boolean isParallel() {
				return stream.isParallel();
			}

			@Override
			public Stream2<A> sequential() {
				return new Stream2<>(stream.sequential());
			}

			@Override
			public Stream2<A> parallel() {
				return new Stream2<>(stream.parallel());
			}

			@Override
			public Stream2<A> unordered() {
				return new Stream2<>(stream.unordered());
			}

			@Override
			public Stream2<A> onClose(final Runnable closeHandler) {
				return new Stream2<>(stream.onClose(closeHandler));
			}

			@Override
			public void close() {
				stream.close();
			}

			public ArrayList<A> toArrayList() {
				return new ArrayList<>(new ArrayCollection<>(stream.toArray()));
			}

			public HashSet<A> toHashSet() {
				return new HashSet<>(new ArrayCollection<>(stream.toArray()));
			}

			public Seq<A> toSeq() {
				final SeqBuilder<A> builder = Seq.builder();
				stream.forEach(builder::append);
				return builder.build();
			}

			public Array<A> toArr() {
				final ArrayBuilder<A> builder = Array.builder();
				stream.forEach(builder::append);
				return builder.build();
			}

			public static <A> Stream2<A> stream2(final Stream<A> stream) {
				requireNonNull(stream);
				return new Stream2<>(stream);
			}
		}
	''' }
}