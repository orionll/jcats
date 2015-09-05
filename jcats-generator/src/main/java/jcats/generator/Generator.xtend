package jcats.generator

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
}