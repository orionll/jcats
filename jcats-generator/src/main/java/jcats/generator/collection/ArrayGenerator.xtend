package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class ArrayGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ArrayGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.arrayShortName }
	def genericName() { type.arrayGenericName }
	def diamondName() { type.diamondName("Array") }
	def paramGenericName() { type.paramGenericName("Array") }
	def arrayBuilderName() { type.genericName("ArrayBuilder") }
	def arrayBuilderDiamondName() { type.diamondName("ArrayBuilder") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Arrays;
		import java.util.Iterator;
		import java.util.Collection;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.stream.Collector;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.lang.Math.min;
		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static «Constants.ARRAY».emptyArray;
		«FOR toType : Type.primitives.filter[it != type]»
			import static «Constants.COLLECTION».«toType.typeName»Array.empty«toType.typeName»Array;
		«ENDFOR»
		import static «Constants.F».id;
		import static «Constants.JCATS».Int«type.typeName»P.*;
		import static «Constants.COMMON».*;
		«IF Type.javaUnboxedTypes.contains(type)»
			import static «Constants.JCATS».«type.typeName»Option.*;
		«ENDIF»
		import static «Constants.JCATS».IntOption.*;


		public final class «genericName» implements «type.indexedContainerGenericName», Serializable {
			static final «shortName» EMPTY = new «shortName»(«type.emptyArrayName»);

			final «type.javaName»[] array;

			«shortName»(final «type.javaName»[] array) {
				this.array = array;
			}

			/**
			 * O(1)
			 */
			@Override
			public int size() {
				return array.length;
			}

			/**
			 * O(1)
			 */
			public «type.genericName» head() {
				return get(0);
			}

			/**
			 * O(1)
			 */
			public «type.genericName» last() {
				return get(array.length - 1);
			}

			/**
			 * O(1)
			 */
			@Override
			public «type.genericName» get(final int index) {
				return «type.genericCast»array[index];
			}

			/**
			 * O(size)
			 */
			public «genericName» set(final int index, final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				final «type.javaName»[] result = array.clone();
				result[index] = value;
				return new «diamondName»(result);
			}

			/**
			 * O(size)
			 */
			public «genericName» prepend(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				final «type.javaName»[] result = new «type.javaName»[array.length + 1];
				System.arraycopy(array, 0, result, 1, array.length);
				result[0] = value;
				return new «diamondName»(result);
			}

			/**
			 * O(size)
			 */
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				final «type.javaName»[] result = new «type.javaName»[array.length + 1];
				System.arraycopy(array, 0, result, 0, array.length);
				result[array.length] = value;
				return new «diamondName»(result);
			}

			public «genericName» removeAt(final int index) {
				if (index < 0 || index >= array.length) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				} else {
					return remove(index);
				}
			}

			public «genericName» removeFirstWhere(final «type.boolFName» predicate) {
				final IntOption index = indexWhere(predicate);
				if (index.isEmpty()) {
					return this;
				} else {
					return remove(index.get());
				}
			}

			public «genericName» removeFirst(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return removeFirstWhere(value::equals);
				«ELSE»
					return removeFirstWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			public «genericName» removeLastWhere(final «type.boolFName» predicate) {
				final IntOption index = lastIndexWhere(predicate);
				if (index.isEmpty()) {
					return this;
				} else {
					return remove(index.get());
				}
			}

			public «genericName» removeLast(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return removeLastWhere(value::equals);
				«ELSE»
					return removeLastWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			private «genericName» remove(final int index) {
				if (array.length == 1) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] result = new «type.javaName»[array.length - 1];
					System.arraycopy(array, 0, result, 0, index);
					System.arraycopy(array, index + 1, result, index, array.length - index - 1);
					return new «diamondName»(result);
				}
			}

			private static «type.javaName»[] concatArrays(final «type.javaName»[] prefix, final «type.javaName»[] suffix) {
				final «type.javaName»[] result = new «type.javaName»[prefix.length + suffix.length];
				System.arraycopy(prefix, 0, result, 0, prefix.length);
				System.arraycopy(suffix, 0, result, prefix.length, suffix.length);
				return result;
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public «genericName» concat(final «genericName» suffix) {
				«IF type == Type.OBJECT»
					requireNonNull(suffix);
				«ENDIF»
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					return new «diamondName»(concatArrays(array, suffix.array));
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillArray(final «type.javaName»[] array, final int startIndex, final Iterable<«type.genericBoxedName»> iterable) {
				int i = startIndex;
				«IF Type.javaUnboxedTypes.contains(type)»
					final «type.iteratorGenericName» iterator = «type.getIterator("iterable.iterator()")»;
					while (iterator.hasNext()) {
						array[i++] = iterator.next«type.typeName»();
					}
				«ELSE»
					for (final «type.genericName» value : iterable) {
						«IF type == Type.OBJECT»
							array[i++] = requireNonNull(value);
						«ELSE»
							array[i++] = value;
						«ENDIF»
					}
				«ENDIF»
			}

			private «genericName» appendSized(final Iterable<«type.genericBoxedName»> suffix, final int suffixSize) {
				if (suffixSize == 0) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[array.length + suffixSize];
					System.arraycopy(array, 0, result, 0, array.length);
					fillArray(result, array.length, suffix);
					return new «diamondName»(result);
				}
			}

			private «genericName» prependSized(final Iterable<«type.genericBoxedName»> prefix, final int prefixSize) {
				if (prefixSize == 0) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[prefixSize + array.length];
					fillArray(result, 0, prefix);
					System.arraycopy(array, 0, result, prefixSize, array.length);
					return new «diamondName»(result);
				}
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> suffix) {
				if (array.length == 0) {
					return ofAll(suffix);
				} else if (suffix instanceof «shortName») {
					return concat((«genericName») suffix);
				} else if (suffix instanceof Sized && ((Sized) suffix).hasFixedSize()) {
					return appendSized(suffix, ((Sized) suffix).size());
				} else {
					final «arrayBuilderName» builder;
					if (suffix instanceof Collection) {
						final Collection<?> col = (Collection<?>) suffix;
						if (col.isEmpty()) {
							return this;
						} else {
							final int suffixSize = col.size();
							builder = builderWithCapacity(array.length + suffixSize);
							builder.appendArray(array);
						}
					} else {
						builder = new «arrayBuilderDiamondName»(array, array.length);
					}
					suffix.forEach(builder::append);
					return builder.build();
				}
			}

			/**
			 * O(prefix.size + this.size)
			 */
			public «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) {
				if (array.length == 0) {
					return ofAll(prefix);
				} else if (prefix instanceof «shortName») {
					return ((«genericName») prefix).concat(this);
				} else if (prefix instanceof Sized && ((Sized) prefix).hasFixedSize()) {
					return prependSized(prefix, ((Sized) prefix).size());
				} else {
					final «arrayBuilderName» builder;
					if (prefix instanceof Collection) {
						final Collection<?> col = (Collection<?>) prefix;
						if (col.isEmpty()) {
							return this;
						} else {
							final int prefixSize = col.size();
							builder = builderWithCapacity(prefixSize + array.length);
						}
					} else {
						builder = builder();
					}
					prefix.forEach(builder::append);
					builder.appendArray(array);
					return builder.build();
				}
			}

			public final «genericName» slice(final int fromIndex, final int toIndex) {
				sliceRangeCheck(fromIndex, toIndex, array.length);
				if (fromIndex == 0 && toIndex == array.length) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[toIndex - fromIndex];
					System.arraycopy(array, fromIndex, result, 0, toIndex - fromIndex);
					return new «diamondName»(result);
				}
			}

			public «genericName» reverse() {
				if (array.length == 0 || array.length == 1) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[array.length];
					for (int i = 0; i < array.length; i++) {
						result[array.length - i - 1] = array[i];
					}
					return new «diamondName»(result);
				}
			}

			«IF type == Type.OBJECT»
				public <B> Array<B> map(final F<A, B> f) {
			«ELSE»
				public <A> Array<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptyArray();
				«IF type == Type.OBJECT»
					} else if (f == F.id()) {
						return (Array<B>) this;
				«ENDIF»
				} else {
					final Object[] result = new Object[array.length];
					for (int i = 0; i < array.length; i++) {
						result[i] = requireNonNull(f.apply(«type.genericCast»array[i]));
					}
					return new Array<>(result);
				}
			}

			«FOR toType : Type.primitives»
				public «toType.typeName»Array mapTo«toType.typeName»(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»«toType.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
					requireNonNull(f);
					if (isEmpty()) {
						return empty«toType.typeName»Array();
					«IF type == toType»
					} else if (f == «type.typeName»«type.typeName»F.id()) {
						return this;
					«ENDIF»
					} else {
						final «toType.javaName»[] result = new «toType.javaName»[array.length];
						for (int i = 0; i < array.length; i++) {
							result[i] = f.apply(«type.genericCast»array[i]);
						}
						return new «toType.typeName»Array(result);
					}
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				public <B> Array<B> flatMap(final F<A, Array<B>> f) {
			«ELSE»
				public <A> Array<A> flatMap(final «type.typeName»ObjectF<Array<A>> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptyArray();
				} else {
					«IF type == Type.OBJECT»
						final ArrayBuilder<B> builder = builder();
					«ELSE»
						final ArrayBuilder<A> builder = Array.builder();
					«ENDIF»
					for (final «type.javaName» value : array) {
						builder.appendArray(f.apply(«type.genericCast»value).array);
					}
					return builder.build();
				}
			}

			public «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return empty«shortName»();
				} else {
					final «arrayBuilderName» builder = builder();
					for (final «type.javaName» value : array) {
						if (predicate.apply(«type.genericCast»value)) {
							builder.append(«type.genericCast»value);
						}
					}
					if (builder.size() == array.length) {
						return this;
					} else {
						return builder.build();
					}
				}
			}

			«IF type == Type.OBJECT»
				public <B> Array<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (Array<B>) filter(clazz::isInstance);
				}

			«ENDIF»
			public «genericName» take(final int n) {
				if (n <= 0) {
					return empty«shortName»();
				} else if (n >= array.length) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[n];
					System.arraycopy(array, 0, result, 0, n);
					return new «diamondName»(result);
				}
			}

			public «genericName» drop(final int n) {
				if (n >= array.length) {
					return empty«shortName»();
				} else if (n <= 0) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[array.length - n];
					System.arraycopy(array, n, result, 0, result.length);
					return new «diamondName»(result);
				}
			}

			«takeWhile(false, type)»

			@Override
			public boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				for (final «type.javaName» a : array) {
					«IF type == Type.OBJECT»
						if (a.equals(value)) {
					«ELSE»
						if (a == value) {
					«ENDIF»
						return true;
					}
				}
				return false;
			}

			@Override
			public IntOption indexOf(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				int index = 0;
				for (final «type.javaName» a : array) {
					«IF type == Type.OBJECT»
						if (a.equals(value)) {
					«ELSE»
						if (a == value) {
					«ENDIF»
						return intSome(index);
					}
					index++;
				}
				return intNone();
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				for (final «type.javaName» value : array) {
					eff.apply(«type.genericCast»value);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				for (int i = 0; i < array.length; i++) {
					eff.apply(i, «type.genericCast»array[i]);
				}
			}

			@Override
			public void foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				for (final «type.javaName» value : array) {
					if (!eff.apply(«type.genericCast»value)) {
						return;
					}
				}
			}

			@Override
			@Deprecated
			public «type.arrayGenericName» to«type.arrayShortName»() {
				return this;
			}

			«IF type == Type.OBJECT»
				@Override
				public Seq<A> toSeq() {
					if (array.length == 0) {
						return Seq.emptySeq();
					} else {
						return Seq.seqFromArray(array);
					}
				}
			«ELSE»
				@Override
				public «type.typeName»Seq to«type.typeName»Seq() {
					if (array.length == 0) {
						return «type.typeName»Seq.empty«type.typeName»Seq();
					} else {
						return «type.typeName»Seq.seqFromArray(array);
					}
				}
			«ENDIF»

			@Override
			public «type.javaName»[] «type.toArrayName»() {
				if (array.length == 0) {
					return array;
				} else {
					final «type.javaName»[] result = new «type.javaName»[array.length];
					System.arraycopy(array, 0, result, 0, array.length);
					return result;
				}
			}
			«IF type == Type.OBJECT»

				@Override
				public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] result = supplier.apply(array.length);
					System.arraycopy(array, 0, result, 0, array.length);
					return result;
				}
			«ENDIF»

			public static «paramGenericName» empty«shortName»() {
				return EMPTY;
			}

			public static «paramGenericName» single«shortName»(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return new «diamondName»(new «type.javaName»[] { value });
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» «shortName.firstToLowerCase»(final «type.genericName»... values) {
				if (values.length == 0) {
					return empty«shortName»();
				} else {
					«IF type == Type.OBJECT»
						for (final Object a : values) {
							requireNonNull(a);
						}
					«ENDIF»
					final «type.javaName»[] array = new «type.javaName»[values.length];
					System.arraycopy(values, 0, array, 0, values.length);
					return new «diamondName»(array);
				}
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			«repeat(type, paramGenericName)»

			«fill(type, paramGenericName)»

			«fillUntil(type, paramGenericName, arrayBuilderName)»

			public static «paramGenericName» tabulate(final int size, final Int«type.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
				requireNonNull(f);
				if (size <= 0) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] array = new «type.javaName»[size];
					for (int i = 0; i < size; i++) {
						«IF type == Type.OBJECT»
							array[i] = requireNonNull(f.apply(i));
						«ELSE»
							array[i] = f.apply(i);
						«ENDIF»
					}
					return new «diamondName»(array);
				}
			}

			«iterate(type, paramGenericName, arrayBuilderName)»

			«IF type == Type.OBJECT»
				public static Array<Character> stringToCharArray(final String str) {
					if (str.isEmpty()) {
						return emptyArray();
					} else {
						final Object[] array = new Object[str.length()];
						for (int i = 0; i < str.length(); i++) {
							array[i] = str.charAt(i);
						}
						return new Array<>(array);
					}
				}

			«ENDIF»
			static «paramGenericName» sizedToArray(final Iterable<«type.genericBoxedName»> iterable, final int size) {
				if (size == 0) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] array = new «type.javaName»[size];
					fillArray(array, 0, iterable);
					return new «diamondName»(array);
				}
			}

			public static «paramGenericName» ofAll(final Iterable<«type.genericBoxedName»> iterable) {
				if (iterable instanceof «type.containerShortName») {
					return ((«type.containerGenericName») iterable).to«type.arrayShortName»();
				} else if (iterable instanceof Sized && ((Sized) iterable).hasFixedSize()) {
					return sizedToArray(iterable, ((Sized) iterable).size());
				«IF type == Type.OBJECT»
					} else if (iterable instanceof Collection) {
						final Object[] array = ((Collection<?>) iterable).toArray();
						if (array.length == 0) {
							return emptyArray();
						} else {
							for (final Object value : array) {
								requireNonNull(value);
							}
							return new Array<>(array);
						}
				«ENDIF»
				} else {
					final «arrayBuilderName» builder = builder();
					iterable.forEach(builder::append);
					return builder.build();
				}
			}

			public static «paramGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				«IF Type.javaUnboxedTypes.contains(type)»
					requireNonNull(iterator);
				«ENDIF»
				final «arrayBuilderName» builder = builder();
				«IF Type.javaUnboxedTypes.contains(type)»
					«type.typeName»Iterator.getIterator(iterator).forEachRemaining((«type.typeName»Consumer) builder::append);
				«ELSE»
					iterator.forEachRemaining(builder::append);
				«ENDIF»
				return builder.build();
			}

			«IF type == Type.OBJECT»
				«join»

			«ENDIF»
			@Override
			public «type.iteratorGenericName» iterator() {
				«IF Type.javaUnboxedTypes.contains(type)»
					return isEmpty() ? «type.noneName»().iterator() : new «shortName»Iterator(array);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «shortName»Iterator«IF type == Type.OBJECT»<>«ENDIF»(array);
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				«IF Type.javaUnboxedTypes.contains(type)»
					return isEmpty() ? «type.noneName»().iterator() : new «shortName»ReverseIterator(array);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «shortName»ReverseIterator«IF type == Type.OBJECT»<>«ENDIF»(array);
				«ENDIF»
			}

			@Override
			«IF type == Type.OBJECT»
				public Spliterator<A> spliterator() {
			«ELSEIF type == Type.BOOLEAN»
				public Spliterator<Boolean> spliterator() {
			«ELSE»
				public Spliterator.Of«type.typeName» spliterator() {
			«ENDIF»
				if (isEmpty()) {
					return Spliterators.«type.emptySpliteratorName»();
				} else {
					return Spliterators.spliterator(«IF type == Type.BOOLEAN»new BooleanArrayIterator(array), size()«ELSE»array«ENDIF», Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
				}
			}

			@Override
			public int hashCode() {
				return Arrays.hashCode(array);
			}

			«equals(type, type.indexedContainerWildcardName, false)»

			public boolean isStrictlyEqualTo(final «genericName» other) {
				if (other == this) {
					return true;
				} else {
					return Arrays.equals(array, other.array);
				}
			}

			«toStr(type, false)»

			«IF type == Type.OBJECT»
				public <B> Array<P<A, B>> zip(final Container<B> that) {
					return zipWith(that, P::p);
				}

				public <B, C> Array<C> zipWith(final Container<B> that, final F2<A, B, C> f) {
					requireNonNull(f);
					if (isEmpty() || that.isEmpty()) {
						return emptyArray();
					} else {
						final Object[] result = new Object[min(array.length, that.size())];
						final Iterator<B> iterator = that.iterator();
						for (int i = 0; i < result.length; i++) {
							result[i] = requireNonNull(f.apply((A) array[i], iterator.next()));
						}
						return new Array<>(result);
					}
				}

				public Array<IntObjectP<A>> zipWithIndex() {
					if (isEmpty()) {
						return emptyArray();
					} else {
						final Object[] result = new Object[array.length];
						for (int i = 0; i < array.length; i++) {
							result[i] = intObjectP(i, array[i]);
						}
						return new Array<>(result);
					}
				}
			«ELSE»
				public <A> Array<«type.typeName»ObjectP<A>> zip(final Container<A> that) {
					return zipWith(that, «type.typeName»ObjectP::«type.typeName.firstToLowerCase»ObjectP);
				}

				public <A, B> Array<B> zipWith(final Container<A> that, final «type.typeName»ObjectObjectF2<A, B> f) {
					requireNonNull(f);
					if (isEmpty() || that.isEmpty()) {
						return emptyArray();
					} else {
						final Object[] result = new Object[min(array.length, that.size())];
						final Iterator<A> iterator = that.iterator();
						for (int i = 0; i < result.length; i++) {
							result[i] = requireNonNull(f.apply(array[i], iterator.next()));
						}
						return new Array<>(result);
					}
				}

				public Array<Int«type.typeName»P> zipWithIndex() {
					if (isEmpty()) {
						return emptyArray();
					} else {
						final Object[] result = new Object[array.length];
						for (int i = 0; i < array.length; i++) {
							result[i] = int«type.typeName»P(i, array[i]);
						}
						return new Array<>(result);
					}
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				«cast(#["A"], #[], #["A"])»

			«ENDIF»
			public static «IF type == Type.OBJECT»<A> «ENDIF»«arrayBuilderName» builder() {
				return new «arrayBuilderDiamondName»(«type.emptyArrayName», 0);
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»«arrayBuilderName» builderWithCapacity(final int initialCapacity) {
				if (initialCapacity == 0) {
					return builder();
				} else {
					return new «arrayBuilderDiamondName»(new «type.javaName»[initialCapacity], 0);
				}
			}
			«IF type == Type.OBJECT»

				public static <A> Collector<A, ArrayBuilder<A>, Array<A>> collector() {
					return Collector.of(Array::builder, ArrayBuilder::append, ArrayBuilder::appendArrayBuilder, ArrayBuilder::build);
				}
			«ENDIF»
		}
	''' }
}
