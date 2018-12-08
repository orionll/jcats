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

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
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
		«IF type.primitive»
			import static «Constants.COLLECTION».«type.arrayShortName».*;
		«ENDIF»

		final class «genericName» implements «type.indexedContainerViewGenericName», Serializable {
			private final int size;
			private final «type.genericName» value;

			«shortName»(final int size, final «type.genericName» value) {
				assert (size > 0);
				this.size = size;
				this.value = value;
			}

			@Override
			public int size() {
				return this.size;
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
			public «type.indexedContainerViewGenericName» limit(final int n) {
				if (n < 0) {
					throw new IndexOutOfBoundsException(Integer.toString(n));
				} else if (n == 0) {
					«IF type == Type.OBJECT»
						return Array.<A>emptyArray().view();
					«ELSE»
						return empty«type.arrayShortName»().view();
					«ENDIF»
				} else if (n >= this.size) {
					return this;
				} else {
					return new «type.diamondName("RepeatedIndexedContainer")»(n, this.value);
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return this;
				} else if (n >= this.size) {
					«IF type == Type.OBJECT»
						return Array.<A>emptyArray().view();
					«ELSE»
						return empty«type.arrayShortName»().view();
					«ENDIF»
				} else {
					return new «type.diamondName("RepeatedIndexedContainer")»(this.size - n, this.value);
				}
			}

			@Override
			public «genericName» reverse() {
				return this;
			}

			«hashcode(type)»

			«indexedEquals(type)»

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