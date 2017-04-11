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
		public «if (isFinal) "final " else ""»«name»«IF type == Type.OBJECT»<A>«ENDIF» takeWhile(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»BoolF«IF type == Type.OBJECT»<A>«ENDIF» predicate) {
			int n = 0;
			for (final «type.genericName» value : this) {
				if (predicate.apply(value)) {
					n++;
				} else {
					break;
				}
			}
			return take(n);
		}
	''' }

	def toStr() { return toStr(Type.OBJECT, false) }

	def toStr(Type type, boolean isFinal) { '''
		@Override
		public «IF isFinal»final «ENDIF»String toString() {
			return iterableToString(this, "«name»");
		}
	'''}

	def static hashcode() { return hashcode("A", false) }

	def static hashcode(String paramBoxedName, boolean isFinal) { '''
		@Override
		public «IF isFinal»final «ENDIF»int hashCode() {
			return iterableHashCode(this);
		}
	'''}

	def static keyValueHashCode() { '''
		@Override
		public int hashCode() {
			return keyValueHashCode(this);
		}
	'''}

	def static equals(Type type, String wildcardName, boolean isFinal) {'''
		@Override
		public «IF isFinal»final «ENDIF»boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof «wildcardName.replaceAll("<\\?>", "")») {
				return «type.indexedContainerShortName.firstToLowerCase»sEqual(this, («wildcardName») obj);
			} else {
				return false;
			}
		}
	'''}

	def static keyValueEquals() {'''
		@Override
		public boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof KeyValue) {
				return keyValuesEqual((KeyValue) this, (KeyValue) obj);
			} else {
				return false;
			}
		}
	'''}

	def static repeat(Type type, String paramGenericName) { '''
		public static «paramGenericName» repeat(final int size, final «type.genericName» value) {
			return tabulate(size, Int«type.typeName»F.constant(value));
		}
	'''}

	def static fill(Type type, String paramGenericName) { '''
		public static «paramGenericName» fill(final int size, final «IF type == Type.OBJECT»F0<A>«ELSE»«type.typeName»F0«ENDIF» f) {
			return tabulate(size, f.toConstInt«type.typeName»F());
		}
	'''}

	def static fillUntil(Type type, String paramGenericName, String builderName) { '''
		public static «paramGenericName» fillUntil(final F0<«type.optionGenericName»> f) {
			final «builderName» builder = builder();
			«type.optionGenericName» value = f.apply();
			while (value.isNotEmpty()) {
				builder.append(value.get());
				value = f.apply();
			}
			return builder.build();
		}
	''' }

	def static iterate(Type type, String paramGenericName, String builderName) { '''
		public static «paramGenericName» iterate(final A start, final F<A, Option<A>> f) {
			final «builderName» builder = builder();
			builder.append(start);
			Option<A> option = f.apply(start);
			while (option.isNotEmpty()) {
				final A value = option.get();
				builder.append(value);
				option = f.apply(value);
			}
			return builder.build();
		}
	''' }

	def join() { joinMultiple(#[], "A") }

	def joinMultiple(Iterable<String> typeParams, String typeParam) { '''
		«staticModifier» <«typeParams.map[it + ", "].join»«typeParam»> «name»<«typeParams.map[it + ", "].join»«typeParam»> join(final «name»<«typeParams.map[it + ", "].join»«name»<«typeParams.map[it + ", "].join»«typeParam»>> «name.firstToLowerCase») {
			return «name.firstToLowerCase».flatMap(id());
		}
	'''}

	def zip() { zip(true, false) }

	def zip(boolean javadocComplexity, boolean isFinal) { '''
		«IF javadocComplexity»
			/**
			 * O(min(this.size, that.size))
			 */
		«ENDIF»
		public «IF isFinal»final «ENDIF»<B> «name»<P<A, B>> zip(final «name»<B> that) {
			return zip2(this, that);
		}
	'''}

	def zipWith() { zipWith(true, false) }

	def zipWith(boolean javadocComplexity, boolean isFinal) { '''
		«IF javadocComplexity»
			/**
			 * O(min(this.size, that.size))
			 */
		«ENDIF»
		public «IF isFinal»final «ENDIF»<B, C> «name»<C> zipWith(final «name»<B> that, final F2<A, B, C> f) {
			return zipWith2(this, that, f);
		}
	'''}

	def zipN() { zipN(true) }

	def zipN(boolean javadocComplexity) { '''
		«FOR arity : 2 .. Constants.MAX_FUNCTIONS_ARITY»
			«IF javadocComplexity»
				/**
				 * O(min(«(1 .. arity).map['''«name.firstToLowerCase»«it».size'''].join(", ")»))
				 */
			«ENDIF»
			«staticModifier» <«(1 .. arity).map["A" + it].join(", ")»> «name»<«PNGenerators.shortName(arity)»<«(1 .. arity).map["A" + it].join(", ")»>> zip«arity»(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")») {
				return zipWith«arity»(«(1 .. arity).map[name.firstToLowerCase + it].join(", ")», «PNGenerators.shortName(arity)»::«PNGenerators.shortName(arity).toLowerCase»);
			}

		«ENDFOR»
	'''}

	def zipWithN((int) => String body) { zipWithN(true, body) }

	def zipWithN(boolean javadocComplexity, (int) => String body) { '''
		«FOR arity : 2 .. Constants.MAX_FUNCTIONS_ARITY»
			«IF javadocComplexity»
				/**
				 * O(min(«(1 .. arity).map['''«name.firstToLowerCase»«it».size'''].join(", ")»))
				 */
			«ENDIF»
			«staticModifier» <«(1 .. arity).map["A" + it + ", "].join»B> «name»<B> zipWith«arity»(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")», final F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> f) {
				«body.apply(arity)»
			}

		«ENDFOR»
	'''}

	def productN() { '''
		«FOR arity : 2 .. Constants.MAX_FUNCTIONS_ARITY»
			«staticModifier» <«(1 .. arity).map["A" + it].join(", ")»> «name»<«PNGenerators.shortName(arity)»<«(1 .. arity).map["A" + it].join(", ")»>> product«arity»(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")») {
				return productWith«arity»(«(1 .. arity).map[name.firstToLowerCase + it].join(", ")», «PNGenerators.shortName(arity)»::«PNGenerators.shortName(arity).toLowerCase»);
			}

		«ENDFOR»
	'''}

	def productWithN((int) => String body) { '''
		«FOR arity : 2 .. Constants.MAX_FUNCTIONS_ARITY»
			«staticModifier» <«(1 .. arity).map["A" + it + ", "].join»B> «name»<B> productWith«arity»(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")», final F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> f) {
				«body.apply(arity)»
			}

		«ENDFOR»
	'''}

	def static firstToLowerCase(String str) {
		if (str.empty) {
			str
		} else if (str.matches("[A-Z]\\d")) {
			// Avoid names like v42, f05, ...
			str.toCharArray.head.toLowerCase.toString
		} else {
			str.toCharArray.head.toLowerCase + str.toCharArray.tail.join
		}
	}

	def cast(Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams) {
		val argumentType = '''«name»<«typeParams.join(", ")»>'''
		val returnType = '''«name»<«typeParams.map[
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
		«staticModifier» <«methodParams»> «returnType» cast(final «argumentType» «name.firstToLowerCase») {
			return («name»)requireNonNull(«name.firstToLowerCase»);
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
}

interface InterfaceGenerator extends Generator {
}

interface ClassGenerator extends Generator {
}
