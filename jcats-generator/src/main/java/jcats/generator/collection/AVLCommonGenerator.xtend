package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Type
import jcats.generator.Constants

final class AVLCommonGenerator implements ClassGenerator {

	override className() { "jcats.collection.AVLCommon" }
	
	override sourceCode() '''
		package «Constants.COLLECTION»;

		import «Constants.ORD»;
		import «Constants.ORDER»;

		import static java.util.Objects.requireNonNull;

		final class AVLCommon {

			private AVLCommon() {
			}

			static NullPointerException nullOrder(final Order order) {
				if (order == null) {
					return new NullPointerException("order() returned null");
				} else {
					throw new AssertionError("order() returned unexpected value: " + order);
				}
			}

			static <A> void checkRange(final Ord<A> ord, final A from, final A to) {
				requireNonNull(from);
				requireNonNull(to);
				if (ord.greater(from, to)) {
					throw new IllegalArgumentException("from > to");
				}
			}
		}
	'''

	def static update(String genericName, String diamondName, String key, String getKey, String createEntry, String sameEntry, String updateArgs) '''
		final Order order = this.ord.order(«key», this.«getKey»);
		if (order == EQ) {
			result.heightIncreased = false;
			if («sameEntry») {
				return this;
			} else {
				return new «diamondName»(«createEntry», this.left, this.right, this.ord, this.balance);
			}
		} else if (order == LT) {
			final «genericName» newLeft;
			if (this.left == null) {
				result.heightIncreased = true;
				newLeft = new «diamondName»(«createEntry», null, null, this.ord, 0);
			} else {
				newLeft = this.left.update(«updateArgs», result);
				if (newLeft == this.left) {
					result.heightIncreased = false;
					return this;
				} else if (!result.heightIncreased) {
					return new «diamondName»(this.entry, newLeft, this.right, this.ord, this.balance);
				}
			}
			if (this.balance == 1) {
				result.heightIncreased = false;
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightIncreased = true;
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, -1);
			} else {
				return insertAndRotateRight(newLeft, result);
			}
		} else if (order == GT) {
			final «genericName» newRight;
			if (this.right == null) {
				result.heightIncreased = true;
				newRight = new «diamondName»(«createEntry», null, null, this.ord, 0);
			} else {
				newRight = this.right.update(«updateArgs», result);
				if (newRight == this.right) {
					result.heightIncreased = false;
					return this;
				} else if (!result.heightIncreased) {
					return new «diamondName»(this.entry, this.left, newRight, this.ord, this.balance);
				}
			}
			if (this.balance == -1) {
				result.heightIncreased = false;
				return new «diamondName»(this.entry, this.left, newRight, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightIncreased = true;
				return new «diamondName»(this.entry, this.left, newRight, this.ord, 1);
			} else {
				return insertAndRotateLeft(newRight, result);
			}
		} else {
			throw nullOrder(order);
		}
	'''

	def static insertAndRotateRight(String genericName, String diamondName) '''
		private «genericName» insertAndRotateRight(final «genericName» newLeft, final InsertResult result) {
			if (newLeft.balance == -1) {
				result.heightIncreased = false;
				final «genericName» newRight = new «diamondName»(this.entry, newLeft.right, this.right, this.ord, 0);
				return new «diamondName»(newLeft.entry, newLeft.left, newRight, this.ord, 0);
			} else if (newLeft.balance == 0) {
				result.heightIncreased = true;
				final «genericName» newRight = new «diamondName»(this.entry, newLeft.right, this.right, this.ord, -1);
				return new «diamondName»(newLeft.entry, newLeft.left, newRight, this.ord, 1);
			} else {
				result.heightIncreased = false;
				final int balanceLeft = (newLeft.right.balance == 1) ? -1 : 0;
				final int balanceRight = (newLeft.right.balance == -1) ? 1 : 0;
				final «genericName» newLeft2 = new «diamondName»(
						newLeft.entry, newLeft.left, newLeft.right.left, this.ord, balanceLeft);
				final «genericName» newRight = new «diamondName»(
						this.entry, newLeft.right.right, this.right, this.ord, balanceRight);
				return new «diamondName»(newLeft.right.entry, newLeft2, newRight, this.ord, 0);
			}
		}
	'''

	def static insertAndRotateLeft(String genericName, String diamondName) '''
		private «genericName» insertAndRotateLeft(final «genericName» newRight, final InsertResult result) {
			if (newRight.balance == 1) {
				result.heightIncreased = false;
				final «genericName» newLeft = new «diamondName»(this.entry, this.left, newRight.left, this.ord, 0);
				return new «diamondName»(newRight.entry, newLeft, newRight.right, this.ord, 0);
			} else if (newRight.balance == 0) {
				result.heightIncreased = true;
				final «genericName» newLeft = new «diamondName»(this.entry, this.left, newRight.left, this.ord, 1);
				return new «diamondName»(newRight.entry, newLeft, newRight.right, this.ord, -1);
			} else {
				result.heightIncreased = false;
				final int balanceLeft = (newRight.left.balance == 1) ? -1 : 0;
				final int balanceRight = (newRight.left.balance == -1) ? 1 : 0;
				final «genericName» newLeft = new «diamondName»(
						this.entry, this.left, newRight.left.left, this.ord, balanceLeft);
				final «genericName» newRight2 = new «diamondName»(
						newRight.entry, newRight.left.right, newRight.right, this.ord, balanceRight);
				return new «diamondName»(newRight.left.entry, newLeft, newRight2, this.ord, 0);
			}
		}
	'''

	def static delete(String genericName, String diamondName, String key, String getKey) '''
		final Order order = this.ord.order(«key», this.«getKey»);
		if (order == EQ) {
			if (this.left == null) {
				result.heightDecreased = true;
				return this.right;
			} else if (this.right == null) {
				result.heightDecreased = true;
				return this.left;
			}
			final «genericName» newLeft = this.left.deleteMaximum(result);
			if (!result.heightDecreased) {
				return new «diamondName»(result.entry, newLeft, this.right, this.ord, this.balance);
			} else if (this.balance == -1) {
				// heightDecreased is already true
				return new «diamondName»(result.entry, newLeft, this.right, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightDecreased = false;
				return new «diamondName»(result.entry, newLeft, this.right, this.ord, 1);
			} else {
				return deleteAndRotateLeft(newLeft, result.entry, result);
			}
		} else if (order == LT) {
			if (this.left == null) {
				result.heightDecreased = false;
				return this;
			}
			final «genericName» newLeft = this.left.delete(«key», result);
			if (newLeft == this.left) {
				result.heightDecreased = false;
				return this;
			} else if (!result.heightDecreased) {
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, this.balance);
			} else if (this.balance == -1) {
				// heightDecreased is already true
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightDecreased = false;
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, 1);
			} else {
				return deleteAndRotateLeft(newLeft, this.entry, result);
			}
		} else if (order == GT) {
			if (this.right == null) {
				result.heightDecreased = false;
				return this;
			}
			final «genericName» newRight = this.right.delete(«key», result);
			if (newRight == this.right) {
				result.heightDecreased = false;
				return this;
			} else if (!result.heightDecreased) {
				return new «diamondName»(this.entry, this.left, newRight, this.ord, this.balance);
			} else if (this.balance == 1) {
				// heightDecreased is already true
				return new «diamondName»(this.entry, this.left, newRight, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightDecreased = false;
				return new «diamondName»(this.entry, this.left, newRight, this.ord, -1);
			} else {
				return deleteAndRotateRight(newRight, result);
			}
		} else {
			throw nullOrder(order);
		}
	'''

	def static deleteMinimum(String genericName, String diamondName, String deleteResultGenericName) '''
		private «genericName» deleteMinimum(final «deleteResultGenericName» result) {
			if (this.left == null) {
				result.entry = this.entry;
				result.heightDecreased = true;
				return this.right;
			}
			final «genericName» newLeft = this.left.deleteMinimum(result);
			if (!result.heightDecreased) {
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, this.balance);
			} else if (this.balance == -1) {
				// heightDecreased is already true
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightDecreased = false;
				return new «diamondName»(this.entry, newLeft, this.right, this.ord, 1);
			} else {
				return deleteAndRotateLeft(newLeft, this.entry, result);
			}
		}
	'''

	def static deleteMaximum(String genericName, String diamondName, String deleteResultGenericName) '''
		private «genericName» deleteMaximum(final «deleteResultGenericName» result) {
			if (this.right == null) {
				result.entry = this.entry;
				result.heightDecreased = true;
				return this.left;
			}
			final «genericName» newRight = this.right.deleteMaximum(result);
			if (!result.heightDecreased) {
				return new «diamondName»(this.entry, this.left, newRight, this.ord, this.balance);
			} else if (this.balance == 1) {
				// heightDecreased is already true
				return new «diamondName»(this.entry, this.left, newRight, this.ord, 0);
			} else if (this.balance == 0) {
				result.heightDecreased = false;
				return new «diamondName»(this.entry, this.left, newRight, this.ord, -1);
			} else {
				return deleteAndRotateRight(newRight, result);
			}
		}
	'''

	def static deleteAndRotateLeft(String genericName, String diamondName, String entryGenericName, String deleteResultGenericName) '''
		private «genericName» deleteAndRotateLeft(final «genericName» newLeft, final «entryGenericName» newEntry, final «deleteResultGenericName» result) {
			if (this.right.balance == 1) {
				// heightDecreased is already true
				final «genericName» newLeft2 = new «diamondName»(newEntry, newLeft, this.right.left, this.ord, 0);
				return new «diamondName»(this.right.entry, newLeft2, this.right.right, this.ord, 0);
			} else if (this.right.balance == 0) {
				result.heightDecreased = false;
				final «genericName» newLeft2 = new «diamondName»(newEntry, newLeft, this.right.left, this.ord, 1);
				return new «diamondName»(this.right.entry, newLeft2, this.right.right, this.ord, -1);
			} else {
				// heightDecreased is already true
				final int balanceLeft = (this.right.left.balance == 1) ? -1 : 0;
				final int balanceRight = (this.right.left.balance == -1) ? 1 : 0;
				final «genericName» newLeft2 = new «diamondName»(
						newEntry, newLeft, this.right.left.left, this.ord, balanceLeft);
				final «genericName» newRight = new «diamondName»(
						this.right.entry, this.right.left.right, this.right.right, this.ord, balanceRight);
				return new «diamondName»(this.right.left.entry, newLeft2, newRight, this.ord, 0);
			}
		}
	'''

	def static deleteAndRotateRight(String genericName, String diamondName, String deleteResultGenericName) '''
		private «genericName» deleteAndRotateRight(final «genericName» newRight, final «deleteResultGenericName» result) {
			if (this.left.balance == -1) {
				// heightDecreased is already true
				final «genericName» newRight2 = new «diamondName»(this.entry, this.left.right, newRight, this.ord, 0);
				return new «diamondName»(this.left.entry, this.left.left, newRight2, this.ord, 0);
			} else if (this.left.balance == 0) {
				result.heightDecreased = false;
				final «genericName» newRight2 = new «diamondName»(this.entry, this.left.right, newRight, this.ord, -1);
				return new «diamondName»(this.left.entry, this.left.left, newRight2, this.ord, 1);
			} else {
				// heightDecreased is already true
				final int balanceLeft = (this.left.right.balance == 1) ? -1 : 0;
				final int balanceRight = (this.left.right.balance == -1) ? 1 : 0;
				final «genericName» newLeft = new «diamondName»(
						this.left.entry, this.left.left, this.left.right.left, this.ord, balanceLeft);
				final «genericName» newRight2 = new «diamondName»(
						this.entry, this.left.right.right, newRight, this.ord, balanceRight);
				return new «diamondName»(this.left.right.entry, newLeft, newRight2, this.ord, 0);
			}
		}
	'''

	def static firstOrLast(String genericName, String name, String getKey, String leftOrRight) '''
		if (isEmpty()) {
			throw new NoSuchElementException();
		} else {
			«genericName» «name» = this;
			while («name».«leftOrRight» != null) {
				«name» = «name».«leftOrRight»;
			}
			return «name».«getKey»;
		}
	'''

	def static initOrTail(String genericName, String shortName, String deleteResultDiamondName, String deleteMinimumOrMaximum) '''
		if (isEmpty()) {
			throw new NoSuchElementException();
		} else {
			final «genericName» result = «deleteMinimumOrMaximum»(new «deleteResultDiamondName»());
			if (result == null) {
				return empty«shortName»By(this.ord);
			} else {
				return result;
			}
		}
	'''

	def static iterator(String genericName, String name, String iteratorShortName, String iteratorReturnType, String iteratorNext, boolean reversed) '''
		private final «genericName» root;
		private Stack<«genericName»> stack;

		«iteratorShortName»(final «genericName» root) {
			this.root = root;
		}

		@Override
		public boolean hasNext() {
			return (this.stack == null || this.stack.isNotEmpty());
		}

		@Override
		public «iteratorReturnType» «iteratorNext»() {
			if (this.stack == null) {
				this.stack = emptyStack();
				for («genericName» «name» = this.root; «name» != null; «name» = «name».«IF reversed»right«ELSE»left«ENDIF») {
					this.stack = this.stack.prepend(«name»);
				}
			}

			final «genericName» result = this.stack.first();
			this.stack = this.stack.tail;

			if (result.«IF reversed»left«ELSE»right«ENDIF» != null) {
				for («genericName» «name» = result.«IF reversed»left«ELSE»right«ENDIF»; «name» != null; «name» = «name».«IF reversed»right«ELSE»left«ENDIF») {
					this.stack = this.stack.prepend(«name»);
				}
			}

			return result.entry;
		}
	'''

	def static slicedForEach(String methodName, String genericName, String name, String getKey, String effGenericName, String apply) '''
		@Override
		public void «methodName»(final «effGenericName» eff) {
			if (this.root.isNotEmpty()) {
				if (this.hasFrom) {
					if (this.hasTo) {
						traverse(this.root, eff);
					} else {
						traverseFrom(this.root, eff);
					}
				} else {
					traverseTo(this.root, eff);
				}
			}
		}

		private void traverse(final «genericName» «name», final «effGenericName» eff) {
			final Order fromOrder = this.root.ord.order(this.from, «name».«getKey»);
			final Order toOrder = this.root.ord.order(this.to, «name».«getKey»);
			if (fromOrder == LT) {
				if (toOrder == LT) {
					if («name».left != null) {
						traverse(«name».left, eff);
					}
				} else if (toOrder == EQ) {
					if («name».left != null) {
						traverseFrom(«name».left, eff);
					}
					if (this.toInclusive) {
						eff.«apply»(«name».entry);
					}
				} else if (toOrder == GT) {
					if («name».left != null) {
						traverseFrom(«name».left, eff);
					}
					eff.«apply»(«name».entry);
					if («name».right != null) {
						traverseTo(«name».right, eff);
					}
				} else {
					throw nullOrder(toOrder);
				}
			} else if (fromOrder == EQ) {
				if (toOrder == EQ) {
					if (this.fromInclusive && this.toInclusive) {
						eff.«apply»(«name».entry);
					}
				} else if (toOrder == GT) {
					if (this.fromInclusive) {
						eff.«apply»(«name».entry);
					}
					if («name».right != null) {
						traverseTo(«name».right, eff);
					}
				} else if (toOrder == LT) {
					throw new IllegalArgumentException("from == entry && entry > to");
				} else {
					throw nullOrder(toOrder);
				}
			} else if (fromOrder == GT) {
				if (toOrder == GT) {
					if («name».right != null) {
						traverse(«name».right, eff);
					}
				} else if (toOrder == LT) {
					throw new IllegalArgumentException("from > entry && entry > to");
				} else if (toOrder == EQ) {
					throw new IllegalArgumentException("from > entry && entry == to");
				} else {
					throw nullOrder(toOrder);
				}
			} else {
				throw nullOrder(fromOrder);
			}
		}

		private void traverseFrom(final «genericName» «name», final «effGenericName» eff) {
			final Order order = this.root.ord.order(this.from, «name».«getKey»);
			if (order == LT) {
				if («name».left != null) {
					traverseFrom(«name».left, eff);
				}
				eff.«apply»(«name».entry);
				if («name».right != null) {
					«name».right.traverse(eff);
				}
			} else if (order == EQ) {
				if (this.fromInclusive) {
					eff.«apply»(«name».entry);
				}
				if («name».right != null) {
					«name».right.traverse(eff);
				}
			} else if (order == GT) {
				if («name».right != null) {
					traverseFrom(«name».right, eff);
				}
			} else {
				throw nullOrder(order);
			}
		}

		private void traverseTo(final «genericName» «name», final «effGenericName» eff) {
			final Order order = this.root.ord.order(this.to, «name».«getKey»);
			if (order == LT) {
				if («name».left != null) {
					traverseTo(«name».left, eff);
				}
			} else if (order == EQ) {
				if («name».left != null) {
					«name».left.traverse(eff);
				}
				if (this.toInclusive) {
					eff.«apply»(«name».entry);
				}
			} else if (order == GT) {
				if («name».left != null) {
					«name».left.traverse(eff);
				}
				eff.«apply»(«name».entry);
				if («name».right != null) {
					traverseTo(«name».right, eff);
				}
			} else {
				throw nullOrder(order);
			}
		}
	'''

	def static slicedSearch(Type type, String key, String none, String shortName) '''
		«IF type == Type.OBJECT»
			requireNonNull(«key»);
		«ENDIF»
		if (this.root.isEmpty()) {
			return «none»;
		} else if (this.hasFrom &&
				(this.fromInclusive && this.root.ord.less(«key», this.from) ||
				!this.fromInclusive && this.root.ord.lessOrEqual(«key», this.from))) {
			return «none»;
		} else if (this.hasTo &&
				(this.toInclusive && this.root.ord.greater(«key», this.to) ||
				!this.toInclusive && this.root.ord.greaterOrEqual(«key», this.to))) {
			return «none»;
		} else {
			return «shortName».search(this.root, «key»);
		}
	'''

	def static slicedSlice(String keyGenericName, String diamondName, String slicedDiamondName, String shortName) '''
		final «keyGenericName» newFrom;
		final boolean newFromInclusive;
		if (this.hasFrom) {
			if (hasFrom2) {
				final Order fromOrder = this.root.ord.order(this.from, from2);
				if (fromOrder == LT) {
					newFrom = from2;
					newFromInclusive = from2Inclusive;
				} else if (fromOrder == EQ) {
					newFrom = from2;
					newFromInclusive = this.fromInclusive && from2Inclusive;
				} else if (fromOrder == GT) {
					newFrom = this.from;
					newFromInclusive = this.fromInclusive;
				} else {
					throw nullOrder(fromOrder);
				}
			} else {
				newFrom = this.from;
				newFromInclusive = this.fromInclusive;
			}
		} else {
			newFrom = from2;
			newFromInclusive = from2Inclusive;
		}

		final «keyGenericName» newTo;
		final boolean newToInclusive;
		if (this.hasTo) {
			if (hasTo2) {
				final Order toOrder = this.root.ord.order(this.to, to2);
				if (toOrder == LT) {
					newTo = this.to;
					newToInclusive = this.toInclusive;
				} else if (toOrder == EQ) {
					newTo = to2;
					newToInclusive = this.toInclusive && to2Inclusive;
				} else if (toOrder == GT) {
					newTo = to2;
					newToInclusive = to2Inclusive;
				} else {
					throw nullOrder(toOrder);
				}
			} else {
				newTo = this.to;
				newToInclusive = this.toInclusive;
			}
		} else {
			newTo = to2;
			newToInclusive = to2Inclusive;
		}

		final boolean newHasFrom = this.hasFrom || hasFrom2;
		final boolean newHasTo = this.hasTo || hasTo2;
		if (newHasFrom && newHasTo && this.root.ord.greater(newFrom, newTo)) {
			return new «diamondName»(empty«shortName»By(this.root.ord));
		} else {
			return new «slicedDiamondName»(this.root, newFrom, newHasFrom, newFromInclusive, newTo, newHasTo, newToInclusive);
		}
	'''

	def static slicedIterator(String genericName, String name, String iteratorShortName, String keyGenericName, String getKey, String params,
		String ordGenericName, String iteratorReturnType, String iteratorNext, boolean reversed) {
		val first = if (reversed) "last" else "first"
		val last = if (reversed) "first" else "last"
		val getFirst = if (reversed) "getLast" else "getFirst"
		val getLast = if (reversed) "getFirst" else "getLast"
		val from = if (reversed) "to" else "from"
		val to = if (reversed) "from" else "to"
		val hasFrom = if (reversed) "hasTo" else "hasFrom"
		val hasTo = if (reversed) "hasFrom" else "hasTo"
		val greater = if (reversed) "less" else "greater"
		val left = if (reversed) "right" else "left"
		val right = if (reversed) "left" else "right"
		val lt = if (reversed) "GT" else "LT"
		val gt = if (reversed) "LT" else "GT"
		val maxLess = if (reversed) "minGreater" else "maxLess"
		'''
			private final «genericName» end;
			private Stack<«genericName»> stack;

			«iteratorShortName»(final «genericName» root,
				final «keyGenericName» from, final boolean hasFrom, final boolean fromInclusive,
				final «keyGenericName» to, final boolean hasTo, final boolean toInclusive) {
				final Stack<«genericName»> «first» = «getFirst»(root, «from», «hasFrom», «from»Inclusive);
				final «genericName» «last» = «getLast»(root, «to», «hasTo», «to»Inclusive);
				if («first».isEmpty() || «last» == null || root.ord.«greater»(«first».head.«getKey», «last».«getKey»)) {
					this.stack = null;
					this.end = null;
				} else {
					this.stack = «first»;
					this.end = «last»;
				}
			}

			private static «params»Stack<«genericName»> «getFirst»(«genericName» «name», final «keyGenericName» «from», final boolean «hasFrom», final boolean inclusive) {
				final «ordGenericName» ord = «name».ord;
				Stack<«genericName»> stack = emptyStack();
				if («hasFrom») {
					while (true) {
						final Order order = ord.order(«from», «name».«getKey»);
						if (order == EQ) {
							if (inclusive) {
								return stack.prepend(«name»);
							} else if («name».«right» == null) {
								return stack;
							} else {
								«name» = «name».«right»;
							}
						} else if (order == «lt») {
							if («name».«left» == null) {
								return stack.prepend(«name»);
							} else {
								stack = stack.prepend(«name»);
								«name» = «name».«left»;
							}
						} else if (order == «gt») {
							if («name».«right» == null) {
								return stack;
							} else {
								«name» = «name».«right»;
							}
						} else {
							throw nullOrder(order);
						}
					}
				} else {
					while («name» != null) {
						stack = stack.prepend(«name»);
						«name» = «name».«left»;
					}
					return stack;
				}
			}

			private static «params»«genericName» «getLast»(«genericName» «name», final «keyGenericName» «to», final boolean «hasTo», final boolean inclusive) {
				final «ordGenericName» ord = «name».ord;
				if («hasTo») {
					«genericName» «maxLess» = null;
					while (true) {
						final Order order = ord.order(«to», «name».«getKey»);
						if (order == EQ) {
							if (inclusive) {
								return «name»;
							} else if («name».«left» == null) {
								return «maxLess»;
							} else {
								«name» = «name».«left»;
							}
						} else if (order == «lt») {
							if («name».«left» == null) {
								return «maxLess»;
							} else {
								«name» = «name».«left»;
							}
						} else if (order == «gt») {
							if («name».«right» == null) {
								return «name»;
							} else {
								«maxLess» = «name»;
								«name» = «name».«right»;
							}
						} else {
							throw nullOrder(order);
						}
					}
				} else {
					while («name».«right» != null) {
						«name» = «name».«right»;
					}
					return «name»;
				}
			}

			@Override
			public boolean hasNext() {
				return (this.stack != null && this.stack.isNotEmpty());
			}

			@Override
			public «iteratorReturnType» «iteratorNext»() {
				if (this.stack == null) {
					throw new NoSuchElementException();
				}

				final «genericName» result = this.stack.head;
				if (result == this.end) {
					this.stack = null;
				} else {
					this.stack = this.stack.tail;

					if (result.«right» != null) {
						for («genericName» «name» = result.«right»; «name» != null; «name» = «name».«left») {
							this.stack = this.stack.prepend(«name»);
						}
					}
				}

				return result.entry;
			}
	''' }
}