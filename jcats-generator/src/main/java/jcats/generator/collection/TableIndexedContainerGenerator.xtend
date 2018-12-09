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
	def wildcardName() { type.wildcardName("TableIndexedContainer") }
	def fName() { if (type == Type.OBJECT) "IntObjectF<A>" else "Int" + type.typeName + "F" }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.function.«IF type.javaUnboxedType»«type.typeName»«ENDIF»Consumer;
		import java.util.stream.IntStream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		«IF type.primitive»
			import static «Constants.COLLECTION».«type.arrayShortName».*;
		«ENDIF»

		final class «genericName» implements «type.indexedContainerViewGenericName», Serializable {
			private final int size;
			private final «fName» f;

			«shortName»(final int size, final «fName» f) {
				assert (size > 0);
				this.size = size;
				this.f = f;
			}

			@Override
			public int size() {
				return this.size;
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
				«IF type.javaUnboxedType»
					return new Table«type.typeName»Iterator(this.size, this.f);
				«ELSEIF type == Type.OBJECT»
					return new TableIterator<>(this.size, this.f);
				«ELSE»
					return new TableIterator<>(this.size, this.f.toIntObjectF());
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
					return new «type.diamondName("TableIndexedContainer")»(n, this.f);
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
					return new «type.diamondName("TableIndexedContainer")»(this.size - n, this.f);
				}
			}

			«hashcode(type)»

			«indexedEquals(type)»

			«toStr(type)»
		}
	'''
}