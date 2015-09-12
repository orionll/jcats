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

	def join() { '''
		«staticModifier» <A> «name» join(final «name»<«name»<A>> «name.firstToLowerCase») {
			return «name.firstToLowerCase».flatMap(id());
		}
	'''}

	def zip() { '''
		/**
		 * O(min(this.size, that.size))
		 */
		public <B> «name»<P2<A, B>> zip(final «name»<B> that) {
			return zip2«name»s(this, that);
		}
	'''}

	def zipWith() { '''
		/**
		 * O(min(this.size, that.size))
		 */
		public <B, C> «name»<C> zipWith(final «name»<B> that, final F2<A, B, C> f) {
			return zip2«name»sWith(this, that, f);
		}
	'''}

	def zipN() { '''
		«FOR arity : 2 .. Constants.MAX_ARITY»
			/**
			 * O(min(«(1 .. arity).map['''«name.firstToLowerCase»«it».size'''].join(", ")»))
			 */
			public static <«(1 .. arity).map["A" + it].join(", ")»> «name»<P«arity»<«(1 .. arity).map["A" + it].join(", ")»>> zip«arity»«name»s(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")») {
				return zip«arity»«name»sWith(«(1 .. arity).map[name.firstToLowerCase + it].join(", ")», P«arity»::p«arity»);
			}

		«ENDFOR»
	'''}

	def zipWithN((int) => String body) { '''
		«FOR arity : 2 .. Constants.MAX_ARITY»
			/**
			 * O(min(«(1 .. arity).map['''«name.firstToLowerCase»«it».size'''].join(", ")»))
			 */
			public static <«(1 .. arity).map["A" + it + ", "].join»B> «name»<B> zip«arity»«name»sWith(«(1 .. arity).map['''final «name»<A«it»> «name.firstToLowerCase»«it»'''].join(", ")», final F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> f) {
				«body.apply(arity)»
			}

		«ENDFOR»
	'''}

	def static firstToLowerCase(String str) {
		if (str.empty) str else str.toCharArray.head.toLowerCase + str.toCharArray.tail.join
	}

	def cast(Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams) {
		cast(typeParams, contravariantTypeParams, covariantTypeParams, false)
	}

	def cast(Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams, boolean isInterface) {
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
		«staticModifier» <«methodParams»> «returnType» cast«name»(final «argumentType» «name.firstToLowerCase») {
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
