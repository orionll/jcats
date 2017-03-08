package jcats.collection;


import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.ThreadLocalRandom;

import org.junit.Test;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterators;

import static jcats.Option.some;
import static jcats.P.p;
import static jcats.collection.OrdDict.BLACK;
import static jcats.collection.OrdDict.RED;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import jcats.Ord;
import jcats.P;

public class TestOrdDict {

	@Test
	public void testPut() {
		final OrdDict<Character, String> dict = createTestDict();

		assertDict(dict, dict, 'M', "mm", null);
		assertDict(dict, dict.left, 'E', "e", RED);
		assertDict(dict, dict.right, 'R', "r", BLACK);
		assertDict(dict, dict.left.left, 'C', "c", BLACK);
		assertDict(dict, dict.left.right, 'J', "jj", BLACK);
		assertDict(dict, dict.right.left, 'P', "pp", BLACK);
		assertDict(dict, dict.right.right, 'X', "x", BLACK);
		assertDict(dict, dict.left.left.left, 'A', "a", BLACK);
		assertDict(dict, dict.left.left.right, 'D', "d", BLACK);
		assertDict(dict, dict.left.right.left, 'H', "hh", BLACK);
		assertDict(dict, dict.left.right.right, 'L', "l", BLACK);
		assertEquals(null, dict.right.left.left);
		assertEquals(null, dict.right.left.right);
		assertDict(dict, dict.right.right.left, 'S', "s", RED);
		assertEquals(null, dict.right.right.right);
	}

	@Test
	public void testPutRandom() {
		OrdDict<Character, Integer> dict = OrdDict.emptyDict(Ord.<Character>ord());
		final Map<Character, Integer> map = new HashMap<>();

		for (int i = 0; i < 100; i++) {
			final char key =  (char) ThreadLocalRandom.current().nextInt('A', 'Z' + 1);
			dict = dict.put(key, i);
			map.put(key, i);
			for (final Entry<Character, Integer> entry : map.entrySet()) {
				assertEquals(some(entry.getValue()), dict.get(entry.getKey()));
			}
		}
	}

	@Test
	public void testEmptyIterator() {
		final OrdDict<Character, Object> dict = OrdDict.emptyDict(Ord.<Character>ord());
		assertEquals(0, Iterators.size(dict.iterator()));
	}

	@Test
	public void testIterator() {
		final OrdDict<Character, String> dict = createTestDict();
		final ImmutableList<P<Character, String>> list = ImmutableList.of(
				p('A', "a"), p('C', "c"), p('D', "d"), p('E', "e"), p('H', "hh"), p('J', "jj"),
				p('L', "l"), p('M', "mm"), p('P', "pp"), p('R', "r"), p('S', "s"), p('X', "x"));

		assertTrue(Iterators.elementsEqual(list.iterator(), dict.iterator()));
	}

	private static OrdDict<Character, String> createTestDict() {
		OrdDict<Character, String> dict = OrdDict.emptyDict(Ord.<Character>ord());
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
		return dict;
	}

	private static <K, A> void assertDict(final OrdDict<K, A> root, final OrdDict<K, A> dict, final K expectedKey, final A expectedValue,
			final Boolean expectedColor) {
		assertEquals(expectedKey, dict.entry.get1());
		assertEquals(expectedValue, dict.entry.get2());
		if (expectedColor != null) {
			assertEquals(expectedColor, dict.color);
		}
		assertEquals(some(expectedValue), root.get(expectedKey));
		assertEquals(Ord.ord(), dict.ord);
	}
}
