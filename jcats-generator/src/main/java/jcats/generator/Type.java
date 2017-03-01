package jcats.generator;

import com.google.common.collect.ImmutableList;

public enum Type {
	OBJECT,
	INT,
	LONG,
	DOUBLE,
	BOOL;

	public String typeName() {
		return toString().substring(0, 1) + toString().substring(1).toLowerCase();
	}

	public String javaName() {
		if (this == BOOL) {
			return "boolean";
		} else if (this == OBJECT) {
			return "Object";
		} else {
			return toString().toLowerCase();
		}
	}

	public String javaPrefix() {
		return javaName().substring(0, 1).toUpperCase() + javaName().substring(1);
	}

	public String boxedName() {
		switch (this) {
			case OBJECT: return "Object";
			case INT: return "Integer";
			case LONG: return "Long";
			case DOUBLE: return "Double";
			case BOOL: return "Boolean";
		}
		throw new IllegalStateException();
	}

	public String defaultValue() {
		switch (this) {
			case OBJECT: return "null";
			case INT: return "0";
			case LONG: return "0L";
			case DOUBLE: return "0.0";
			case BOOL: return "false";
		}
		throw new IllegalStateException();
	}

	public String genericName() {
		return (this == OBJECT) ? "A" : javaName();
	}

	public String genericName(String clazz) {
		return (this == OBJECT) ? clazz + "<A>" : typeName() + clazz;
	}

	public String paramGenericName(String clazz) {
		return (this == OBJECT) ? "<A> " + clazz + "<A>" : typeName() + clazz;
	}

	public String shortName(String clazz) {
		return (this == OBJECT) ? clazz : typeName() + clazz;
	}

	public String diamondName(String clazz) {
		return (this == OBJECT) ? clazz + "<>" : typeName() + clazz;
	}

	public String wildcardName(String clazz) {
		return (this == OBJECT) ? clazz + "<?>" : typeName() + clazz;
	}

	public String genericBoxedName() {
		return (this == OBJECT) ? "A" : boxedName();
	}

	public String genericJavaUnboxedName() {
		return (this == BOOL) ? "Boolean" : genericName();
	}

	public String javaUnboxedName() {
		return (this == BOOL) ? "Boolean" : javaName();
	}

	public String genericCast() {
		return (this == OBJECT) ? "(A) " : "";
	}

	public String f0GenericName() {
		return genericName("F0");
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

	public String iteratorGenericName() {
		switch (this) {
			case OBJECT: return "Iterator<A>";
			case BOOL: return "Iterator<Boolean>";
			default: return "PrimitiveIterator.Of" + javaPrefix();
		}
	}

	public String iteratorReturnType() {
		switch (this) {
			case OBJECT: return "A";
			case BOOL: return "Boolean";
			default: return javaName();
		}
	}

	public String spliteratorGenericName() {
		switch (this) {
			case OBJECT: return "Spliterator<A>";
			case BOOL: return "Spliterator<Boolean>";
			default: return "Spliterator.Of" + javaPrefix();
		}
	}

	public String emptySpliteratorName() {
		switch (this) {
			case OBJECT:
			case BOOL: return "emptySpliterator";
			default: return "empty" + javaPrefix() + "Spliterator";
		}
	}

	public String streamGenericName() {
		switch (this) {
			case OBJECT: return "Stream<A>";
			case BOOL: return "Stream<Boolean>";
			default: return javaPrefix() + "Stream";
		}
	}

	public String streamName() {
		if (Type.javaUnboxedTypes().contains(this)) {
			return javaPrefix() + "Stream";
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

	public String iteratorWildcardName() {
		switch (this) {
			case OBJECT: return "Iterator<?>";
			case BOOL: return "Iterator<Boolean>";
			default: return "PrimitiveIterator.Of" + javaPrefix();
		}
	}

	public String iteratorNext() {
		return javaUnboxedTypes().contains(this) ? "next" + javaPrefix() : "next";
	}

	public String toArrayName() {
		return (this == Type.OBJECT) ? "toObjectArray" : "toPrimitiveArray";
	}

	public String getIterator(String iterator) {
		return javaUnboxedTypes().contains(this) ? typeName() + "Iterator.getIterator(" + iterator + ")" : iterator;
	}

	public String emptyArrayName() {
		return "EMPTY_" + javaName().toUpperCase() + "_ARRAY";
	}

	public String updateFunction() {
		return (this == Type.OBJECT) ? "F<A, A>" : typeName() + typeName() + "F";
	}

	public String requireNonNull(String expr) {
		return (this == Type.OBJECT) ? "requireNonNull(" + expr + ")" : expr;
	}

	public String updateArray(String array, String index) {
		return "update" + shortName("Array") + "(" + array + ", " + index + ", f)";
	}

	public String boolFName() {
		return (this == Type.OBJECT) ? "BoolF<A>" : typeName() + "BoolF";
	}

	public static ImmutableList<Type> javaUnboxedTypes() {
		return ImmutableList.of(Type.INT, Type.LONG, Type.DOUBLE);
	}

	public static ImmutableList<Type> primitives() {
		return ImmutableList.of(Type.INT, Type.LONG, Type.DOUBLE, Type.BOOL);
	}
}
