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

	public String genericName() {
		return (this == OBJECT) ? "A" : javaName();
	}

	public String genericBoxedName() {
		return (this == OBJECT) ? "A" : boxedName();
	}

	public String genericCast() {
		return (this == OBJECT) ? "(A) " : "";
	}

	public String iteratorGenericName() {
		if (this == Type.OBJECT) {
			return "Iterator<A>";
		} else if (this == Type.BOOL) {
			return "Iterator<Boolean>";
		} else {
			return "PrimitiveIterator.Of" + javaPrefix();
		}
	}

	public String streamGenericName() {
		if (this == Type.OBJECT) {
			return "Stream<A>";
		} else if (this == Type.BOOL) {
			return "Stream<Boolean>";
		} else {
			return javaPrefix() + "Stream";
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
		if (this == Type.OBJECT) {
			return "Iterator<?>";
		} else if (this == Type.BOOL) {
			return "Iterator<Boolean>";
		} else {
			return "PrimitiveIterator.Of" + javaPrefix();
		}
	}

	public String iteratorNext() {
		return javaUnboxedTypes().contains(this) ? "next" + javaPrefix() : "next";
	}

	public String getIterator(String iterator) {
		return javaUnboxedTypes().contains(this) ? typeName() + "Iterator.getIterator(" + iterator + ")" : iterator;
	}

	public static ImmutableList<Type> javaUnboxedTypes() {
		return ImmutableList.of(Type.INT, Type.LONG, Type.DOUBLE);
	}
}
