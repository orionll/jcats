package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class StackGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new StackGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.stackShortName }
	def genericName() { type.stackGenericName }
	def diamondName() { type.diamondName("Stack") }
	def wildcardName() { type.wildcardName("Stack") }
	def paramGenericName() { type.paramGenericName("Stack") }
	def builderGenericName() { type.genericName("StackBuilder") }
	def builderDiamondName() { type.diamondName("StackBuilder") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.Spliterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static java.util.Spliterators.spliteratorUnknownSize;
		import static «Constants.F».id;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		«IF type != Type.OBJECT»
			import static «Constants.STACK».*;
		«ENDIF»

		public final class «type.covariantName("Stack")» implements «type.containerGenericName», Equatable<«genericName»>, Serializable {
			private static final «wildcardName» EMPTY = new «diamondName»(«type.defaultValue», null);

			final «type.genericName» head;
			«genericName» tail;

			private «shortName»(final «type.genericName» head, final «genericName» tail) {
				this.head = head;
				this.tail = tail;
			}

			/**
			 * O(size)
			 */
			@Override
			public int size() {
				int len = 0;
				«genericName» stack = this;
				while (stack.isNotEmpty()) {
					stack = stack.tail;
					if (++len < 0) {
						throw new IndexOutOfBoundsException("Integer overflow");
					}
				}
				return len;
			}

			/**
			 * O(1)
			 */
			@Override
			public boolean isEmpty() {
				return (this == EMPTY);
			}

			/**
			 * O(1)
			 */
			@Override
			public boolean isNotEmpty() {
				return (this != EMPTY);
			}

			/**
			 * O(1)
			 */
			public «type.genericName» head() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return this.head;
				}
			}

			/**
			 * O(1)
			 */
			public «genericName» tail() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return this.tail;
				}
			}

			/**
			 * O(1)
			 */
			public «type.optionGenericName» headOption() {
				return isEmpty() ? «type.noneName»() : «type.someName»(this.head);
			}

			/**
			 * O(1)
			 */
			public «genericName» prepend(final «type.genericName» value) {
				return new «diamondName»(«type.requireNonNull("value")», this);
			}

			/**
			 * O(size)
			 */
			public «genericName» append(final «type.genericName» value) {
				final «builderGenericName» builder = new «builderDiamondName»();
				foreach(builder::append);
				builder.append(value);
				return builder.build();
			}

			/**
			 * O(size)
			 */
			public «genericName» concat(final «genericName» suffix) {
				requireNonNull(suffix);
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					final «builderGenericName» builder = new «builderDiamondName»();
					foreach(builder::append);
					return builder.prependToStack(suffix);
				}
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> suffix) {
				if (isEmpty()) {
					return ofAll(suffix);
				} else if (suffix instanceof «wildcardName») {
					return concat((«genericName») suffix);
				} else if (suffix instanceof Sized && ((Sized) suffix).isEmpty()) {
					return this;
				} else if (suffix instanceof Collection<?> && ((Collection<?>) suffix).isEmpty()) {
					return this;
				} else {
					final «builderGenericName» builder = new «builderDiamondName»();
					foreach(builder::append);
					builder.appendAll(suffix);
					return builder.build();
				}
			}

			/**
			 * O(prefix.size)
			 */
			public «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) {
				final «builderGenericName» builder = new «builderDiamondName»();
				builder.appendAll(prefix);
				return builder.prependToStack(this);
			}

			/**
			 * O(size)
			 */
			«IF type == Type.OBJECT»
				public <B> Stack<B> map(final F<A, B> f) {
			«ELSE»
				public <A> Stack<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptyStack();
				«IF type == Type.OBJECT»
					} else if (f == F.id()) {
						return (Stack<B>) this;
				«ENDIF»
				} else {
					final StackBuilder«IF type == Type.OBJECT»<B>«ELSE»<A>«ENDIF» builder = new StackBuilder<>();
					«genericName» stack = this;
					while (stack.isNotEmpty()) {
						builder.append(f.apply(stack.head));
						stack = stack.tail;
					}
					return builder.build();
				}
			}

			«IF type == Type.OBJECT»
				public final <B> Stack<B> flatMap(final F<A, Iterable<B>> f) {
			«ELSE»
				public final <A> Stack<A> flatMap(final «type.typeName»ObjectF<Iterable<A>> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptyStack();
				} else {
					final StackBuilder«IF type == Type.OBJECT»<B>«ELSE»<A>«ENDIF» builder = new StackBuilder<>();
					«genericName» stack = this;
					while (stack.isNotEmpty()) {
						builder.appendAll(f.apply(stack.head));
						stack = stack.tail;
					}
					return builder.build();
				}
			}

			public «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return empty«shortName»();
				} else {
					final «builderGenericName» builder = new «builderDiamondName»();
					«genericName» stack = this;
					while (stack.isNotEmpty()) {
						if (predicate.apply(stack.head)) {
							builder.append(stack.head);
						}
						stack = stack.tail;
					}
					return builder.build();
				}
			}

			public «genericName» take(final int n) {
				if (isEmpty() || n <= 0) {
					return empty«shortName»();
				} else {
					final «builderGenericName» builder = new «builderDiamondName»();
					«genericName» stack = this;
					int i = 0;
					while (!stack.isEmpty() && i < n) {
						builder.append(stack.head);
						stack = stack.tail;
						i++;
					}
					return builder.build();
				}
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return isEmpty() ? «type.noneName»().iterator() : new «type.typeName»StackIterator(this);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «type.iteratorDiamondName("Stack")»(this);
				«ENDIF»
			}

			«hashcode(type)»
			
			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof «wildcardName») {
					«wildcardName» stack1 = this;
					«wildcardName» stack2 = («wildcardName») obj;
					while (stack1.isNotEmpty()) {
						«IF type == Type.OBJECT»
							if (stack2.isEmpty() || !stack1.head.equals(stack2.head)) {
						«ELSE»
							if (stack2.isEmpty() || stack1.head != stack2.head) {
						«ENDIF»
							return false;
						}
						stack1 = stack1.tail;
						stack2 = stack2.tail;
					}
					return stack2.isEmpty();
				} else {
					return false;
				}
			}

			«toStr»

			public static «paramGenericName» empty«shortName»() {
				return «IF type == Type.OBJECT»(Stack<A>) «ENDIF»EMPTY;
			}

			public static «paramGenericName» single«shortName»(final «type.genericName» value) {
				return new «diamondName»(«type.requireNonNull("value")», empty«shortName»());
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» «shortName.firstToLowerCase»(final «type.genericName»... values) {
				«genericName» stack = empty«shortName»();
				for (int i = values.length - 1; i >= 0; i--) {
					stack = new «diamondName»(«type.requireNonNull("values[i]")», stack);
				}
				return stack;
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			public static «paramGenericName» ofAll(final Iterable<«type.genericBoxedName»> iterable) {
				if (iterable instanceof «wildcardName») {
					return («genericName») iterable;
				} else {
					return new «builderGenericName»().appendAll(iterable).build();
				}
			}

			public static «type.paramGenericName("StackBuilder")» builder() {
				return new «type.diamondName("StackBuilder")»();
			}
			«IF type == Type.OBJECT»

				«joinCollection»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		final class «type.iteratorGenericName("Stack")» implements «type.iteratorGenericName» {
			private «genericName» stack;

			«type.iteratorShortName("Stack")»(final «genericName» stack) {
				this.stack = stack;
			}

			@Override
			public boolean hasNext() {
				return this.stack.isNotEmpty();
			}

			@Override
			public «type.iteratorReturnType» «type.iteratorNext»() {
				if (this.stack.isEmpty()) {
					throw new NoSuchElementException();
				} else {
					final «type.genericName» result = this.stack.head;
					this.stack = this.stack.tail;
					return result;
				}
			}
		}
	''' }
}
