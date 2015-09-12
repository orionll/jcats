package jcats.generator

final class IndexedGenerator implements InterfaceGenerator {
	override className() { Constants.INDEXED }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface Indexed<A> {
			A get(final int index);
		}
	''' }
}