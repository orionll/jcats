package jcats.generator

import jcats.generator.Constants
import jcats.generator.Generator

final class IndexedGenerator implements Generator {
	override className() { Constants.INDEXED }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface Indexed<A> {
			A get(final int index);
		}
	''' }
}