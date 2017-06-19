package jcats.generator

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.Arrays
import java.util.List
import jcats.generator.collection.ArrayBuilderGenerator
import jcats.generator.collection.ArrayGenerator
import jcats.generator.collection.ContainerGenerator
import jcats.generator.collection.DictGenerator
import jcats.generator.collection.IndexedContainerGenerator
import jcats.generator.collection.KeyValueGenerator
import jcats.generator.collection.OrdDictGenerator
import jcats.generator.collection.Seq0Generator
import jcats.generator.collection.Seq1Generator
import jcats.generator.collection.Seq2Generator
import jcats.generator.collection.Seq3Generator
import jcats.generator.collection.Seq4Generator
import jcats.generator.collection.Seq5Generator
import jcats.generator.collection.Seq6Generator
import jcats.generator.collection.SeqBuilderGenerator
import jcats.generator.collection.SeqGenerator
import jcats.generator.collection.StackBuilderGenerator
import jcats.generator.collection.StackGenerator
import jcats.generator.collection.UniqueContainerGenerator
import jcats.generator.collection.VNGenerators
import jcats.generator.function.Eff0Generator
import jcats.generator.function.Eff2Generator
import jcats.generator.function.EffGenerator
import jcats.generator.function.EffNGenerators
import jcats.generator.function.F0Generator
import jcats.generator.function.F2Generator
import jcats.generator.function.FGenerator
import jcats.generator.function.FNGenerators
import jcats.generator.function.FsGenerator

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
			println('''Generating «srcFile»''')
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
			new EitherGenerator,
			new FsGenerator,
			new Eff0Generator,
			new EquatableGenerator,
			new SizedGenerator,
			new OrderGenerator,
			new OrdGenerator,
			new StackGenerator,
			new StackBuilderGenerator,
			new KeyValueGenerator,
			new DictGenerator,
			new OrdDictGenerator,
			new CommonGenerator,
			new CastsGenerator,
			new String1Generator,
			new jcats.generator.collection.CommonGenerator
		],
			OptionGenerator.generators,
			FGenerator.generators,
			F0Generator.generators,
			EffGenerator.generators,
			Eff2Generator.generators,
			F2Generator.generators,
			FNGenerators.generators,
			EffNGenerators.generators,
			ContainerGenerator.generators,
			IndexedContainerGenerator.generators,
			UniqueContainerGenerator.generators,
			ArrayGenerator.generators,
			ArrayBuilderGenerator.generators,
			SeqGenerator.generators,
			Seq0Generator.generators,
			Seq1Generator.generators,
			Seq2Generator.generators,
			Seq3Generator.generators,
			Seq4Generator.generators,
			Seq5Generator.generators,
			Seq6Generator.generators,
			SeqBuilderGenerator.generators,
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