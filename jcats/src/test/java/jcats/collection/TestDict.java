package jcats.collection;

import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Iterators;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import jcats.P;
import org.junit.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static jcats.Option.none;
import static jcats.Option.some;
import static jcats.P.p;
import static jcats.collection.Dict.*;
import static org.junit.Assert.*;


public class TestDict {

	private static final int LARGE_MAP_SIZE = 60;

	@Test
	public void empty() {
		assertTrue(emptyDict().isEmpty());
	}

	@Test
	public void emptyZeroSize() {
		assertEquals(0, emptyDict().size());
	}

	@Test
	public void emptyContainsNothing() {
		assertFalse(emptyDict().containsKey("a"));
	}

	@Test
	public void emptyGetNone() {
		assertEquals(none(), emptyDict().get("a"));
	}

	/*@Test
	public void emptyKeySet() {
		assertTrue(emptyDict().keySet().isEmpty());
	}*/

	@Test
	public void singleElementNotEmpty() {
		assertFalse(emptyDict().put("a", 1).isEmpty());
	}

	@Test
	public void singleElementSize() {
		assertEquals(1, dict("a", 1).size());
		assertEquals(1, dict2("a", 1, "a", 1).size());
	}

	@Test
	public void singleElementContains() {
		assertTrue(dict("a", 1).containsKey("a"));
	}

	@Test
	public void singleElementGet() {
		final Dict<String, Integer> dict = dict("a", 1);
		assertEquals(some(1), dict.get("a"));
		assertEquals(some(2), dict.put("a", 2).get("a"));
		assertEquals(none(), dict.get("A"));
	}

	@Test
	public void singleElementRemove() {
		assertTrue(dict("a", 1).remove("a").isEmpty());
		assertEquals(some(1), dict("a", 1).remove("A").get("a"));
	}

	@Test
	public void singleElementRemoveAbsent() {
		assertEquals(some(1), dict("a", 1).remove("b").get("a"));
		assertEquals(1, dict("a", 1).remove("b").size());
	}

	/*@Test
	public void singleElementKeySet() {
		assertTrue(emptyDict().put("a", 1).keySet().contains("a"));
	}*/

	@Test
	public void hashCodeClashContains() {
		assertTrue(dict2("Aa", 1, "BB", 2).containsKey("BB"));
		assertFalse(dict2("Aa", 1, "BB", 2).containsKey("XX"));
	}

	@Test
	public void hashCodeClashGet() {
		final Dict<String, Integer> dict1 = dict2("Aa", 1, "BB", 2);
		assertEquals(some(1), dict1.get("Aa"));
		assertEquals(some(2), dict1.get("BB"));
		assertEquals(none(), dict1.get("XX"));
		assertEquals(2, dict1.size());

		final Dict<String, Integer> dict2 = dict5("a", 1, "b", 2, "c", 3, "Aa", 4, "BB", 5);
		assertEquals(some(1), dict2.get("a"));
		assertEquals(some(2), dict2.get("b"));
		assertEquals(some(3), dict2.get("c"));
		assertEquals(some(4), dict2.get("Aa"));
		assertEquals(some(5), dict2.get("BB"));
		assertEquals(none(), dict2.get("XX"));
		assertEquals(5, dict2.size());

		final Dict<String, Integer> dict3 = dict4("Aa", 1, "BB", 2, "BB", 2, "Aa", 3);
		assertEquals(some(3), dict3.get("Aa"));
		assertEquals(some(2), dict3.get("BB"));
		assertEquals(2, dict3.size());
	}

	@Test
	public void hashCodeClashRemove() {
		final Dict<String, Integer> dict = dict2("Aa", 1, "BB", 2).remove("Aa");
		assertFalse(dict.containsKey("Aa"));
		assertEquals(some(2), dict.get("BB"));
		assertEquals(1, dict.size());
	}

	/*@Test
	public void hashCodeClashKeySet() {
		assertEquals(2, emptyDict().put("Aa", 1).put("BB", 2).keySet().size());
	}*/

	@Test
	public void largeMapSize() {
		assertEquals(LARGE_MAP_SIZE, getLargeMap().size());
	}

	@Test
	public void largeMapContains() {
		assertTrue(getLargeMap().containsKey(Character.toString((char) ('A' + LARGE_MAP_SIZE - 1))));
	}

	@Test
	public void largeMapGet() {
		assertEquals(some(LARGE_MAP_SIZE - 1), getLargeMap().get(Character.toString((char) ('A' + LARGE_MAP_SIZE - 1))));
	}

	@Test
	public void largeMapRemove() {
		assertEquals(LARGE_MAP_SIZE - 1, getLargeMap().remove(Character.toString((char) ('A' + LARGE_MAP_SIZE - 1))).size());
	}

	@Test
	public void sameTree() {
		final Dict<String, Integer> dict = dict3("!", 1, "a", 2, "A", 3);
		assertEquals(some(1), dict.get("!"));
		assertEquals(some(2), dict.get("a"));
		assertEquals(some(3), dict.get("A"));
		assertEquals(3, dict.size());
	}

	/*@Test
	public void largeMapKeySet() {
		assertEquals(LARGE_MAP_SIZE, getLargeMap().keySet().size());
	}*/

	@Test
	public void immutability() {
		final Dict<Object, Object> map = dict("Aa", 1);
		map.put("BB", 2);
		map.remove("Aa");
		assertTrue(map.containsKey("Aa"));
		assertFalse(map.containsKey("BB"));
	}

	private static Dict<String, Integer> getLargeMap() {
		Dict<String, Integer> m = emptyDict();
		for (int i = 0; i < LARGE_MAP_SIZE; i++) {
			m = m.put(Character.toString((char) ('A' + i)), i);
		}
		return m;
	}

	@Test
	public void iterator() {
		final Dict<String, Integer> dict = dict("a", 1).put("b", 2).put("c", 3).put("Aa", 4).put("BB", 5).put("A", 6);
		final Set<P<String, Integer>> actual = Sets.newHashSet(dict);
		final Set<P<String, Integer>> expected =
				ImmutableSet.of(p("a", 1), p("b", 2), p("c", 3), p("Aa", 4), p("BB", 5), p("A", 6));
		assertEquals(expected, actual);
	}

	@Test
	public void equals() {
		final Dict<String, Integer> dict1 = dict3("a", 1, "b", 2, "c", 3);
		final Dict<String, Integer> dict2 = dict3("a", 1, "b", 2, "c", 3);
		final Dict<String, Integer> dict3 = dict3("a", 1, "b", 2, "c", 4);
		final Dict<String, Integer> dict4 = dict2("a", 1, "b", 2);
		final Dict<String, Integer> dict5 = dict3("a", 1, "b", 2, "d", 3);
		assertEquals(dict1, dict1);
		assertEquals(dict1, dict2);
		assertNotEquals(dict1, dict3);
		assertNotEquals(dict1, dict4);
		assertNotEquals(dict1, dict5);
	}

	@Test
	public void hashcode() {
		final Dict<String, Integer> dict1 = dict5("a", 1, "b", 2, "c", 3, "Aa", 4, "BB", 5);
		final Dict<String, Integer> dict2 = dict5("BB", 5, "b", 2, "c", 3, "Aa", 4, "a", 1);
		assertEquals(dict1.hashCode(), dict2.hashCode());
	}

	@Test
	public void traverse() {
		final Dict<String, Integer> dict = dict5("a", 1, "b", 2, "c", 3, "Aa", 4, "BB", 5);
		final Set<String> keys = Sets.newHashSet();
		final Set<Integer> values = Sets.newHashSet();
		dict.traverse((key, value) -> {
			keys.add(key);
			values.add(value);
		});

		assertEquals(ImmutableSet.of("a", "b", "c", "Aa", "BB"), keys);
		assertEquals(ImmutableSet.of(1, 2, 3, 4, 5), values);
	}

	@Test(expected = NullPointerException.class)
	public void nullValue() {
		dict("a", null);
	}

	@Test(expected = NullPointerException.class)
	public void nullKey() {
		dict(null, 1);
	}
}
