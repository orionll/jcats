package jcats.annotations

import com.google.common.collect.ImmutableList
import com.google.common.collect.ImmutableSet
import com.google.common.collect.Lists
import java.io.Serializable
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.ArrayList
import java.util.Collections
import java.util.Iterator
import org.eclipse.xtend.lib.macro.AbstractInterfaceProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static extension jcats.annotations.TransformationHelper.*
import java.util.function.BiFunction

@Target(ElementType::TYPE)
@Active(typeof(RegisterTypesProcessor))
annotation RegisterTypes {}

class RegisterTypesProcessor extends AbstractInterfaceProcessor {
	
	override doRegisterGlobals(InterfaceDeclaration __, extension RegisterGlobalsContext context) {
		for (arity : 2 .. Constants.MAX_ARITY) {
			(Constants.F + arity).registerInterface;
			(Constants.P + arity).registerClass;
			(Constants.V + arity).registerClass
		}
	}

	override doTransform(MutableInterfaceDeclaration annotatedInterface, extension TransformationContext context) {
		if (annotatedInterface.qualifiedName == Constants.F) {
			val serializable = typeof(Serializable).findTypeGlobally.newTypeReference
				
			for (arity : 2 .. Constants.MAX_ARITY) {
				val fn = (Constants.F + arity).findInterface
				fn.addAnnotation(findTypeGlobally(typeof(FunctionalInterface)).newAnnotationReference)
				fn.addAnnotation(findTypeGlobally(typeof(Functor)).newAnnotationReference)
				(1 .. arity).forEach[fn.addTypeParameter("A" + it)]
				fn.addTypeParameter("B")
				
				val pn = (Constants.P + arity).findClass
				pn.implementedInterfaces = ImmutableList.of(serializable)
				pn.final = true
				(1 .. arity).forEach[pn.addTypeParameter("A" + it)]
				
				val vn = (Constants.V + arity).findClass
				vn.final = true
				val a = vn.addTypeParameter("A").newTypeReference
				val iterable = typeof(Iterable).findTypeGlobally.newTypeReference(a)
				vn.implementedInterfaces = ImmutableList.of(serializable, iterable)
			}

			for (arity : 2 .. Constants.MAX_ARITY) {
				transformFunction(arity, (Constants.F + arity).findInterface, context)
				transformProduct(arity, (Constants.P + arity).findClass, context)
				transformVector(arity, (Constants.V + arity).findClass, context)
			}
		} else {
			annotatedInterface.addError('''@«typeof(RegisterTypes).simpleName» can only be applied to «Constants.F»''')
		}
	}
	
	private def static transformFunction(int arity, MutableInterfaceDeclaration type, extension TransformationContext context) {
		val typeParams = type.typeParameters.toList
		val a = typeParams.subList(0, typeParams.size - 1).map[it.newTypeReference]
		val b = typeParams.last.newTypeReference
		
		type.addMethod("apply") [
			a.forEach[input, index | addParameter("a" + (index + 1), input)]
			returnType = b
		]
		
		val f = Constants.F.findTypeGlobally
		val pn = (Constants.P + arity).findTypeGlobally
		
		if (arity == 2) {
			addF2Methods(type, a.get(0), a.get(1), b, f, context)
		}
		
		type.addMethod("map") [
			abstract = false
			val c = addTypeParameter("C").newTypeReference
			addParameter("f", f.newTypeReference(b, c))
			returnType = type.typeReference(a, c, context)
			val params = (1 .. arity).map["a" + it].join(", ")
			body = ['''
				java.util.Objects.requireNonNull(f);
				return («params») -> f.apply(apply(«params»));
			''']
		]

		a.forEach[param, index |
			type.addMethod('''contraMap«index + 1»''') [
				abstract = false
				val c = addTypeParameter("C").newTypeReference
				val aCopy = Lists.newArrayList(a)
				addParameter("f", f.newTypeReference(c, aCopy.get(index)))
				aCopy.set(index, c)
				returnType = type.typeReference(aCopy, b, context)
				body = ['''
					java.util.Objects.requireNonNull(f);
					return («(1 .. arity).map[if (it == index + 1) "c" else '''a«it»'''].join(", ")») -> apply(«(1 .. arity).map[if (it == index + 1) "f.apply(c)" else '''a«it»'''].join(", ")»);
				''']
			]
		]

		for (index : 1 ..< arity) {
			type.addMethod(if (index == 1) "curry" else '''curry«index»''') [
				abstract = false
				
				val lastFunctionArity = arity - index
				val lastFunctionType = (if (lastFunctionArity == 1) Constants.F else (Constants.F + lastFunctionArity)).findInterface
				val aTail = a.subList(index, arity)

				var retType = lastFunctionType.typeReference(aTail, b, context)
				for (i : index >.. 0) {
					retType = f.newTypeReference(a.get(i), retType)
				}

				returnType = retType
				body = ['''
					return «(1 .. index).map['''a«it»'''].join(" -> ")» -> («(index + 1 .. arity).map['''a«it»'''].join(", ")») -> apply(«(1 .. arity).map['''a«it»'''].join(", ")»);
				''']
			]
		}
		
		type.addMethod("flatMap") [
			abstract = false
			val c = addTypeParameter("C").newTypeReference
			addParameter("f", f.newTypeReference(b, type.typeReference(a, c, context)))
			returnType = type.typeReference(a, c, context)
			val params = (1 .. arity).map["a" + it].join(", ")
			body = ['''
				java.util.Objects.requireNonNull(f);
				return («params») -> f.apply(apply(«params»)).apply(«params»);
			''']
		]
		
		type.addMethod("tuple") [
			abstract = false
			returnType = f.newTypeReference(pn.typeReference(a, context), b)
			body = ['''
				return p«arity» -> apply(«(1 .. arity).map['''p«arity».get«it»()'''].join(", ")»);
			''']
		]

		FunctorProcessor.addMethodsForMultiParamFunctor(type, type.typeParameters, f, context)
		ApplicativeProcessor.addMethodsForMultiParamApplicative(type, type.typeParameters, f, context)
		MonadProcessor.addMethodsForMultiParamMonad(type, type.typeParameters, f, context)
	}
	
	private def static addF2Methods(MutableInterfaceDeclaration type, TypeReference a1, TypeReference a2, TypeReference b,
		Type f, extension TransformationContext context
	) {
		type.addMethod("flip") [
			abstract = false
			returnType = type.newTypeReference(a2, a1, b)
			body = ["return (a2, a1) -> apply(a1, a2);"]
		]

		type.addMethod("uncurry") [
			abstract = false
			static = true
			val aa1 = addTypeParameter("A1").newTypeReference
			val aa2 = addTypeParameter("A2").newTypeReference
			val bb = addTypeParameter("B").newTypeReference
			returnType = type.newTypeReference(aa1, aa2, bb)
			addParameter("f", f.newTypeReference(aa1, f.newTypeReference(aa2, bb)))
			body = ['''
				java.util.Objects.requireNonNull(f);
				return (a1, a2) -> f.apply(a1).apply(a2);
			''']
		]

		type.addMethod("toBiFunction") [
			abstract = false
			returnType = typeof(BiFunction).newTypeReference(a1, a2, b)
			body = ["return (a1, a2) -> apply(a1, a2);"]
		]

		type.addMethod("fromBiFunction") [
			abstract = false
			static = true
			val aa1 = addTypeParameter("A1").newTypeReference
			val aa2 = addTypeParameter("A2").newTypeReference
			val bb = addTypeParameter("B").newTypeReference
			returnType = type.newTypeReference(aa1, aa2, bb)
			addParameter("f", typeof(BiFunction).newTypeReference(aa1, aa2, bb))
			body = ['''
				java.util.Objects.requireNonNull(f);
				return (a1, a2) -> f.apply(a1, a2);
			''']
		]
	}
	
	private def static transformProduct(int arity, MutableClassDeclaration type, extension TransformationContext context) {
		val f = Constants.F.findTypeGlobally
		val fn = (Constants.F + arity).findTypeGlobally
		
		val a = type.typeParameters.toList.map[it.newTypeReference]

		a.forEach[param, index |
			type.addField('''a«index + 1»''') [
				final = true
				type = param
			]
		]
		
		type.addConstructor[
			visibility = Visibility.PRIVATE
			val method = it
			a.forEach[param, index | method.addParameter('''a«index + 1»''', param)]
			body = ['''
				«FOR index : 1 .. arity»
					this.a«index» = a«index»;
				«ENDFOR»
			''']
		]
		
		a.forEach[param, index |
			type.addMethod('''get«index + 1»''') [
				returnType = param
				body = ['''return a«index + 1»;''']
			]
		]
	
		type.addMethod("match") [
			val b = addTypeParameter("B").newTypeReference
			returnType = b
			addParameter("f", fn.typeReference(a, b, context))
			body = ['''return f.apply(«(1 .. arity).map["a" + it].join(", ")»);''']
		]
		
		if (arity == 2) {
			addP2Methods(type, a.get(0), a.get(1), context)
		}
		
		a.forEach[param, index |
			type.addMethod('''map«index + 1»''') [
				val b = addTypeParameter("B").newTypeReference
				val aCopy = Lists.newArrayList(a)
				addParameter("f", f.newTypeReference(aCopy.get(index), b))
				aCopy.set(index, b)
				returnType = type.typeReference(aCopy, context)
				body = ['''
					return new P«arity»<>(«(1 .. arity).map[if (it == index + 1) '''java.util.Objects.requireNonNull(f.apply(a«it»))''' else "a" + it].join(", ")»);
				''']
			]
		]

		type.addMethod("p" + arity) [
			abstract = false
			static = true
			val method = it
			val aa = (1 .. arity).map[method.addTypeParameter("A" + it).newTypeReference].toList
			returnType = type.typeReference(aa, context)
			aa.forEach[param, index | method.addParameter('''a«index + 1»''', param)]
			body = ['''
				«FOR index : 1 .. arity»
					java.util.Objects.requireNonNull(a«index»);
				«ENDFOR»
				return new P«arity»<>(«(1 .. arity).map["a" + it].join(", ")»);
			''']
		]
		
		type.addMethod("toString") [
			returnType = typeof(String).newTypeReference
			addAnnotation(typeof(Override).newAnnotationReference)
			body = ['''return "(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";''']
		]
		
		// TODO Equals
	}
	
	private def static addP2Methods(MutableClassDeclaration type, TypeReference a1, TypeReference a2, extension TransformationContext context) {
		type.addMethod('''flip''') [
			returnType = type.newTypeReference(a2, a1)
			body = ['''return new P2<>(a2, a1);''']
		]
	}
	
	private def static transformVector(int arity, MutableClassDeclaration type, extension TransformationContext context) {
		val f = Constants.F.findTypeGlobally
		val f2 = Constants.F2.findTypeGlobally
		val fn = (Constants.F + arity).findTypeGlobally
		val option = Constants.OPTION.findTypeGlobally
		val a = type.typeParameters.head.newTypeReference
		
		val serializable = typeof(Serializable).findTypeGlobally.newTypeReference
		val iterable = typeof(Iterable).findTypeGlobally.newTypeReference(a)
		type.implementedInterfaces = ImmutableList.of(serializable, iterable)
		
		type.addAnnotation(typeof(Functor).newAnnotationReference)
		type.addAnnotation(typeof(Foldable).newAnnotationReference)

		for (index : 1 .. arity) {
			type.addField('''a«index»''') [
				final = true
				type = a
			]
		}

		type.addConstructor[
			visibility = Visibility.PRIVATE
			for (index : 1 .. arity) {
				addParameter('''a«index»''', a)
			}
			body = ['''
				«FOR index : 1 .. arity»
					this.a«index» = a«index»;
				«ENDFOR»
			''']
		]

		for (index : 1 .. arity) {
			type.addMethod('''get«index»''') [
				returnType = a
				body = ['''return a«index»;''']
			]
		}
		
		type.addMethod("get") [
			returnType = a
			addParameter("index", typeof(int).newTypeReference)
			body = ['''
				switch (index) {
					«FOR i : 1 .. arity»
						case «i»: return a«i»;
					«ENDFOR»
					default: throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			''']
		]
		
		type.addMethod("set") [
			returnType = type.newSelfTypeReference
			addParameter("index", typeof(int).newTypeReference)
			addParameter("value", a)
			body = ['''
				switch (index) {
					«FOR i : 1 .. arity»
						case «i»: return new V«arity»<>(«(1 .. arity).map[if (it == i) '''java.util.Objects.requireNonNull(value)''' else "a" + it].join(", ")»);
					«ENDFOR»
					default: throw new IndexOutOfBoundsException(Integer.toString(index));
				}
			''']
		]
		
		for (index : 1 .. arity) {
			type.addMethod('''set«index»''') [
				addParameter("value", a)
				returnType = type.newSelfTypeReference
				body = ['''
					return new V«arity»<>(«(1 .. arity).map[if (it == index) '''java.util.Objects.requireNonNull(value)''' else "a" + it].join(", ")»);
				''']
			]
		}

		for (index : 1 .. arity) {
			type.addMethod('''update«index»''') [
				addParameter("f", f.newTypeReference(a, a))
				returnType = type.newSelfTypeReference
				body = ['''
					return new V«arity»<>(«(1 .. arity).map[if (it == index) '''java.util.Objects.requireNonNull(f.apply(a«it»))''' else "a" + it].join(", ")»);
				''']
			]
		}

		type.addMethod("match") [
			val b = addTypeParameter("B").newTypeReference
			returnType = b
			val aa = Collections.nCopies(arity, a)
			addParameter("f", fn.typeReference(aa, b, context))
			body = ['''return f.apply(«(1 .. arity).map["a" + it].join(", ")»);''']
		]

		if (arity == 2) {
			addV2Methods(type, a, context)
		}
		
		type.addMethod("map") [
			val b = addTypeParameter("B").newTypeReference
			addParameter("f", f.newTypeReference(a, b))
			returnType = type.newTypeReference(b)
			body = ['''
				return v«arity»(«(1 .. arity).map['''f.apply(a«it»)'''].join(", ")»);
			''']
		]

		type.addMethod("v" + arity) [
			abstract = false
			static = true
			val aa = addTypeParameter("A").newTypeReference
			returnType = type.newTypeReference(aa)
			for (index : 1 .. arity) {
				addParameter('''a«index»''', aa)
			}
			body = ['''
				«FOR index : 1 .. arity»
					java.util.Objects.requireNonNull(a«index»);
				«ENDFOR»
				return new V«arity»<>(«(1 .. arity).map["a" + it].join(", ")»);
			''']
		]
		
		type.addMethod("iterator") [
			returnType = typeof(Iterator).findTypeGlobally.newTypeReference(a)
			addAnnotation(typeof(Override).newAnnotationReference)
			body = ['''return java.util.Arrays.asList(«(1 .. arity).map["a" + it].join(", ")»).iterator();''']
		]

		type.addMethod("toArray") [
			abstract = false
			returnType =  Constants.ARRAY.findTypeGlobally.newTypeReference(a)
			body = ['''
				final A[] array = (A[]) new Object[«arity»];
				«FOR index : 0 ..< arity»
					array[«index»] = a«index + 1»;
				«ENDFOR»
				return new Array<A>(array);
			''']
		]

		type.addMethod("toArrayList") [
			abstract = false
			returnType = typeof(ArrayList).newTypeReference(a)
			body = ['''
				ArrayList<A> result = new ArrayList<>(«arity»);
				«FOR index : 1 .. arity»
					result.add(a«index»);
				«ENDFOR»
				return result;
			''']
		]

		type.addMethod("toString") [
			returnType = typeof(String).newTypeReference
			addAnnotation(typeof(Override).newAnnotationReference)
			body = ['''return "V«arity»(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";''']
		]
		
		// TODO Equals
		// TODO any, all, find etc.
		
		FunctorProcessor.addMethodsForSingleParamFunctor(type, f, context)
		FoldableProcessor.addMethodsForSingleParamFoldable(type, a, f, f2, option,
			ImmutableSet.of("size", "isEmpty", "isNotEmpty", "toArray", "toArrayList"), context
		)
	}
	
	private def static addV2Methods(MutableClassDeclaration type, TypeReference a, extension TransformationContext context) {
		type.addMethod('''flip''') [
			returnType = type.newTypeReference(a)
			body = ['''return new V2<>(a2, a1);''']
		]
	}
}
