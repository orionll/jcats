package jcats.generator

final class String1Generator implements ClassGenerator {
	override className() { Constants.STRING1 }

	override sourceCode() { '''
		package «Constants.JCATS»;

		import java.io.Serializable;
		import java.util.Locale;
		import «Constants.COLLECTION».IntStream2;

		/**
		 * Nonempty string
		 */
		public final class String1 implements CharSequence, Equatable<String1>, Ordered<String1>, Serializable {
			private static final String1CaseInsensitiveOrd CASE_INSENSITIVE_ORD = new String1CaseInsensitiveOrd();

			final String str;

			private String1(final String str) {
				this.str = str;
			}

			@Override
			public int length() {
				return this.str.length();
			}

			@Override
			public char charAt(final int index) {
				return this.str.charAt(index);
			}

			@Override
			public CharSequence subSequence(final int start, final int end) {
				return this.str.subSequence(start, end);
			}

			@Override
			public IntStream2 chars() {
				return IntStream2.from(this.str.chars());
			}

			@Override
			public IntStream2 codePoints() {
				return IntStream2.from(this.str.codePoints());
			}

			public boolean startsWith(final String1 prefix) {
				return this.str.startsWith(prefix.str);
			}

			public boolean endsWith(final String1 suffix) {
				return this.str.endsWith(suffix.str);
			}

			public int indexOf(final int ch) {
				return this.str.indexOf(ch);
			}

			public int lastIndexOf(final int ch) {
				return this.str.lastIndexOf(ch);
			}

			public String1 concat(final String1 other) {
				return new String1(this.str.concat(other.str));
			}

			public String1 appendString(final String suffix) {
				return new String1(this.str.concat(suffix));
			}

			public String1 prependString(final String prefix) {
				return new String1(prefix.concat(this.str));
			}

			public String1 replace(final char oldChar, final char newChar) {
				return new String1(this.str.replace(oldChar, newChar));
			}

			public String1 reverse() {
				if (this.str.length() == 1) {
					return this;
				} else {
					return new String1(new StringBuilder(this.str).reverse().toString());
				}
			}

			public String1 toUpperCase() {
				return toUpperCase(Locale.getDefault());
			}

			public String1 toUpperCase(final Locale locale) {
				final String upper = this.str.toUpperCase(locale);
				return (this.str == upper) ? this : new String1(upper);
			}

			public String1 toLowerCase() {
				return toLowerCase(Locale.getDefault());
			}

			public String1 toLowerCase(final Locale locale) {
				final String lower = this.str.toLowerCase(locale);
				return (this.str == lower) ? this : new String1(lower);
			}

			/**
			 * «equalsDeprecatedJavaDoc»
			 */
			@Override
			@Deprecated
			public boolean equals(final Object obj) {
				if (this == obj) {
					return true;
				} else if (obj instanceof String1) {
					return this.str.equals(((String1) obj).str);
				} else {
					return false;
				}
			}

			public boolean isEqualToString(final String other) {
				return this.str.equals(other);
			}

			public boolean equalsIgnoreCase(final String1 other) {
				return this.str.equalsIgnoreCase(other.str);
			}

			@Override
			public int hashCode() {
				return this.str.hashCode();
			}

			@Override
			public int compareTo(final String1 other) {
				return this.str.compareTo(other.str);
			}

			public int compareToIgnoreCase(final String1 other) {
				return this.str.compareToIgnoreCase(other.str);
			}

			@Override
			public Order order(final String1 other) {
				return Order.fromInt(this.str.compareTo(other.str));
			}

			public Order orderIgnoreCase(final String1 other) {
				return Order.fromInt(this.str.compareToIgnoreCase(other.str));
			}

			@Override
			public String toString() {
				return this.str;
			}

			«javadocSynonym("string1")»
			public static String1 of(final String str) throws IllegalArgumentException {
				return string1(str);
			}

			public static String1 string1(final String str) throws IllegalArgumentException {
				if (str.isEmpty()) {
					throw new IllegalArgumentException("Empty string");
				} else {
					return new String1(str);
				}
			}

			public static String1 fromObject(final Object value) {
				return new String1(value.toString());
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
			public Order order(final String1 x, final String1 y) {
				return Order.fromInt(String.CASE_INSENSITIVE_ORDER.compare(x.str, y.str));
			}
		}
	''' }
}