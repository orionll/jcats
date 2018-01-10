package jcats.collection;


import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterators;
import jcats.Ord;
import jcats.P;
import org.junit.Test;

import java.util.List;
import java.util.Map.Entry;
import java.util.Random;
import java.util.SortedMap;
import java.util.TreeMap;

import static jcats.Option.some;
import static jcats.P.p;
import static jcats.collection.Array.array;
import static jcats.collection.SortedDict.emptySortedDict;
import static org.junit.Assert.*;

public class TestSortedDict {

	@Test
	public void empty() {
		final SortedDict<Character, Object> dict = emptySortedDict();
		assertEquals(0, dict.size());
		assertEquals(0, Iterators.size(dict.iterator()));
	}

	@Test
	public void emptyContainsNothing() {
		final SortedDict<Character, Integer> dict = emptySortedDict();
		assertFalse(dict.containsKey('A'));
	}

	@Test
	public void iterator() {
		final SortedDict<Character, String> dict = createTestDict();
		final ImmutableList<P<Character, String>> list = ImmutableList.of(
				p('A', "a"), p('C', "c"), p('D', "d"), p('E', "e"), p('H', "hh"), p('J', "jj"),
				p('L', "l"), p('M', "mm"), p('P', "pp"), p('R', "r"), p('S', "s"), p('X', "x"));

		assertTrue(Iterators.elementsEqual(list.iterator(), dict.iterator()));
		assertEquals(list.size(), dict.size());
	}

	@Test
	public void putRandom() {
		SortedDict<Integer, Integer> dict = emptySortedDict();
		final SortedMap<Integer, Integer> map = new TreeMap<>();

		final long seed = System.currentTimeMillis();
		final Random random = new Random(seed);
		final int size = 1000;

		for (int i = 0; i < size; i++) {
			final int key = random.nextInt(size);
			dict = dict.put(key, i);
			map.put(key, i);
			for (final Entry<Integer, Integer> entry : map.entrySet()) {
				assertEquals("Assertion failed for seed: " + seed, some(entry.getValue()), dict.get(entry.getKey()));
			}
			assertDictEquals("Assertion failed for seed: " + seed, map, dict);
		}
	}

	@Test
	public void putSame() {
		final SortedDict<Character, String> dict = createTestDict();
		final SortedDict<Character, String> newDict = dict.put('H', "hh");
		assertTrue(dict == newDict);
	}

	@Test
	public void removeFromEmpty() {
		final SortedDict<Character, Object> dict = emptySortedDict();
		assertTrue(dict == dict.remove('A'));
	}

	@Test
	public void remove() {
		SortedDict<Integer, Integer> dict = emptySortedDict();
		final SortedMap<Integer, Integer> map = new TreeMap<>();
		final int size = 300;
		for (int i = 0; i < size; i++) {
			dict = dict.put(i, i);
			map.put(i, i);
		}
		for (int i = 0; i < size; i++) {
			dict = dict.remove(i);
			map.remove(i);
			assertDictEquals("Assertion failed after removing " + i, map, dict);
		}
	}

	@Test
	public void removeReverse() {
		SortedDict<Integer, Integer> dict = emptySortedDict();
		final SortedMap<Integer, Integer> map = new TreeMap<>();
		final int size = 300;
		for (int i = 0; i < size; i++) {
			dict = dict.put(i, i);
			map.put(i, i);
		}
		for (int i = 0; i < size; i++) {
			final int elem = size - i - 1;
			dict = dict.remove(elem);
			map.remove(elem);
			assertDictEquals("Assertion failed after removing " + elem, map, dict);
		}
	}

	@Test
	public void removeAbsent() {
		final SortedDict<Character, String> dict = createTestDict();
		final SortedDict<Character, String> newDict = dict.remove('Y');
		assertTrue(dict == newDict);
	}

	@Test
	public void removeWithDoubleRightLeftRotation() {
		SortedDict<Integer, Integer> dict = emptySortedDict();
		final SortedMap<Integer, Integer> map = new TreeMap<>();
		final Array<Integer> sequence = array(3, 2, 6, 1, 5, 7, 4);
		for (final Integer i : sequence) {
			dict = dict.put(i, i);
			map.put(i, i);
		}
		dict = dict.remove(1);
		map.remove(1);
		assertDictEquals("Assertion failed after double right left rotation", map, dict);
	}

	@Test
	public void removeWithDoubleLeftRightRotation() {
		SortedDict<Integer, Integer> dict = emptySortedDict();
		final SortedMap<Integer, Integer> map = new TreeMap<>();
		final Array<Integer> sequence = array(4, 7, 5, 1, 6, 2, 3);
		for (final Integer i : sequence) {
			dict = dict.put(i, i);
			map.put(i, i);
		}
		dict = dict.remove(6);
		map.remove(6);
		assertDictEquals("Assertion failed after double left right rotation", map, dict);
	}

	@Test
	public void removeRandom() {
		SortedDict<Integer, Integer> dict = emptySortedDict();
		final SortedMap<Integer, Integer> map = new TreeMap<>();

		final long seed = System.currentTimeMillis();
		final Random random = new Random(seed);
		final int size = 1000;

		for (int i = 0; i < size; i++) {
			final int key = random.nextInt(size);
			dict = dict.put(key, i);
			map.put(key, i);
		}

		for (int i = 0; i < (2 * size); i++) {
			final int key = random.nextInt(size);
			dict = dict.remove(key);
			map.remove(key);
			for (final Entry<Integer, Integer> entry : map.entrySet()) {
				assertEquals("Assertion failed for seed: " + seed, some(entry.getValue()), dict.get(entry.getKey()));
			}
			assertDictEquals("Assertion failed for seed: " + seed, map, dict);
		}

		System.out.println(Iterators.size(dict.iterator()));
	}

	@Test
	public void immutability() {
		final SortedDict<Character, String> dict = createTestDict();
		dict.put('B', "b");
		dict.remove('D');
		assertFalse(dict.containsKey('B'));
		assertTrue(dict.containsKey('D'));
	}

	private static SortedDict<Character, String> createTestDict() {
		SortedDict<Character, String> dict = emptySortedDict();
		dict = dict.put('E', "e");
		dict = dict.put('A', "a");
		dict = dict.put('R', "r");
		dict = dict.put('S', "s");
		dict = dict.put('C', "c");
		dict = dict.put('H', "h");
		dict = dict.put('X', "x");
		dict = dict.put('M', "m");
		dict = dict.put('P', "p");
		dict = dict.put('J', "j");
		dict = dict.put('D', "d");
		dict = dict.put('L', "l");

		dict = dict.put('H', "hh");
		dict = dict.put('J', "jj");
		dict = dict.put('P', "pp");
		dict = dict.put('M', "mm");

		dict = dict.put('A', "a");
		dict = dict.put('X', "x");

		dict.checkHeight();

		return dict;
	}

	private static void assertDictEquals(final String message, final SortedMap<Integer, Integer> map, final SortedDict<Integer, Integer> dict) {
		assertNotNull(message, dict);
		dict.checkHeight();
		assertEquals(message, map.size(), dict.size());
		final List<Entry<Integer, Integer>> dictEntries = ImmutableList.copyOf(Iterators.transform(dict.iterator(), P::toEntry));
		final List<Entry<Integer, Integer>> mapEntries = ImmutableList.copyOf(map.entrySet());
		assertEquals(message, mapEntries, dictEntries);
	}
}
