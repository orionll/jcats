package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class ContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Container" else type.typeName + "Container" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.HashSet;
		import java.util.Iterator;
		import java.util.LinkedHashSet;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		«IF type == Type.OBJECT»
			import java.util.NavigableSet;
			import java.util.Collections;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;
		import java.util.stream.«type.streamName»;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;
		«IF type != Type.INT»
			import static «Constants.JCATS».«type.optionShortName».*;
		«ENDIF»
		import static «Constants.COLLECTION».Common.*;

		public interface «type.covariantName("Container")» extends Iterable<«type.genericBoxedName»>, Sized {

			default boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (iterator.«type.iteratorNext»() == value) {
							return true;
						}
					}
				«ELSE»
					for (final «type.genericName» a : this) {
						«IF type == Type.OBJECT»
							if (a.equals(value)) {
						«ELSE»
							if (a == value) {
						«ENDIF»
							return true;
						}
					}
				«ENDIF»
				return false;
			}

			default IntOption indexOf(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type == Type.OBJECT»
					return indexWhere(value::equals);
				«ELSE»
					return indexWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			default IntOption indexWhere(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				int index = 0;
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (predicate.apply(iterator.«type.iteratorNext»())) {
							return intSome(index);
						}
						index++;
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (predicate.apply(value)) {
							return intSome(index);
						}
						index++;
					}
				«ENDIF»
				return intNone();
			}

			default IntOption lastIndexOf(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type == Type.OBJECT»
					return lastIndexWhere(value::equals);
				«ELSE»
					return lastIndexWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			default IntOption lastIndexWhere(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				int index = size() - 1;
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					if (predicate.apply(iterator.«type.iteratorNext»())) {
						return intSome(index);
					}
					index--;
				}
				return intNone();
			}

			default «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						final «type.genericName» value = iterator.«type.iteratorNext»();
						if (predicate.apply(value)) {
							return «type.someName»(value);
						}
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (predicate.apply(value)) {
							return «type.someName»(value);
						}
					}
				«ENDIF»
				return «type.noneName»();
			}

			default «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					final «type.genericName» value = iterator.«type.iteratorNext»();
					if (predicate.apply(value)) {
						return «type.someName»(value);
					}
				}
				return «type.noneName»();
			}

			default boolean anyMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (predicate.apply(iterator.«type.iteratorNext»())) {
							return true;
						}
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (predicate.apply(value)) {
							return true;
						}
					}
				«ENDIF»
				return false;
			}

			default boolean allMatch(final «type.boolFName» predicate) {
				return !anyMatch(predicate.negate());
			}

			default boolean noneMatch(final «type.boolFName» predicate) {
				return !anyMatch(predicate);
			}

			«IF type.primitive»
				default <A> A foldLeft(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					final «type.typeName»Folder<A> folder = new «type.typeName»Folder<>(start, f2);
					foreach(folder);
					return folder.acc;
				}
			«ELSE»
				default <B> B foldLeft(final B start, final F2<B, A, B> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					final Folder<A, B> folder = new Folder<>(start, f2);
					foreach(folder);
					return folder.acc;
				}
			«ENDIF»

			«IF type.primitive»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
						requireNonNull(f2);
						final «type.typeName»FolderTo«returnType.typeName» folder = new «type.typeName»FolderTo«returnType.typeName»(start, f2);
						foreach(folder);
						return folder.acc;
					}

				«ENDFOR»
			«ELSE»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<A> f2) {
						requireNonNull(f2);
						final FolderTo«returnType.typeName»<A> folder = new FolderTo«returnType.typeName»<>(start, f2);
						foreach(folder);
						return folder.acc;
					}

				«ENDFOR»
			«ENDIF»
			«IF type.javaUnboxedType»
				default <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSEIF type == Type.BOOLEAN»
				default <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSE»
				default <B> B foldRight(final B start, final F2<A, B, B> f2) {
			«ENDIF»
				requireNonNull(start);
				requireNonNull(f2);
				«IF type == Type.OBJECT»B«ELSE»A«ENDIF» result = start;
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					final «type.genericName» value = iterator.«type.iteratorNext»();
					result = requireNonNull(f2.apply(value, result));
				}
				return result;
			}

			«FOR returnType : Type.primitives»
				«IF type == Type.OBJECT»
					default «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<A> f2) {
				«ELSE»
					default «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final «type.typeName»«returnType.typeName»«returnType.typeName»F2 f2) {
				«ENDIF»
					requireNonNull(f2);
					«returnType.javaName» result = start;
					final «type.iteratorGenericName» iterator = reverseIterator();
					while (iterator.hasNext()) {
						final «type.genericName» value = iterator.«type.iteratorNext»();
						result = f2.apply(value, result);
					}
					return result;
				}

			«ENDFOR»

			default «type.optionGenericName» reduceLeft(final «IF type == Type.OBJECT»F2<A, A, A>«ELSE»«type.typeName»«type.typeName»«type.typeName»F2«ENDIF» f2) {
				requireNonNull(f2);
				final «type.iteratorGenericName» iterator = iterator();
				if (iterator.hasNext()) {
					«type.genericName» result = iterator.«type.iteratorNext»();
					while (iterator.hasNext()) {
						«IF type == Type.OBJECT»
							result = requireNonNull(f2.apply(result, iterator.«type.iteratorNext»()));
						«ELSE»
							result = f2.apply(result, iterator.«type.iteratorNext»());
						«ENDIF»
					}
					return «type.someName»(result);
				} else {
					return «type.noneName»();
				}
			}

			«IF type.javaUnboxedType»
				default «type.javaName» sum() {
					return foldLeftTo«type.typeName»(0, Common.SUM_«type.typeName.toUpperCase»);
				}

			«ENDIF»
			default void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						eff.apply(iterator.«type.iteratorNext»());
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						eff.apply(value);
					}
				«ENDIF»
			}

			«IF type == Type.OBJECT»
				default void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				default void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				int i = 0;
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (i < 0) {
							throw new IndexOutOfBoundsException("Integer overflow");
						}
						eff.apply(i++, iterator.«type.iteratorNext»());
				«ELSE»
					for (final «type.genericName» value : this) {
						if (i < 0) {
							throw new IndexOutOfBoundsException("Integer overflow");
						}
						eff.apply(i++, value);
				«ENDIF»
				}
			}

			default void foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (!eff.apply(iterator.«type.iteratorNext»())) {
							return;
						}
					}
				«ELSE»
					for (final «type.genericName» value : this) {
						if (!eff.apply(value)) {
							return;
						}
					}
				«ENDIF»
			}

			@Override
			default void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				requireNonNull(action);
				foreach(action::accept);
			}

			default void printAll() {
				foreach(System.out::println);
			}

			«IF type.javaUnboxedType»
				@Override
				«type.iteratorGenericName» iterator();

			«ENDIF»
			default «type.iteratorGenericName» reverseIterator() {
				return to«type.arrayShortName»().reverseIterator();
			}

			default String joinToString() {
				if (isEmpty()) {
					return "";
				} else {
					final StringBuilder builder = new StringBuilder();
					foreach(builder::append);
					return builder.toString();
				}
			}

			default String joinToStringWithSeparator(final String separator) {
				if (isEmpty()) {
					return "";
				} else {
					final StringBuilder builder = new StringBuilder();
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						builder.append(iterator.«type.iteratorNext»());
						if (iterator.hasNext()) {
							builder.append(separator);
						}
					}
					return builder.toString();
				}
			}

			default int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE;
			}

			@Override
			default «type.spliteratorGenericName» spliterator() {
				if (isEmpty()) {
					return Spliterators.«type.emptySpliteratorName»();
				} else if (hasFixedSize()) {
					return Spliterators.spliterator(iterator(), size(), spliteratorCharacteristics());
				} else {
					return Spliterators.spliteratorUnknownSize(iterator(), spliteratorCharacteristics());
				}
			}

			default «type.arrayGenericName» to«type.arrayShortName»() {
				if (isEmpty()) {
					return «type.arrayShortName».empty«type.arrayShortName»();
				} else {
					return new «type.diamondName("Array")»(«type.toArrayName»());
				}
			}

			default «type.seqGenericName» to«type.seqShortName»() {
				return «type.seqShortName».sizedToSeq(iterator(), size());
			}

			default «type.javaName»[] «type.toArrayName»() {
				if (isEmpty()) {
					return «type.emptyArrayName»;
				} else {
					final «type.javaName»[] array = new «type.javaName»[size()];
					int i = 0;
					«IF type.javaUnboxedType»
						final «type.iteratorGenericName» iterator = iterator();
						while (iterator.hasNext()) {
							array[i++] = iterator.«type.iteratorNext»();
						}
					«ELSE»
						for (final «type.javaName» value : this) {
							array[i++] = value;
						}
					«ENDIF»
					return array;
				}
			}
			«IF type == Type.OBJECT»

				default A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] array = supplier.apply(size());
					requireNonNull(array);
					int i = 0;
					for (final A value : this) {
						array[i++] = value;
					}
					return array;
				}
			«ENDIF»

			default Collection<«type.genericBoxedName»> asCollection() {
				return new «shortName»AsCollection«IF type == Type.OBJECT»<>«ENDIF»(this);
			}

			default ArrayList<«type.genericBoxedName»> toArrayList() {
				return new ArrayList<>(asCollection());
			}

			default HashSet<«type.genericBoxedName»> toHashSet() {
				return new HashSet<>(asCollection());
			}

			default LinkedHashSet<«type.genericBoxedName»> toLinkedHashSet() {
				return new LinkedHashSet<>(asCollection());
			}

			default «type.stream2GenericName» stream() {
				return new «type.stream2DiamondName»(StreamSupport.«type.streamFunction»(spliterator(), false));
			}

			default «type.stream2GenericName» parallelStream() {
				return new «type.stream2DiamondName»(StreamSupport.«type.streamFunction»(spliterator(), true));
			}
			«IF type == Type.OBJECT»

				static <A> Container<A> asContainer(final Collection<A> collection) {
					requireNonNull(collection);
					return new CollectionAsContainer<>(collection);
				}

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class «type.genericName("ContainerAsCollection")» extends AbstractImmutableCollection<«type.genericBoxedName»> {
			final «genericName» container;

			«shortName»AsCollection(final «genericName» container) {
				this.container = container;
			}

			@Override
			public int size() {
				return this.container.size();
			}

			@Override
			public boolean isEmpty() {
				return this.container.isEmpty();
			}

			«IF type == Type.OBJECT»
				@Override
				public Object[] toArray() {
					return this.container.toObjectArray();
				}

			«ENDIF»
			@Override
			public Iterator<«type.genericBoxedName»> iterator() {
				return this.container.iterator();
			}

			@Override
			public Spliterator<«type.genericBoxedName»> spliterator() {
				return this.container.spliterator();
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.container.forEach(action);
			}
		}
		«IF type == Type.OBJECT»

			class CollectionAsContainer<A> implements Container<A> {
				final Collection<A> collection;

				CollectionAsContainer(final Collection<A> collection) {
					this.collection = collection;
				}

				@Override
				public boolean isEmpty() {
					return this.collection.isEmpty();
				}

				@Override
				public boolean isNotEmpty() {
					return !this.collection.isEmpty();
				}

				@Override
				public int size() {
					return this.collection.size();
				}

				@Override
				public boolean hasFixedSize() {
					return false;
				}

				@Override
				public boolean contains(final A value) {
					requireNonNull(value);
					return this.collection.contains(value);
				}

				@Override
				public void forEach(final Consumer<? super A> action) {
					this.collection.forEach(action);
				}

				@Override
				public void foreach(final Eff<A> eff) {
					this.collection.forEach(eff.toConsumer());
				}

				@Override
				public Iterator<A> iterator() {
					return this.collection.iterator();
				}

				@Override
				public Spliterator<A> spliterator() {
					return this.collection.spliterator();
				}

				@Override
				public Iterator<A> reverseIterator() {
					if (this.collection instanceof NavigableSet) {
						return ((NavigableSet<A>) this.collection).descendingIterator();
					} else {
						return Container.super.reverseIterator();
					}
				}

				@Override
				public Stream2<A> stream() {
					return new Stream2<>(this.collection.stream());
				}

				@Override
				public Stream2<A> parallelStream() {
					return new Stream2<>(this.collection.parallelStream());
				}

				@Override
				public Object[] toObjectArray() {
					return this.collection.toArray();
				}

				@Override
				public Collection<A> asCollection() {
					return Collections.unmodifiableCollection(this.collection);
				}

				@Override
				public String toString() {
					return this.collection.toString();
				}
			}
		«ENDIF»

		«IF type == Type.OBJECT»
			final class Folder<A, B> implements Eff<A> {
				B acc;
				final F2<B, A, B> f2;

				Folder(final B start, final F2<B, A, B> f2) {
					this.acc = start;
					this.f2 = f2;
				}

				public void apply(final A value) {
					this.acc = this.f2.apply(this.acc, value);
				}
			}

			«FOR returnType : Type.primitives»
				final class FolderTo«returnType.typeName»<A> implements Eff<A> {
					«returnType.javaName» acc;
					final «returnType.typeName»«type.typeName»«returnType.typeName»F2<A> f2;

					FolderTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2<A> f2) {
						this.acc = start;
						this.f2 = f2;
					}

					public void apply(final A value) {
						this.acc = this.f2.apply(this.acc, value);
					}
				}

			«ENDFOR»
		«ELSE»
			final class «type.typeName»Folder<A> implements «type.effGenericName» {
				A acc;
				final Object«type.typeName»ObjectF2<A, A> f2;

				«type.typeName»Folder(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
					this.acc = start;
					this.f2 = f2;
				}

				public void apply(final «type.javaName» value) {
					this.acc = this.f2.apply(this.acc, value);
				}
			}

			«FOR returnType : Type.primitives»
				final class «type.typeName»FolderTo«returnType.typeName» implements «type.effGenericName» {
					«returnType.javaName» acc;
					final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2;

					«type.typeName»FolderTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
						this.acc = start;
						this.f2 = f2;
					}

					public void apply(final «type.javaName» value) {
						this.acc = this.f2.apply(this.acc, value);
					}
				}

			«ENDFOR»
		«ENDIF»
	''' }
}