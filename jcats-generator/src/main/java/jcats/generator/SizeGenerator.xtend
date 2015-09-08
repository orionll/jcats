package jcats.generator

import jcats.generator.Constants
import jcats.generator.Generator

final class SizeGenerator implements Generator {
	override className() { Constants.SIZE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import «Constants.F»;
		import «Constants.F0»;

		public abstract class Size {
			private static final PreciseSize EMPTY = new PreciseSize(0);
			private static final InfiniteSize INF = new InfiniteSize();

			Size() {}

			public <A> A match(final F<PreciseSize, A> precise, final F0<A> infinite) {
				if (this instanceof PreciseSize) {
					return precise.apply((PreciseSize) this);
				} else {
					return infinite.apply();
				}
			}

			public static PreciseSize preciseSize(final int size) {
				if (size < 0) {
					throw new IllegalArgumentException("Negative size: " + size);
				} else if (size == 0) {
					return EMPTY;
				} else {
					return new PreciseSize(size);
				}
			}

			public static InfiniteSize infiniteSize() {
				return INF;
			}
		}
	''' }
}

final class PreciseSizeGenerator implements Generator {
	override className() { Constants.PRECISE_SIZE }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public final class PreciseSize extends Size {
			private final int size;

			PreciseSize(final int size) {
				this.size = size;
			}

			public int size() {
				return size;
			}

			public boolean isEmpty() {
				return (size == 0);
			}

			public boolean isNotEmpty() {
				return (size != 0);
			}

			@Override
			public String toString() {
				return Integer.toString(size);
			}
		}
	''' }
}

final class InfiniteSizeGenerator implements Generator {
	override className() { Constants.INFINITE_SIZE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		public final class InfiniteSize extends Size {
			@Override
			public String toString() {
				return "<infinite>";
			}
		}
	''' }
}
