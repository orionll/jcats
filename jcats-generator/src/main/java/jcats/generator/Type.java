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

	public String arrayShortName() {
		return shortName("Array");
	}

	public String arrayGenericName() {
		return genericName("Array");
	}

	public String arrayDiamondName() {
		return diamondName("Array");
	}

	public String seqShortName() {
		return shortName("Seq");
	}

	public String seqGenericName() {
		return genericName("Seq");
	}

	public String seqBuilderGenericName() {
		return genericName("SeqBuilder");
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

	public String indexedContainerGenericName() {
		return genericName("IndexedContainer");
	}

	public String indexedContainerShortName() {
		return shortName("IndexedContainer");
	}

	public String indexedContainerWildcardName() {
		return wildcardName("IndexedContainer");
	}

	public String indexedGenericName() {
		return genericName("Indexed");
	}

	public String uniqueContainerShortName() {
		return shortName("UniqueContainer");
	}

	public String iteratorGenericName() {
		switch (this) {
			case OBJECT: return "Iterator<A>";
			case BOOLEAN: return "Iterator<Boolean>";
			default: return "PrimitiveIterator.Of" + typeName();
		}
	}

	public String iteratorReturnType() {
		switch (this) {
			case OBJECT: return "A";
			case BOOLEAN: return "Boolean";
			default: return javaName();
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
		if (Type.javaUnboxedTypes().contains(this)) {
			return typeName() + "Stream";
		} else {
			return "Stream";
		}
	}

	public String streamFunction() {
		if (Type.javaUnboxedTypes().contains(this)) {
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
		if (Type.javaUnboxedTypes().contains(this)) {
			return typeName() + "Stream2";
		} else {
			return "Stream2<>";
		}
	}

	public String stream2Name() {
		if (Type.javaUnboxedTypes().contains(this)) {
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
		return javaUnboxedTypes().contains(this) ? "next" + typeName() : "next";
	}

	public String toArrayName() {
		return (this == Type.OBJECT) ? "toObjectArray" : "toPrimitiveArray";
	}

	public String getIterator(final String iterator) {
		return javaUnboxedTypes().contains(this) ? typeName() + "Iterator.getIterator(" + iterator + ")" : iterator;
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
