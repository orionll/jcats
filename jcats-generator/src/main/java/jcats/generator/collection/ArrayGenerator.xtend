package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.List
import jcats.generator.Generator

@FinalFieldsConstructor
final class ArrayGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ArrayGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Array" else type.typeName + "Array" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }
	def genericCast() { if (type == Type.OBJECT) "(A) " else "" }
	def diamondName() { if (type == Type.OBJECT) "Array<>" else shortName }
	def paramGenericName() { if (type == Type.OBJECT) "<A> Array<A>" else shortName }
	def arrayBuilderName() { if (type == Type.OBJECT) "ArrayBuilder<A>" else shortName + "Builder" }
	def arrayBuilderDiamondName() { if (type == Type.OBJECT) "ArrayBuilder<>" else shortName + "Builder" }
	def fListGenericName() { if (type == Type.OBJECT) "FList<A>" else type.typeName + "FList" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.AbstractList;
		import java.util.ArrayList;
		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Collections;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.HashSet;
		import java.util.List;
		import java.util.NoSuchElementException;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.stream.«type.javaPrefix»Stream;
		«ELSE»
			import java.util.stream.Stream;
		«ENDIF»
		import java.util.stream.StreamSupport;

		import «Constants.F»;
		«IF type == Type.OBJECT»
			import «Constants.F0»;
		«ELSE»
			import «Constants.FUNCTION».«type.typeName»F0;
		«ENDIF»
		«IF type == Type.OBJECT»
			«FOR toType : Type.primitives»
				import «Constants.FUNCTION».«toType.typeName»F;
			«ENDFOR»
			import «Constants.FUNCTION».IntObjectF;
		«ELSE»
			«FOR toType : Type.primitives»
				import «Constants.FUNCTION».«type.typeName»«toType.typeName»F;
			«ENDFOR»
			import «Constants.FUNCTION».«type.typeName»ObjectF;
			«IF type != Type.INT»
				import «Constants.FUNCTION».Int«type.typeName»F;
			«ENDIF»
		«ENDIF»
		«FOR arity : 2 .. Constants.MAX_ARITY»
			import «Constants.F»«arity»;
		«ENDFOR»
		import «Constants.EQUATABLE»;
		import «Constants.JCATS».«IF type != Type.OBJECT»«type.typeName»«ENDIF»Indexed;
		import «Constants.P»;
		«FOR arity : 3 .. Constants.MAX_ARITY»
			import «Constants.P»«arity»;
		«ENDFOR»
		import «Constants.SIZED»;

		import static java.lang.Math.min;
		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static «Constants.ARRAY».emptyArray;
		«FOR toType : Type.primitives.filter[it != type]»
			import static «Constants.COLLECTION».«toType.typeName»Array.empty«toType.typeName»Array;
		«ENDFOR»
		«IF type == Type.OBJECT»
			import static «Constants.FLIST».emptyFList;
		«ELSE»
			import static «Constants.COLLECTION».«type.typeName»FList.empty«type.typeName»FList;
		«ENDIF»
		import static «Constants.F».id;
		import static «Constants.P».p;
		import static «Constants.COMMON».iterableToString;
		import static «Constants.COMMON».iterableHashCode;


		public final class «genericName» implements Iterable<«type.genericBoxedName»>, Equatable<«genericName»>, Sized, «IF type == Type.OBJECT»Indexed<A>«ELSE»«type.typeName»Indexed«ENDIF», Serializable {
			static final «shortName» EMPTY = new «shortName»(new «type.javaName»[0]);

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
				return «genericCast»array[index];
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
				final «type.javaName»[] newArray = new «type.javaName»[array.length + 1];
				System.arraycopy(array, 0, newArray, 1, array.length);
				newArray[0] = value;
				return new «diamondName»(newArray);
			}

			/**
			 * O(size)
			 */
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				final «type.javaName»[] newArray = Arrays.copyOf(array, array.length + 1);
				newArray[array.length] = value;
				return new «diamondName»(newArray);
			}

			static «type.javaName»[] concatArrays(final «type.javaName»[] prefix, final «type.javaName»[] suffix) {
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
						array[i++] = iterator.next«type.javaPrefix»();
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
					final «type.javaName»[] result = Arrays.copyOf(array, array.length + suffixSize);
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
				if (suffix instanceof «shortName») {
					return concat((«genericName») suffix);
				} else if (suffix instanceof Collection<?> && suffix instanceof RandomAccess) {
					final Collection<«type.genericBoxedName»> col = (Collection<«type.genericBoxedName»>) suffix;
					return col.isEmpty() ? this : appendSized(suffix, col.size());
				} else if (suffix instanceof Sized) {
					return appendSized(suffix, ((Sized) suffix).size());
				} else {
					final «type.iteratorGenericName» iterator = «type.getIterator("suffix.iterator()")»;
					if (iterator.hasNext()) {
						final «arrayBuilderName» builder = new «arrayBuilderDiamondName»(array);
						while (iterator.hasNext()) {
							builder.append(iterator.«type.iteratorNext»());
						}
						return builder.build();
					} else {
						return this;
					}
				}
			}

			/**
			 * O(prefix.size + this.size)
			 */
			public «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) {
				if (prefix instanceof «shortName») {
					return ((«genericName») prefix).concat(this);
				} else if (prefix instanceof Collection<?> && prefix instanceof RandomAccess) {
					final Collection<«type.genericBoxedName»> col = (Collection<«type.genericBoxedName»>) prefix;
					return col.isEmpty() ? this : prependSized(prefix, col.size());
				} else if (prefix instanceof Sized) {
					return prependSized(prefix, ((Sized) prefix).size());
				} else {
					final «type.iteratorGenericName» iterator = «type.getIterator("prefix.iterator()")»;
					if (iterator.hasNext()) {
						final «arrayBuilderName» builder = new «arrayBuilderDiamondName»();
						while (iterator.hasNext()) {
							builder.append(iterator.«type.iteratorNext»());
						}
						return builder.build().concat(this);
					} else {
						return this;
					}
				}
			}

			public «genericName» reverse() {
				if (array.length == 0 || array.length == 1) {
					return this;
				} else {
					final «type.javaName»[] newArray = new «type.javaName»[array.length];
					for (int i = 0; i < array.length; i++) {
						newArray[array.length - i - 1] = array[i];
					}
					return new «diamondName»(newArray);
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
					final Object[] newArray = new Object[array.length];
					for (int i = 0; i < array.length; i++) {
						newArray[i] = requireNonNull(f.apply(«type.genericCast»array[i]));
					}
					return new Array<>(newArray);
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
						final «toType.javaName»[] newArray = new «toType.javaName»[array.length];
						for (int i = 0; i < array.length; i++) {
							newArray[i] = f.apply(«type.genericCast»array[i]);
						}
						return new «toType.typeName»Array(newArray);
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
					final ArrayBuilder<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> builder = new ArrayBuilder<>();
					for (final «type.javaName» value : array) {
						builder.appendArray(f.apply(«type.genericCast»value).array);
					}
					return builder.build();
				}
			}

			public «genericName» filter(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»BoolF«IF type == Type.OBJECT»<A>«ENDIF» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return empty«shortName»();
				} else {
					final «arrayBuilderName» builder = new «arrayBuilderDiamondName»();
					for (final «type.javaName» value : array) {
						if (predicate.apply(«type.genericCast»value)) {
							builder.append(«type.genericCast»value);
						}
					}
					return builder.build();
				}
			}

			public «genericName» take(final int n) {
				if (isEmpty() || n <= 0) {
					return empty«shortName»();
				} else if (n >= array.length) {
					return this;
				} else {
					return new «diamondName»(Arrays.copyOf(array, n));
				}
			}

			«takeWhile(false, type)»

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

			«IF type == Type.OBJECT»
				public List<A> asList() {
					return new ArrayAsList<>(this);
				}
			«ELSE»
				public List<«type.genericBoxedName»> asList() {
					return new «type.typeName»IndexedIterableAsList<>(this);
				}
			«ENDIF»

			«toArrayList(type, false)»

			«toHashSet(type, false)»

			«IF type == Type.OBJECT»
				public Seq<A> toSeq() {
					if (array.length == 0) {
						return Seq.emptySeq();
					} else {
						return Seq.seqFromArray(array);
					}
				}
			«ELSE»
				public «type.typeName»Seq to«type.typeName»Seq() {
					if (array.length == 0) {
						return «type.typeName»Seq.empty«type.typeName»Seq();
					} else {
						return «type.typeName»Seq.seqFromArray(array);
					}
				}
			«ENDIF»

			public «type.javaName»[] to«type.javaPrefix»Array() {
				if (array.length == 0) {
					return array;
				} else {
					final «type.javaName»[] newArray = new «type.javaName»[array.length];
					System.arraycopy(array, 0, newArray, 0, array.length);
					return newArray;
				}
			}

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

			/**
			 * Synonym for {@link #«shortName.firstToLowerCase»}
			 */
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			«repeat(type, paramGenericName)»

			«fill(type, paramGenericName)»

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
			private static «paramGenericName» sizedToArray(final Iterable<«type.genericBoxedName»> iterable, final int iterableSize) {
				final «type.javaName»[] array = new «type.javaName»[iterableSize];
				fillArray(array, 0, iterable);
				return new «diamondName»(array);
			}

			public static «paramGenericName» iterableTo«shortName»(final Iterable<«type.genericBoxedName»> iterable) {
				requireNonNull(iterable);
				if (iterable instanceof «shortName») {
					return («genericName») iterable;
				} else if (iterable instanceof Collection<?>) {
					final Collection<«type.genericBoxedName»> col = (Collection<«type.genericBoxedName»>) iterable;
					return col.isEmpty() ? empty«shortName»() : sizedToArray(iterable, col.size());
				} else if (iterable instanceof Sized) {
					return sizedToArray(iterable, ((Sized) iterable).size());
				} else {
					final «type.iteratorGenericName» iterator = «type.getIterator("iterable.iterator()")»;
					if (iterator.hasNext()) {
						final «arrayBuilderName» builder = new «arrayBuilderDiamondName»();
						while (iterator.hasNext()) {
							builder.append(iterator.«type.iteratorNext»());
						}
						return builder.build();
					} else {
						return empty«shortName»();
					}
				}
			}

			/**
			 * Synonym for {@link #iterableTo«shortName»}
			 */
			public static «paramGenericName» fromIterable(final Iterable<«type.genericBoxedName»> iterable) {
				return iterableTo«shortName»(iterable);
			}

			«IF type == Type.OBJECT»
				«join»

			«ENDIF»
			@Override
			public «type.iteratorGenericName» iterator() {
				«IF Type.javaUnboxedTypes.contains(type)»
					return isEmpty() ? Empty«type.typeName»Iterator.empty«type.typeName»Iterator() : new «shortName»Iterator(array);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «shortName»Iterator«IF type == Type.OBJECT»<>«ENDIF»(array);
				«ENDIF»
			}

			@Override
			«IF type == Type.OBJECT»
				public Spliterator<A> spliterator() {
			«ELSEIF type == Type.BOOL»
				public Spliterator<Boolean> spliterator() {
			«ELSE»
				public Spliterator.Of«type.javaPrefix» spliterator() {
			«ENDIF»
				if (isEmpty()) {
					return Spliterators.empty«IF Type.javaUnboxedTypes.contains(type)»«type.javaPrefix»«ENDIF»Spliterator();
				} else {
					return Spliterators.spliterator(«IF type == Type.BOOL»new BoolArrayIterator(array), size()«ELSE»array«ENDIF», Spliterator.ORDERED | Spliterator.IMMUTABLE);
				}
			}

			«stream(type)»

			«parallelStream(type)»

			@Override
			public int hashCode() {
				return Arrays.hashCode(array);
			}

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «shortName») {
					return Arrays.equals(array, ((«shortName») obj).array);
				} else {
					return false;
				}
			}

			«toStr(type)»

			«IF type == Type.OBJECT»
			«zip»

			«zipWith»

			/**
			 * O(size)
			 */
			public Array<P<A, Integer>> zipWithIndex() {
				if (isEmpty()) {
					return emptyArray();
				} else {
					final Object[] result = new Object[array.length];
					for (int i = 0; i < array.length; i++) {
						result[i] = p(array[i], i);
					}
					return new Array<>(result);
				}
			}

			«zipN»
			«zipWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["array" + it + ".isEmpty()"].join(" || ")») {
					return emptyArray();
				} else {
					final int length = «(1 ..< arity).map['''min(array«it».array.length'''].join(", ")», array«arity».array.length«(1 ..< arity).map[")"].join»;
					final Object[] array = new Object[length];
					for (int i = 0; i < length; i++) {
						array[i] = requireNonNull(f.apply(«(1 .. arity).map['''array«it».get(i)'''].join(", ")»));
					}
					return new Array<>(array);
				}
			''']»
			«productN»
			«productWithN[arity | '''
				requireNonNull(f);
				if («(1 .. arity).map["array" + it + ".isEmpty()"].join(" || ")») {
					return emptyArray();
				} else {
					«FOR i : 1 .. arity»
						final Object[] arr«i» = array«i».array;
					«ENDFOR»
					final long size1 = arr1.length;
					«FOR i : 2 .. arity»
						final long size«i» = size«i-1» * arr«i».length;
						if (size«i» != (int) size«i») {
							throw new IndexOutOfBoundsException("Size overflow");
						}
					«ENDFOR»
					final Object[] array = new Object[(int) size«arity»];
					int i = 0;
					«FOR i : 1 .. arity»
						«(1 ..< i).map["\t"].join»for (final Object a«i» : arr«i») {
					«ENDFOR»
						«(1 ..< arity).map["\t"].join»array[i++] = requireNonNull(f.apply(«(1 .. arity).map['''(A«it») a«it»'''].join(", ")»));
					«FOR i : 1 .. arity»
						«(1 ..< arity - i + 1).map["\t"].join»}
					«ENDFOR»
					return new Array<>(array);
				}
			''']»

			«cast(#["A"], #[], #["A"])»

			«ENDIF»
			public static «IF type == Type.OBJECT»<A> «ENDIF»«arrayBuilderName» «shortName.firstToLowerCase»Builder() {
				return new «arrayBuilderDiamondName»();
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»«arrayBuilderName» «shortName.firstToLowerCase»WithCapacity(final int initialCapacity) {
				return new «arrayBuilderDiamondName»(initialCapacity);
			}
		}
		«IF type == Type.OBJECT»

			final class ArrayAsList<A> extends IndexedIterableAsList<A, Array<A>> {
				ArrayAsList(final Array<A> array) {
					super(array);
				}

				@Override
				public Object[] toArray() {
					return iterable.toObjectArray();
				}
			}
		«ENDIF»
	''' }
}
