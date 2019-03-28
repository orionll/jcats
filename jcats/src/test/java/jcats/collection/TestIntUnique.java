package jcats.collection;

import org.junit.Test;

import java.util.HashSet;
import java.util.Random;
import java.util.Set;

import static jcats.collection.IntUnique.*;
import static org.junit.Assert.*;

public class TestIntUnique {

	@Test
	public void hashcode() {
		final IntUnique unique1 = intUnique(0, 1, 32, 33, 64);
		final IntUnique unique2 = intUnique(64, 1, 32, 33, 0);
		assertEquals(unique1.hashCode(), unique2.hashCode());
	}

	@Test
	public void random() {
		final Random random = new Random();
		final int size = random.nextInt(1000);
		IntUnique unique = emptyIntUnique();
		final Set<Integer> set = new HashSet<>();
		for (int i = 0; i < size; i++) {
			unique = unique.put(i);
			set.add(i);
			assertEquals(i + 1, unique.size());
			assertEquals(set, unique.toHashSet());
		}
		for (int i = 0; i < size; i++) {
			unique = unique.remove(i);
			set.remove(i);
			assertEquals(size - i - 1, unique.size());
			assertEquals(set, unique.toHashSet());
		}
		assertTrue(unique.isEmpty());
	}
}
