package jcats.generator

final class SizedGenerator implements InterfaceGenerator {
	override className() { Constants.SIZED }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface Sized {
			int size();

			default boolean isEmpty() {
				return size() == 0;
			}

			default boolean isNotEmpty() {
				return size() != 0;
			}
		}
	''' }
}