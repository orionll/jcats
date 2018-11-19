package jcats.generator

import com.google.common.base.Stopwatch
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.Arrays
import java.util.List
import jcats.generator.collection.ArrayBuilderGenerator
import jcats.generator.collection.ArrayGenerator
import jcats.generator.collection.ContainerGenerator
import jcats.generator.collection.ContainerViewGenerator
import jcats.generator.collection.DictBuilderGenerator
import jcats.generator.collection.DictGenerator
import jcats.generator.collection.HashTableCommonGenerator
import jcats.generator.collection.IndexedContainerGenerator
import jcats.generator.collection.IndexedContainerViewGenerator
import jcats.generator.collection.KeyValueGenerator
import jcats.generator.collection.PrimitiveStream2Generator
import jcats.generator.collection.RangeGenerator
import jcats.generator.collection.Seq0Generator
import jcats.generator.collection.Seq1Generator
import jcats.generator.collection.Seq2Generator
import jcats.generator.collection.Seq3Generator
import jcats.generator.collection.Seq4Generator
import jcats.generator.collection.Seq5Generator
import jcats.generator.collection.Seq6Generator
import jcats.generator.collection.SeqBuilderGenerator
import jcats.generator.collection.SeqGenerator
import jcats.generator.collection.SortedDictBuilderGenerator
import jcats.generator.collection.SortedDictGenerator
import jcats.generator.collection.SortedUniqueBuilderGenerator
import jcats.generator.collection.SortedUniqueContainerGenerator
import jcats.generator.collection.SortedUniqueContainerViewGenerator
import jcats.generator.collection.SortedUniqueGenerator
import jcats.generator.collection.StackBuilderGenerator
import jcats.generator.collection.StackGenerator
import jcats.generator.collection.Stream2Generator
import jcats.generator.collection.UniqueBuilderGenerator
import jcats.generator.collection.UniqueContainerGenerator
import jcats.generator.collection.UniqueContainerViewGenerator
import jcats.generator.collection.UniqueGenerator
import jcats.generator.collection.VNGenerators
import jcats.generator.function.Eff0Generator
import jcats.generator.function.Eff0XGenerator
import jcats.generator.function.Eff2Generator
import jcats.generator.function.EffGenerator
import jcats.generator.function.EffNGenerators
import jcats.generator.function.EffXGenerator
import jcats.generator.function.F0Generator
import jcats.generator.function.F0XGenerator
import jcats.generator.function.F2Generator
import jcats.generator.function.FGenerator
import jcats.generator.function.FNGenerators
import jcats.generator.function.FXGenerator
import jcats.generator.function.FsGenerator

import static extension java.nio.file.Files.*

final class Main {
	def static void main(String[] args) {
		if (args.length > 1) {
			println("Error: too many arguments")
			System.exit(1)
		}

		val stopwatch = Stopwatch.createStarted

		val dir = new File(if (args.length > 0) args.head else "../jcats")
		if (!dir.directory) {
			println('''Error: «dir.canonicalPath» must be an existing directory''')
			System.exit(1)
		}

		val srcDir = new File(dir, "src/main/java")
		if (!srcDir.directory) {
			srcDir.mkdir
		}

		generateSourceCode(srcDir)

		println('''Execution time: «stopwatch.stop»''')
	}

	private def static generateSourceCode(File srcDir) {
		println('''Generating source code to «srcDir.canonicalPath»''')
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
			new UnitGenerator,
			new ControlGenerator,
			new MatcherGenerator,
			new FsGenerator,
			new FXGenerator,
			new F0XGenerator,
			new EffXGenerator,
			new Eff0Generator,
			new Eff0XGenerator,
			new EquatableGenerator,
			new SizedGenerator,
			new OrderGenerator,
			new OrderedGenerator,
			new CloseableXGenerator,
			new RangeGenerator,
			new KeyValueGenerator,
			new DictGenerator,
			new DictBuilderGenerator,
			new UniqueGenerator,
			new UniqueBuilderGenerator,
			new SortedDictGenerator,
			new SortedDictBuilderGenerator,
			new HashTableCommonGenerator,
			new CommonGenerator,
			new CastGenerator,
			new String1Generator,
			new Stream2Generator,
			new SizeOverflowExceptionGenerator,
			varianceAnnotationGenerator(true),
			varianceAnnotationGenerator(false),
			new jcats.generator.collection.CommonGenerator
		],
			OrdGenerator.generators,
			OrdsGenerator.generators,
			MaybeGenerator.generators,
			OptionGenerator.generators,
			EitherGenerator.generators,
			FGenerator.generators,
			F0Generator.generators,
			EffGenerator.generators,
			Eff2Generator.generators,
			F2Generator.generators,
			FNGenerators.generators,
			EffNGenerators.generators,
			ContainerGenerator.generators,
			ContainerViewGenerator.generators,
			IndexedContainerGenerator.generators,
			IndexedContainerViewGenerator.generators,
			UniqueContainerGenerator.generators,
			UniqueContainerViewGenerator.generators,
			SortedUniqueContainerGenerator.generators,
			SortedUniqueContainerViewGenerator.generators,
			ArrayGenerator.generators,
			ArrayBuilderGenerator.generators,
			StackGenerator.generators,
			StackBuilderGenerator.generators,
			SeqGenerator.generators,
			Seq0Generator.generators,
			Seq1Generator.generators,
			Seq2Generator.generators,
			Seq3Generator.generators,
			Seq4Generator.generators,
			Seq5Generator.generators,
			Seq6Generator.generators,
			SeqBuilderGenerator.generators,
			SortedUniqueGenerator.generators,
			SortedUniqueBuilderGenerator.generators,
			PNGenerators.generators,
			PGenerator.generators,
			IndexedGenerator.generators,
			PrimitiveStream2Generator.generators,
			VNGenerators.generators
		].flatten.toList
	}

	private def static Generator varianceAnnotationGenerator(boolean covariant) {
		new Generator() {
			def shortName() {
				if (covariant) "Covariant" else "Contravariant"
			}

			override className() {
				Constants.JCATS + "." + shortName
			}

			override sourceCode() { '''
				package «Constants.JCATS»;

				import java.lang.annotation.Documented;
				import java.lang.annotation.Retention;
				import java.lang.annotation.Target;

				import static java.lang.annotation.ElementType.TYPE_PARAMETER;
				import static java.lang.annotation.RetentionPolicy.SOURCE;

				@Documented
				@Retention(SOURCE)
				@Target(TYPE_PARAMETER)
				public @interface «shortName» {
				}
			''' }
		}
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