package jcats.collection;

import org.junit.Ignore;
import org.junit.Test;

import static jcats.collection.Seq.seq;
import static org.junit.Assert.assertEquals;

public final class TestSeqBuilder {

	@Test
	public void appendEmptySeqBuilder() {
		final Seq<Integer> seq = Seq.<Integer> builder().append(0).appendSeqBuilder(Seq.builder()).build();
		assertEquals(1, seq.size());
		assertEquals(0, (int) seq.first());
	}

	@Test
	public void appendSeqBuilder1() {
		final SeqBuilder<Integer> builder1 = Seq.<Integer>builder().append(0);
		final SeqBuilder<Integer> builder2 = Seq.<Integer>builder().append(1).append(2);
		final Seq<Integer> seq = builder1.appendSeqBuilder(builder2).build();
		assertEquals(3, seq.size());
		assertEquals(seq(0, 1, 2), seq);
	}

	@Test
	public void appendSeqBuilder2() {
		final Seq<Integer> seq2 = Seq.tabulate(250, i -> i + 1);
		final SeqBuilder<Integer> builder1 = Seq.<Integer>builder().append(0);
		final SeqBuilder<Integer> builder2 = Seq.<Integer>builder().appendAll(seq2);
		final Seq<Integer> seq = builder1.appendSeqBuilder(builder2).build();
		assertEquals(251, seq.size());
		assertEquals(seq(0).concat(seq2), seq);
	}

	@Test
	public void appendSeqBuilder3() {
		final Seq<Integer> seq3 = Seq.tabulate(2500, i -> i + 1);
		final SeqBuilder<Integer> builder1 = Seq.<Integer>builder().append(0);
		final SeqBuilder<Integer> builder2 = Seq.<Integer>builder().appendAll(seq3);
		final Seq<Integer> seq = builder1.appendSeqBuilder(builder2).build();
		assertEquals(2501, seq.size());
		assertEquals(seq(0).concat(seq3), seq);
	}

	@Test
	public void appendSeqBuilder4() {
		final Seq<Integer> seq4 = Seq.tabulate(35_000, i -> i + 1);
		final SeqBuilder<Integer> builder1 = Seq.<Integer>builder().append(0);
		final SeqBuilder<Integer> builder2 = Seq.<Integer>builder().appendAll(seq4);
		final Seq<Integer> seq = builder1.appendSeqBuilder(builder2).build();
		assertEquals(35001, seq.size());
		assertEquals(seq(0).concat(seq4), seq);
	}

	@Test
	public void appendSeqBuilder5() {
		final Seq<Integer> seq5 = Seq.tabulate(1_500_000, i -> i + 1);
		final SeqBuilder<Integer> builder1 = Seq.<Integer>builder().append(0);
		final SeqBuilder<Integer> builder2 = Seq.<Integer>builder().appendAll(seq5);
		final Seq<Integer> seq = builder1.appendSeqBuilder(builder2).build();
		assertEquals(1500001, seq.size());
		assertEquals(seq(0).concat(seq5), seq);
	}

	@Ignore
	@Test
	public void appendSeqBuilder6() {
		final Seq<Integer> seq6 = Seq.tabulate(35_000_000, i -> i + 1);
		final SeqBuilder<Integer> builder1 = Seq.<Integer>builder().append(0);
		final SeqBuilder<Integer> builder2 = Seq.<Integer>builder().appendAll(seq6);
		final Seq<Integer> seq = builder1.appendSeqBuilder(builder2).build();
		assertEquals(35_000_001, seq.size());
		assertEquals(seq(0).concat(seq6), seq);
	}
}
