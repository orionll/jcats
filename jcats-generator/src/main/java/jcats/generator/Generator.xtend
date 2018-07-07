package jcats.generator

import com.google.common.collect.Sets

import static extension com.google.common.collect.Iterables.contains
import static extension java.lang.Character.toLowerCase

interface Generator {
	def String className()
	def String name() { className.substring(className.lastIndexOf('.') + 1) }

	val public static PRIMITIVES = #["int", "long", "boolean", "double", "float", "short", "byte"]

	def String sourceCode()

	def static boxedName(String primitive) {
		if (primitive == "int") "Integer"
		else Character.toUpperCase(primitive.toCharArray.head) + primitive.toCharArray.tail.join
	}

	def static shortName(String primitive) {
		if (primitive == "boolean") "bool" else primitive
	}

	def String takeWhile(boolean isFinal, Type type) { '''
		public «if (isFinal) "final " else ""»«name»«IF type == Type.OBJECT»<A>«ENDIF» takeWhile(final «type.boolFName» predicate) {
			int n = 0;
			for (final «type.genericName» value : this) {
				if (predicate.apply(value)) {
					n++;
				} else {
					break;
				}
			}
			return limit(n);
		}
	''' }

	def toStr() { toStr(Type.OBJECT, false) }

	def toStr(Type type, boolean isFinal) { toStr(type, name, isFinal) }

	def toStr(Type type, String name, boolean isFinal) { '''
		@Override
		public «IF isFinal»final «ENDIF»String toString() {
			«IF type.javaUnboxedType»
				return «type.containerShortName.firstToLowerCase»ToString(this, "«name»");
			«ELSE»
				return iterableToString(this, "«name»");
			«ENDIF»
		}
	'''}

	def static hashcode(Type type) { return hashcode(type, false) }

	def static hashcode(Type type, boolean isFinal) { '''
		@Override
		public «IF isFinal»final «ENDIF»int hashCode() {
			«IF type.primitive»
				return «type.containerShortName.firstToLowerCase»HashCode(this);
			«ELSE»
				return containerHashCode(this);
			«ENDIF»
		}
	'''}

	def static uniqueHashCode(Type type) { '''
		@Override
		public int hashCode() {
			«IF type.primitive»
				return «type.uniqueContainerShortName.firstToLowerCase»HashCode(this);
			«ELSE»
				return uniqueContainerHashCode(this);
			«ENDIF»
		}
	'''}

	def static keyValueHashCode() { '''
		@Override
		public int hashCode() {
			return asUniqueContainer().hashCode();
		}
	'''}

	def static equals(Type type, String wildcardName, boolean isFinal) {'''
		/**
		 * «equalsDeprecatedJavaDoc»
		 */
		@Override
		@Deprecated
		public «IF isFinal»final «ENDIF»boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof «wildcardName») {
				return «type.indexedContainerShortName.firstToLowerCase»sEqual(this, («wildcardName») obj);
			} else {
				return false;
			}
		}
	'''}

	def static indexedEquals(Type type) { equals(type, type.indexedContainerWildcardName, false) }

	def static uniqueEquals(Type type) {'''
		/**
		 * «equalsDeprecatedJavaDoc»
		 */
		@Override
		@Deprecated
		public boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof «type.uniqueContainerWildcardName») {
				return «type.uniqueContainerShortName.firstToLowerCase»sEqual(this, («type.uniqueContainerWildcardName») obj);
			} else {
				return false;
			}
		}
	'''}

	def static keyValueEquals() {'''
		/**
		 * «equalsDeprecatedJavaDoc»
		 */
		@Override
		@Deprecated
		public boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof KeyValue<?, ?>) {
				return keyValuesEqual((KeyValue<Object, ?>) this, (KeyValue<Object, ?>) obj);
			} else {
				return false;
			}
		}
	'''}

	def static equalsDeprecatedJavaDoc() { "@deprecated This method is not type-safe. Use {@link #isEqualTo} instead." }

	def static repeat(Type type, String paramGenericName) { '''
		public static «paramGenericName» repeat(final int size, final «type.genericName» value) {
			return tabulate(size, int«type.typeName»Always(value));
		}
	'''}

	def static fill(Type type, String paramGenericName) { '''
		public static «paramGenericName» fill(final int size, final «IF type == Type.OBJECT»F0<A>«ELSE»«type.typeName»F0«ENDIF» f) {
			return tabulate(size, f.toInt«type.typeName»F());
		}
	'''}

	def static fillUntil(Type type, String paramGenericName, String builderName, String method) { '''
		public static «paramGenericName» fillUntil(final F0<«type.optionGenericName»> f) {
			final «builderName» builder = builder();
			«type.optionGenericName» value = f.apply();
			while (value.isNotEmpty()) {
				builder.«method»(value.get());
				value = f.apply();
			}
			return builder.build();
		}
	''' }

	def static iterate(Type type, String paramGenericName, String builderName) { '''
		«IF type == Type.OBJECT»
			public static «paramGenericName» iterate(final A start, final F<A, Option<A>> f) {
		«ELSE»
			public static «paramGenericName» iterate(final «type.javaName» start, final «type.typeName»ObjectF<«type.optionShortName»> f) {
		«ENDIF»
			final «builderName» builder = builder();
			builder.append(start);
			«type.optionGenericName» option = f.apply(start);
			while (option.isNotEmpty()) {
				final «type.genericName» value = option.get();
				builder.append(value);
				option = f.apply(value);
			}
			return builder.build();
		}
	''' }

	def joinCollection(Type type, String boxedShortName) { '''
		«IF type == Type.OBJECT»
			public static <A, C extends Iterable<A>> «name»<A> join(final Iterable<C> iterable) {
				return «boxedShortName».ofAll(iterable).flatMap((F) id());
			}
		«ELSE»
			public static <C extends Iterable<«type.boxedName»>> «name» join(final Iterable<C> iterable) {
				return «boxedShortName».ofAll(iterable).flatMapTo«type.typeName»((F) F.id());
			}
		«ENDIF»
	'''}

	def join() { joinMultiple(#[], "A") }

	def joinMultiple(Iterable<String> typeParams, String typeParam) { '''
		«staticModifier» <«typeParams.map[it + ", "].join»«typeParam»> «name»<«typeParams.map[it + ", "].join»«typeParam»> join(final «name»<«typeParams.map[it + ", "].join»«name»<«typeParams.map[it + ", "].join»«typeParam»>> «name.firstToLowerCase») {
			return «name.firstToLowerCase».flatMap(id());
		}
	'''}

	def static firstToLowerCase(String str) {
		if (str.empty) {
			str
		} else {
			str.toCharArray.head.toLowerCase + str.toCharArray.tail.join
		}
	}

	def static streamForEach(Type type, String method, boolean ordered) { '''
		if (stream.isParallel()) {
			stream.forEach«IF ordered»Ordered«ENDIF»((final «type.genericJavaUnboxedName» value) -> {
				synchronized (this) {
					«method»(value);
				}
			});
		} else {
			stream.forEach«IF ordered»Ordered«ENDIF»(this::«method»);
		}
	''' }

	def cast(Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams) {
		cast(name, "cast", typeParams, contravariantTypeParams, covariantTypeParams)
	}

	def cast(String typeName, String methodName, Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams) {
		val argumentType = '''«typeName»<«typeParams.join(", ")»>'''
		val returnType = '''«typeName»<«typeParams.map[
			if (contravariantTypeParams.contains(it) || covariantTypeParams.contains(it)) it + "X" else it].join(", ")»>'''

		val invariantTypeParams = Sets.newHashSet(typeParams)
		invariantTypeParams.removeAll(contravariantTypeParams)
		invariantTypeParams.removeAll(covariantTypeParams)

		val methodParams = new StringBuilder
		if (!contravariantTypeParams.empty) {
			methodParams.append(contravariantTypeParams.join(", "))
			methodParams.append(", ")
			methodParams.append(contravariantTypeParams.map[it + "X extends " + it].join(", "))
			if (!covariantTypeParams.empty || !invariantTypeParams.empty) {
				methodParams.append(", ")
			}
		}
		if (!covariantTypeParams.empty) {
			methodParams.append(covariantTypeParams.map[it + "X"].join(", "))
			methodParams.append(", ")
			methodParams.append(covariantTypeParams.map[it + " extends " + it + "X"].join(", "))
			if (!invariantTypeParams.empty) {
				methodParams.append(", ")
			}
		}
		if (!invariantTypeParams.empty) {
			methodParams.append(invariantTypeParams.join(", "))
		}

		'''
		«staticModifier» <«methodParams»> «returnType» «methodName»(final «argumentType» «typeName.firstToLowerCase») {
			return («returnType») requireNonNull(«typeName.firstToLowerCase»);
		}
		'''
	}

	def staticModifier() {
		if (this instanceof InterfaceGenerator) "static" else "public static"
	}

	def javadocSynonym(String of) {
		return '''
			/**
			 * Alias for {@link #«of»}
			 */
		'''
	}

	def indexOutOfBounds(String shortName) {
		'''throw new IndexOutOfBoundsException("Index " + index + " is out of range («shortName» length = " + this.size() + ")");'''
	}
}

interface InterfaceGenerator extends Generator {
}

interface ClassGenerator extends Generator {
}
