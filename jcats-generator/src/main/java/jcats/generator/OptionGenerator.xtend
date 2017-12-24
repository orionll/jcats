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
		«IF type == Type.OBJECT»
			import java.util.Objects;
		«ELSE»
			import java.util.NoSuchElementException;
		«ENDIF»
		«IF Type.javaUnboxedTypes.contains(type)»
			import java.util.Optional«type.typeName»;
		«ELSE»
			import java.util.Optional;
		«ENDIF»

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF type == Type.OBJECT»
			import static «Constants.F».id;
		«ELSE»
			import static «Constants.FUNCTION».«type.typeName»«type.typeName»F.id;
		«ENDIF»
		«IF type != Type.OBJECT»
			import static «Constants.OPTION».*;
		«ENDIF»
		«FOR returnType : Type.primitives»
			«IF type != returnType»
				import static «Constants.JCATS».«returnType.optionShortName».*;
			«ENDIF»
		«ENDFOR»

		public final class «type.covariantName("Option")» implements «type.maybeGenericName», Equatable<«genericName»>, Serializable {
			«IF type == Type.OBJECT»
				private static final Option<?> NONE = new Option<>(null);
			«ELSE»
				private static final «shortName» NONE = new «shortName»(«type.defaultValue»);
			«ENDIF»
			«IF type == Type.BOOLEAN»
				private static final «shortName» FALSE = new «shortName»(false);
				private static final «shortName» TRUE = new «shortName»(true);
			«ENDIF»

			final «type.genericName» value;

			private «shortName»(final «type.genericName» value) {
				this.value = value;
			}

			«IF type == Type.OBJECT»
				@Override
				public boolean isEmpty() {
					return (this.value == null);
				}

				@Override
				public boolean isNotEmpty() {
					return (this.value != null);
				}
			«ELSE»
				@Override
				public boolean isEmpty() {
					return (this == NONE);
				}

				@Override
				public boolean isNotEmpty() {
					return (this != NONE);
				}

				@Override
				public «type.genericName» get() {
					if (isEmpty()) {
						throw new NoSuchElementException();
					} else {
						return this.value;
					}
				}
			«ENDIF»

			public «genericName» set(final «type.genericName» newValue) {
				«IF type == Type.OBJECT»
					requireNonNull(newValue);
				«ENDIF»
				return isEmpty() ? «type.noneName»() : «type.someName»(newValue);
			}

			public «type.genericName» getOr(final «type.genericName» other) {
				«IF type == Type.OBJECT»
					requireNonNull(other);
				«ENDIF»
				return isEmpty() ? other : this.value;
			}

			public «type.genericName» getOrElse(final «type.f0GenericName» other) {
				requireNonNull(other);
				return isEmpty() ? other.apply() : this.value;
			}

			«IF type == Type.OBJECT»
				@Override
				public «type.genericName» getOrNull() {
					return this.value;
				}

			«ENDIF»
			public «genericName» or(final «genericName» other) {
				requireNonNull(other);
				return isEmpty() ? other : this;
			}

			public «genericName» orElse(final F0<«genericName»> other) {
				requireNonNull(other);
				return isEmpty() ? other.apply() : this;
			}

			public void ifEmpty(final Eff0 eff) {
				requireNonNull(eff);
				if (isEmpty()) {
					eff.apply();
				}
			}

			public void ifNotEmpty(final «type.effGenericName» eff) {
				requireNonNull(eff);
				if (isNotEmpty()) {
					eff.apply(this.value);
				}
			}

			public void ifNotEmptyOrElse(final «type.effGenericName» ifNotEmpty, final Eff0 ifEmpty) {
				requireNonNull(ifNotEmpty);
				requireNonNull(ifEmpty);
				if (isEmpty()) {
					ifEmpty.apply();
				} else {
					ifNotEmpty.apply(this.value);
				}
			}

			«IF type == Type.OBJECT»
				public <B> B match(final F<A, B> ifNotEmpty, final F0<B> ifEmpty) {
			«ELSE»
				public <A> A match(final «type.typeName»ObjectF<A> ifNotEmpty, final F0<A> ifEmpty) {
			«ENDIF»
				requireNonNull(ifNotEmpty);
				requireNonNull(ifEmpty);
				if (isEmpty()) {
					return ifEmpty.apply();
				} else {
					return ifNotEmpty.apply(this.value);
				}
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
					} else if (f == id()) {
						return (Option<B>) this;
				«ENDIF»
				} else {
					return some(f.apply(this.value));
				}
			}

			«IF type == Type.OBJECT»
				public <B> Option<B> mapToNullable(final F<A, B> f) {
			«ELSE»
				public <A> Option<A> mapToNullable(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return none();
				«IF type == Type.OBJECT»
					} else if (f == id()) {
						return (Option<B>) this;
				«ENDIF»
				} else {
					return fromNullable(f.apply(this.value));
				}
			}

			«FOR returnType : Type.primitives»
				«IF type == Type.OBJECT»
					public «returnType.typeName»Option mapTo«returnType.typeName»(final «returnType.typeName»F<A> f) {
						requireNonNull(f);
						return isEmpty() ? «returnType.noneName»() : «returnType.someName»(f.apply(this.value));
					}
				«ELSE»
					public «returnType.typeName»Option mapTo«returnType.typeName»(final «type.typeName»«returnType.typeName»F f) {
						requireNonNull(f);
						if (isEmpty()) {
							return «returnType.noneName»();
						«IF returnType == type»
							} else if (f == id()) {
								return this;
						«ENDIF»
						} else {
							return «returnType.someName»(f.apply(this.value));
						}
					}
				«ENDIF»

			«ENDFOR»
			«IF type == Type.OBJECT»
				public <B> Option<B> flatMap(final F<A, Option<B>> f) {
			«ELSE»
				public <A> Option<A> flatMap(final «type.typeName»ObjectF<Option<A>> f) {
			«ENDIF»
				requireNonNull(f);
				return isEmpty() ? none() : f.apply(this.value);
			}

			public «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return «type.noneName»();
				} else if (predicate.apply(this.value)) {
					return this;
				} else {
					return «type.noneName»();
				}
			}

			public boolean contains(final «type.genericName» val) {
				«IF type == Type.OBJECT»
					requireNonNull(val);
					return isNotEmpty() && this.value.equals(val);
				«ELSE»
					return isNotEmpty() && (this.value == val);
				«ENDIF»
			}

			public boolean exists(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				return isNotEmpty() && predicate.apply(this.value);
			}

			@Override
			public int hashCode() {
				«IF type == Type.OBJECT»
					return Objects.hashCode(this.value);
				«ELSE»
					return «type.boxedName».hashCode(this.value);
				«ENDIF»
			}

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «shortName») {
					«IF type == Type.OBJECT»
						return Objects.equals(this.value, ((Option<?>) obj).value);
					«ELSE»
						final «shortName» other = («shortName») obj;
						return isEmpty() == other.isEmpty() && this.value == other.value;
					«ENDIF»
				} else {
					return false;
				}
			}

			@Override
			public String toString() {
				return isEmpty() ? "«type.shortName("None")»" : "«type.shortName("Some")»(" + this.value + ")";
			}

			public static «paramGenericName» «type.noneName»() {
				«IF type == Type.OBJECT»
					return (Option<A>) NONE;
				«ELSE»
					return NONE;
				«ENDIF»
			}

			public static «paramGenericName» «type.someName»(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				«IF type == Type.BOOLEAN»
					return value ? TRUE : FALSE;
				«ELSE»
					return new «diamondName»(value);
				«ENDIF»
			}

			«javadocSynonym(type.someName)»
			public static «paramGenericName» of(final «type.genericName» value) {
				return «type.someName»(value);
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
			«ELSEIF type == Type.BOOLEAN»
				public static «genericName» fromOptional(final Optional<Boolean> optional) {
					return optional.isPresent() ? «type.someName»(optional.get()) : «type.noneName»();
				}
			«ELSE»
				public static «genericName» fromOptional«type.typeName»(final Optional«type.typeName» optional) {
					return optional.isPresent() ? «type.someName»(optional.getAs«type.typeName»()) : «type.noneName»();
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				public <B> Option<P<A, B>> zip(final Option<B> that) {
					return zipWith(that, P::p);
				}

				public <B, C> Option<C> zipWith(final Option<B> that, final F2<A, B, C> f) {
					requireNonNull(f);
					if (isEmpty() || that.isEmpty()) {
						return none();
					} else {
						return some(requireNonNull(f.apply(this.value, that.value)));
					}
				}
			«ELSE»
				public <A> Option<«type.typeName»ObjectP<A>> zip(final Option<A> that) {
					return zipWith(that, «type.typeName»ObjectP::«type.typeName.firstToLowerCase»ObjectP);
				}

				public <A, B> Option<B> zipWith(final Option<A> that, final «type.typeName»ObjectObjectF2<A, B> f) {
					requireNonNull(f);
					if (isEmpty() || that.isEmpty()) {
						return none();
					} else {
						return some(requireNonNull(f.apply(this.value, that.value)));
					}
				}
			«ENDIF»
			«IF type == Type.OBJECT»

				«join»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}