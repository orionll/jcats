package jcats.generator

final class String1Generator implements ClassGenerator {
	override className() { Constants.STRING1 }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Locale;
		import «Constants.COLLECTION».IntStream2;

		import static «Constants.COLLECTION».IntStream2.*;

		/**
		 * Nonempty string
		 */
		public final class String1 implements CharSequence, Equatable<String1>, Comparable<String1>, Serializable {
			private static final String1CaseInsensitiveOrd CASE_INSENSITIVE_ORD = new String1CaseInsensitiveOrd();

			final String str;

			private String1(final String str) {
				this.str = str;
			}

			@Override
			public int length() {
				return str.length();
			}

			@Override
			public char charAt(final int index) {
				return str.charAt(index);
			}

			@Override
			public CharSequence subSequence(final int start, final int end) {
				return str.subSequence(start, end);
			}

			@Override
			public IntStream2 chars() {
				return intStream2(str.chars());
			}

			@Override
			public IntStream2 codePoints() {
				return intStream2(str.codePoints());
			}

			public boolean startsWith(final String1 prefix) {
				return str.startsWith(prefix.str);
			}

			public boolean endsWith(final String1 suffix) {
				return str.endsWith(suffix.str);
			}

			public int indexOf(final int ch) {
				return str.indexOf(ch);
			}

			public int lastIndexOf(final int ch) {
				return str.lastIndexOf(ch);
			}

			public String1 concat(final String1 other) {
				return new String1(str.concat(other.str));
			}

			public String1 appendString(final String suffix) {
				return new String1(str.concat(suffix));
			}

			public String1 prependString(final String prefix) {
				return new String1(prefix.concat(str));
			}

			public String1 replace(final char oldChar, final char newChar) {
				return new String1(str.replace(oldChar, newChar));
			}

			public String1 reverse() {
				if (str.length() == 1) {
					return this;
				} else {
					return new String1(new StringBuilder(str).reverse().toString());
				}
			}

			public String1 toUpperCase() {
				return toUpperCase(Locale.getDefault());
			}

			public String1 toUpperCase(final Locale locale) {
				final String upper = this.str.toUpperCase(locale);
				return (str == upper) ? this : new String1(upper);
			}

			public String1 toLowerCase() {
				return toLowerCase(Locale.getDefault());
			}

			public String1 toLowerCase(final Locale locale) {
				final String lower = this.str.toLowerCase(locale);
				return (str == lower) ? this : new String1(lower);
			}

			@Override
			public boolean equals(final Object obj) {
				if (this == obj) {
					return true;
				} else if (obj instanceof String1) {
					return str.equals(((String1) obj).str);
				} else {
					return false;
				}
			}

			public boolean equalsIgnoreCase(final String1 other) {
				return str.equalsIgnoreCase(other.str);
			}

			@Override
			public int hashCode() {
				return str.hashCode();
			}

			@Override
			public int compareTo(final String1 other) {
				return str.compareTo(other.str);
			}

			public int compareToIgnoreCase(final String1 other) {
				return str.compareToIgnoreCase(other.str);
			}

			@Override
			public String toString() {
				return str;
			}

			«javadocSynonym("string1")»
			public static String1 of(final String str) {
				return string1(str);
			}

			public static String1 string1(final String str) {
				if (str.isEmpty()) {
					throw new IllegalArgumentException("Empty string");
				} else {
					return new String1(str);
				}
			}

			«FOR type : Type.primitives»
				public static String1 from«type.typeName»(final «type.javaName» value) {
					return new String1(«type.boxedName».toString(value));
				}

			«ENDFOR»
			public static String1 fromFloat(final float value) {
				return new String1(Float.toString(value));
			}

			public static Ord<String1> caseInsensitiveOrd() {
				return CASE_INSENSITIVE_ORD;
			}
		}

		final class String1CaseInsensitiveOrd implements Ord<String1> {
			@Override
			public Order compare(final String1 x, final String1 y) {
				return Order.fromInt(String.CASE_INSENSITIVE_ORDER.compare(x.str, y.str));
			}
		}
	''' }
}