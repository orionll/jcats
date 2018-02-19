package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class MaybeGenerator implements InterfaceGenerator {
	val Type type

	override className() { Constants.JCATS + "." + shortName }

	def shortName() { type.maybeShortName }
	def genericName() { type.maybeGenericName }

	def static List<Generator> generators() {
		Type.values.toList.map[new MaybeGenerator(it) as Generator]
	}

	override sourceCode() { '''
		package «Constants.JCATS»;

		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.NoSuchElementException;
		«IF type.javaUnboxedType»
			import java.util.Optional«type.typeName»;
		«ELSE»
			import java.util.Optional;
		«ENDIF»
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;
		import java.util.stream.«type.streamName»;

		import «Constants.COLLECTION».*;
		import «Constants.FUNCTION».*;

		«IF type.javaUnboxedType»
			import static «Constants.JCATS».Empty«type.typeName»Iterator.empty«type.typeName»Iterator;
		«ELSE»
			import static java.util.Collections.emptyIterator;
		«ENDIF»
		import static java.util.Objects.requireNonNull;

		public interface «type.covariantName("Maybe")» extends Iterable<«type.genericBoxedName»>, Sized {
			«IF type == Type.OBJECT»
				A getOrNull();

				default A get() throws NoSuchElementException {
					final A value = getOrNull();
					if (value == null) {
						throw new NoSuchElementException();
					} else {
						return value;
					}
				}

				@Override
				default boolean isEmpty() {
					return (getOrNull() == null);
				}

				@Override
				default boolean isNotEmpty() {
					return (getOrNull() != null);
				}

				@Override
				default int size() {
					return (getOrNull() == null) ? 0 : 1;
				}

				@Override
				default void forEach(final Consumer<? super A> action) {
					final A value = getOrNull();
					if (value != null) {
						action.accept(value);
					}
				}

				default void foreach(final Eff<A> eff) {
					final A value = getOrNull();
					if (value != null) {
						eff.apply(value);
					}
				}
			«ELSE»
				«type.genericName» get() throws NoSuchElementException;

				@Override
				boolean isEmpty();

				default «type.boxedName» getOrNull() {
					return isEmpty() ? null : get();
				}

				@Override
				default boolean isNotEmpty() {
					return !isEmpty();
				}

				@Override
				default int size() {
					return isEmpty() ? 0 : 1;
				}

				@Override
				default void forEach(final Consumer<? super «type.boxedName»> action) {
					if (isNotEmpty()) {
						action.accept(get());
					}
				}

				default void foreach(final «type.effShortName» eff) {
					if (isNotEmpty()) {
						eff.apply(get());
					}
				}
			«ENDIF»

			default <X extends Throwable> «type.genericName» getOrThrow(final F0<X> f) throws X {
				requireNonNull(f);
				«IF type == Type.OBJECT»
					final A value = getOrNull();
					if (value == null) {
						throw f.apply();
					} else {
						return value;
					}
				«ELSE»
					if (isEmpty()) {
						throw f.apply();
					} else {
						return get();
					}
				«ENDIF»
			}

			default boolean contains(final «type.genericName» val) {
				«IF type == Type.OBJECT»
					requireNonNull(val);
					return isNotEmpty() && getOrNull().equals(val);
				«ELSE»
					return isNotEmpty() && (get() == val);
				«ENDIF»
			}

			default boolean exists(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				«IF type == Type.OBJECT»
					return isNotEmpty() && predicate.apply(getOrNull());
				«ELSE»
					return isNotEmpty() && predicate.apply(get());
				«ENDIF»
			}

			«IF type.javaUnboxedType»
				default Optional«type.typeName» toOptional«type.typeName»() {
					return isEmpty() ? Optional«type.typeName».empty() : Optional«type.typeName».of(get());
				}
			«ELSEIF type == Type.OBJECT»
				default Optional<A> toOptional() {
					return Optional.ofNullable(getOrNull());
				}
			«ELSE»
				default Optional<Boolean> toOptional() {
					return isEmpty() ? Optional.empty() : Optional.of(get());
				}
			«ENDIF»

			default «type.containerGenericName» as«type.containerShortName»() {
				return new «type.diamondName("MaybeAsContainer")»(this);
			}

			default «type.stream2GenericName» stream() {
				«IF type == Type.OBJECT»
					final A value = getOrNull();
					return Stream2.from((value == null) ? «type.streamName».empty() : «type.streamName».of(value));
				«ELSE»
					return «type.stream2Name».from(isEmpty() ? «type.streamName».empty() : «type.streamName».of(get()));
				«ENDIF»
			}

			@Override
			default «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return isEmpty() ? empty«type.typeName»Iterator() : new «type.typeName»SingletonIterator(get());
				«ELSEIF type == Type.OBJECT»
					final A value = getOrNull();
					return (value == null) ? emptyIterator() : new SingletonIterator<>(value);
				«ELSE»
					return isEmpty() ? emptyIterator() : new  SingletonIterator<>(get());
				«ENDIF»
			}

			@Override
			default «type.spliteratorGenericName» spliterator() {
				«IF type.javaUnboxedType»
					if (isEmpty()) {
						return Spliterators.«type.emptySpliteratorName»();
					} else {
						return Spliterators.spliterator(new «type.javaUnboxedName»[] { get() }, Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
					}
				«ELSEIF type == Type.OBJECT»
					final A value = getOrNull();
					if (value == null) {
						return Spliterators.emptySpliterator();
					} else {
						return Spliterators.spliterator(new Object[] { value }, Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
					}
				«ELSE»
					if (isEmpty()) {
						return Spliterators.emptySpliterator();
					} else {
						return Spliterators.spliterator(new «type.boxedName»[] { get() }, Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
					}
				«ENDIF»
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class «type.genericName("MaybeAsContainer")» implements «type.containerGenericName» {
			private final «genericName» maybe;

			«shortName»AsContainer(final «genericName» maybe) {
				this.maybe = maybe;
			}

			@Override
			public int size() {
				return this.maybe.size();
			}

			@Override
			public boolean isEmpty() {
				return this.maybe.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return this.maybe.isNotEmpty();
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				this.maybe.forEach(action);
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				this.maybe.foreach(eff);
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				return this.maybe.iterator();
			}

			@Override
			public «type.spliteratorGenericName» spliterator() {
				return this.maybe.spliterator();
			}

			@Override
			public String toString() {
				return this.maybe.toString();
			}
		}
	''' }
}