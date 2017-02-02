package jcats.generator.collection

import jcats.generator.InterfaceGenerator
import jcats.generator.Constants

class KeyValueGenerator implements InterfaceGenerator {
	
	override className() { Constants.COLLECTION + ".KeyValue" }
	
	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Spliterator;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.OPTION»;
		import «Constants.P»;
		import «Constants.SIZED»;
		import «Constants.EFF»;
		import «Constants.EFF»2;

		import static java.util.Objects.requireNonNull;


		public interface KeyValue<K, A> extends Iterable<P<K, A>>, Sized {

			Option<A> get(final K key);

			boolean containsKey(final K key);
			
			default boolean containsValue(final A value) {
				requireNonNull(value);
				for (final P<K, A> entry : this) {
					if (entry.get2().equals(value)) {
						return true;
					}
				}
				return false;
			}

			default void foreach(final Eff2<K, A> eff) {
				requireNonNull(eff);
				forEach(entry -> eff.apply(entry.get1(), entry.get2()));
			}

			default void forEachKey(final Eff<K> eff) {
				requireNonNull(eff);
				forEach(entry -> eff.apply(entry.get1()));
			}

			default void forEachValue(final Eff<A> eff) {
				requireNonNull(eff);
				forEach(entry -> eff.apply(entry.get2()));
			}

			default Stream<P<K, A>> stream() {
				return StreamSupport.stream(spliterator(), false);
			}

			default Stream<P<K, A>> parallelStream() {
				return StreamSupport.stream(spliterator(), true);
			}
		}
	''' }
	
}