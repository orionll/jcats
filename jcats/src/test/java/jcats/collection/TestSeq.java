package jcats.collection;

import static jcats.collection.Seq.emptySeq;
import static org.junit.Assert.*;

import com.google.common.collect.Iterables;
import org.junit.Assert;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class TestSeq {

	public static final int MAX = (1 << 21) + (1 << 19) + 117;

	private static final int[] TEST_INDICES = testIndices();

	private static int[] testIndices() {
		final List<Integer> list = new ArrayList<>();
		for (int i = 0; i < 30; i++) {
			list.add((1 << i) - 1);
			list.add(1 << i);
			list.add((1 << i) + 1);
			for (int j = 1; j < i; j++) {
				list.add((1 << i) + (1 << j) - 1);
				list.add((1 << i) + (1 << j));
				list.add((1 << i) + (1 << j) + 1);
			}
		}
		int[] arr = new int[list.size()];
		for (int i = 0; i < list.size(); i++) {
			arr[i] = list.get(i);
		}

		Arrays.sort(arr);

		return arr;
	}

	private static boolean isTestIndex(final int i) {
		return Arrays.binarySearch(TEST_INDICES, i) >= 0;
	}

	private static void assertElementEquals(final Seq<Integer> seq, final int index, final int expected) {
		try {
			final Integer n = seq.get(index);
			assertEquals(Integer.valueOf(expected), n);
		} catch (final IndexOutOfBoundsException ex) {
			throw new Error("Error while getting element " + index, ex);
		}
	}

	private static <A> void assertSeqsDeepEqual(final String msg, final Seq<A> expectedSeq, final Seq<A> seq) {
		try {
			if (expectedSeq instanceof Seq0<?>) {
				assertTrue(Seq.emptySeq() == seq);
			} else if (expectedSeq instanceof Seq1<?>) {
				assertArrayEquals(msg, ((Seq1<?>) expectedSeq).node1, ((Seq1<?>) seq).node1);
			} else if (expectedSeq instanceof Seq2<?>) {
				assertArrayEquals(msg, ((Seq2<?>) expectedSeq).init, ((Seq2<?>) seq).init);
				assertArrayEquals(msg, ((Seq2<?>) expectedSeq).node2, ((Seq2<?>) seq).node2);
				assertArrayEquals(msg, ((Seq2<?>) expectedSeq).tail, ((Seq2<?>) seq).tail);
				assertEquals(msg, ((Seq2<?>) expectedSeq).length, ((Seq2<?>) seq).length);
			} else if (expectedSeq instanceof Seq3<?>) {
				assertArrayEquals(msg, ((Seq3<?>) expectedSeq).init, ((Seq3<?>) seq).init);
				assertArrayEquals(msg, ((Seq3<?>) expectedSeq).node3, ((Seq3<?>) seq).node3);
				assertArrayEquals(msg, ((Seq3<?>) expectedSeq).tail, ((Seq3<?>) seq).tail);
				assertEquals(msg, ((Seq3<?>) expectedSeq).startIndex, ((Seq3<?>) seq).startIndex);
				assertEquals(msg, ((Seq3<?>) expectedSeq).length, ((Seq3<?>) seq).length);
			} else if (expectedSeq instanceof Seq4<?>) {
				assertArrayEquals(msg, ((Seq4<?>) expectedSeq).init, ((Seq4<?>) seq).init);
				assertArrayEquals(msg, ((Seq4<?>) expectedSeq).node4, ((Seq4<?>) seq).node4);
				assertArrayEquals(msg, ((Seq4<?>) expectedSeq).tail, ((Seq4<?>) seq).tail);
				assertEquals(msg, ((Seq4<?>) expectedSeq).startIndex, ((Seq4<?>) seq).startIndex);
				assertEquals(msg, ((Seq4<?>) expectedSeq).length, ((Seq4<?>) seq).length);
			} else if (expectedSeq instanceof Seq5<?>) {
				assertArrayEquals(msg, ((Seq5<?>) expectedSeq).init, ((Seq5<?>) seq).init);
				assertArrayEquals(msg, ((Seq5<?>) expectedSeq).node5, ((Seq5<?>) seq).node5);
				assertArrayEquals(msg, ((Seq5<?>) expectedSeq).tail, ((Seq5<?>) seq).tail);
				assertEquals(msg, ((Seq5<?>) expectedSeq).startIndex, ((Seq5<?>) seq).startIndex);
				assertEquals(msg, ((Seq5<?>) expectedSeq).length, ((Seq5<?>) seq).length);
			} else if (expectedSeq instanceof Seq6<?>) {
				assertArrayEquals(msg, ((Seq6<?>) expectedSeq).init, ((Seq6<?>) seq).init);
				assertArrayEquals(msg, ((Seq6<?>) expectedSeq).node6, ((Seq6<?>) seq).node6);
				assertArrayEquals(msg, ((Seq6<?>) expectedSeq).tail, ((Seq6<?>) seq).tail);
				assertEquals(msg, ((Seq6<?>) expectedSeq).startIndex, ((Seq6<?>) seq).startIndex);
				assertEquals(msg, ((Seq6<?>) expectedSeq).length, ((Seq6<?>) seq).length);
			} else {
				fail();
			}
		} catch (ClassCastException ex) {
			fail(msg + ": " + ex.getMessage());
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
			assertEquals(i + 1, seq.size());
			assertEquals(0, seq.head().intValue());
			assertEquals(i % 63, seq.last().intValue());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, j % 63);
			}
			for (int j = i; j >= 0; j -= step) {
				assertElementEquals(seq, j, j % 63);
			}
			if (isTestIndex(i)) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.size()) {
						fail("j == length (" + seq.size() + ")");
					}
					assertEquals(j % 63, e);
					j++;
				}
				assertEquals(seq.size(), j);
			}
		}
	}

	@Test
	public void test2() {
		Seq<Integer> seq = emptySeq();
		for (int i = 0; i < MAX; i++) {
			final int step = step(i);
			seq = seq.prepend(i % 63);
			assertEquals(i + 1, seq.size());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, (i - j) % 63);
			}
			for (int j = i; j >= 0; j -= step) {
				assertElementEquals(seq, j, (i - j) % 63);
			}
			if (isTestIndex(i)) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.size()) {
						fail("j == length (" + seq.size() + ")");
					}
					assertEquals((i - j) % 63, e);
					j++;
				}
				assertEquals(seq.size(), j);
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
		assertEquals(40, seq.size());

		for (int i = 40; i < MAX; i++) {
			final int step = step(i);
			seq = seq.append(i % 61);
			assertEquals(i + 1, seq.size());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, j % 61);
			}
			if (isTestIndex(i)) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.size()) {
						fail("j == length (" + seq.size() + ")");
					}
					assertEquals(j % 61, e);
					j++;
				}
				assertEquals(seq.size(), j);
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
		assertEquals(40, seq.size());

		for (int i = 40; i < MAX; i++) {
			final int step = step(i);
			seq = seq.prepend(i % 63);
			assertEquals(i + 1, seq.size());
			for (int j = 0; j <= i; j += step) {
				assertElementEquals(seq, j, (i - j) % 63);
			}
			if (isTestIndex(i)) {
				int j = 0;
				for (int e : seq) {
					if (j == seq.size()) {
						fail("j == length (" + seq.size() + ")");
					}
					assertEquals((i - j) % 63, e);
					j++;
				}
				assertEquals(seq.size(), j);
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

	@Test
	public void testSeqBuilder() {
		Seq<Integer> expectedSeq = emptySeq();
		SeqBuilder<Integer> builder = new SeqBuilder<>();
		for (int i = 0; i < MAX; i++) {
			expectedSeq = expectedSeq.append(i % 61);
			builder.append(i % 61);
			if (isTestIndex(i)) {
				assertSeqsDeepEqual("Seq is not equal to expected seq (size = " + expectedSeq.size() + ")", expectedSeq, builder.build());
			}
		}
	}

	@Test
	public void testSeqFromArray() {
		List<Integer> list = new ArrayList<>();

		for (int i = 0; i < MAX; i++) {
			list.add(i % 63);
			if (isTestIndex(i)) {
				Seq<Integer> seq = Seq.seq(list.toArray(new Integer[0]));
				assertEquals(list.size(), seq.size());
				assertTrue("Elements not equal for size = " + list.size(), Iterables.elementsEqual(list, seq));
			}
		}
	}

	@Test
	public void testInit() {
		Seq<Integer> seq = Seq.emptySeq();
		for (int i = 0; i < MAX; i++) {
			if (i == 40) {
				seq = seq.prepend(-1);
				continue;
			}
			Seq<Integer> newSeq = seq.append(i % 63);
			if (isTestIndex(i + 31)) {
				assertSeqsDeepEqual("Init is not equal to expected seq (size = " + seq.size() + ")", seq, newSeq.init());
			}
			seq = newSeq;
		}

		seq = Seq.emptySeq();
		for (int i = 0; i < MAX; i++) {
			Seq<Integer> newSeq = seq.append(i % 61);
			if (isTestIndex(i)) {
				assertSeqsDeepEqual("Init is not equal to expected seq (size = " + seq.size() + ")", seq, newSeq.init());
			}
			seq = newSeq;
		}
	}

	@Test
	public void testTail() {
		Seq<Integer> seq = Seq.emptySeq();
		for (int i = 0; i < MAX; i++) {
			if (i == 40) {
				seq = seq.append(-1);
				continue;
			}
			Seq<Integer> newSeq = seq.prepend(i % 63);
			if (isTestIndex(i + 31)) {
				assertSeqsDeepEqual("Tail is not equal to expected seq (size = " + seq.size() + ")", seq, newSeq.tail());
			}
			seq = newSeq;
		}

		seq = Seq.emptySeq();
		for (int i = 0; i < MAX; i++) {
			Seq<Integer> newSeq = seq.prepend(i % 61);
			if (isTestIndex(i)) {
				assertSeqsDeepEqual("Tail is not equal to expected seq (size = " + seq.size() + ")", seq, newSeq.tail());
			}
			seq = newSeq;
		}
	}

	@Test
	public void testConcat() {
		Seq<Integer> seq = Seq.emptySeq();
		for (int i = 0; i < MAX; i++) {
			if (i == 40) {
				seq = seq.prepend(-1);
			}
			if (isTestIndex(i + 31)) {
				Seq<Integer> concat = seq.concat(Seq.seq(-1));
				assertSeqsDeepEqual("Concatenated seq is not equal to expected seq (size = " + seq.size() + ")", seq.append(-1), concat);
				assertSeqsDeepEqual("Init of concatenated seq is not equal to expected seq (size = " + seq.size() + ")", seq, concat.init());
			}
			seq = seq.append(i % 61);
		}

		seq = Seq.emptySeq();
		for (int i = 0; i < MAX; i++) {
			if (isTestIndex(i)) {
				Seq<Integer> concat = seq.concat(Seq.seq(-1));
				assertSeqsDeepEqual("Concatenated seq is not equal to expected seq (size = " + seq.size() + ")", seq.append(-1), concat);
				assertSeqsDeepEqual("Init of concatenated seq is not equal to expected seq (size = " + seq.size() + ")", seq, concat.init());
			}
			seq = seq.append(i % 63);
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
