package jcats.collection;


import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;
import org.junit.Test;

import java.util.Random;
import java.util.Set;

import static jcats.collection.Unique.*;
import static org.junit.Assert.*;

public class TestUnique {

	private static final int LARGE_MAP_SIZE = 60;

	@Test
	public void empty() {
		assertTrue(emptyUnique().isEmpty());
	}

	@Test
	public void emptyZeroSize() {
		assertEquals(0, emptyUnique().size());
	}

	@Test
	public void emptyContainsNothing() {
		assertFalse(emptyUnique().contains("a"));
	}

	@Test
	public void singleElementNotEmpty() {
		assertFalse(emptyUnique().put("a").isEmpty());
	}

	@Test
	public void singleElementSize() {
		assertEquals(1, unique("a").size());
		assertEquals(1, unique("a", "a").size());
	}

	@Test
	public void singleElementContains() {
		assertTrue(unique("a", 1).contains("a"));
	}

	@Test
	public void singleElementRemove() {
		assertTrue(unique("a").remove("a").isEmpty());
		assertTrue(unique("a").remove("A").contains("a"));
	}

	@Test
	public void singleElementRemoveAbsent() {
		assertTrue(unique("a").remove("b").contains("a"));
		assertEquals(1, unique("a").remove("b").size());
	}

	@Test
	public void hashCodeClashContains() {
		assertTrue(unique("Aa", "BB").contains("BB"));
		assertFalse(unique("Aa", "BB").contains("XX"));
	}

	@Test
	public void hashCodeClashGet() {
		final Unique<String> unique1 = unique("Aa", "BB");
		assertTrue(unique1.contains("Aa"));
		assertTrue(unique1.contains("BB"));
		assertFalse(unique1.contains("XX"));
		assertEquals(2, unique1.size());

		final Unique<String> unique2 = unique("a", "b", "c", "Aa", "BB");
		assertTrue(unique2.contains("a"));
		assertTrue(unique2.contains("b"));
		assertTrue(unique2.contains("c"));
		assertTrue(unique2.contains("Aa"));
		assertTrue(unique2.contains("BB"));
		assertFalse(unique2.contains("XX"));
		assertEquals(5, unique2.size());

		final Unique<String> unique3 = unique("Aa", "BB", "BB", "Aa");
		assertTrue(unique3.contains("Aa"));
		assertTrue(unique3.contains("BB"));
		assertEquals(2, unique3.size());

		final Unique<String> unique4 = unique("AaAa", "BBBB", "AaBB", "AaAa");
		assertTrue(unique4.contains("AaAa"));
		assertTrue(unique4.contains("BBBB"));
		assertTrue(unique4.contains("AaBB"));
		assertEquals(3, unique4.size());
	}

	@Test
	public void hashCodeClashRemove() {
		final Unique<String> unique = unique("Aa", "BB").remove("Aa");
		assertFalse(unique.contains("Aa"));
		assertTrue(unique.contains("BB"));
		assertEquals(1, unique.size());
	}

	@Test
	public void largeMapSize() {
		assertEquals(LARGE_MAP_SIZE, getLargeMap().size());
	}

	@Test
	public void largeMapContains() {
		assertTrue(getLargeMap().contains(Character.toString((char) (('A' + LARGE_MAP_SIZE) - 1))));
	}

	@Test
	public void largeMapGet() {
		assertTrue(getLargeMap().contains(Character.toString((char) (('A' + LARGE_MAP_SIZE) - 1))));
	}

	@Test
	public void largeMapRemove() {
		assertEquals(LARGE_MAP_SIZE - 1, getLargeMap().remove(Character.toString((char) (('A' + LARGE_MAP_SIZE) - 1))).size());
	}

	@Test
	public void sameTree() {
		final Unique<String> unique = unique("!", "a", "A");
		assertTrue(unique.contains("!"));
		assertTrue(unique.contains("a"));
		assertTrue(unique.contains("A"));
		assertEquals(3, unique.size());
	}

	@Test
	public void immutability() {
		final Unique<Object> map = unique("Aa", 1);
		map.put("BB");
		map.remove("Aa");
		assertTrue(map.contains("Aa"));
		assertFalse(map.contains("BB"));
	}

	private static Unique<String> getLargeMap() {
		Unique<String> m = emptyUnique();
		for (int i = 0; i < LARGE_MAP_SIZE; i++) {
			m = m.put(Character.toString((char) ('A' + i)));
		}
		return m;
	}

	@Test
	public void iterator() {
		final Unique<String> unique = unique("a").put("b").put("c").put("Aa").put("BB").put("A");
		final Set<String> actual = Sets.newHashSet(unique);
		final Set<String> expected = ImmutableSet.of("a", "b", "c", "Aa", "BB", "A");
		assertEquals(expected, actual);
	}

	@Test
	public void equals() {
		final Unique<String> unique1 = unique("a", "b", "c");
		final Unique<String> unique2 = unique("a", "b", "c");
		final Unique<String> unique3 = unique("a", "b", "c");
		final Unique<String> unique4 = unique("a", "b");
		final Unique<String> unique5 = unique("a", "b", "d");
		assertEquals(unique1, unique1);
		assertEquals(unique1, unique2);
		assertEquals(unique1, unique3);
		assertNotEquals(unique1, unique4);
		assertNotEquals(unique1, unique5);
	}

	@Test
	public void hashcode() {
		final Unique<String> unique1 = unique("a", "b", "c", "Aa", "BB");
		final Unique<String> unique2 = unique("BB", "b", "c", "Aa", "a");
		assertEquals(unique1.hashCode(), unique2.hashCode());
	}

	@Test
	public void traverse() {
		final Unique<String> unique = unique("a", "b", "c", "Aa", "BB");
		final Set<String> keys = Sets.newHashSet();
		unique.foreach(keys::add);

		assertEquals(ImmutableSet.of("a", "b", "c", "Aa", "BB"), keys);
	}

	@Test(expected = NullPointerException.class)
	public void nullValue() {
		unique("a", null);
	}

	@Test(expected = NullPointerException.class)
	public void nullKey() {
		unique(null, 1);
	}

	@Test
	public void random() {
		final Random random = new Random();
		final int size = random.nextInt(1000);
		Unique<Integer> unique = emptyUnique();
		for (int i = 0; i < size; i++) {
			unique = unique.put(i);
			assertEquals(i + 1, unique.size());
		}
		for (int i = 0; i < size; i++) {
			unique = unique.remove(i);
			assertEquals(size - i - 1, unique.size());
		}
		assertTrue(unique.isEmpty());
	}
}

