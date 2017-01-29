package jcats.collection;

import com.google.common.collect.Iterators;
import com.google.common.collect.Sets;
import jcats.P;
import org.junit.Test;

import java.util.HashSet;
import java.util.Set;

import static jcats.Option.none;
import static jcats.Option.some;
import static jcats.P.p;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;


public class TestDict {

	private static final int LARGE_MAP_SIZE = 60;

	@Test
	public void empty() {
		assertTrue(Dict.empty().isEmpty());
	}

	@Test
	public void emptyZeroSize() {
		assertEquals(0, Dict.empty().size());
	}

	@Test
	public void emptyContainsNothing() {
		assertFalse(Dict.empty().containsKey("a"));
	}

	@Test
	public void emptyGetNone() {
		assertEquals(none(), Dict.empty().get("a"));
	}

	/*@Test
	public void emptyKeySet() {
		assertTrue(Dict.empty().keySet().isEmpty());
	}*/

	@Test
	public void singleElementNotEmpty() {
		assertFalse(Dict.empty().put("a", 1).isEmpty());
	}

	@Test
	public void singleElementSize() {
		assertEquals(1, Dict.empty().put("a", 1).size());
		assertEquals(1, Dict.empty().put("a", 1).put("a", 1).size());
	}

	@Test
	public void singleElementContains() {
		assertTrue(Dict.empty().put("a", 1).containsKey("a"));
	}

	@Test
	public void singleElementGet() {
		final Dict<String, Integer> dict = Dict.<String, Integer> empty().put("a", 1);
		assertEquals(some(1), dict.get("a"));
		assertEquals(some(2), dict.put("a", 2).get("a"));
		assertEquals(none(), dict.get("A"));
	}

	@Test
	public void singleElementRemove() {
		assertTrue(Dict.empty().put("a", 1).remove("a").isEmpty());
		assertEquals(some(1), Dict.empty().put("a", 1).remove("A").get("a"));
	}

	@Test
	public void singleElementRemoveAbsent() {
		assertEquals(some(1), Dict.empty().put("a", 1).remove("b").get("a"));
		assertEquals(1, Dict.empty().put("a", 1).remove("b").size());
	}

	/*@Test
	public void singleElementKeySet() {
		assertTrue(Dict.empty().put("a", 1).keySet().contains("a"));
	}*/

	@Test
	public void hashCodeClashContains() {
		assertTrue(Dict.empty().put("Aa", 1).put("BB", 2).containsKey("BB"));
		assertFalse(Dict.empty().put("Aa", 1).put("BB", 2).containsKey("XX"));
	}

	@Test
	public void hashCodeClashGet() {
		final Dict<String, Integer> dict1 = Dict.<String, Integer> empty().put("Aa", 1).put("BB", 2);
		assertEquals(some(1), dict1.get("Aa"));
		assertEquals(some(2), dict1.get("BB"));
		assertEquals(none(), dict1.get("XX"));
		assertEquals(2, dict1.size());

		final Dict<String, Integer> dict2 = Dict.<String, Integer>empty()
				.put("a", 1).put("b", 2).put("c", 3).put("Aa", 4).put("BB", 5);
		assertEquals(some(1), dict2.get("a"));
		assertEquals(some(2), dict2.get("b"));
		assertEquals(some(3), dict2.get("c"));
		assertEquals(some(4), dict2.get("Aa"));
		assertEquals(some(5), dict2.get("BB"));
		assertEquals(none(), dict2.get("XX"));
		assertEquals(5, dict2.size());

		Dict<String, Integer> dict3 = Dict.<String, Integer> empty()
				.put("Aa", 1).put("BB", 2).put("BB", 2).put("Aa", 3);
		assertEquals(some(3), dict3.get("Aa"));
		assertEquals(some(2), dict3.get("BB"));
		assertEquals(2, dict3.size());
	}

	@Test
	public void hashCodeClashRemove() {
		Dict<String, Integer> dict = Dict.<String, Integer> empty()
				.put("Aa", 1).put("BB", 2).remove("Aa");
		assertFalse(dict.containsKey("Aa"));
		assertEquals(some(2), dict.get("BB"));
		assertEquals(1, dict.size());
	}

	/*@Test
	public void hashCodeClashKeySet() {
		assertEquals(2, Dict.empty().put("Aa", 1).put("BB", 2).keySet().size());
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
		final Dict<String, Integer> dict = Dict.<String, Integer> empty().put("!", 1).put("a", 2).put("A", 3);
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
	public void immutabiluty() {
		Dict<Object, Object> map = Dict.empty().put("Aa", 1);
		map.put("BB", 2);
		map.remove("Aa");
		assertTrue(map.containsKey("Aa"));
		assertFalse(map.containsKey("BB"));
	}

	private static Dict<String, Integer> getLargeMap() {
		Dict<String, Integer> m = Dict.empty();
		for (int i = 0; i < LARGE_MAP_SIZE; i++) {
			m = m.put(Character.toString((char) ('A' + i)), i);
		}
		return m;
	}

	@Test
	public void testIterator() {
		final Dict<String, Integer> dict = Dict.<String, Integer> empty()
				.put("a", 1).put("b", 2).put("c", 3).put("Aa", 4).put("BB", 5).put("A", 6);
		final Set<P<String, Integer>> actual = Sets.newHashSet(dict);
		final Set<P<String, Integer>> expected =
				Sets.newHashSet(p("a", 1), p("b", 2), p("c", 3), p("Aa", 4), p("BB", 5), p("A", 6));
		assertEquals(expected, actual);
	}
}
