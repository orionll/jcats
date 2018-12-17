package jcats.generator

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension com.google.common.collect.Iterables.concat

@FinalFieldsConstructor
final class EitherGenerator implements ClassGenerator {
	val Type leftType
	val Type rightType

	def static List<Generator> generators() {
		Type.values.toList.map[type1 |
			Type.values.toList.map[type2 | new EitherGenerator(type1, type2) as Generator]]
			.concat.toList
	}

	override className() { Constants.JCATS + "." + shortName }

	def String shortName() { '''«IF leftType != Type.OBJECT || rightType != Type.OBJECT»«leftType.typeName»«rightType.typeName»«ENDIF»Either''' }

	def genericName() {
		if (leftType == Type.OBJECT && rightType == Type.OBJECT) {
			"Either<X, A>"
		} else if (leftType == Type.OBJECT) {
			shortName + "<X>"
		} else if (rightType == Type.OBJECT) {
			shortName + "<A>"
		} else {
			shortName
		}
	}

	def covariantName() {
		if (leftType == Type.OBJECT && rightType == Type.OBJECT) {
			"Either<@Covariant X, @Covariant A>"
		} else if (leftType == Type.OBJECT) {
			shortName + "<@Covariant X>"
		} else if (rightType == Type.OBJECT) {
			shortName + "<@Covariant A>"
		} else {
			shortName
		}
	}

	def paramGenericName() {
		if (leftType == Type.OBJECT && rightType == Type.OBJECT) {
			"<X, A> Either<X, A>"
		} else if (leftType == Type.OBJECT) {
			"<X> " + shortName + "<X>"
		} else if (rightType == Type.OBJECT) {
			"<A> " + shortName + "<A>"
		} else {
			shortName
		}
	}

	def diamondName() {
		if (leftType == Type.OBJECT || rightType == Type.OBJECT) {
			'''«shortName»<>'''
		} else {
			shortName
		}
	}

	def wildcardName() {
		if (leftType == Type.OBJECT && rightType == Type.OBJECT) {
			'''«shortName»<?, ?>'''
		} else if (leftType == Type.OBJECT || rightType == Type.OBJECT) {
			'''«shortName»<?>'''
		} else {
			shortName
		}
	}

	def leftTypeGenericName() {
		if (leftType == Type.OBJECT) "X" else leftType.javaName	
	}

	def leftTypeGenericBoxedName() {
		if (leftType == Type.OBJECT) "X" else leftType.genericBoxedName	
	}

	def leftName() {
		if (leftType == Type.OBJECT && rightType == Type.OBJECT) "left" else leftType.typeName.firstToLowerCase + rightType.typeName + "Left";
	}

	def rightName() {
		if (leftType == Type.OBJECT && rightType == Type.OBJECT) "right" else leftType.typeName.firstToLowerCase + rightType.typeName + "Right";
	}

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.NoSuchElementException;
		«IF leftType == Type.OBJECT || rightType == Type.OBJECT»
			import java.util.Objects;
		«ENDIF»

		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		«IF rightType == Type.OBJECT»
			import static «Constants.F».id;
		«ENDIF»
		«IF leftType != Type.OBJECT || rightType != Type.OBJECT»
			import static «Constants.EITHER».*;
		«ENDIF»

		public final class «covariantName» implements «rightType.maybeGenericName», Equatable<«genericName»>, Serializable {
			private final «leftTypeGenericName» left;
			private final «rightType.genericName» right;
			«IF leftType == Type.OBJECT || rightType == Type.OBJECT»

				«shortName»(final «leftTypeGenericName» left, final «rightType.genericName» right) {
					this.left = left;
					this.right = right;
				}
			«ELSE»
				private final boolean isLeft;

				«shortName»(final «leftTypeGenericName» left, final «rightType.genericName» right, final boolean isLeft) {
					this.left = left;
					this.right = right;
					this.isLeft = isLeft;
				}
			«ENDIF»

			public boolean isLeft() {
				«IF leftType == Type.OBJECT»
					return (this.left != null);
				«ELSEIF rightType == Type.OBJECT»
					return (this.right == null);
				«ELSE»
					return this.isLeft;
				«ENDIF»
			}

			public boolean isRight() {
				«IF rightType == Type.OBJECT»
					return (this.right != null);
				«ELSEIF leftType == Type.OBJECT»
					return (this.left == null);
				«ELSE»
					return !this.isLeft;
				«ENDIF»
			}

			«IF rightType != Type.OBJECT»
				@Override
				public «rightType.javaName» get() throws NoSuchElementException {
					if (isRight()) {
						return this.right;
					} else {
						throw new NoSuchElementException();
					}
				}

				@Override
				public boolean isEmpty() {
					return isLeft();
				}

			«ENDIF»
			public «leftTypeGenericName» getLeft() throws NoSuchElementException {
				if (isLeft()) {
					return this.left;
				} else {
					throw new NoSuchElementException();
				}
			}

			«IF rightType == Type.OBJECT»
				@Override
				public «rightType.genericBoxedName» getOrNull() {
					if (isRight()) {
						return this.right;
					} else {
						return null;
					}
				}

			«ENDIF»
			public «leftTypeGenericBoxedName» getLeftOrNull() {
				if (isLeft()) {
					return this.left;
				} else {
					return null;
				}
			}

			public «rightType.genericName» getOr(final «rightType.genericName» other) {
				«IF rightType == Type.OBJECT»
					requireNonNull(other);
				«ENDIF»
				return isRight() ? this.right : other;
			}

			public «leftTypeGenericName» getLeftOr(final «leftTypeGenericName» other) {
				«IF leftType == Type.OBJECT»
					requireNonNull(other);
				«ENDIF»
				return isLeft() ? this.left : other;
			}

			public void ifLeft(final «leftType.genericName("Eff", "X")» eff) {
				requireNonNull(eff);
				if (isLeft()) {
					eff.apply(this.left);
				}
			}

			public void ifRight(final «rightType.effGenericName» eff) {
				requireNonNull(eff);
				if (isRight()) {
					eff.apply(this.right);
				}
			}

			public void ifLeftOrElse(final «leftType.genericName("Eff", "X")» ifLeft, final «rightType.effGenericName» ifRight) {
				requireNonNull(ifLeft);
				requireNonNull(ifRight);
				if (isLeft()) {
					ifLeft.apply(this.left);
				} else {
					ifRight.apply(this.right);
				}
			}

			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public <B> B match(final F<X, B> ifLeft, final F<A, B> ifRight) {
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public <B> B match(final «leftType.typeName»ObjectF<B> ifLeft, final F<A, B> ifRight) {
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public <A> A match(final F<X, A> ifLeft, final «rightType.typeName»ObjectF<A> ifRight) {
			«ELSE»
				public <A> A match(final «leftType.typeName»ObjectF<A> ifLeft, final «rightType.typeName»ObjectF<A> ifRight) {
			«ENDIF»
				requireNonNull(ifLeft);
				requireNonNull(ifRight);
				if (isLeft()) {
					return ifLeft.apply(this.left);
				} else {
					return ifRight.apply(this.right);
				}
			}

			«FOR to : Type.primitives»
				«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
					public «to.genericName» matchTo«to.typeName»(final «to.typeName»F<X> ifLeft, final «to.typeName»F<A> ifRight) {
				«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
					public «to.genericName» matchTo«to.typeName»(final «leftType.typeName»«to.typeName»F ifLeft, final «to.typeName»F<A> ifRight) {
				«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
					public «to.genericName» matchTo«to.typeName»(final «to.typeName»F<X> ifLeft, final «rightType.typeName»«to.typeName»F ifRight) {
				«ELSE»
					public «to.genericName» matchTo«to.typeName»(final «leftType.typeName»«to.typeName»F ifLeft, final «rightType.typeName»«to.typeName»F ifRight) {
				«ENDIF»
					requireNonNull(ifLeft);
					requireNonNull(ifRight);
					if (isLeft()) {
						return ifLeft.apply(this.left);
					} else {
						return ifRight.apply(this.right);
					}
				}

			«ENDFOR»
			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public <B> Either<X, B> map(final F<A, B> f) {
					requireNonNull(f);
					if (isRight()) {
						final B newRight = requireNonNull(f.apply(this.right));
						return new Either<>(null, newRight);
					} else {
						return (Either)this;
					}
				}
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public <B> «leftType.typeName»ObjectEither<B> map(final F<A, B> f) {
					requireNonNull(f);
					if (isRight()) {
						final B newRight = requireNonNull(f.apply(this.right));
						return new «leftType.typeName»ObjectEither<>(«leftType.defaultValue», newRight);
					} else {
						return («leftType.typeName»ObjectEither)this;
					}
				}
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public <A> Either<X, A> map(final «rightType.typeName»ObjectF<A> f) {
					requireNonNull(f);
					if (isRight()) {
						final A newRight = requireNonNull(f.apply(this.right));
						return new Either<>(null, newRight);
					} else {
						return new Either<>(this.left, null);
					}
				}
			«ELSE»
				public <A> «leftType.typeName»ObjectEither<A> map(final «rightType.typeName»ObjectF<A> f) {
					requireNonNull(f);
					if (isRight()) {
						final A newRight = requireNonNull(f.apply(this.right));
						return new «leftType.typeName»ObjectEither<>(«leftType.defaultValue», newRight);
					} else {
						return new «leftType.typeName»ObjectEither<>(this.left, null);
					}
				}
			«ENDIF»

			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public <Y> Either<Y, A> mapLeft(final F<X, Y> f) {
					requireNonNull(f);
					if (isLeft()) {
						final Y newLeft = requireNonNull(f.apply(this.left));
						return new Either<>(newLeft, null);
					} else {
						return (Either)this;
					}
				}
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public <X> Either<X, A> mapLeft(final «leftType.typeName»ObjectF<X> f) {
					requireNonNull(f);
					if (isLeft()) {
						final X newLeft = requireNonNull(f.apply(this.left));
						return new Either<>(newLeft, null);
					} else {
						return new Either<>(null, this.right);
					}
				}
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public <Y> Object«rightType.typeName»Either<Y> mapLeft(final F<X, Y> f) {
					requireNonNull(f);
					if (isLeft()) {
						final Y newLeft = requireNonNull(f.apply(this.left));
						return new Object«rightType.typeName»Either<>(newLeft, «rightType.defaultValue»);
					} else {
						return new Object«rightType.typeName»Either<>(null, this.right);
					}
				}
			«ELSE»
				public <X> Object«rightType.typeName»Either<X> mapLeft(final «leftType.typeName»ObjectF<X> f) {
					requireNonNull(f);
					if (isLeft()) {
						final X newLeft = requireNonNull(f.apply(this.left));
						return new Object«rightType.typeName»Either<>(newLeft, «rightType.defaultValue»);
					} else {
						return new Object«rightType.typeName»Either<>(null, this.right);
					}
				}
			«ENDIF»

			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public <B> Either<X, B> flatMap(final F<A, Either<X, B>> f) {
					requireNonNull(f);
					if (isRight()) {
						return requireNonNull(f.apply(this.right));
					} else {
						return (Either)this;
					}
				}
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public <B> «leftType.typeName»ObjectEither<B> flatMap(final F<A, «leftType.typeName»ObjectEither<B>> f) {
					requireNonNull(f);
					if (isRight()) {
						return requireNonNull(f.apply(this.right));
					} else {
						return («leftType.typeName»ObjectEither)this;
					}
				}
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public <A> Either<X, A> flatMap(final «rightType.typeName»ObjectF<Either<X, A>> f) {
					requireNonNull(f);
					if (isRight()) {
						return requireNonNull(f.apply(this.right));
					} else {
						return new Either<>(this.left, null);
					}
				}
			«ELSE»
				public <A> «leftType.typeName»ObjectEither<A> flatMap(final «rightType.typeName»ObjectF<«leftType.typeName»ObjectEither<A>> f) {
					requireNonNull(f);
					if (isRight()) {
						return requireNonNull(f.apply(this.right));
					} else {
						return new «leftType.typeName»ObjectEither<>(this.left, null);
					}
				}
			«ENDIF»

			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public <Y> Either<Y, A> flatMapLeft(final F<X, Either<Y, A>> f) {
					requireNonNull(f);
					if (isLeft()) {
						return requireNonNull(f.apply(this.left));
					} else {
						return (Either)this;
					}
				}
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public <X> Either<X, A> flatMapLeft(final «leftType.typeName»ObjectF<Either<X, A>> f) {
					requireNonNull(f);
					if (isLeft()) {
						return requireNonNull(f.apply(this.left));
					} else {
						return new Either<>(null, this.right);
					}
				}
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public <Y> Object«rightType.typeName»Either<Y> flatMapLeft(final F<X, Object«rightType.typeName»Either<Y>> f) {
					requireNonNull(f);
					if (isLeft()) {
						return requireNonNull(f.apply(this.left));
					} else {
						return (Object«rightType.typeName»Either)this;
					}
				}
			«ELSE»
				public <X> Object«rightType.typeName»Either<X> flatMapLeft(final «leftType.typeName»ObjectF<Object«rightType.typeName»Either<X>> f) {
					requireNonNull(f);
					if (isLeft()) {
						return requireNonNull(f.apply(this.left));
					} else {
						return new Object«rightType.typeName»Either<>(null, this.right);
					}
				}
			«ENDIF»

			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public <Y, B> Either<Y, B> biMap(final F<X, Y> f, final F<A, B> g) {
					if (isLeft()) {
						final Y newLeft = requireNonNull(f.apply(this.left));
						return new Either<>(newLeft, null);
					} else {
						final B newRight = requireNonNull(g.apply(this.right));
						return new Either<>(null, newRight);
					}
				}
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public <X, B> Either<X, B> biMap(final «leftType.typeName»ObjectF<X> f, final F<A, B> g) {
					if (isLeft()) {
						final X newLeft = requireNonNull(f.apply(this.left));
						return new Either<>(newLeft, null);
					} else {
						final B newRight = requireNonNull(g.apply(this.right));
						return new Either<>(null, newRight);
					}
				}
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public <Y, A> Either<Y, A> biMap(final F<X, Y> f, final «rightType.typeName»ObjectF<A> g) {
					if (isLeft()) {
						final Y newLeft = requireNonNull(f.apply(this.left));
						return new Either<>(newLeft, null);
					} else {
						final A newRight = requireNonNull(g.apply(this.right));
						return new Either<>(null, newRight);
					}
				}
			«ELSE»
				public <X, A> Either<X, A> biMap(final «leftType.typeName»ObjectF<X> f, final «rightType.typeName»ObjectF<A> g) {
					if (isLeft()) {
						final X newLeft = requireNonNull(f.apply(this.left));
						return new Either<>(newLeft, null);
					} else {
						final A newRight = requireNonNull(g.apply(this.right));
						return new Either<>(null, newRight);
					}
				}
			«ENDIF»

			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
				public Either<A, X> reverse() {
					return new Either<>(this.right, this.left);
				}
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
				public «rightType.typeName»«leftType.typeName»Either<X> reverse() {
					return new «rightType.typeName»«leftType.typeName»Either<>(this.right, this.left);
				}
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
				public «rightType.typeName»«leftType.typeName»Either<A> reverse() {
					return new «rightType.typeName»«leftType.typeName»Either<>(this.right, this.left);
				}
			«ELSE»
				public «rightType.typeName»«leftType.typeName»Either reverse() {
					return new «rightType.typeName»«leftType.typeName»Either(this.right, this.left, !this.isLeft);
				}
			«ENDIF»

			«IF leftType != Type.OBJECT || rightType != Type.OBJECT»
				public Either<«leftTypeGenericBoxedName», «rightType.genericBoxedName»> toEither() {
					if (isLeft()) {
						return left(this.left);
					} else {
						return right(this.right);
					}
				}

			«ENDIF»
			@Override
			public int hashCode() {
				return isRight() ? «IF rightType == Type.OBJECT»this.right.hashCode()«ELSE»«rightType.boxedName».hashCode(this.right)«ENDIF» : ~«IF leftType == Type.OBJECT»this.left.hashCode()«ELSE»«leftType.boxedName».hashCode(this.left)«ENDIF»;
			}

			/**
			 * «equalsDeprecatedJavaDoc»
			 */
			@Override
			@Deprecated
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «shortName») {
					final «wildcardName» either = («wildcardName») obj;
					«IF leftType == Type.OBJECT && rightType == Type.OBJECT»
						return Objects.equals(this.left, either.left) && Objects.equals(this.right, either.right);
					«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»
						return Objects.equals(this.left, either.left) && this.right == either.right;
					«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»
						return this.left == either.left && Objects.equals(this.right, either.right);
					«ELSE»
						return this.left == either.left && this.right == either.right && this.isLeft == either.isLeft;
					«ENDIF»
				} else {
					return false;
				}
			}

			@Override
			public String toString() {
				return isLeft() ? "«shortName.replace("Either", "")»Left(" + this.left + ")" : "«shortName.replace("Either", "")»Right(" + this.right + ")";
			}

			public static «paramGenericName» «leftName»(final «leftTypeGenericName» left) {
				«IF leftType == Type.OBJECT»
					requireNonNull(left);
				«ENDIF»
				«IF leftType == Type.OBJECT || rightType == Type.OBJECT»
					return new «diamondName»(left, «rightType.defaultValue»);
				«ELSE»
					return new «diamondName»(left, «rightType.defaultValue», true);
				«ENDIF»
			}

			public static «paramGenericName» «rightName»(final «rightType.genericName» right) {
				«IF rightType == Type.OBJECT»
					requireNonNull(right);
				«ENDIF»
				«IF leftType == Type.OBJECT || rightType == Type.OBJECT»
					return new «diamondName»(«leftType.defaultValue», right);
				«ELSE»
					return new «diamondName»(«leftType.defaultValue», right, false);
				«ENDIF»
			}

			«javadocSynonym(rightName)»
			public static «paramGenericName» of(final «rightType.genericName» right) {
				return «rightName»(right);
			}
			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»

				public static <X extends Throwable, A> «genericName» run(final F0X<A, X> f, final Class<X> throwableClass) {
					try {
						return right(f.apply());
					} catch (final Throwable t) {
						if (throwableClass.isInstance(t)) {
							return left((X) t);
						} else {
							throw Control.<RuntimeException> sneakyThrow(t); // Safe here
						}
					}
				}
			«ENDIF»
			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»

				«joinMultiple(#["X"], "A")»
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»

				«join»
			«ENDIF»
			«IF leftType == Type.OBJECT && rightType == Type.OBJECT»

				«cast(#["X", "A"], #[], #["X", "A"])»
			«ELSEIF leftType != Type.OBJECT && rightType == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ELSEIF leftType == Type.OBJECT && rightType != Type.OBJECT»

				«cast(#["X"], #[], #["X"])»
			«ENDIF»
		}

	'''}
}