package jcats.collection;

import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;
import org.junit.Test;

import java.util.Set;

import static jcats.collection.LongUnique.longUnique;
import static org.junit.Assert.*;

public class TestLongUnique {

	@Test
	public void singleElementSize() {
		assertEquals(1, longUnique(1).size());
		assertEquals(1, longUnique(1, 1).size());
	}

	@Test
	public void singleElementRemove() {
		assertTrue(longUnique(1).remove(1).isEmpty());
		assertTrue(longUnique(1).remove(2).contains(1));
	}

	@Test
	public void hashCodeClashContains() {
		final long a = 3, b = 0x3_0000_0000L;
		assertTrue(longUnique(a, b).contains(b));
		assertFalse(longUnique(a, b).contains(17));
	}

	@Test
	public void iterator() {
		final long a = 0, b = 1, c = 2, d = 3, e = 0x3_0000_0000L, f = 17;
		final LongUnique unique = longUnique(a).put(b).put(c).put(d).put(e).put(f);
		final Set<Long> actual = Sets.newHashSet(unique);
		final Set<Long> expected = ImmutableSet.of(a, b, c, d, e, f);
		assertEquals(expected, actual);
	}

	@Test
	public void hashcode() {
		final long a = 0, b = 1, c = 2, d = 3, e = 0x3_0000_0000L;
		final LongUnique unique1 = longUnique(a, b, c, d, e);
		final LongUnique unique2 = longUnique(e, b, c, d, a);
		assertEquals(unique1.hashCode(), unique2.hashCode());
	}
}
