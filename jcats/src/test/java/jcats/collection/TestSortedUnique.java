package jcats.collection;


import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterators;
import org.junit.Test;

import java.util.List;
import java.util.Random;
import java.util.SortedSet;
import java.util.TreeSet;

import static jcats.collection.Array.array;
import static jcats.collection.SortedUnique.*;
import static org.junit.Assert.*;

public class TestSortedUnique {

	@Test
	public void empty() {
		final SortedUnique<Character> unique = emptySortedUnique();
		assertEquals(0, unique.size());
		assertEquals(0, Iterators.size(unique.iterator()));
	}

	@Test
	public void emptyContainsNothing() {
		final SortedUnique<Character> unique = emptySortedUnique();
		assertFalse(unique.contains('A'));
	}

	@Test
	public void iterator() {
		final SortedUnique<Character> unique = createTestSortedUnique();
		final ImmutableList<Character> list = ImmutableList.of('A', 'C', 'D', 'E', 'H', 'J', 'L', 'M', 'P', 'R', 'S', 'X');

		assertTrue(Iterators.elementsEqual(list.iterator(), unique.iterator()));
		assertEquals(list.size(), unique.size());
	}

	@Test
	public void putRandom() {
		SortedUnique<Integer> unique = emptySortedUnique();
		final SortedSet<Integer> set = new TreeSet<>();

		final long seed = System.currentTimeMillis();
		final Random random = new Random(seed);
		final int size = 1000;

		for (int i = 0; i < size; i++) {
			final int key = random.nextInt(size);
			unique = unique.put(key);
			set.add(key);
			for (final Integer value : set) {
				assertTrue("Assertion failed for seed: " + seed, unique.contains(value));
			}
			assertUniqueEquals("Assertion failed for seed: " + seed, set, unique);
		}
	}

	@Test
	public void putSame() {
		final SortedUnique<Character> unique = createTestSortedUnique();
		final SortedUnique<Character> newUnique = unique.put('H');
		assertSame(unique, newUnique);
	}

	@Test
	public void removeFromEmpty() {
		final SortedUnique<Character> unique = emptySortedUnique();
		assertSame(unique, unique.remove('A'));
	}

	@Test
	public void remove() {
		SortedUnique<Integer> unique = emptySortedUnique();
		final SortedSet<Integer> set = new TreeSet<>();
		final int size = 300;
		for (int i = 0; i < size; i++) {
			unique = unique.put(i);
			set.add(i);
		}
		for (int i = 0; i < size; i++) {
			unique = unique.remove(i);
			set.remove(i);
			assertUniqueEquals("Assertion failed after removing " + i, set, unique);
		}
	}

	@Test
	public void removeReverse() {
		SortedUnique<Integer> unique = emptySortedUnique();
		final SortedSet<Integer> set = new TreeSet<>();
		final int size = 300;
		for (int i = 0; i < size; i++) {
			unique = unique.put(i);
			set.add(i);
		}
		for (int i = 0; i < size; i++) {
			final int elem = size - i - 1;
			unique = unique.remove(elem);
			set.remove(elem);
			assertUniqueEquals("Assertion failed after removing " + elem, set, unique);
		}
	}

	@Test
	public void removeAbsent() {
		final SortedUnique<Character> unique = createTestSortedUnique();
		final SortedUnique<Character> newUnique = unique.remove('Y');
		assertSame(unique, newUnique);
	}

	@Test
	public void removeWithDoubleRightLeftRotation() {
		SortedUnique<Integer> unique = emptySortedUnique();
		final SortedSet<Integer> set = new TreeSet<>();
		final Array<Integer> sequence = array(3, 2, 6, 1, 5, 7, 4);
		for (final Integer i : sequence) {
			unique = unique.put(i);
			set.add(i);
		}
		unique = unique.remove(1);
		set.remove(1);
		assertUniqueEquals("Assertion failed after double right left rotation", set, unique);
	}

	@Test
	public void removeWithDoubleLeftRightRotation() {
		SortedUnique<Integer> unique = emptySortedUnique();
		final SortedSet<Integer> set = new TreeSet<>();
		final Array<Integer> sequence = array(4, 7, 5, 1, 6, 2, 3);
		for (final Integer i : sequence) {
			unique = unique.put(i);
			set.add(i);
		}
		unique = unique.remove(6);
		set.remove(6);
		assertUniqueEquals("Assertion failed after double left right rotation", set, unique);
	}

	@Test
	public void removeRandom() {
		SortedUnique<Integer> unique = emptySortedUnique();
		final SortedSet<Integer> set = new TreeSet<>();

		final long seed = System.currentTimeMillis();
		final Random random = new Random(seed);
		final int size = 1000;

		for (int i = 0; i < size; i++) {
			final int key = random.nextInt(size);
			unique = unique.put(key);
			set.add(key);
		}

		for (int i = 0; i < (2 * size); i++) {
			final int key = random.nextInt(size);
			unique = unique.remove(key);
			set.remove(key);
			for (final Integer value : set) {
				assertTrue("Assertion failed for seed: " + seed, unique.contains(value));
			}
			assertUniqueEquals("Assertion failed for seed: " + seed, set, unique);
		}
	}

	@Test
	public void immutability() {
		final SortedUnique<Character> unique = createTestSortedUnique();
		unique.put('B');
		unique.remove('D');
		assertFalse(unique.contains('B'));
		assertTrue(unique.contains('D'));
	}

	private static SortedUnique<Character> createTestSortedUnique() {
		SortedUnique<Character> unique = sortedUnique('E', 'A', 'R', 'S', 'C', 'H', 'X', 'M', 'P', 'J', 'D', 'L');

		unique = unique.put('H');
		unique = unique.put('J');
		unique = unique.put('P');
		unique = unique.put('M');
		unique = unique.put('A');
		unique = unique.put('X');

		unique.checkHeight();

		return unique;
	}

	private static void assertUniqueEquals(final String message, final SortedSet<Integer> set, final SortedUnique<Integer> unique) {
		assertNotNull(message, unique);
		unique.checkHeight();
		assertEquals(message, set.size(), unique.size());
		final List<Integer> uniqueValues = ImmutableList.copyOf(unique.iterator());
		final List<Integer> setValues = ImmutableList.copyOf(set);
		assertEquals(message, setValues, uniqueValues);
	}
}
