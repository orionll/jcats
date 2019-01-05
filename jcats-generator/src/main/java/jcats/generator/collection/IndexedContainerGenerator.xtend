package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class IndexedContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new IndexedContainerGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def baseName() { "IndexedContainer" }
	def shortName() { type.shortName(baseName) }
	def genericName() { type.genericName(baseName) }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		«IF !type.javaUnboxedType»
			import java.util.Collections;
		«ENDIF»
		import java.util.Iterator;
		import java.util.List;
		import java.util.NoSuchElementException;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.function.Consumer;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.io.Serializable;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;
		«IF type != Type.INT && type.javaUnboxedType»
			import static «Constants.JCATS».«type.optionShortName».*;
		«ENDIF»
		«IF type.primitive»
			import static «Constants.COMMON».*;
		«ENDIF»
		import static «Constants.COLLECTION».«type.arrayShortName».*;

		public interface «type.covariantName("IndexedContainer")» extends «type.containerGenericName», «type.indexedGenericName», Equatable<«genericName»> {

			@Override
			default «type.iteratorGenericName» iterator() {
				if (hasKnownFixedSize()) {
					if (isEmpty()) {
						return «type.emptyIterator»;
					} else {
						return new «type.diamondName("IndexedContainerIterator")»(this);
					}
				} else {
					throw new UnsupportedOperationException("Cannot get default Iterator implementation if hasKnownFixedSize() == false");
				}
			}

			@Override
			default «type.iteratorGenericName» reverseIterator() {
				if (hasKnownFixedSize()) {
					if (isEmpty()) {
						return «type.emptyIterator»;
					} else {
						return new «type.diamondName("IndexedContainerReverseIterator")»(this);
					}
				} else {
					return «type.containerShortName».super.reverseIterator();
				}
			}

			@Override
			default void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (hasKnownFixedSize()) {
					final int size = size();
					for (int i = 0; i < size; i++) {
						eff.apply(get(i));
					}
				} else {
					«type.containerShortName».super.foreach(eff);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				default void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				default void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				if (hasKnownFixedSize()) {
					final int size = size();
					for (int i = 0; i < size; i++) {
						eff.apply(i, get(i));
					}
				} else {
					«type.containerShortName».super.foreachWithIndex(eff);
				}
			}

			@Override
			default boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				if (hasKnownFixedSize()) {
					final int size = size();
					for (int i = 0; i < size; i++) {
						if (!eff.apply(get(i))) {
							return false;
						}
					}
					return true;
				} else {
					return «type.containerShortName».super.foreachUntil(eff);
				}
			}

			@Override
			default «type.genericName» first() throws NoSuchElementException {
				try {
					return get(0);
				} catch (final IndexOutOfBoundsException __) {
					throw new NoSuchElementException();
				}
			}

			@Override
			default «type.genericName» last() throws NoSuchElementException {
				if (hasKnownFixedSize()) {
					if (isEmpty()) {
						throw new NoSuchElementException();
					} else {
						return get(size() - 1);
					}
				} else {
					return reverseIterator().«type.iteratorNext»();
				}
			}

			default IntOption indexOf(final «type.genericName» value) throws SizeOverflowException {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type == Type.OBJECT»
					return indexWhere(value::equals);
				«ELSE»
					return indexWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			default IntOption indexWhere(final «type.boolFName» predicate) throws SizeOverflowException {
				requireNonNull(predicate);
				final «type.genericName("IndexFinder")» finder = new «type.diamondName("IndexFinder")»(predicate);
				if (foreachUntil(finder)) {
					return intNone();
				} else {
					return intSome(finder.index);
				}
			}

			default IntOption lastIndexOf(final «type.genericName» value) throws SizeOverflowException {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type == Type.OBJECT»
					return lastIndexWhere(value::equals);
				«ELSE»
					return lastIndexWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			default IntOption lastIndexWhere(final «type.boolFName» predicate) throws SizeOverflowException {
				requireNonNull(predicate);
				if (hasKnownFixedSize()) {
					int index = size() - 1;
					final «type.iteratorGenericName» iterator = reverseIterator();
					while (iterator.hasNext()) {
						if (predicate.apply(iterator.«type.iteratorNext»())) {
							return intSome(index);
						}
						index--;
					}
					return intNone();
				} else {
					final «type.genericName("LastIndexFinder")» finder = new «type.diamondName("LastIndexFinder")»(predicate);
					foreach(finder);
					if (finder.lastIndex < 0) {
						return intNone();
					} else {
						return intSome(finder.lastIndex);
					}
				}
			}

			@Override
			default «type.indexedContainerViewGenericName» view() {
				return new «type.shortName("BaseIndexedContainerView")»<>(this);
			}

			«IF type.primitive»
				@Override
				default IndexedContainerView<«type.boxedName»> asContainer() {
					return new «shortName»AsIndexedContainer(this);
				}

			«ENDIF»
			@Override
			default List<«type.genericBoxedName»> asCollection() {
				return new «shortName»AsList«IF type == Type.OBJECT»<>«ENDIF»(this);
			}

			/**
			 * «equalsDeprecatedJavaDoc»
			 */
			@Override
			@Deprecated
			boolean equals(Object other);

			«IF type == Type.INT»
				static IntIndexedContainer range(final int lowInclusive, final int highExclusive) {
					if (lowInclusive >= highExclusive) {
						return emptyIntArray();
					} else {
						return new Range(lowInclusive, highExclusive, false);
					}
				}

				static IntIndexedContainer rangeClosed(final int lowInclusive, final int highInclusive) {
					if (lowInclusive > highInclusive) {
						return emptyIntArray();
					} else {
						return new Range(lowInclusive, highInclusive, true);
					}
				}

			«ENDIF»
			static «type.paramGenericName("IndexedContainer")» repeat(final int size, final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (size < 0) {
					throw new IllegalArgumentException(Integer.toString(size));
				} else if (size == 0) {
					return empty«type.arrayShortName»();
				} else {
					return new «type.diamondName("RepeatedIndexedContainer")»(size, value);
				}
			}

			static «type.paramGenericName("IndexedContainer")» tabulate(final int size, final Int«type.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
				«IF type == Type.OBJECT»
					requireNonNull(f);
				«ENDIF»
				if (size < 0) {
					throw new IllegalArgumentException(Integer.toString(size));
				} else if (size == 0) {
					return empty«type.arrayShortName»();
				} else {
					return new «type.diamondName("TableIndexedContainer")»(size, f);
				}
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class «type.iteratorGenericName(baseName)» implements «type.iteratorGenericName» {
			private int i;
			private final «genericName» container;
			private final int size;
		
			«type.shortName("IndexedContainerIterator")»(final «genericName» container) {
				this.container = container;
				this.size = container.size();
			}

			@Override
			public boolean hasNext() {
				return (this.i < this.size);
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				try {
					final «type.genericName» next = this.container.get(this.i);
					this.i++;
					return next;
				} catch (final IndexOutOfBoundsException __) {
					throw new NoSuchElementException();
				}
			}
		}

		final class «type.genericName(baseName + "ReverseIterator")» implements «type.iteratorGenericName» {
			private int i;
			private final «genericName» container;

			«type.shortName("IndexedContainerReverseIterator")»(final «genericName» container) {
				this.container = container;
				this.i = container.size() - 1;
			}

			@Override
			public boolean hasNext() {
				return (this.i >= 0);
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				try {
					final «type.genericName» next = this.container.get(this.i);
					this.i--;
					return next;
				} catch (final IndexOutOfBoundsException __) {
					throw new NoSuchElementException();
				}
			}
		}

		«IF type.primitive»
			final class «shortName»AsIndexedContainer extends «type.typeName»ContainerAsContainer<«shortName»> implements IndexedContainerView<«type.boxedName»> {

				«shortName»AsIndexedContainer(final «shortName» container) {
					super(container);
				}

				@Override
				public «type.boxedName» get(final int index) throws IndexOutOfBoundsException {
					return this.container.get(index);
				}

				@Override
				public IntOption indexOf(final «type.boxedName» value) {
					return this.container.indexOf(value);
				}

				@Override
				public IntOption indexWhere(final BooleanF<«type.boxedName»> predicate) {
					return this.container.indexWhere(predicate::apply);
				}

				@Override
				public IntOption lastIndexOf(final «type.boxedName» value) {
					return this.container.lastIndexOf(value);
				}

				@Override
				public IntOption lastIndexWhere(final BooleanF<«type.boxedName»> predicate) {
					return this.container.lastIndexWhere(predicate::apply);
				}

				@Override
				public List<«type.boxedName»> asCollection() {
					return this.container.asCollection();
				}

				«hashcode(Type.OBJECT)»

				«equals(Type.OBJECT, Type.OBJECT.indexedContainerWildcardName, false)»
			}

		«ENDIF»
		final class «type.genericName("IndexedContainerAsList")» extends AbstractImmutableList<«type.genericBoxedName»> implements RandomAccess, Serializable {
			final «genericName» container;

			«shortName»AsList(final «genericName» container) {
				this.container = container;
			}

			@Override
			public «type.genericBoxedName» get(final int index) {
				return this.container.get(index);
			}

			@Override
			public int size() {
				return this.container.size();
			}

			@Override
			public boolean isEmpty() {
				return this.container.isEmpty();
			}

			@Override
			public Object[] toArray() {
				«IF type == Type.OBJECT»
					return this.container.toObjectArray();
				«ELSE»
					return «type.containerShortName.firstToLowerCase»ToArray(this.container);
				«ENDIF»
			}

			@Override
			public Iterator<«type.genericBoxedName»> iterator() {
				return this.container.iterator();
			}

			@Override
			public Spliterator<«type.genericBoxedName»> spliterator() {
				return this.container.spliterator();
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.container.forEach(action);
			}
		}

		final class «type.genericName("IndexFinder")» implements «type.boolFName» {
			int index;
			final «type.boolFName» predicate;
		
			«type.shortName("IndexFinder")»(final «type.boolFName» predicate) {
				this.predicate = predicate;
			}

			@Override
			public boolean apply(final «type.genericName» value) {
				if (this.predicate.apply(value)) {
					return false;
				}
				if (++this.index < 0) {
					throw new SizeOverflowException();
				}
				return true;
			}
		}

		final class «type.genericName("LastIndexFinder")» implements «type.effGenericName» {
			int index;
			int lastIndex = -1;
			final «type.boolFName» predicate;
		
			«type.shortName("LastIndexFinder")»(final «type.boolFName» predicate) {
				this.predicate = predicate;
			}

			@Override
			public void apply(final «type.genericName» value) {
				if (this.predicate.apply(value)) {
					this.lastIndex = this.index;
				}
				if (++this.index < 0) {
					throw new SizeOverflowException();
				}
			}
		}
	'''
}