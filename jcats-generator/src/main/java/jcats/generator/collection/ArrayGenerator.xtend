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
		import java.util.Collection;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.Spliterators;

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
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		«IF Type.javaUnboxedTypes.contains(type)»
			import static «Constants.JCATS».«type.typeName»Option.«type.noneName»;
		«ENDIF»


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
				} else if (array.length == 1) {
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
				} else if (suffix instanceof Sized) {
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
				} else if (prefix instanceof Sized) {
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

			public «genericName» filter(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»BoolF«IF type == Type.OBJECT»<A>«ENDIF» predicate) {
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
					return builder.build();
				}
			}

			public «genericName» take(final int n) {
				if (isEmpty() || n <= 0) {
					return empty«shortName»();
				} else if (n >= array.length) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[n];
					System.arraycopy(array, 0, result, 0, n);
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
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				for (final «type.javaName» value : array) {
					eff.apply(«type.genericCast»value);
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

			«IF type == Type.OBJECT»
				«fillUntil(type, paramGenericName, arrayBuilderName)»

			«ENDIF»
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
				«iterate(type, paramGenericName, arrayBuilderName)»

			«ENDIF»
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
			private static «paramGenericName» sizedToArray(final Iterable<«type.genericBoxedName»> iterable, final int size) {
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
				} else if (iterable instanceof Sized) {
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
		}
	''' }
}
