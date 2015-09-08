package jcats.generator

import jcats.generator.Constants
import jcats.generator.Generator

final class SizedGenerator implements Generator {
	override className() { Constants.SIZED }
	
	override sourceCode() { '''
		package «Constants.JCATS»;
		
		public interface Sized {
			Size size();
		}
	''' }
}