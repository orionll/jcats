package jcats.generator

final class SizeGenerator implements ClassGenerator {
	override className() { Constants.SIZE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import «Constants.F»;
		import «Constants.F0»;

		public abstract class Size {
			private static final PreciseSize EMPTY = new PreciseSize(0);
			private static final InfiniteSize INF = new InfiniteSize();

			Size() {}

			public final boolean isPrecise() {
				return (this instanceof PreciseSize);
			}

			public abstract boolean mayBeFinite();

			public abstract boolean mayBeInfinite();

			public <A> A match(final F<PreciseSize, A> precise, final F0<A> infinite) {
				if (this instanceof PreciseSize) {
					return precise.apply((PreciseSize) this);
				} else {
					return infinite.apply();
				}
			}

			public static PreciseSize preciseSize(final int length) {
				if (length < 0) {
					throw new IllegalArgumentException("Negative size: " + length);
				} else if (length == 0) {
					return EMPTY;
				} else {
					return new PreciseSize(length);
				}
			}

			public static InfiniteSize infiniteSize() {
				return INF;
			}
		}
	''' }
}

final class PreciseSizeGenerator implements ClassGenerator {
	override className() { Constants.PRECISE_SIZE }
	
	override sourceCode() { '''
		package «Constants.JCATS»;

		public final class PreciseSize extends Size {
			private final int length;

			PreciseSize(final int length) {
				this.length = length;
			}

			public int length() {
				return length;
			}

			public final boolean mayBeFinite() {
				return true;
			}

			public final boolean mayBeInfinite() {
				return false;
			}

			public boolean isEmpty() {
				return (length == 0);
			}

			public boolean isNotEmpty() {
				return (length != 0);
			}

			@Override
			public String toString() {
				return Integer.toString(length);
			}
		}
	''' }
}

final class InfiniteSizeGenerator implements ClassGenerator {
	override className() { Constants.INFINITE_SIZE }

	override sourceCode() { '''
		package «Constants.JCATS»;

		public final class InfiniteSize extends Size {
			InfiniteSize() {}

			public final boolean mayBeFinite() {
				return false;
			}

			public final boolean mayBeInfinite() {
				return true;
			}

			@Override
			public int hashCode() {
				return -1;
			}

			@Override
			public String toString() {
				return "<infinite>";
			}
		}
	''' }
}
