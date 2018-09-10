package jcats.generator

final class CloseableXGenerator implements ClassGenerator {
	override className() { "jcats.CloseableX" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		public interface CloseableX<X extends Exception> extends AutoCloseable {
			@Override
			void close() throws X;
		}
	''' }
}