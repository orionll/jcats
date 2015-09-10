package jcats.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclarator

import static extension jcats.annotations.TransformationHelper.*

@Target(ElementType::TYPE)
@Active(typeof(ContravariantProcessor))
annotation Contravariant {}

class ContravariantProcessor implements TransformationParticipant<MutableTypeDeclaration> {

	override doTransform(List<? extends MutableTypeDeclaration> annotatedClasses, @Extension TransformationContext context) {
		for (MutableTypeDeclaration annotatedClass : annotatedClasses) {
			doTransform(annotatedClass, context);
		}
	}

	def doTransform(MutableTypeDeclaration type, extension TransformationContext context) {
		val typeParams = (type as TypeParameterDeclarator).typeParameters
		val f = Constants.F.findTypeGlobally

		if (typeParams.size == 0) {
			type.addError('''@«typeof(Contravariant).simpleName» can only be applied to generic types''')
		} else if (typeParams.size == 1) {
			addMethodsForSingleParamContravariantFunctor(type, typeParams.head, f, context)
		} else {
			addMethodsForMultiParamContravariantFunctor(type, typeParams, f, context)
		}
	}

	private def static narrowBody(TypeDeclaration type) { '''return («type.simpleName»)this;''' }

	def addMethodsForSingleParamContravariantFunctor(MutableTypeDeclaration type, TypeParameterDeclaration aDecl, Type f, extension TransformationContext context) {
		type.addMethod("narrow") [
			abstract = false
			val a = aDecl.newTypeReference
			val b = addTypeParameter("B", a).newTypeReference
			returnType = type.newTypeReference(b)
			body = [narrowBody(type)]
		]
	}

	def addMethodsForMultiParamContravariantFunctor(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams,
		Type f, extension TransformationContext context
	) {
		type.addMethod("narrow") [
			abstract = false
			val a = typeParams.head.newTypeReference
			val b = typeParams.tail.map[newTypeReference].toList
			val c = addTypeParameter("C", a).newTypeReference
			returnType = type.typeReference(c, b, context)
			body = [narrowBody(type)]
		]
	}
}