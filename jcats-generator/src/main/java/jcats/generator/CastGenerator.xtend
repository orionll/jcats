package jcats.generator

final class CastGenerator implements ClassGenerator {
	override className() { "jcats.Cast" }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.lang.ref.*;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.Optional;
		import java.util.stream.Stream;
		import java.util.concurrent.Callable;
		import java.util.concurrent.Future;
		import java.util.function.*;

		import static java.util.Objects.requireNonNull;

		public final class Cast {

			private Cast() {}

			«cast("Iterable", "castIterable", #["A"], #[], #["A"])»

			«cast("Iterator", "castIterator", #["A"], #[], #["A"])»

			«cast("Comparator", "castComparator", #["A"], #["A"], #[])»

			«cast("Optional", "castOptional", #["A"], #[], #["A"])»

			«cast("Stream", "castStream", #["A"], #[], #["A"])»

			«cast("Callable", "castCallable", #["A"], #[], #["A"])»

			«cast("Future", "castFuture", #["A"], #[], #["A"])»

			«cast("BiConsumer", "castBiConsumer", #["A1", "A2"], #["A1", "A2"], #[])»

			«cast("BiFunction", "castBiFunction", #["A1", "A2", "B"], #["A1", "A2"], #["B"])»

			«cast("BiPredicate", "castBiPredicate", #["A1", "A2"], #["A1", "A2"], #[])»

			«cast("Consumer", "castConsumer", #["A"], #["A"], #[])»

			«cast("DoubleFunction", "castDoubleFunction", #["A"], #[], #["A"])»

			«cast("IntFunction", "castIntFunction", #["A"], #[], #["A"])»

			«cast("LongFunction", "castLongFunction", #["A"], #[], #["A"])»

			«cast("Function", "castFunction", #["A", "B"], #["A"], #["B"])»

			«cast("ObjDoubleConsumer", "castObjDoubleConsumer", #["A"], #["A"], #[])»

			«cast("ObjIntConsumer", "castObjIntConsumer", #["A"], #["A"], #[])»

			«cast("ObjLongConsumer", "castObjLongConsumer", #["A"], #["A"], #[])»

			«cast("Predicate", "castPredicate", #["A"], #["A"], #[])»

			«cast("Supplier", "castSupplier", #["A"], #[], #["A"])»

			«cast("ToDoubleBiFunction", "castToDoubleBiFunction", #["A1", "A2"], #["A1", "A2"], #[])»

			«cast("ToIntBiFunction", "castToIntBiFunction", #["A1", "A2"], #["A1", "A2"], #[])»

			«cast("ToLongBiFunction", "castToLongBiFunction", #["A1", "A2"], #["A1", "A2"], #[])»

			«cast("ToDoubleFunction", "castToDoubleFunction", #["A"], #["A"], #[])»

			«cast("ToIntFunction", "castToIntFunction", #["A"], #["A"], #[])»

			«cast("ToLongFunction", "castToLongFunction", #["A"], #["A"], #[])»

			«cast("Reference", "castReference", #["A"], #[], #["A"])»

			«cast("WeakReference", "castWeakReference", #["A"], #[], #["A"])»

			«cast("SoftReference", "castSoftReference", #["A"], #[], #["A"])»

			«cast("PhantomReference", "castPhantomReference", #["A"], #[], #["A"])»

			«cast("ReferenceQueue", "castReferenceQueue", #["A"], #[], #["A"])»
		}
	''' }
}