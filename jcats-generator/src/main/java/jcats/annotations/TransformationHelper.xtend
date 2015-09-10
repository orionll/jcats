package jcats.annotations

import com.google.common.collect.ObjectArrays
import java.util.Collection
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference

package final class TransformationHelper {

	package def static boolean methodExists(TypeDeclaration type, String name, int typeParametersSize,
		int parametersSize, @Extension TransformationContext context) {
		if (type.declaredMethods.exists[simpleName == name]) {
			val method = type.declaredMethods.findFirst[simpleName == name]
			if (method.typeParameters.size !== typeParametersSize) {
				addError(method, '''Method «name» must have «typeParametersSize» type parameters''')
			} else if (method.parameters.size !== parametersSize) {
				addError(method, '''Method «name» must have «parametersSize» arguments''')
			}
			true
		} else {
			false
		}
	}
	
	package def static typeReference(Type t, Collection<TypeReference> params, extension TransformationContext context) {
		val TypeReference[] paramsArray = params.toArray(newArrayOfSize(params.size))
		t.newTypeReference(paramsArray)
	}
	
	package def static typeReference(Type t, Collection<TypeReference> params, TypeReference param, extension TransformationContext context) {
		val TypeReference[] paramsArray = params.toArray(newArrayOfSize(params.size))
		t.newTypeReference(ObjectArrays.concat(paramsArray, param))
	}
	
	package def static typeReference(Type t, TypeReference param, Collection<TypeReference> params, extension TransformationContext context) {
		val TypeReference[] paramsArray = params.toArray(newArrayOfSize(params.size))
		t.newTypeReference(ObjectArrays.concat(param, paramsArray))
	}
}