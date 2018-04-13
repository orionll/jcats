package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class StackBuilderGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new StackBuilderGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("StackBuilder") }
	def genericName() { type.genericName("StackBuilder") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Iterator;
		«IF type.javaUnboxedType»
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»
		import java.util.stream.«type.streamName»;

		import static «Constants.COLLECTION».«type.stackShortName».*;

		public final class «genericName» {
			private «type.stackGenericName» start = empty«type.stackShortName»();
			private «type.stackGenericName» tail;
			private boolean exported;

			«shortName»() {
			}

			public «genericName» append(final «type.genericName» value) {
				if (this.exported) {
					copy();
				}

				final «type.stackGenericName» t = single«type.stackShortName»(value);

				if (this.tail == null) {
					this.start = t;
				} else {
					this.tail.tail = t;
				}

				this.tail = t;
				return this;
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public final «genericName» appendValues(final «type.genericName»... values) {
				for (final «type.genericName» value : values) {
					append(value);
				}
				return this;
			}

			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> iterable) {
				«IF type.javaUnboxedType»
					if (iterable instanceof «type.containerShortName») {
						((«type.containerShortName») iterable).foreach(this::append);
					} else {
						appendIterator(iterable.iterator());
					}
				«ELSE»
					if (iterable instanceof «type.containerWildcardName») {
						((«type.containerGenericName») iterable).foreach(this::append);
					} else {
						iterable.forEach(this::append);
					}
				«ENDIF»
				return this;
			}

			public «genericName» appendIterator(final Iterator<«type.genericBoxedName»> iterator) {
				«IF type.javaUnboxedType»
					«type.typeName»Iterator.getIterator(iterator).forEachRemaining((«type.typeName»Consumer) this::append);
				«ELSE»
					iterator.forEachRemaining(this::append);
				«ENDIF»
				return this;
			}

			«genericName» appendStackBuilder(final «genericName» builder) {
				«type.stackGenericName» stack = builder.start;
				while (stack.isNotEmpty()) {
					append(stack.head);
					stack = stack.tail;
				}
				return this;
			}

			public «genericName» append«type.streamName»(final «type.streamGenericName» stream) {
				stream.forEachOrdered(this::append);
				return this;
			}

			public boolean isEmpty() {
				return this.start.isEmpty();
			}

			public «type.stackGenericName» build() {
				this.exported = this.start.isNotEmpty();
				return this.start;
			}

			public «type.stackGenericName» prependToStack(final «type.stackGenericName» stack) {
				if (isEmpty()) {
					return stack;
				} else {
					if (this.exported) {
						copy();
					}

					this.tail.tail = stack;
					return build();
				}
			}

			private void copy() {
				«type.stackGenericName» s = this.start;
				final «type.stackGenericName» t = this.tail;
				this.start = empty«type.stackShortName»();
				this.tail = null;
				this.exported = false;
				while (s != t) {
					append(s.head);
					s = s.tail;
				}

				if (t != null) {
					append(t.head);
				}
			}

			@Override
			public String toString() {
				final StringBuilder builder = new StringBuilder("«shortName»(");
				«type.stackGenericName» stack = this.start;
				while (stack.isNotEmpty()) {
					builder.append(stack.head);
					stack = stack.tail;
					if (stack.isNotEmpty()) {
						builder.append(", ");
					}
				}
				builder.append(")");
				return builder.toString();
			}
		}
	''' }
}