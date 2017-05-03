package jcats.generator.collection

import jcats.generator.Generator
import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import jcats.generator.Type
import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

@FinalFieldsConstructor
class ContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { if (type == Type.OBJECT) "Container" else type.typeName + "Container" }
	def genericName() { if (type == Type.OBJECT) shortName + "<A>" else shortName }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.AbstractCollection;
		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.HashSet;
		import java.util.Iterator;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
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

		public interface «genericName» extends Iterable<«type.genericBoxedName»>, Sized {

			default boolean contains(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF Type.javaUnboxedTypes.contains(type)»
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
				int index = 0;
				«IF Type.javaUnboxedTypes.contains(type)»
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						if (iterator.«type.iteratorNext»() == value) {
							return intSome(index);
						}
						index++;
					}
				«ELSE»
					for (final «type.genericName» a : this) {
						«IF type == Type.OBJECT»
							if (a.equals(value)) {
						«ELSE»
							if (a == value) {
						«ENDIF»
							return intSome(index);
						}
						index++;
					}
				«ENDIF»
				return intNone();
			}

			«IF Type.javaUnboxedTypes.contains(type)»
				default <A> A foldLeft(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					A result = start;
					final «type.iteratorGenericName» iterator = iterator();
					while (iterator.hasNext()) {
						final «type.javaName» value = iterator.«type.iteratorNext»();
						result = requireNonNull(f2.apply(result, value));
					}
					return result;
				}
			«ELSEIF type == Type.BOOL»
				default <A> A foldLeft(final A start, final Object«type.typeName»ObjectF2<A, A> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					A result = start;
					for (final boolean value : this) {
						result = requireNonNull(f2.apply(result, value));
					}
					return result;
				}
			«ELSE»
				default <B> B foldLeft(final B start, final F2<B, A, B> f2) {
					requireNonNull(start);
					requireNonNull(f2);
					B result = start;
					for (final A a : this) {
						result = requireNonNull(f2.apply(result, a));
					}
					return result;
				}
			«ENDIF»

			«IF Type.javaUnboxedTypes.contains(type)»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
						requireNonNull(f2);
						«returnType.javaName» result = start;
						final «type.iteratorGenericName» iterator = iterator();
						while (iterator.hasNext()) {
							final «type.javaName» value = iterator.«type.iteratorNext»();
							result = f2.apply(result, value);
						}
						return result;
					}

				«ENDFOR»
			«ELSEIF type == Type.BOOL»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»«type.typeName»«returnType.typeName»F2 f2) {
						requireNonNull(f2);
						«returnType.javaName» result = start;
						for (final boolean value : this) {
							result = f2.apply(result, value);
						}
						return result;
					}

				«ENDFOR»
			«ELSE»
				«FOR returnType : Type.primitives»
					default «returnType.javaName» foldLeftTo«returnType.typeName»(final «returnType.javaName» start, final «returnType.typeName»Object«returnType.typeName»F2<A> f2) {
						requireNonNull(f2);
						«returnType.javaName» result = start;
						for (final A a : this) {
							result = f2.apply(result, a);
						}
						return result;
					}

				«ENDFOR»
			«ENDIF»
			«IF Type.javaUnboxedTypes.contains(type)»
				default <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSEIF type == Type.BOOL»
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

			«IF Type.javaUnboxedTypes.contains(type)»
				default «type.javaName» sum() {
					return foldLeftTo«type.typeName»(0, Common.SUM_«type.typeName.toUpperCase»);
				}

			«ENDIF»
			default void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				«IF Type.javaUnboxedTypes.contains(type)»
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

			@Override
			default void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				requireNonNull(action);
				foreach(action::accept);
			}

			«IF Type.javaUnboxedTypes.contains(type)»
				@Override
				«type.iteratorGenericName» iterator();

			«ENDIF»
			default «type.iteratorGenericName» reverseIterator() {
				return to«type.arrayShortName»().reverseIterator();
			}

			@Override
			default «type.spliteratorGenericName» spliterator() {
				if (isEmpty()) {
					return Spliterators.«type.emptySpliteratorName»();
				} else {
					return Spliterators.spliterator(iterator(), size(), Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
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
					«IF Type.javaUnboxedTypes.contains(type)»
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

			default «type.streamGenericName» stream() {
				return StreamSupport.«type.streamFunction»(spliterator(), false);
			}

			default «type.streamGenericName» parallelStream() {
				return StreamSupport.«type.streamFunction»(spliterator(), true);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		class «type.genericName("ContainerAsCollection")» extends AbstractCollection<«type.genericBoxedName»> {
			final «genericName» container;

			«shortName»AsCollection(final «genericName» container) {
				this.container = container;
			}

			@Override
			public int size() {
				return container.size();
			}

			«IF type == Type.OBJECT»
				@Override
				public Object[] toArray() {
					return container.toObjectArray();
				}

			«ENDIF»
			@Override
			public Iterator<«type.genericBoxedName»> iterator() {
				return container.iterator();
			}

			@Override
			public Spliterator<«type.genericBoxedName»> spliterator() {
				return container.spliterator();
			}
		}
	''' }
}