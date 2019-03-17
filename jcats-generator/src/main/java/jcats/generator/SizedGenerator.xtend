package jcats.generator

final class SizedGenerator implements InterfaceGenerator {
	override className() { Constants.SIZED }

	override sourceCode() '''
		package «Constants.JCATS»;

		public interface Sized {

			/**
			 * Returns the number of elements in this container.
			 *
			 * <p>This method must never return a negative value.
			 *
			 * @return The number of elements in this container.
			 *
			 * @throws SizeOverflowException
			 *         If the number of elements is greater than {@link Integer#MAX_VALUE} elements.
			 */
			int size() throws SizeOverflowException;

			/**
			 * Returns {@code true} if this container has a known exact fixed size.
			 *
			 * <p>The container has a <i>known exact fixed</i> size if all of these conditions are true:
			 * <ul>
			 *    <li>The size is finite. I.e. {@link #size()} does not throw {@link SizeOverflowException}.
			 *    <li>The size is constant. I.e. {@link #size()}, {@link #isEmpty()} and {@link #isNotEmpty()}
			 *        always return the same value.
			 *    <li>{@link #size()}, {@link #isEmpty()} and {@link #isNotEmpty()} are consistent
			 *        ({@code isEmpty == true} implies {@code isNotEmpty == false} and {@code size > 0} and vice versa).
			 *    <li>{@link #size()} is consistent with all traversal operations for this container
			 *        (e.g. {@code foreach}, {@code foreachUntil}, {@code iterator} and so forth).
			 *    <li>{@link #size()}, {@link #isEmpty()} and {@link #isNotEmpty()} are fast operations
			 *        (constant-time or nearly constant-time).
			 * </ul>
			 *
			 * <p>The default implementation returns {@code true}.
			 *
			 * @return {@code true} if this container has a known exact fixed size.
			 */
			default boolean hasKnownFixedSize() {
				return true;
			}

			/**
			 * Returns {@code true} if this container has no elements.
			 *
			 * <p>The default implementation calls {@link #size()} and checks if the returned value is {@code 0}.
			 *
			 * @return {@code true} if this container has no elements or {@code false} otherwise
			 */
			default boolean isEmpty() {
				return size() == 0;
			}

			/**
			 * Returns {@code true} if this container has at least one element.
			 *
			 * <p>The default implementation calls {@link #size()} and checks if the returned value is not {@code 0}.
			 *
			 * @return {@code true} if this container has at least one element or {@code false} otherwise
			 */
			default boolean isNotEmpty() {
				return size() != 0;
			}
		}
	'''
}