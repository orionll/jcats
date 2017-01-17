package jcats.generator

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.List
import jcats.generator.collection.ArrayBuilderGenerator
import jcats.generator.collection.ArrayGenerator
import jcats.generator.collection.CommonGenerator
import jcats.generator.collection.StackBuilderGenerator
import jcats.generator.collection.StackGenerator
import jcats.generator.collection.SeqGenerator
import jcats.generator.collection.SeqBuilderGenerator
import jcats.generator.collection.VNGenerators
import jcats.generator.function.Eff0Generator
import jcats.generator.function.EffGenerator
import jcats.generator.function.EffNGenerators
import jcats.generator.function.F0Generator
import jcats.generator.function.FGenerator
import jcats.generator.function.FNGenerators
import jcats.generator.function.FsGenerator

import static extension java.nio.file.Files.*
import java.util.Arrays
import jcats.generator.collection.FListGenerator

class Main {
	def static void main(String[] args) {
		if (args.length == 0) {
			println("Error: specify jcats folder path")
		} else if (args.length > 1) {
			println("Error: too many arguments")
		} else {
			val dir = new File(args.head)
			if (dir.directory) {
				val srcDir = new File(dir, "src/main/java")
				if (dir.directory) {
					generateSourceCode(srcDir)
				} else {
					println('''Error: «srcDir.absolutePath» must be an existing directory''')
				}
			} else {
				println('''Error: «dir.absolutePath» must be an existing directory''')				
			}
		}
	}

	private def static generateSourceCode(File srcDir) {
		for (generator : allGenerators) {
			val srcFile = generator.className.replace('.', '/') + ".java"
			val srcFilePath = new File(srcDir, srcFile).toPath
			println('''Generating «srcFilePath.fileName»''')
			srcFilePath.parent.createDirectories
			val sourceCode = generator.sourceCode
			validate(sourceCode, srcFilePath.fileName)
			val bytes = sourceCode.getBytes(StandardCharsets.UTF_8)
			if (!srcFilePath.exists || !Arrays.equals(bytes, srcFilePath.readAllBytes)) {
				srcFilePath.write(bytes)
			}
		}
	}

	private def static List<Generator> allGenerators() {
		#[#[
			new OptionGenerator,
			new EitherGenerator,
			new SingletonIteratorGenerator,
			new FsGenerator,
			new Eff0Generator,
			new EquatableGenerator,
			new SizedGenerator,
			new OrderGenerator,
			new OrdGenerator,
			new StackGenerator,
			new StackBuilderGenerator,
			new CommonGenerator
		],
			FGenerator.generators,
			F0Generator.generators,
			EffGenerator.generators,
			FNGenerators.generators,
			EffNGenerators.generators,
			ArrayGenerator.generators,
			ArrayBuilderGenerator.generators,
			SeqGenerator.generators,
			SeqBuilderGenerator.generators,
			FListGenerator.generators,
			PNGenerators.generators,
			PGenerator.generators,
			IndexedGenerator.generators,
			VNGenerators.generators
		].flatten.toList
	}

	private def static validate(String sourceCode, Path path) {
		sourceCode.split("\\r?\\n", -1).forEach[line, lineNumber |
			if (line.matches("\t* [^\\*].*")) {
				println('''WARNING: «path»:«lineNumber + 1» - space is used for indentation''')
			}
			if (line.endsWith(" ") || line.endsWith("\t")) {
				println('''WARNING: «path»:«lineNumber + 1» - trailing whitespace''')
			} 
		]
	}
}