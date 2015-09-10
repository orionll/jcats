package jcats.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration

import static extension jcats.annotations.TransformationHelper.*

@Target(ElementType::TYPE)
@Active(typeof(ZipListProcessor))
annotation ZipList {}

class ZipListProcessor extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration type, extension TransformationContext context) {
		if (type.qualifiedName == Constants.LIST) {
			addMethods(type, context)
		} else {
			type.addError('''@«typeof(ZipList).simpleName» can only be applied to «Constants.LIST»''')
		}
	}

	private def static String zipBody(int arity) {
		'''return zipWith«arity»(«(1 .. arity).map["list" + it].join(", ")», P«arity»::p«arity»);'''
	}

	private def static String zipWithBody(int arity) { '''
		java.util.Objects.requireNonNull(f);
		if («(1 .. arity).map["list" + it + ".isEmpty()"].join(" || ")») {
			return nil();
		} else {
			«FOR i : 1 .. arity»
				List<A«i»> i«i» = list«i»;
			«ENDFOR»
			final ListBuilder<B> buffer = new ListBuilder<>();
			while («(1 .. arity).map["!i" + it + ".isEmpty()"].join(" && ")») {
				buffer.append(f.apply(«(1 .. arity).map["i" + it + ".head()"].join(", ")»));
				«FOR i : 1 .. arity»
					i«i» = i«i».tail();
				«ENDFOR»
			}
			return buffer.toList();
		}
	''' }

	val static zipWithIndexBody = '''
		if (isEmpty()) {
			return nil();
		} else {
			final ListBuilder<P2<A, Integer>> buffer = new ListBuilder<>();
			List<A> list = this;
			int index = 0;
			while (!list.isEmpty()) {
				buffer.append(P2.p2(list.head(), index));
				list = list.tail();
				if (index == Integer.MAX_VALUE && !list.isEmpty()) {
					throw new IndexOutOfBoundsException("Index overflow");
				}
				index++;
			}
			return buffer.toList();
		}
	'''

	private def static addMethods(MutableClassDeclaration type, extension TransformationContext context) {
		val a = type.typeParameters.head.newTypeReference
		val f2 = Constants.F2.findTypeGlobally
		val p2 = Constants.P2.findTypeGlobally
		
		type.addMethod("zip") [
			abstract = false
			val b = addTypeParameter("B").newTypeReference
			addParameter("list", type.newTypeReference(b))
			returnType = type.newTypeReference(p2.newTypeReference(a, b))
			body = ["return zip2(this, list);"]
		]
		
		type.addMethod("zipWith") [
			abstract = false
			val b = addTypeParameter("B").newTypeReference
			val c = addTypeParameter("C").newTypeReference
			addParameter("list", type.newTypeReference(b))
			addParameter("f", f2.newTypeReference(a, b, c))
			returnType = type.newTypeReference(c)
			body = ["return zipWith2(this, list, f);"]
		]
		
		type.addMethod("zipWithIndex") [
			abstract = false
			returnType = type.newTypeReference(p2.newTypeReference(a, typeof(Integer).newTypeReference))
			body = [zipWithIndexBody]
		]
		
		for (arity : 2 .. Constants.MAX_ARITY) {
			val pn = (Constants.P + arity).findTypeGlobally
			
			type.addMethod("zip" + arity) [
				abstract = false
				static = true
				abstract = false
				val method = it
				val aa = (1 .. arity).map[method.addTypeParameter("A" + it).newTypeReference].toList
				aa.forEach[param, index |
					method.addParameter('''list«index + 1»''', type.newTypeReference(param))
				]
				returnType = type.newTypeReference(pn.typeReference(aa, context))
				body = [zipBody(arity)]
			]
		}
		
		for (arity : 2 .. Constants.MAX_ARITY) {
			val fn = (Constants.F + arity).findTypeGlobally
			
			type.addMethod('''zipWith«arity»''') [
				static = true
				abstract = false
				val method = it
				val aa = (1 .. arity).map[method.addTypeParameter("A" + it).newTypeReference].toList
				val b = addTypeParameter("B").newTypeReference
				aa.forEach[param, index |
					method.addParameter('''list«index + 1»''', type.newTypeReference(param))
				]
				addParameter("f", fn.typeReference(aa, b, context))
				returnType = type.newTypeReference(b)
				body = [zipWithBody(arity)]
			]
		}
	}
}