package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OptionGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new OptionGenerator(it) as Generator]
	}

	override className() { Constants.JCATS + "." + shortName }
	
	def shortName() { type.optionShortName }
	def genericName() { type.optionGenericName }
	def diamondName() { type.diamondName("Option") }
	def paramGenericName() { type.paramGenericName("Option") }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.PrimitiveIterator;
		«ELSE»
			import java.util.Iterator;
		«ENDIF»
		import java.util.NoSuchElementException;
		import java.util.Objects;
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.Optional«type.javaPrefix»;
		«ELSE»
			import java.util.Optional;
		«ENDIF»

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;
		«IF type != Type.OBJECT»
			import static «Constants.OPTION».*;
		«ENDIF»
		«IF Type.javaUnboxedTypes.contains(type)»
			import static «Constants.JCATS».Empty«type.typeName»Iterator.empty«type.typeName»Iterator;
		«ELSE»
			import static java.util.Collections.emptyIterator;
		«ENDIF»

		public final class «genericName» implements Equatable<«genericName»>, Iterable<«type.genericBoxedName»>, Sized, Serializable {
			«IF type == Type.OBJECT»
				private static final Option NONE = new Option(null);
			«ELSE»
				private static final «shortName» NONE = new «shortName»(«type.defaultValue»);
			«ENDIF»

			private final «type.genericName» value;

			private «shortName»(final «type.genericName» value) {
				this.value = value;
			}

			@Override
			public int size() {
				«IF type == Type.OBJECT»
					return (value == null) ? 0 : 1;
				«ELSE»
					return (this == NONE) ? 0 : 1;
				«ENDIF»
			}

			public «type.genericName» get() {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return value;
				}
			}

			public «genericName» set(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return isEmpty() ? «type.noneName»() : «type.someName»(value);
			}

			public «type.genericName» getOr(final «type.genericName» other) {
				«IF type == Type.OBJECT»
					requireNonNull(other);
				«ENDIF»
				return isEmpty() ? other : value;
			}

			public «genericName» or(final «genericName» other) {
				requireNonNull(other);
				return isEmpty() ? other : this;
			}

			«IF type == Type.OBJECT»
				public <B> Option<B> map(final F<A, B> f) {
			«ELSE»
				public <A> Option<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return none();
				«IF type == Type.OBJECT»
					} else if (f == F.id()) {
						return (Option) this;
				«ENDIF»
				} else {
					return some(f.apply(value));
				}
			}

			«IF type == Type.OBJECT»
				public <B> Option<B> flatMap(final F<A, Option<B>> f) {
			«ELSE»
				public <A> Option<A> flatMap(final «type.typeName»ObjectF<Option<A>> f) {
			«ENDIF»
				requireNonNull(f);
				return isEmpty() ? none() : f.apply(value);
			}

			public «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return «type.noneName»();
				} else if (predicate.apply(value)) {
					return this;
				} else {
					return «type.noneName»();
				}
			}

			«IF type == Type.OBJECT»
				public Optional<A> toOptional() {
					return Optional.ofNullable(value);
				}
			«ELSEIF type == Type.BOOL»
				public Optional<Boolean> toOptional() {
					return isEmpty() ? Optional.empty() : Optional.of(value);
				}
			«ELSE»
				public Optional«type.javaPrefix» toOptional«type.javaPrefix»() {
					return isEmpty() ? Optional«type.javaPrefix».empty() : Optional«type.javaPrefix».of(value);
				}
			«ENDIF»

			@Override
			public int hashCode() {
				«IF type == Type.OBJECT»
					return Objects.hashCode(value);
				«ELSE»
					return «type.boxedName».hashCode(value);
				«ENDIF»
			}

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «shortName») {
					«IF type == Type.OBJECT»
						return Objects.equals(value, ((Option<?>) obj).value);
					«ELSE»
						final «shortName» other = («shortName») obj;
						return isEmpty() == other.isEmpty() && value == other.value;
					«ENDIF»
				} else {
					return false;
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF Type.javaUnboxedTypes.contains(type)»
					return isEmpty() ? empty«type.typeName»Iterator() : new «type.typeName»SingletonIterator(value);
				«ELSE»
					return isEmpty() ? emptyIterator() : new SingletonIterator<>(value);
				«ENDIF»
			}

			@Override
			public String toString() {
				return isEmpty() ? "«type.shortName("None")»" : "«type.shortName("Some")»(" + value + ")";
			}

			public static «paramGenericName» «type.noneName»() {
				return NONE;
			}

			public static «paramGenericName» «type.someName»(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return new «diamondName»(value);
			}

			«IF type == Type.OBJECT»
				public static <A> Option<A> fromNullable(final A value) {
					return (value == null) ? none() : new Option<>(value);
				}

			«ENDIF»
			«IF type == Type.OBJECT»
				public static <A> Option<A> fromOptional(final Optional<A> optional) {
					return optional.isPresent() ? some(optional.get()) : none();
				}
			«ELSEIF type == Type.BOOL»
				public static «genericName» fromOptional(final Optional<Boolean> optional) {
					return optional.isPresent() ? «type.someName»(optional.get()) : «type.noneName»();
				}
			«ELSE»
				public static «genericName» fromOptional«type.javaPrefix»(final Optional«type.javaPrefix» optional) {
					return optional.isPresent() ? «type.someName»(optional.getAs«type.javaPrefix»()) : «type.noneName»();
				}
			«ENDIF»
			«IF type == Type.OBJECT»

				«productN»
				«productWithN[arity | '''
					requireNonNull(f);
					if («(1 .. arity).map["option" + it + ".isEmpty()"].join(" || ")») {
						return none();
					} else {
						return some(f.apply(«(1 .. arity).map['''option«it».value'''].join(", ")»));
					}
				''']»
				«join»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}