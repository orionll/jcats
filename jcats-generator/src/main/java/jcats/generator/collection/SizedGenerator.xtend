package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class SizedGenerator implements Generator {
	override className() { Constants.SIZED }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;
		
		/**
		 * Implemented by collections whose size() is a fast operation (O(1), O(log n) etc.)
		 */
		public interface Sized {
			int size();

			default boolean isEmpty() {
				return (size() == 0);
			}

			default boolean isNotEmpty() {
				return (size() != 0);
			}
		}
	''' }
}