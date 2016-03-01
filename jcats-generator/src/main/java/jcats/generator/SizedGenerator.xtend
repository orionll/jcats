package jcats.generator

final class SizedGenerator implements InterfaceGenerator {
	override className() { Constants.SIZED }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface Sized {
			Size size();

			default boolean isEmpty() {
				return size().isEmpty();
			}

			default boolean isNotEmpty() {
				return size().isNotEmpty();
			}
		}
	''' }
}