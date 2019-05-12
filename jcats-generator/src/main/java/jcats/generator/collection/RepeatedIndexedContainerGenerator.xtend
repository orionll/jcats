package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class RepeatedIndexedContainerGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new RepeatedIndexedContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }
	def shortName() { type.shortName("RepeatedIndexedContainer") }
	def genericName() { type.genericName("RepeatedIndexedContainer") }
	def diamondName() { type.diamondName("RepeatedIndexedContainer") }
	def wildcardName() { type.wildcardName("RepeatedIndexedContainer") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Arrays;
		import java.util.Collections;
		import java.util.HashSet;
		import java.util.List;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.NoSuchElementException;
		import java.util.Spliterator;
		import java.util.function.«IF type.javaUnboxedType»«type.typeName»«ENDIF»Consumer;
		import java.util.stream.IntStream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.JCATS».IntOption.*;
		«IF type != Type.INT»
			import static «Constants.JCATS».«type.optionShortName».*;
		«ENDIF»
		«IF type == Type.OBJECT»
			import static «Constants.COLLECTION».Unique.*;
		«ENDIF»
		import static «Constants.COLLECTION».«type.indexedContainerViewShortName».*;

		final class «genericName» implements «type.indexedContainerViewGenericName», Serializable {
			private final int size;
			private final «type.genericName» value;

			«shortName»(final int size, final «type.genericName» value) {
				«IF ea»
					assert (size > 0);
				«ENDIF»
				this.size = size;
				this.value = value;
			}

			@Override
			public int size() {
				return this.size;
			}

			@Override
			public boolean isEmpty() {
				return false;
			}

			@Override
			public boolean isNotEmpty() {
				return true;
			}

			@Override
			public «type.genericName» first() {
				return this.value;
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return «type.someName»(this.value);
			}

			@Override
			public «type.genericName» last() {
				return this.value;
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return «type.someName»(this.value);
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index >= 0 && index < this.size) {
					return this.value;
				} else {
					«indexOutOfBounds(shortName)»
				}
			}

			@Override
			public boolean contains(final «type.genericName» value2) {
				«IF type == Type.OBJECT»
					return value2.equals(this.value);
				«ELSE»
					return value2 == this.value;
				«ENDIF»
			}

			@Override
			public «type.optionGenericName» firstMatch(final «type.boolFName» predicate) {
				if (predicate.apply(this.value)) {
					return «type.someName»(this.value);
				} else {
					return «type.noneName»();
				}
			}

			@Override
			public «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				return firstMatch(predicate);
			}

			@Override
			public boolean anyMatch(final «type.boolFName» predicate) {
				return predicate.apply(this.value);
			}

			@Override
			public boolean allMatch(final «type.boolFName» predicate) {
				return predicate.apply(this.value);
			}

			@Override
			public boolean noneMatch(final «type.boolFName» predicate) {
				return !predicate.apply(this.value);
			}

			@Override
			public IntOption indexOf(final «type.genericName» value2) {
				if (contains(value2)) {
					return intSome(0);
				} else {
					return intNone();
				}
			}

			@Override
			public IntOption lastIndexOf(final «type.genericName» value2) {
				if (contains(value2)) {
					return intSome(this.size - 1);
				} else {
					return intNone();
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				for (int i = 0; i < this.size; i++) {
					eff.apply(this.value);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				for (int i = 0; i < this.size; i++) {
					if (!eff.apply(this.value)) {
						return false;
					}
				}
				return true;
			}

			@Override
			public void foreachWithIndex(final «type.intEff2GenericName» eff) {
				requireNonNull(eff);
				for (int i = 0; i < this.size; i++) {
					eff.apply(i, this.value);
				}
			}

			@Override
			public «type.javaName»[] «type.toArrayName»() {
				final «type.javaName»[] array = new «type.javaName»[this.size];
				Arrays.fill(array, this.value);
				return array;
			}

			«IF type == Type.OBJECT»
				@Override
				public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] array = supplier.apply(this.size);
					Arrays.fill(array, this.value);
					return array;
				}

				@Override
				public Unique<A> toUnique() {
					return singleUnique(this.value);
				}

			«ENDIF»
			@Override
			public HashSet<«type.genericBoxedName»> toHashSet() {
				final HashSet<«type.genericBoxedName»> set = new HashSet<>(1);
				set.add(this.value);
				return set;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("RepeatedIterator")»(this.size, this.value);
				«ELSE»
					return new RepeatedIterator<>(this.size, this.value);
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				«IF type.javaUnboxedType»
					return new «type.diamondName("RepeatedIterator")»(this.size, this.value);
				«ELSE»
					return new RepeatedIterator<>(this.size, this.value);
				«ENDIF»
			}

			@Override
			public «type.stream2GenericName» stream() {
				return «type.stream2Name».from(IntStream.range(0, this.size).map«IF !type.javaUnboxedType»ToObj«ELSEIF type != Type.INT»To«type.boxedName»«ENDIF»(__ -> this.value));
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return «type.stream2Name».from(IntStream.range(0, this.size).parallel().map«IF !type.javaUnboxedType»ToObj«ELSEIF type != Type.INT»To«type.boxedName»«ENDIF»(__ -> this.value));
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				return stream().spliterator();
			}

			@Override
			public «type.indexedContainerViewGenericName» slice(final int fromIndexInclusive, final int toIndexExclusive) {
				sliceRangeCheck(fromIndexInclusive, toIndexExclusive, this.size);
				if (fromIndexInclusive == 0 && toIndexExclusive == this.size) {
					return this;
				} else if (fromIndexInclusive == toIndexExclusive) {
					return empty«type.indexedContainerViewShortName»();
				} else {
					return new «diamondName»(toIndexExclusive - fromIndexInclusive, this.value);
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» limit(final int n) {
				if (n < 0) {
					throw new IndexOutOfBoundsException(Integer.toString(n));
				} else if (n == 0) {
					return empty«type.indexedContainerViewShortName»();
				} else if (n >= this.size) {
					return this;
				} else {
					return new «diamondName»(n, this.value);
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return this;
				} else if (n >= this.size) {
					return empty«type.indexedContainerViewShortName»();
				} else {
					return new «diamondName»(this.size - n, this.value);
				}
			}

			@Override
			public «genericName» reverse() {
				return this;
			}

			«IF type == Type.OBJECT»
				@Override
				public «type.optionGenericName» max(final «type.ordGenericName» ord) {
					requireNonNull(ord);
					return «type.someName»(this.value);
				}

				@Override
				public «type.optionGenericName» min(final «type.ordGenericName» ord) {
					requireNonNull(ord);
					return «type.someName»(this.value);
				}
			«ELSE»
				@Override
				public «type.optionGenericName» max() {
					return «type.someName»(this.value);
				}

				@Override
				public «type.optionGenericName» min() {
					return «type.someName»(this.value);
				}

				@Override
				public «type.optionGenericName» maxByOrd(final «type.ordGenericName» ord) {
					requireNonNull(ord);
					return «type.someName»(this.value);
				}

				@Override
				public «type.optionGenericName» minByOrd(final «type.ordGenericName» ord) {
					requireNonNull(ord);
					return «type.someName»(this.value);
				}
			«ENDIF»

			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» maxBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» maxBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return «type.someName»(this.value);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» maxBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» maxBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return «type.someName»(this.value);
				}

			«ENDFOR»
			@Override
			«IF type == Type.OBJECT»
				public <B extends Comparable<B>> «type.optionGenericName» minBy(final F<A, B> f) {
			«ELSE»
				public <A extends Comparable<A>> «type.optionGenericName» minBy(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				return «type.someName»(this.value);
			}

			«FOR to : Type.primitives»
				@Override
				«IF type == Type.OBJECT»
					public «type.optionGenericName» minBy«to.typeName»(final «to.typeName»F<A> f) {
				«ELSE»
					public «type.optionGenericName» minBy«to.typeName»(final «type.typeName»«to.typeName»F f) {
				«ENDIF»
					requireNonNull(f);
					return «type.someName»(this.value);
				}

			«ENDFOR»
			«IF type.primitive»
				@Override
				public IndexedContainerView<«type.boxedName»> boxed() {
					return new RepeatedIndexedContainer<>(this.size, this.value);
				}

			«ENDIF»
			@Override
			public List<«type.genericBoxedName»> asCollection() {
				return Collections.nCopies(this.size, this.value);
			}

			@Override
			public <«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> IndexedContainerView<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> map(final «type.fGenericName» f) {
				return new RepeatedIndexedContainer<>(this.size, f.apply(this.value));
			}

			«FOR toType : Type.primitives»
				@Override
				public «toType.indexedContainerViewGenericName» mapTo«toType.typeName»(final «IF type.primitive»«type.typeName»«ENDIF»«toType.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
					return new «toType.diamondName("RepeatedIndexedContainer")»(this.size, f.apply(this.value));
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				@Override
				public «type.indexedContainerViewGenericName» sort(final Ord<A> ord) {
					requireNonNull(ord);
					return this;
				}
			«ELSE»
				@Override
				public «type.indexedContainerViewGenericName» sortAsc() {
					return this;
				}

				@Override
				public «type.indexedContainerViewGenericName» sortDesc() {
					return this;
				}
			«ENDIF»

			@Override
			public int hashCode() {
				int pow = 31;
				int sum = 1;
				for (int i = Integer.numberOfLeadingZeros(this.size) + 1; i < Integer.SIZE; i++) {
					sum *= pow + 1;
					pow *= pow;
					if ((this.size << i) < 0) {
						pow *= 31;
						sum = sum * 31 + 1;
					}
				}
				«IF type == Type.OBJECT»
					return pow + sum * this.value.hashCode();
				«ELSE»
					return pow + sum * «type.genericBoxedName».hashCode(this.value);
				«ENDIF»
			}

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «wildcardName») {
					final «wildcardName» other = («wildcardName») obj;
					«IF type == Type.OBJECT»
						return (this.size == other.size) && this.value.equals(other.value);
					«ELSE»
						return (this.size == other.size) && (this.value == other.value);
					«ENDIF»
				} else if (obj instanceof «type.indexedContainerWildcardName») {
					return «type.indexedContainerShortName.firstToLowerCase»sEqual(this, («type.indexedContainerWildcardName») obj);
				} else {
					return false;
				}
			}

			«toStr(type)»
		}
		«IF type == Type.OBJECT || type.javaUnboxedType»

			final class «type.genericName("RepeatedIterator")» implements «type.iteratorGenericName» {
				private final int size;
				private final «type.genericName» value;
				private int i;

				«type.shortName("RepeatedIterator")»(final int size, final «type.genericName» value) {
					this.value = value;
					this.size = size;
				}

				@Override
				public boolean hasNext() {
					return (this.i < this.size);
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (this.i < this.size) {
						this.i++;
						return this.value;
					} else {
						throw new NoSuchElementException();
					}
				}

				@Override
				«IF type.javaUnboxedType»
					public void forEachRemaining(final «type.typeName»Consumer action) {
				«ELSE»
					public void forEachRemaining(final Consumer<? super «type.genericBoxedName»> action) {
				«ENDIF»
					requireNonNull(action);
					while (this.i < this.size) {
						this.i++;
						action.accept(this.value);
					}
				}
			}
		«ENDIF»
	'''
}