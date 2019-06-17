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
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.stream.Collector;
		import java.util.stream.«type.streamName»;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.optionShortName».*;
		«IF type == Type.OBJECT»
			import static «Constants.F».id;
		«ENDIF»
		«IF type.primitive»
			import static «Constants.FUNCTION».«type.typeName»«type.typeName»F.*;
		«ENDIF»
		import static «Constants.COMMON».*;
		«IF type != Type.OBJECT»
			import static «Constants.STACK».*;
		«ENDIF»
		«FOR toType : Type.primitives.filter[it != type]»
			import static «Constants.COLLECTION».«toType.stackShortName».*;
		«ENDFOR»

		public final class «type.covariantName("Stack")» implements «type.orderedContainerGenericName», Equatable<«genericName»>, Serializable {
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
			public int size() throws SizeOverflowException {
				int len = 0;
				«genericName» stack = this;
				while (stack.isNotEmpty()) {
					stack = stack.tail;
					if (++len < 0) {
						throw new SizeOverflowException();
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

			@Override
			public boolean hasKnownFixedSize() {
				return (this == EMPTY);
			}

			/**
			 * O(1)
			 */
			@Override
			public «type.genericName» first() throws NoSuchElementException {
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
			@Override
			public «type.optionGenericName» findFirst() {
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
			public «genericName» reverse() {
				«genericName» result = empty«shortName»();
				«genericName» stack = this;
				while (stack.isNotEmpty()) {
					result = new «diamondName»(stack.head, result);
					stack = stack.tail;
				}
				return result;
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

			«FOR toType : Type.primitives»
				public «toType.stackGenericName» mapTo«toType.typeName»(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»«toType.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
					requireNonNull(f);
					if (isEmpty()) {
						return empty«toType.stackShortName»();
					«IF type == toType»
					} else if (f == «type.javaName»Id()) {
						return this;
					«ENDIF»
					} else {
						final «toType.stackBuilderGenericName» builder = «toType.stackShortName».builder();
						«genericName» stack = this;
						while (stack.isNotEmpty()) {
							builder.append(f.apply(stack.head));
							stack = stack.tail;
						}
						return builder.build();
					}
				}

			«ENDFOR»
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

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					public final «toType.stackGenericName» flatMapTo«toType.typeName»(final F<A, Iterable<«toType.genericBoxedName»>> f) {
				«ELSE»
					public final «toType.stackGenericName» flatMapTo«toType.typeName»(final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
				«ENDIF»
					requireNonNull(f);
					if (isEmpty()) {
						return empty«toType.stackShortName»();
					} else {
						final «toType.stackBuilderGenericName» builder = «toType.stackShortName».builder();
						«genericName» stack = this;
						while (stack.isNotEmpty()) {
							builder.appendAll(f.apply(stack.head));
							stack = stack.tail;
						}
						return builder.build();
					}
				}

			«ENDFOR»
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

			«IF type == Type.OBJECT»
				public final <B extends A> Stack<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (Stack<B>) filter(clazz::isInstance);
				}

			«ENDIF»
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (isEmpty() || n == 0) {
					return empty«shortName»();
				} else {
					final «builderGenericName» builder = new «builderDiamondName»();
					«genericName» stack = this;
					int i = 0;
					while (stack.isNotEmpty() && i < n) {
						builder.append(stack.head);
						stack = stack.tail;
						i++;
					}
					return builder.build();
				}
			}

			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else {
					«genericName» stack = this;
					int i = 0;
					while (stack.isNotEmpty() && i < n) {
						stack = stack.tail;
						i++;
					}
					return stack;
				}
			}

			public «genericName» takeWhile(final «type.boolFName» predicate) {
				final «builderGenericName» builder = new «builderDiamondName»();
				«genericName» stack = this;
				while (stack.isNotEmpty() && predicate.apply(stack.head)) {
					builder.append(stack.head);
					stack = stack.tail;
				}
				return builder.build();
			}

			public «genericName» dropWhile(final «type.boolFName» predicate) {
				«genericName» stack = this;
				while (stack.isNotEmpty() && predicate.apply(stack.head)) {
					stack = stack.tail;
				}
				return stack;
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				«genericName» stack = this;
				while (stack.isNotEmpty()) {
					eff.apply(stack.head);
					stack = stack.tail;
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				«genericName» stack = this;
				while (stack.isNotEmpty()) {
					if (!eff.apply(stack.head)) {
						return false;
					}
					stack = stack.tail;
				}
				return true;
			}

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return isEmpty() ? «type.noneName»().iterator() : new «type.typeName»StackIterator(this);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «type.iteratorDiamondName("Stack")»(this);
				«ENDIF»
			}

			«orderedHashCode(type)»

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

			«transform(genericName)»

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

			public static «paramGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				requireNonNull(iterator);
				final «type.stackBuilderGenericName» builder = builder();
				builder.appendIterator(iterator);
				return builder.build();
			}

			public static «paramGenericName» from«type.streamName»(final «type.streamGenericName» stream) {
				final «type.stackBuilderGenericName» builder = builder();
				builder.append«type.streamName»(stream);
				return builder.build();
			}

			«IF type == Type.OBJECT»
				«FOR arity : 2 .. Constants.MAX_PRODUCT_ARITY»
					public static <«(1..arity).map['''A«it», '''].join»B> Stack<B> map«arity»(«(1..arity).map['''final Stack<A«it»> stack«it», '''].join»final F«arity»<«(1..arity).map['''A«it», '''].join»B> f) {
						requireNonNull(f);
						final StackBuilder<B> builder = builder();
						«FOR i : 1 .. arity»
							«(1 ..< i).map["\t"].join»stack«i».forEach(value«i» ->
						«ENDFOR»
							«(1 ..< arity).map["\t"].join»builder.append(f.apply(«(1 .. arity).map['''value«it»'''].join(", ")»))
						«(1 .. arity).map[")"].join»;
						return builder.build();
					}

				«ENDFOR»
			«ENDIF»
			public static «type.paramGenericName("StackBuilder")» builder() {
				return new «type.diamondName("StackBuilder")»();
			}

			«flattenCollection(type, genericName, type.stackBuilderGenericName)»

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» concat(final «genericName»... stacks) {
				if (stacks.length == 0) {
					return empty«shortName»();
				} else if (stacks.length == 1) {
					return requireNonNull(stacks[0]);
				} else if (stacks.length == 2) {
					return stacks[0].concat(stacks[1]);
				} else {
					// Index of last non-empty stack
					int lastIndex = -1;
					for (int i = 0; i < stacks.length; i++) {
						if (stacks[i].isNotEmpty()) {
							lastIndex = i;
						}
					}
					if (lastIndex >= 0) {
						final «builderGenericName» builder = builder();
						for (int i = 0; i < lastIndex; i++) {
							stacks[i].foreach(builder::append);
						}
						return builder.prependToStack(stacks[lastIndex]);
					} else {
						return empty«shortName»();
					}
				}
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»Collector<«type.genericBoxedName», ?, «genericName»> collector() {
				«IF type == Type.OBJECT»
					return Collector.<«type.genericBoxedName», «type.stackBuilderGenericName», «genericName»> of(
				«ELSE»
					return Collector.of(
				«ENDIF»
					«shortName»::builder, «type.stackBuilderShortName»::append, «type.stackBuilderShortName»::appendStackBuilder, «type.stackBuilderShortName»::build);
			}
			«IF type == Type.OBJECT»

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
