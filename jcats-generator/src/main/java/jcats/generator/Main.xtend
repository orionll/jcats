package jcats.generator

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.List
import jcats.generator.collection.ArrayBuilderGenerator
import jcats.generator.collection.ArrayGenerator
import jcats.generator.collection.ListBuilderGenerator
import jcats.generator.collection.ListGenerator
import jcats.generator.collection.SeqGenerator
import jcats.generator.collection.VNGenerators
import jcats.generator.function.EffGenerator
import jcats.generator.function.EffNGenerators
import jcats.generator.function.F0Generator
import jcats.generator.function.FGenerator
import jcats.generator.function.FNGenerators
import jcats.generator.function.FsGenerator
import jcats.generator.function.PNGenerators

import static extension java.nio.file.Files.*

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
			srcFilePath.write(sourceCode.getBytes(StandardCharsets.UTF_8))
		}
	}

	private def static List<Generator> allGenerators() {
		#[#[
			new OptionGenerator,
			new EitherGenerator,
			new SingletonIteratorGenerator,
			new FGenerator,
			new F0Generator,
			new FsGenerator,
			new EffGenerator,
			new SizedGenerator,
			new SizeGenerator,
			new IndexedGenerator,
			new PreciseSizeGenerator,
			new InfiniteSizeGenerator,
			new ListGenerator,
			new ListBuilderGenerator,
			new ArrayGenerator,
			new ArrayBuilderGenerator,
			new SeqGenerator
		],
			FNGenerators.generators,
			EffNGenerators.generators,
			PNGenerators.generators,
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