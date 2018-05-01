package jcats.generator;

import com.google.common.collect.ImmutableList;

public enum Type {
	OBJECT,
	INT,
	LONG,
	DOUBLE,
	BOOLEAN;

	public String typeName() {
		return toString().substring(0, 1) + toString().substring(1).toLowerCase();
	}

	public String javaName() {
		if (this == OBJECT) {
			return "Object";
		} else {
			return toString().toLowerCase();
		}
	}

	public String boxedName() {
		switch (this) {
			case OBJECT: return "Object";
			case INT: return "Integer";
			case LONG: return "Long";
			case DOUBLE: return "Double";
			case BOOLEAN: return "Boolean";
		}
		throw new IllegalStateException();
	}

	public boolean isPrimitive() {
		return (this != OBJECT);
	}

	public boolean isJavaUnboxedType() {
		return javaUnboxedTypes().contains(this);
	}

	public String defaultValue() {
		switch (this) {
			case OBJECT: return "null";
			case INT: return "0";
			case LONG: return "0L";
			case DOUBLE: return "0.0";
			case BOOLEAN: return "false";
		}
		throw new IllegalStateException();
	}

	public String genericName() {
		return (this == OBJECT) ? "A" : javaName();
	}

	public String genericName(final String clazz) {
		return (this == OBJECT) ? clazz + "<A>" : typeName() + clazz;
	}

	public String covariantName(final String clazz) {
		return (this == OBJECT) ? clazz + "<@Covariant A>" : typeName() + clazz;
	}

	public String contravariantName(final String clazz) {
		return (this == OBJECT) ? clazz + "<@Contravariant A>" : typeName() + clazz;
	}

	public String paramGenericName(final String clazz) {
		return (this == OBJECT) ? "<A> " + clazz + "<A>" : typeName() + clazz;
	}

	public String shortName(final String clazz) {
		return (this == OBJECT) ? clazz : typeName() + clazz;
	}

	public String diamondName(final String clazz) {
		return (this == OBJECT) ? clazz + "<>" : typeName() + clazz;
	}

	public String wildcardName(final String clazz) {
		return (this == OBJECT) ? clazz + "<?>" : typeName() + clazz;
	}

	public String genericBoxedName() {
		return (this == OBJECT) ? "A" : boxedName();
	}

	public String genericJavaUnboxedName() {
		return (this == BOOLEAN) ? "Boolean" : genericName();
	}

	public String javaUnboxedName() {
		return (this == BOOLEAN) ? "Boolean" : javaName();
	}

	public String genericCast() {
		return (this == OBJECT) ? "(A) " : "";
	}

	public String f0GenericName() {
		return genericName("F0");
	}

	public String maybeShortName() {
		return shortName("Maybe");
	}

	public String maybeGenericName() {
		return genericName("Maybe");
	}

	public String optionShortName() {
		return shortName("Option");
	}

	public String optionGenericName() {
		return genericName("Option");
	}

	public String someName() {
		return Generator.firstToLowerCase(shortName("Some"));
	}

	public String noneName() {
		return Generator.firstToLowerCase(shortName("None"));
	}

	public String ordShortName() {
		return shortName("Ord");
	}

	public String ordGenericName() {
		return genericName("Ord");
	}

	public String asc() {
		return Generator.firstToLowerCase(shortName("Asc"));
	}

	public String desc() {
		return Generator.firstToLowerCase(shortName("Desc"));
	}

	public String arrayShortName() {
		return shortName("Array");
	}

	public String arrayGenericName() {
		return genericName("Array");
	}

	public String arrayDiamondName() {
		return diamondName("Array");
	}

	public String arrayWildcardName() {
		return wildcardName("Array");
	}

	public String arrayBuilderShortName() {
		return shortName("ArrayBuilder");
	}

	public String arrayBuilderGenericName() {
		return genericName("ArrayBuilder");
	}

	public String stackShortName() {
		return shortName("Stack");
	}

	public String stackGenericName() {
		return genericName("Stack");
	}

	public String stackBuilderShortName() {
		return shortName("StackBuilder");
	}

	public String stackBuilderGenericName() {
		return genericName("StackBuilder");
	}

	public String seqShortName() {
		return shortName("Seq");
	}

	public String seqGenericName() {
		return genericName("Seq");
	}

	public String seqBuilderShortName() {
		return shortName("SeqBuilder");
	}

	public String seqBuilderGenericName() {
		return genericName("SeqBuilder");
	}

	public String seqBuilderDiamondName() {
		return diamondName("SeqBuilder");
	}

	public String sortedUniqueShortName() {
		return shortName("SortedUnique");
	}

	public String sortedUniqueGenericName() {
		return genericName("SortedUnique");
	}

	public String effShortName() {
		return shortName("Eff");
	}

	public String effGenericName() {
		return genericName("Eff");
	}

	public String containerShortName() {
		return shortName("Container");
	}

	public String containerGenericName() {
		return genericName("Container");
	}

	public String containerWildcardName() {
		return wildcardName("Container");
	}

	public String containerViewGenericName() {
		return genericName("ContainerView");
	}

	public String indexedContainerGenericName() {
		return genericName("IndexedContainer");
	}

	public String indexedContainerShortName() {
		return shortName("IndexedContainer");
	}

	public String indexedContainerWildcardName() {
		return wildcardName("IndexedContainer");
	}

	public String indexedContainerViewShortName() {
		return shortName("IndexedContainerView");
	}

	public String indexedContainerViewGenericName() {
		return genericName("IndexedContainerView");
	}

	public String indexedGenericName() {
		return genericName("Indexed");
	}

	public String uniqueContainerShortName() {
		return shortName("UniqueContainer");
	}

	public String uniqueContainerGenericName() {
		return genericName("UniqueContainer");
	}

	public String uniqueContainerWildcardName() {
		return wildcardName("UniqueContainer");
	}

	public String iteratorShortName(final String baseName) {
		return shortName(baseName + "Iterator");
	}

	public String iteratorGenericName() {
		if (isJavaUnboxedType()) {
			return "PrimitiveIterator.Of" + typeName();
		} else {
			return "Iterator<" + genericBoxedName() + ">";
		}
	}

	public String iteratorGenericName(final String baseName) {
		return genericName(baseName + "Iterator");
	}

	public String iteratorDiamondName(final String baseName) {
		return diamondName(baseName + "Iterator");
	}

	public String iteratorReturnType() {
		if (isJavaUnboxedType()) {
			return javaName();
		} else {
			return genericBoxedName();
		}
	}

	public String emptyIterator() {
		if (isJavaUnboxedType()) {
			return noneName() + "().iterator()";
		} else {
			return "Collections.emptyIterator()";
		}
	}

	public String spliteratorGenericName() {
		switch (this) {
			case OBJECT: return "Spliterator<A>";
			case BOOLEAN: return "Spliterator<Boolean>";
			default: return "Spliterator.Of" + typeName();
		}
	}

	public String emptySpliteratorName() {
		switch (this) {
			case OBJECT:
			case BOOLEAN: return "emptySpliterator";
			default: return "empty" + typeName() + "Spliterator";
		}
	}

	public String streamGenericName() {
		switch (this) {
			case OBJECT: return "Stream<A>";
			case BOOLEAN: return "Stream<Boolean>";
			default: return typeName() + "Stream";
		}
	}

	public String streamName() {
		if (isJavaUnboxedType()) {
			return typeName() + "Stream";
		} else {
			return "Stream";
		}
	}

	public String streamFunction() {
		if (isJavaUnboxedType()) {
			return javaName() + "Stream";
		} else {
			return "stream";
		}
	}

	public String stream2GenericName() {
		switch (this) {
			case OBJECT: return "Stream2<A>";
			case BOOLEAN: return "Stream2<Boolean>";
			default: return typeName() + "Stream2";
		}
	}

	public String stream2DiamondName() {
		if (isJavaUnboxedType()) {
			return typeName() + "Stream2";
		} else {
			return "Stream2<>";
		}
	}

	public String stream2Name() {
		if (isJavaUnboxedType()) {
			return typeName() + "Stream2";
		} else {
			return "Stream2";
		}
	}

	public String iteratorWildcardName() {
		switch (this) {
			case OBJECT: return "Iterator<?>";
			case BOOLEAN: return "Iterator<Boolean>";
			default: return "PrimitiveIterator.Of" + typeName();
		}
	}

	public String iteratorNext() {
		return isJavaUnboxedType() ? "next" + typeName() : "next";
	}

	public String toArrayName() {
		return (this == Type.OBJECT) ? "toObjectArray" : "toPrimitiveArray";
	}

	public String getIterator(final String iterator) {
		return isJavaUnboxedType() ? typeName() + "Iterator.getIterator(" + iterator + ")" : iterator;
	}

	public String emptyArrayName() {
		return "EMPTY_" + javaName().toUpperCase() + "_ARRAY";
	}

	public String updateFunction() {
		return (this == Type.OBJECT) ? "F<A, A>" : typeName() + typeName() + "F";
	}

	public String requireNonNull(final String expr) {
		return (this == Type.OBJECT) ? "requireNonNull(" + expr + ")" : expr;
	}

	public String updateArray(final String array, final String index) {
		return "update" + shortName("Array") + "(" + array + ", " + index + ", f)";
	}

	public String boolFName() {
		return (this == Type.OBJECT) ? "BooleanF<A>" : typeName() + "BooleanF";
	}

	public static ImmutableList<Type> javaUnboxedTypes() {
		return ImmutableList.of(Type.INT, Type.LONG, Type.DOUBLE);
	}

	public static ImmutableList<Type> primitives() {
		return ImmutableList.of(Type.INT, Type.LONG, Type.DOUBLE, Type.BOOLEAN);
	}
}
