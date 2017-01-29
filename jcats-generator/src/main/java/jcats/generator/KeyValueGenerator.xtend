package jcats.generator


class KeyValueGenerator implements InterfaceGenerator {
	
	override className() { Constants.JCATS + ".KeyValue" }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface KeyValue<K, A> {

			Option<A> get(final K key);

			boolean containsKey(final K key);
		}
	''' }
	
}