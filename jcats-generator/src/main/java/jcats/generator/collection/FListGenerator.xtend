package jcats.generator.collection

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import jcats.generator.Type
import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Generator
import jcats.generator.Constants

@FinalFieldsConstructor
class FListGenerator implements ClassGenerator {
	val Type type
	
	def static List<Generator> generators() {
		Type.values.toList.map[new FListGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "FList" else type.typeName + "FList" }
	def genericName() { if (type == Type.OBJECT) "FList<A>" else shortName }
	def diamondName() { if (type == Type.OBJECT) "FList<>" else shortName }
	def wildcardName() { if (type == Type.OBJECT) "FList<?>" else shortName }
	def paramGenericName() { if (type == Type.OBJECT) "<A> FList<A>" else shortName }
	def fName() { if (type == Type.OBJECT) "IntObjectF<A>" else "Int" + type.typeName + "F" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
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

		import «Constants.EQUATABLE»;
		import «Constants.F»;
		import «Constants.F0»;
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
		import «Constants.JCATS».«IF type != Type.OBJECT»«type.typeName»«ENDIF»Indexed;
		import «Constants.SIZED»;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».iterableToString;
		import static «Constants.COMMON».iterableHashCode;


		public final class «genericName» implements Iterable<«type.genericBoxedName»>, Equatable<«genericName»>, «IF type == Type.OBJECT»Indexed<A>«ELSE»«type.typeName»Indexed«ENDIF», Sized, RandomAccess {
			private static final «shortName» EMPTY = new «shortName»(0, (__) -> { throw new NoSuchElementException(); }, () -> «IF Type.javaUnboxedTypes.contains(type)»Empty«type.typeName»Iterator.empty«type.javaPrefix»«ELSE»empty«ENDIF»Iterator());

			private final «fName» f;
			private final int size;
			private final F0<«type.iteratorGenericName»> iteratorF0;

			«shortName»(final int size, final «fName» f, final F0<«type.iteratorGenericName»> iteratorF0) {
				this.size = size;
				this.f = f;
				this.iteratorF0 = iteratorF0;
			}

			«shortName»(final int size, final «fName» f) {
				this(size, f, () -> new «shortName»Iterator«IF type == Type.OBJECT»<>«ENDIF»(f, size));
			}

			@Override
			public int size() {
				return size;
			}

			@Override
			public «type.genericName» get(final int index) {
				if (index < 0 || index >= size) {
					throw new IndexOutOfBoundsException(Integer.toString(index));
				} else {
					«IF type == Type.OBJECT»
						return requireNonNull(f.apply(index));
					«ELSE»
						return f.apply(index);
					«ENDIF»
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return iteratorF0.apply();
			}

			«IF type == Type.OBJECT»
				public <B> FList<B> map(final F<A, B> function) {
			«ELSE»
				public <A> FList<A> map(final «type.typeName»ObjectF<A> function) {
			«ENDIF»
				return new FList<>(size, f.map(function));
			}

			«spliterator(type)»

			«stream(type)»

			«parallelStream(type)»

			«hashcode(type.genericBoxedName)»

			«equals(type, wildcardName)»

			«toStr(type)»

			public static «paramGenericName» tabulate(final int size, final «fName» f) {
				requireNonNull(f);
				if (size < 0) {
					throw new IndexOutOfBoundsException(Integer.toString(size));
				}
				return new «diamondName»(size, f);
			}

			public static «paramGenericName» empty«shortName»() {
				return EMPTY;
			}
			«IF type == Type.INT»

			public static «genericName» fromTo(final int from, final int to) {
				return new «diamondName»((to >= from) ? to - from + 1 : 0, i -> from + i);
			}

			public static «genericName» fromUntil(final int from, final int until) {
				return new «diamondName»((until > from) ? until - from : 0, i -> from + i);
			}
			«ENDIF»
		}
		
		final class «shortName»Iterator«IF type == Type.OBJECT»<A>«ENDIF» implements «type.iteratorGenericName» {
			private final «fName» f;
			private final int size;
			private int i;

			public «shortName»Iterator(final «fName» f, final int size) {
				this.f = f;
				this.size = size;
			}

			@Override
			public boolean hasNext() {
				return i < size;
			}

			@Override
			public «type.genericJavaUnboxedName» «type.iteratorNext»() {
				if (i < size) {
					«IF type == Type.OBJECT»
						return requireNonNull(f.apply(i++));
					«ELSE»
						return f.apply(i++);
					«ENDIF»
				} else {
					throw new NoSuchElementException();
				}
			}
		}
	'''}
}