package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Seq0Generator extends SeqGenerator {

	def static List<Generator> generators() {
		Type.values.toList.map[new Seq0Generator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName + "0" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.NoSuchElementException;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		«IF type.javaUnboxedType»
			import static «Constants.JCATS».«type.typeName»Option.«type.noneName»;
		«ELSE»
			import static java.util.Collections.emptyIterator;
		«ENDIF»
		import static java.util.Objects.requireNonNull;
		«IF type != Type.OBJECT»
			import static jcats.collection.Seq.*;
		«ENDIF»
		import static «Constants.COMMON».*;

		final class «genericName(0)» extends «genericName» {

			static final «wildcardName» EMPTY = new «shortName»0();

			@Override
			public int size() {
				return 0;
			}

			@Override
			public «genericName» init() {
				throw new NoSuchElementException();
			}

			@Override
			public «genericName» tail() {
				throw new NoSuchElementException();
			}

			@Override
			public «type.genericName» get(final int index) {
				«indexOutOfBounds(shortName)»
			}

			@Override
			public «genericName» update(final int index, final «type.endoGenericName» __) {
				throw new IndexOutOfBoundsException(Integer.toString(index));
			}

			@Override
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else {
					return empty«shortName»();
				}
			}

			@Override
			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else {
					return empty«shortName»();
				}
			}

			@Override
			public «genericName» prepend(final «type.genericName» value) {
				return append(value);
			}

			@Override
			public «genericName» append(final «type.genericName» value) {
				final «type.javaName»[] node1 = { «type.requireNonNull("value")» };
				return new «diamondName(1)»(node1);
			}

			@Override
			«genericName» appendSized(final «type.iteratorGenericName» suffix, final int suffixSize) {
				return sizedToSeq(suffix, suffixSize);
			}

			@Override
			«genericName» prependSized(final «type.iteratorGenericName» prefix, final int prefixSize) {
				return sizedToSeq(prefix, prefixSize);
			}

			@Override
			void initSeqBuilder(final «seqBuilderName» builder) {
			}

			«IF type == Type.OBJECT»
				@Override
				void copyToArray(final Object[] array) {
				}
			«ELSE»
				@Override
				public «type.javaName»[] «type.toArrayName»() {
					return «type.emptyArrayName»;
				}
			«ENDIF»

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return «type.noneName»().iterator();
				«ELSE»
					return emptyIterator();
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				«IF type.javaUnboxedType»
					return «type.noneName»().iterator();
				«ELSE»
					return emptyIterator();
				«ENDIF»
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				return true;
			}

			@Override
			public String toString() {
				return "[]";
			}
		}
	''' }
}
