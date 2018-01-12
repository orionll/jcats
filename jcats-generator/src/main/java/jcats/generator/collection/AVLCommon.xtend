package jcats.generator.collection

final class AVLCommon {

	def static update(String genericName, String diamondName, String getKey, String createEntry, String sameEntry, String updateArgs) '''
		final Order order = this.ord.compare(key, this.«getKey»);
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

	def static delete(String genericName, String diamondName, String getKey) '''
		final Order order = this.ord.compare(key, this.«getKey»);
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
			final «genericName» newLeft = this.left.delete(key, result);
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
			final «genericName» newRight = this.right.delete(key, result);
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
}