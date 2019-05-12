package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class TableIndexedContainerGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new TableIndexedContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }
	def shortName() { type.shortName("TableIndexedContainer") }
	def genericName() { type.genericName("TableIndexedContainer") }
	def diamondName() { type.diamondName("TableIndexedContainer") }
	def wildcardName() { type.wildcardName("TableIndexedContainer") }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.stream.IntStream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.COLLECTION».«type.indexedContainerViewShortName».*;

		final class «genericName» implements «type.indexedContainerViewGenericName», Serializable {
			private final int size;
			private final «type.intFGenericName» f;

			«shortName»(final int size, final «type.intFGenericName» f) {
				«IF ea»
					assert (size > 0);
				«ENDIF»
				this.size = size;
				this.f = f;
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
				return «type.requireNonNull("this.f.apply(0)")»;
			}

			@Override
			public «type.optionGenericName» firstOption() {
				return «type.someName»(this.f.apply(0));
			}

			@Override
			public «type.genericName» last() {
				return «type.requireNonNull("this.f.apply(this.size - 1)")»;
			}

			@Override
			public «type.optionGenericName» lastOption() {
				return «type.someName»(this.f.apply(this.size - 1));
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index >= 0 && index < this.size) {
					«IF type == Type.OBJECT»
						return requireNonNull(this.f.apply(index));
					«ELSE»
						return this.f.apply(index);
					«ENDIF»
				} else {
					«indexOutOfBounds(shortName)»
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				for (int i = 0; i < this.size; i++) {
					final «type.genericName» value = «type.requireNonNull("this.f.apply(i)")»;
					eff.apply(value);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				for (int i = 0; i < this.size; i++) {
					final «type.genericName» value = «type.requireNonNull("this.f.apply(i)")»;
					if (!eff.apply(value)) {
						return false;
					}
				}
				return true;
			}

			@Override
			public void foreachWithIndex(final «type.intEff2GenericName» eff) {
				requireNonNull(eff);
				for (int i = 0; i < this.size; i++) {
					final «type.genericName» value = «type.requireNonNull("this.f.apply(i)")»;
					eff.apply(i, value);
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type == Type.OBJECT || type.javaUnboxedType»
					return new «type.diamondName("TableIterator")»(this.size, this.f);
				«ELSE»
					return new TableIterator<>(this.size, this.f.toIntObjectF());
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				«IF type == Type.OBJECT || type.javaUnboxedType»
					return new «type.diamondName("ReverseTableIterator")»(this.size, this.f);
				«ELSE»
					return new ReverseTableIterator<>(this.size, this.f.toIntObjectF());
				«ENDIF»
			}

			@Override
			public «type.stream2GenericName» stream() {
				return «type.stream2Name».from(IntStream
					.range(0, this.size)
					«IF type == Type.OBJECT»
						.mapToObj((final int i) -> requireNonNull(this.f.apply(i))));
					«ELSEIF type == Type.INT»
						.map(this.f::apply));
					«ELSEIF type.javaUnboxedType»
						.mapTo«type.boxedName»(this.f::apply));
					«ELSE»
						.mapToObj(this.f::apply));
					«ENDIF»
			}

			@Override
			public «type.stream2GenericName» parallelStream() {
				return stream().parallel();
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
				} else if (fromIndexInclusive == 0) {
					return new «diamondName»(toIndexExclusive, this.f);
				} else {
					return new «diamondName»(toIndexExclusive - fromIndexInclusive,
							i -> this.f.apply(fromIndexInclusive + i));
				}
			}

			@Override
			public «type.indexedContainerViewGenericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return empty«type.indexedContainerViewShortName»();
				} else if (n >= this.size) {
					return this;
				} else {
					return new «diamondName»(n, this.f);
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
					return new «diamondName»(this.size - n, i -> this.f.apply(i + n));
				}
			}

			@Override
			public <«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> IndexedContainerView<«IF type == Type.OBJECT»B«ELSE»A«ENDIF»> map(final «type.fGenericName» g) {
				return new TableIndexedContainer<>(this.size, this.f.map(g));
			}

			«FOR toType : Type.primitives»
				@Override
				public «toType.indexedContainerViewGenericName» mapTo«toType.typeName»(final «IF type.primitive»«type.typeName»«ENDIF»«toType.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» g) {
					return new «toType.diamondName("TableIndexedContainer")»(this.size, this.f.mapTo«toType.typeName»(g));
				}

			«ENDFOR»
			«orderedHashCode(type)»

			«indexedEquals(type)»

			«toStr(type)»
		}
	'''
}