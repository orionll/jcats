package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class Stream2Generator implements ClassGenerator {

	override className() { Constants.COLLECTION + ".Stream2" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Collections;
		import java.util.Comparator;
		import java.util.HashSet;
		import java.util.Iterator;
		import java.util.LinkedHashSet;
		import java.util.List;
		import java.util.Optional;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.*;
		import java.util.stream.Collector;
		import java.util.stream.Collectors;
		import java.util.stream.DoubleStream;
		import java.util.stream.IntStream;
		import java.util.stream.LongStream;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.ORD».*;

		public final class Stream2<A> implements Stream<A>, Iterable<A>, Sized {
			private final Stream<A> stream;

			Stream2(final Stream<A> stream) {
				this.stream = stream;
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public boolean isEmpty() {
				return this.stream.noneMatch(__ -> true);
			}

			@Override
			public boolean isNotEmpty() {
				return this.stream.anyMatch(__ -> true);
			}

			public Stream<A> stream() {
				return this.stream;
			}

			@Override
			public Stream2<A> filter(final Predicate<? super A> predicate) {
				return new Stream2<>(this.stream.filter(predicate));
			}

			@Override
			public <R> Stream2<R> map(final Function<? super A, ? extends R> mapper) {
				return new Stream2<>(this.stream.map(mapper));
			}

			«FOR type : Type.javaUnboxedTypes»
				@Override
				public «type.typeName»Stream2 mapTo«type.typeName»(final To«type.typeName»Function<? super A> mapper) {
					return new «type.typeName»Stream2(this.stream.mapTo«type.typeName»(mapper));
				}

			«ENDFOR»
			@Override
			public <R> Stream2<R> flatMap(final Function<? super A, ? extends Stream<? extends R>> mapper) {
				return new Stream2<>(this.stream.flatMap(mapper));
			}

			«FOR type : Type.javaUnboxedTypes»
				@Override
				public «type.typeName»Stream2 flatMapTo«type.typeName»(final Function<? super A, ? extends «type.typeName»Stream> mapper) {
					return new «type.typeName»Stream2(this.stream.flatMapTo«type.typeName»(mapper));
				}

			«ENDFOR»
			@Override
			public Stream2<A> distinct() {
				return new Stream2<>(this.stream.distinct());
			}

			@Override
			public Stream2<A> sorted() {
				return new Stream2<>(this.stream.sorted());
			}

			@Override
			public Stream2<A> sorted(final Comparator<? super A> comparator) {
				return new Stream2<>(this.stream.sorted(comparator));
			}

			@Override
			public Stream2<A> peek(final Consumer<? super A> action) {
				return new Stream2<>(this.stream.peek(action));
			}

			@Override
			public Stream2<A> limit(final long maxSize) {
				return new Stream2<>(this.stream.limit(maxSize));
			}

			@Override
			public Stream2<A> skip(final long n) {
				return new Stream2<>(this.stream.skip(n));
			}

			@Override
			public void forEach(final Consumer<? super A> action) {
				this.stream.forEach(action);
			}

			@Override
			public void forEachOrdered(final Consumer<? super A> action) {
				this.stream.forEachOrdered(action);
			}

			@Override
			public Object[] toArray() {
				return this.stream.toArray();
			}

			@Override
			public <A1> A1[] toArray(final IntFunction<A1[]> generator) {
				return this.stream.toArray(generator);
			}

			@Override
			public A reduce(final A identity, final BinaryOperator<A> accumulator) {
				return this.stream.reduce(identity, accumulator);
			}

			@Override
			public Optional<A> reduce(final BinaryOperator<A> accumulator) {
				return this.stream.reduce(accumulator);
			}

			@Override
			public <U> U reduce(final U identity, final BiFunction<U, ? super A, U> accumulator, final BinaryOperator<U> combiner) {
				return this.stream.reduce(identity, accumulator, combiner);
			}

			@Override
			public <R> R collect(final Supplier<R> supplier, final BiConsumer<R, ? super A> accumulator, final BiConsumer<R, R> combiner) {
				return this.stream.collect(supplier, accumulator, combiner);
			}

			@Override
			public <R, A1> R collect(final Collector<? super A, A1, R> collector) {
				return this.stream.collect(collector);
			}

			@Override
			public Optional<A> max(final Comparator<? super A> comparator) {
				return this.stream.max(comparator);
			}

			@Override
			public Optional<A> min(final Comparator<? super A> comparator) {
				return this.stream.min(comparator);
			}

			public Option<A> maxByOrd(final Ord<A> ord) {
				return Option.fromOptional(reduce(ord::max));
			}

			public Option<A> minByOrd(final Ord<A> ord) {
				return Option.fromOptional(reduce(ord::min));
			}

			public <B extends Comparable<B>> Option<A> maxBy(final F<A, B> f) {
				return maxByOrd(by(f));
			}

			«FOR to : Type.primitives»
				public Option<A> maxBy«to.typeName»(final «to.typeName»F<A> f) {
					return maxByOrd(by«to.typeName»(f));
				}

			«ENDFOR»
			public <B extends Comparable<B>> Option<A> minBy(final F<A, B> f) {
				return minByOrd(by(f));
			}

			«FOR to : Type.primitives»
				public Option<A> minBy«to.typeName»(final «to.typeName»F<A> f) {
					return minByOrd(by«to.typeName»(f));
				}

			«ENDFOR»
			@Override
			public long count() {
				return this.stream.count();
			}

			@Override
			public int size() throws SizeOverflowException {
				final long count = this.stream.count();
				if (count == (int) count) {
					return (int) count;
				} else {
					throw new SizeOverflowException();
				}
			}

			@Override
			public boolean anyMatch(final Predicate<? super A> predicate) {
				return this.stream.anyMatch(predicate);
			}

			@Override
			public boolean allMatch(final Predicate<? super A> predicate) {
				return this.stream.allMatch(predicate);
			}

			@Override
			public boolean noneMatch(final Predicate<? super A> predicate) {
				return this.stream.noneMatch(predicate);
			}

			@Override
			public Optional<A> findFirst() {
				return this.stream.findFirst();
			}

			@Override
			public Optional<A> findAny() {
				return this.stream.findAny();
			}

			public boolean contains(final A value) {
				return anyMatch(value::equals);
			}

			@Override
			public Iterator<A> iterator() {
				return this.stream.iterator();
			}

			@Override
			public Spliterator<A> spliterator() {
				return this.stream.spliterator();
			}

			@Override
			public boolean isParallel() {
				return this.stream.isParallel();
			}

			@Override
			public Stream2<A> sequential() {
				return new Stream2<>(this.stream.sequential());
			}

			@Override
			public Stream2<A> parallel() {
				return new Stream2<>(this.stream.parallel());
			}

			@Override
			public Stream2<A> unordered() {
				return new Stream2<>(this.stream.unordered());
			}

			@Override
			public Stream2<A> onClose(final Runnable closeHandler) {
				return new Stream2<>(this.stream.onClose(closeHandler));
			}

			@Override
			public void close() {
				this.stream.close();
			}

			public String joinToString() {
				return this.stream.map(Object::toString).collect(Collectors.joining());
			}

			public String joinToString(final String separator) {
				return this.stream.map(Object::toString).collect(Collectors.joining(separator));
			}

			public String joinToString(final String separator, final String prefix, final String suffix) {
				return this.stream.map(Object::toString).collect(Collectors.joining(separator, prefix, suffix));
			}

			public List<A> toUnmodifiableList() {
				final Object[] array = this.stream.toArray();
				if (array.length == 0) {
					return Collections.emptyList();
				} else {
					return new ImmutableArrayList<>(array);
				}
			}

			public ArrayList<A> toArrayList() {
				return new ArrayList<>(new ArrayCollection<>(this.stream.toArray()));
			}

			public HashSet<A> toHashSet() {
				return this.stream.collect(Collectors.toCollection(HashSet::new));
			}

			public Seq<A> toSeq() {
				return this.stream.collect(Seq.collector());
			}

			public Array<A> toArr() {
				return this.stream.collect(Array.collector());
			}

			public static <A> Stream2<A> from(final Stream<A> stream) {
				requireNonNull(stream);
				return new Stream2<>(stream);
			}

			@SafeVarargs
			public static <A> Stream2<A> stream2(final A... values) {
				for (final A value : values) {
					requireNonNull(value);
				}
				return new Stream2<>(Stream.of(values));
			}

			«javadocSynonym("stream2")»
			@SafeVarargs
			public static <A> Stream2<A> of(final A... values) {
				return stream2(values);
			}

			public static <A> Stream2<A> ofAll(final Iterable<A> iterable) {
				if (iterable instanceof Collection<?>) {
					return new Stream2<>(((Collection<A>) iterable).stream());
				} else if (iterable instanceof Stream<?>) {
					return (iterable instanceof Stream2<?>) ? (Stream2<A>) iterable : new Stream2<>((Stream<A>) iterable);
				} else {
					return fromSpliterator(iterable.spliterator());
				}
			}

			public static <A> Stream2<A> fromIterator(final Iterator<A> iterator) {
				return fromSpliterator(Spliterators.spliteratorUnknownSize(iterator, Spliterator.ORDERED));
			}

			public static <A> Stream2<A> fromSpliterator(final Spliterator<A> spliterator) {
				return new Stream2<>(StreamSupport.stream(spliterator, false));
			}

			public static <A> Stream2<A> concat(final Stream<A> prefix, final Stream<A> suffix) {
				return new Stream2<>(Stream.concat(prefix, suffix));
			}
		}
	''' }
}