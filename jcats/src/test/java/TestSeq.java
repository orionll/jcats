import static jcats.collection.Seq.emptySeq;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import jcats.collection.Seq;
import org.junit.Assert;
import org.junit.Test;

public class TestSeq {

	public static final int MAX = (1 << 26) + (1 << 23) + 117;

	private static void assertElementEquals(final Seq<Integer> seq, final int index, final int expected) {
		try {
			final Integer n = seq.get(index);
			Assert.assertEquals(Integer.valueOf(expected), n);
		} catch (final IndexOutOfBoundsException ex) {
			throw new Error("Error while getting element " + index, ex);
		}
	}

	private static int step(final int i) {
		final int s = i / 4;
		return (s == 0) ? 1 : s;
	}

	@Test
	public void test1() {
		Seq<Integer> seq = emptySeq();
		for (int i = 0; i < MAX; i++) {
			final int step = step(i);
			seq = seq.append(i % 63);
			assertEquals(i + 1, seq.length());
			assertEquals(0, seq.head().intValue());
			assertEquals(i % 63, seq.last().intValue());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, j % 63);
			}
			for (int j = i; j >= 0; j -= step) {
				assertElementEquals(seq, j, j % 63);
			}
			if (i < (1 << 16) || i % 17 == 0) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.length()) {
						fail("j == length (" + seq.length() + ")");
					}
					assertEquals(j % 63, e);
					j++;
				}
				assertEquals(seq.length(), j);
			}
		}
	}

	@Test
	public void test2() {
		Seq<Integer> seq = emptySeq();
		for (int i = 0; i < MAX; i++) {
			final int step = step(i);
			seq = seq.prepend(i % 63);
			assertEquals(i + 1, seq.length());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, (i - j) % 63);
			}
			for (int j = i; j >= 0; j -= step) {
				assertElementEquals(seq, j, (i - j) % 63);
			}
			if (i < (1 << 16) || i % 17 == 0) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.length()) {
						fail("j == length (" + seq.length() + ")");
					}
					assertEquals((i - j) % 63, e);
					j++;
				}
				assertEquals(seq.length(), j);
			}
		}
	}

	@Test
	public void test3() {
		Seq<Integer> seq = emptySeq();
		for (int i = 1; i < 40; i++) {
			seq = seq.append(i);
		}

		seq = seq.prepend(0);
		assertEquals(40, seq.length());

		for (int i = 40; i < MAX; i++) {
			final int step = step(i);
			seq = seq.append(i % 61);
			assertEquals(i + 1, seq.length());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, j % 61);
			}
			if (i < (1 << 16) || i % 19 == 0) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.length()) {
						fail("j == length (" + seq.length() + ")");
					}
					assertEquals(j % 61, e);
					j++;
				}
				assertEquals(seq.length(), j);
			}
		}
	}

	@Test
	public void test4() {
		Seq<Integer> seq = emptySeq();
		for (int i = 1; i < 40; i++) {
			seq = seq.prepend(i);
		}

		seq = seq.append(0);
		assertEquals(40, seq.length());

		for (int i = 40; i < MAX; i++) {
			final int step = step(i);
			seq = seq.prepend(i % 63);
			assertEquals(i + 1, seq.length());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, (i - j) % 63);
			}
			if (i < (1 << 16) || i % 19 == 0) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.length()) {
						fail("j == length (" + seq.length() + ")");
					}
					assertEquals((i - j) % 63, e);
					j++;
				}
				assertEquals(seq.length(), j);
			}
		}
	}

	@Test
	public void test5() {
		Seq<Integer> seq = emptySeq();

		for (int i = 0; i < MAX; i++) {
			final int step = step(i);

			seq = seq.append(i % 63);

			Seq<Integer> newSeq = seq;
			for (int j = 0; j <= i; j += step) {
				newSeq = newSeq.set(j, (j + 1) % 63);
			}

			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, j % 63);
				assertElementEquals(newSeq, j, (j + 1) % 63);
			}
		}
	}

	@Test
	public void test6() {
		Seq<Integer> seq = emptySeq();
		for (int i = 1; i < 40; i++) {
			seq = seq.append(i);
		}

		seq = seq.prepend(0);

		for (int i = 40; i < MAX; i++) {
			final int step = step(i);

			seq = seq.append(i % 61);

			Seq<Integer> newSeq = seq;
			for (int j = 0; j <= i; j += step) {
				newSeq = newSeq.set(j, (j + 1) % 61);
			}

			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, j % 61);
				assertElementEquals(newSeq, j, (j + 1) % 61);
			}
		}
	}

	@Test(expected = IndexOutOfBoundsException.class)
	public void test7() {
		Seq<Integer> seq = emptySeq();
		final int max = 10000;
		for (int i = 0; i < max; i++) {
			seq = seq.append(i);
		}

		seq.get(max);
	}
}
