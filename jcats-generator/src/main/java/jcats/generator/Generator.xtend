package jcats.generator

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

	def static String stream() { '''
		public Stream<A> stream() {
			return StreamSupport.stream(spliterator(), false);
		}
	''' }

	def static String parallelStream() { '''
		public Stream<A> parallelStream() {
			return StreamSupport.stream(spliterator(), true);
		}
	'''}

	def toStr() { '''
		@Override
		public String toString() {
			final StringBuilder builder = new StringBuilder("«name»(");
			final Iterator<A> iterator = iterator();
			while (iterator.hasNext()) {
				builder.append(iterator.next());
				if (iterator.hasNext()) {
					builder.append(", ");
				}
			}
			builder.append(")");
			return builder.toString();
		}
	'''}

	def toArrayList() { '''
		public final ArrayList<A> toArrayList() {
			return new ArrayList<>(asList());
		}
	'''}

	def static hashcode() { '''
		@Override
		public int hashCode() {
			int hashCode = 1;
			for (final A value : this) {
				hashCode = 31 * hashCode + value.hashCode();
			}
			return hashCode;
		}
	'''}

	def join() { joinMultiple(#[], "A") }

	def joinMultiple(Iterable<String> typeParams, String typeParam) { '''
		«staticModifier» <«typeParams.map[it + ", "].join»«typeParam»> «name»<«typeParams.map[it + ", "].join»«typeParam»> join(final «name»<«typeParams.map[it + ", "].join»«name»<«typeParams.map[it + ", "].join»«typeParam»>> «name.firstToLowerCase») {
			return «name.firstToLowerCase».flatMap(id());
		}
	'''}

	def zip() { zip(true) }

	def zip(boolean javadocComplexity) { '''
		«IF javadocComplexity»
			/**
			 * O(min(this.size, that.size))
			 */
		«ENDIF»
		public <B> «name»<P<A, B>> zip(final «name»<B> that) {
			return zip2(this, that);
		}
	'''}

	def zipWith() { zipWith(true) }

	def zipWith(boolean javadocComplexity) { '''
		«IF javadocComplexity»
			/**
			 * O(min(this.size, that.size))
			 */
		«ENDIF»
		public <B, C> «name»<C> zipWith(final «name»<B> that, final F2<A, B, C> f) {
			return zipWith2(this, that, f);
		}
	'''}

	def zipN() { zipN(true) }

	def zipN(boolean javadocComplexity) { '''
		«FOR arity : 2 .. Constants.MAX_ARITY»
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
		«FOR arity : 2 .. Constants.MAX_ARITY»
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
		«FOR arity : 2 .. Constants.MAX_ARITY»
			«staticModifier» <«(1 .. arity).map["A" + it].join(", ")»> «name»<«PNGenerators.shortName(arity)»<«(1 .. arity).map["A" + it].join(", ")»>> product«arity»(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")») {
				return productWith«arity»(«(1 .. arity).map[name.firstToLowerCase + it].join(", ")», «PNGenerators.shortName(arity)»::«PNGenerators.shortName(arity).toLowerCase»);
			}

		«ENDFOR»
	'''}

	def productWithN((int) => String body) { '''
		«FOR arity : 2 .. Constants.MAX_ARITY»
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
		val returnType = '''«name»<«typeParams.map[it + "X"].join(", ")»>'''

		val methodParams = new StringBuilder
		if (!contravariantTypeParams.empty) {
			methodParams.append(contravariantTypeParams.join(", "))
			methodParams.append(", ")
			methodParams.append(contravariantTypeParams.map[it + "X extends " + it].join(", "))
			if (!covariantTypeParams.empty) {
				methodParams.append(", ")
			}
		}
		if (!covariantTypeParams.empty) {
			methodParams.append(covariantTypeParams.map[it + "X"].join(", "))
			methodParams.append(", ")
			methodParams.append(covariantTypeParams.map[it + " extends " + it + "X"].join(", "))
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
}

interface InterfaceGenerator extends Generator {
}

interface ClassGenerator extends Generator {
}
