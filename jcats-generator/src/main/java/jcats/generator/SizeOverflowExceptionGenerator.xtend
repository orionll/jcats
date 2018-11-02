package jcats.generator

final class SizeOverflowExceptionGenerator implements ClassGenerator {

	override className() { Constants.JCATS + ".SizeOverflowException" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		public final class SizeOverflowException extends ArithmeticException {

			public SizeOverflowException() {
			}
		}
	''' }
}