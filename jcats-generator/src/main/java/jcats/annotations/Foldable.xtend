package jcats.annotations

import com.google.common.collect.ImmutableSet
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.ArrayList
import java.util.List
import java.util.Set
import java.util.function.Predicate
import java.util.stream.Stream
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclarator
import org.eclipse.xtend.lib.macro.declaration.TypeReference

import static jcats.annotations.TransformationHelper.*

@Target(ElementType::TYPE)
@Active(typeof(FoldableProcessor))
annotation Foldable {}

class FoldableProcessor implements TransformationParticipant<MutableTypeDeclaration> {

	override doTransform(List<? extends MutableTypeDeclaration> annotatedClasses, @Extension TransformationContext context) {
		for (MutableTypeDeclaration annotatedClass : annotatedClasses) {
			doTransform(annotatedClass, context);
		}
	}

	def doTransform(MutableTypeDeclaration type, extension TransformationContext context) {
		val typeParams = (type as TypeParameterDeclarator).typeParameters
		val f = Constants.F.findTypeGlobally
		val f2 = Constants.F2.findTypeGlobally
		val option = Constants.OPTION.findTypeGlobally
		
		if (typeParams.size == 0) {
			type.addError('''@«typeof(Foldable).simpleName» can only be applied to generic types''')
		} else if (typeParams.size == 1) {
			val exclude = if (type.qualifiedName == Constants.ARRAY) {
				ImmutableSet.of("toArray")
			} else if (type.qualifiedName == Constants.LIST) {
				ImmutableSet.of("toList")
			} else {
				ImmutableSet.of
			}
			
			addMethodsForSingleParamFoldable(type, typeParams.head.newTypeReference, f, f2, option, exclude, context)
		} else {
			addError(type, "Not implemented")
		}
	}

	private val static foldLeftBody = '''
		java.util.Objects.requireNonNull(f);
		java.util.Objects.requireNonNull(seed);
		B b = seed;
		for (A a : this) {
			b = f.apply(b, a);
		}
		return b;
	'''
	
	private val static sizeBody = '''
		int size = 0;
		for (A __ : this) {
			if (size == Integer.MAX_VALUE) {
				throw new IndexOutOfBoundsException("Size overflow");
			}
			size++;
		}
		return size;
	'''
	
	private val static allBody = '''
		java.util.Objects.requireNonNull(predicate);
		for (A a : this) {
			if (!predicate.test(a)) {
				return false;
			}
		}
		return true;
	'''

	private val static anyBody = '''
		java.util.Objects.requireNonNull(predicate);
		for (A a : this) {
			if (predicate.test(a)) {
				return true;
			}
		}
		return false;
	'''

	private val static findBody = '''
		java.util.Objects.requireNonNull(predicate);
		for (A a : this) {
			if (predicate.test(a)) {
				return Option.some(a);
			}
		}
		return Option.none();
	'''

	private val static findOrNullBody = '''
		java.util.Objects.requireNonNull(predicate);
		for (A a : this) {
			if (predicate.test(a)) {
				return a;
			}
		}
		return null;
	'''
	
	private val static toArrayListBody = '''
		final ArrayList<A> result = new ArrayList<>(size());
		for (A a : this) {
			result.add(a);
		}
		return result;
	'''
	
	private val static toArrayBody = '''
		final A[] array = (A[]) new Object[size()];
		int i = 0;
		for (A a : this) {
			array[i++] = a;
		}
		return new Array<A>(array);
	'''

	private val static toListBody = '''
		final «Constants.LIST».ListBuilder<A> buffer = new «Constants.LIST».ListBuilder<>();
		for (A a : this) {
			buffer.append(a);
		}
		return buffer.toList();
	'''

	private def static toStringBody(TypeDeclaration type) { '''
		final StringBuilder builder = new StringBuilder("«type.simpleName»(");
		final Iterator<A> iterator = iterator();
		while (iterator.hasNext()) {
			builder.append(iterator.next());
			if (iterator.hasNext()) {
				builder.append(", ");
			}
		}
		builder.append(")");
		return builder.toString();
	'''}
	
	package def static addMethodsForSingleParamFoldable(MutableTypeDeclaration type, TypeReference a,
		Type f, Type f2, Type option, Set<String> exclude, extension TransformationContext context) {
			
		if (!methodExists(type, "foldLeft", 1, 2, context) && !exclude.contains("foldLeft")) {
			type.addMethod("foldLeft") [
				abstract = false
				val b = addTypeParameter("B").newTypeReference
				addParameter("f", f2.newTypeReference(b, a, b))
				addParameter("seed", b)
				returnType = b
				body = [foldLeftBody]
			]
		}
		
		if (!methodExists(type, "isEmpty", 0, 0, context) && !exclude.contains("isEmpty")) {
			type.addMethod("isEmpty") [
				abstract = false
				returnType = typeof(boolean).newTypeReference
				body = ["return !iterator().hasNext();"]
			]
		}

		if (!methodExists(type, "isNotEmpty", 0, 0, context) && !exclude.contains("isNotEmpty")) {
			type.addMethod("isNotEmpty") [
				abstract = false
				returnType = typeof(boolean).newTypeReference
				body = ["return !isEmpty();"]
			]
		}

		if (!methodExists(type, "size", 0, 0, context) && !exclude.contains("size")) {
			type.addMethod("size") [
				abstract = false
				returnType = typeof(int).newTypeReference
				body = [sizeBody]
			]
		}
		
		if (!methodExists(type, "all", 0, 1, context) && !exclude.contains("all")) {
			type.addMethod("all") [
				abstract = false
				addParameter("predicate", typeof(Predicate).newTypeReference(a))
				returnType = typeof(boolean).newTypeReference
				body = [allBody]
			]
		}

		if (!methodExists(type, "any", 0, 1, context) && !exclude.contains("any")) {
			type.addMethod("any") [
				abstract = false
				addParameter("predicate", typeof(Predicate).newTypeReference(a))
				returnType = typeof(boolean).newTypeReference
				body = [anyBody]
			]
		}

		if (!methodExists(type, "find", 0, 1, context) && !exclude.contains("find")) {
			type.addMethod("find") [
				abstract = false
				addParameter("predicate", typeof(Predicate).newTypeReference(a))
				returnType = option.newTypeReference(a)
				body = [findBody]
			]
		}

		if (!methodExists(type, "findOrNull", 0, 1, context) && !exclude.contains("findOrNull")) {
			type.addMethod("findOrNull") [
				abstract = false
				addParameter("predicate", typeof(Predicate).newTypeReference(a))
				returnType = a
				body = [findOrNullBody]
			]
		}
		
		if (!methodExists(type, "toArray", 0, 0, context) && !exclude.contains("toArray")) {
			type.addMethod("toArray") [
				abstract = false
				returnType = Constants.ARRAY.findTypeGlobally.newTypeReference(a)
				body = [toArrayBody]
			]
		}
		
		if (!methodExists(type, "toList", 0, 0, context) && !exclude.contains("toList")) {
			type.addMethod("toList") [
				abstract = false
				returnType = Constants.LIST.findTypeGlobally.newTypeReference(a)
				body = [toListBody]
			]
		}
		
		if (!methodExists(type, "toArrayList", 0, 0, context) && !exclude.contains("toArrayList")) {
			type.addMethod("toArrayList") [
				abstract = false
				returnType = typeof(ArrayList).newTypeReference(a)
				body = [toArrayListBody]
			]
		}
		
		if (!methodExists(type, "stream", 0, 0, context) && !exclude.contains("stream")) {
			type.addMethod("stream") [
				abstract = false
				returnType = typeof(Stream).newTypeReference(a)
				body = ["return java.util.stream.StreamSupport.stream(spliterator(), false);"]
			]
		}
		
		if (!methodExists(type, "parallelStream", 0, 0, context) && !exclude.contains("parallelStream")) {
			type.addMethod("parallelStream") [
				abstract = false
				returnType = typeof(Stream).newTypeReference(a)
				body = ["return java.util.stream.StreamSupport.stream(spliterator(), true);"]
			]
		}
		
		if (!methodExists(type, "toString", 0, 0, context) && !exclude.contains("toString")) {
			type.addMethod("toString") [
				abstract = false
				returnType = typeof(String).newTypeReference
				addAnnotation(typeof(Override).newAnnotationReference)
				body = [toStringBody(type)]
			]
		}
		
		// TODO ToList, ToArray, ToVector
	}
	

}