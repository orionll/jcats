package jcats.generator

import static extension java.lang.Character.toLowerCase

interface Generator {
	def String className()
	def String sourceCode()
	
	val public static PRIMITIVES = #["int", "long", "boolean", "double", "float", "short", "byte"]
	
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

	def static toString(String type) { '''
		@Override
		public String toString() {
			final StringBuilder builder = new StringBuilder("«type»(");
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

	def static zip(String type) { '''
		/**
		 * O(min(this.size, that.size))
		 */
		public <B> «type»<P2<A, B>> zip(final «type»<B> that) {
			return zip2«type»s(this, that);
		}
	'''}

	def static zipWith(String type) { '''
		/**
		 * O(min(this.size, that.size))
		 */
		public <B, C> «type»<C> zipWith(final «type»<B> that, final F2<A, B, C> f) {
			return zip2«type»sWith(this, that, f);
		}
	'''}

	def static zipN(String type) { '''
		«FOR arity : 2 .. Constants.MAX_ARITY»
			/**
			 * O(min(«(1 .. arity).map['''«type.firstToLowerCase»«it».size'''].join(", ")»))
			 */
			public static <«(1 .. arity).map["A" + it].join(", ")»> «type»<P«arity»<«(1 .. arity).map["A" + it].join(", ")»>> zip«arity»«type»s(«(1 .. arity).map['''final «type»<A«it»> «type.firstToLowerCase»«it»'''].join(", ")») {
				return zip«arity»«type»sWith(«(1 .. arity).map[type.firstToLowerCase + it].join(", ")», P«arity»::p«arity»);
			}

		«ENDFOR»
	'''}

	def static zipWithN(String type, (int) => String body) { '''
		«FOR arity : 2 .. Constants.MAX_ARITY»
			/**
			 * O(min(«(1 .. arity).map['''«type.firstToLowerCase»«it».size'''].join(", ")»))
			 */
			public static <«(1 .. arity).map["A" + it + ", "].join»B> «type»<B> zip«arity»«type»sWith(«(1 .. arity).map['''final «type»<A«it»> «type.firstToLowerCase»«it»'''].join(", ")», final F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> f) {
				«body.apply(arity)»
			}

		«ENDFOR»
	'''}

	def static firstToLowerCase(String str) {
		if (str.empty) str else str.toCharArray.head.toLowerCase + str.toCharArray.tail.join
	}
}