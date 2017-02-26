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
		import «Constants.FUNCTION».«type.effShortName»;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;


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
				if (isEmpty()) {
					return «type.seqShortName».empty«type.seqShortName»();
				} else {
					final «type.genericName("SeqBuilder")» builder = «type.seqShortName».builder();
					«IF Type.javaUnboxedTypes.contains(type)»
						final «type.iteratorGenericName» iterator = iterator();
						while (iterator.hasNext()) {
							builder.append(iterator.«type.iteratorNext»());
						} 
					«ELSE»
						builder.appendAll(this);
					«ENDIF»
					return builder.build();		
				}
			}

			default «type.javaName»[] «type.toArrayName»() {
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