import std/[algorithm, marshal, os, osproc, sequtils, sets, strutils, strformat, tables, streams]
import packages/docutils/rst, packages/docutils/rstgen
import "$nim"/compiler/pathutils
import nimDeBlogArticle, localize

proc toAbsoluteDir(dir: string): AbsoluteDir =
  toAbsolute(dir, getCurrentDir().AbsoluteDir).AbsoluteDir

proc toAbsolute(file: string): AbsoluteFile  =
  toAbsolute(file, getCurrentDir().AbsoluteDir)

proc execArticles*(
                  articlesSrcDir, articlesDstDir, execDstDir,
                  header, footer, cssPath: string): ArticlesInfo =
  result = @[]
  let absArticlesSrcDir = toAbsoluteDir(articlesSrcDir)
  let absArticlesDstDir = toAbsoluteDir(articlesDstDir)
  let absExecDstDir = toAbsoluteDir(execDstDir)
  let absCssPath    = if cssPath.len == 0: "".AbsoluteFile else: toAbsolute(cssPath)
  if not dirExists(absArticlesSrcDir.string):
    raise newException(IOError, absArticlesSrcDir.string & " does not exists")
  for i in walkDirRec(absArticlesSrcDir.string, {pcFile}, {pcDir}):
    let path = splitFile(i)
    if path .ext != ".nim":
      continue

    let outPathRel = changeFileExt(relativeTo(i.AbsoluteFile, absArticlesSrcDir), "")
    let exePath = absExecDstDir / outPathRel
    createDir(parentDir(exePath.string))
    const modPath = currentSourcePath().splitFile.dir / "nimDeBlogArticle.nim"
    let drelease = when defined(release): "-d:release" else: ""
    if execCmd(&"nim c {drelease} --out:{exePath.string} --import:{modPath} {i}") != 0:
      quit "Fix error!"

    let outPath = absArticlesDstDir / outPathRel
    var relativeDstDir = relativeTo(absArticlesDstDir.AbsoluteFile, parentDir(outPath.string).AbsoluteDir).string
    if relativeDstDir.len == 0:
      relativeDstDir = $CurDir
    let relativeCssPath = relativeTo(absCssPath, outPath.string.parentDir.AbsoluteDir).string
    var args = @[
                "-o=" & string(outPath),
                "--header=" & header,
                "--footer=" & footer,
                "--relativeDstDir=" & relativeDstDir]
    if relativeCssPath.len != 0:
      args.add "--cssPath=" & relativeCssPath

    var
      p = startProcess(command = string(exePath),
                       args = args,
                       options = {poEchoCmd})
      outStrm = p.outputStream()

    let err = p.errorStream().readAll
    stderr.write err
    let outp = outStrm.readAll
    if outp.len == 0:
      echo "Error: no output from ", i
    else:
      result.add to[ArticleInfo](outp)

    if p.waitForExit != 0:
      quit "Failed to run " & i

    p.close

proc makeIndex(
              articlesInfo: openArray[ArticleInfo];
              lang: Lang;
              preIndex, postIndex: string;
              indexDir: AbsoluteDir): string =
  proc getIndices(articlesInfo: openArray[ArticleInfo]; lang: Lang): string =
    var categorySet: HashSet[string]

    for a in articlesInfo:
      if lang notin a:
        continue
      categorySet.incl a[lang].category

    var categories = toSeq(categorySet)
    categories.sort()

    result = ""
    for c in categories:
      let indent = if c.len == 0: "" else: "  "
      if c.len != 0:
        result.add &"- {c}\n"

      for a in articlesInfo:
        if lang notin a:
          continue
        let al = a[lang]
        if al.category != c:
          continue
        let path = replace(relativeTo(AbsoluteFile(al.path), indexDir).string, '\\', '/')
        result.add indent & &"- `{al.title} <{path}>`_\n"

  let rstSrc = preIndex & getIndices(articlesInfo, lang) & postIndex

  let (rstNode, filenames, _) = rstParse(rstSrc, "", 1, 1, {roSupportMarkdown, roSupportRawDirective, roSandboxDisabled})
  var gen: RstGenerator
  initRstGenerator(gen, outHtml, defaultConfig(), "", filenames = filenames)
  result = ""
  renderRstToOut(gen, rstNode, result)

proc makeIndexPage*(
                    articlesInfo: openArray[ArticleInfo];
                    lang: Lang;
                    title, description, preIndex, postIndex: string;
                    transLinks: string;
                    indexDir: string): string =
  let absIndexDir = toAbsoluteDir(indexDir)
  result = getHtmlHead(lang, title, description)
  result.add "<body>\n"
  result.add transLinks
  result.add makeIndex(articlesInfo, lang, preIndex, postIndex, absIndexDir)
  result.add "</body></html>"

proc makeIndexPages*(
                    articlesInfo: openArray[ArticleInfo];
                    title, description, preIndex, postIndex: string;
                    indexDir: string) =
  var langSet: HashSet[Lang]
  langSet.init(2)
  for a in articlesInfo:
    for l in a.keys:
      langSet.incl l

  for l in langSet:
    var transLinks = "\n"
    for ll in langSet:
      if l == ll:
        continue
      transLinks.add &"<a href=\"index.{ll}.html\">{langToNativeName[ll]}</a> "
    transLinks.add '\n'

    let html = makeIndexPage(
                            articlesInfo,
                            l,
                            localize(title, l),
                            localize(description, l),
                            localize(preIndex, l),
                            localize(postIndex, l),
                            transLinks,
                            indexDir)
    writeFile(indexDir / fmt"index.{l}.html", html)

proc makeBlog*(
              articlesSrcDir, articlesDstDir, execDstDir, header, footer: string;
              title, description, preIndex, postIndex: string;
              cssPath: string = "") =
  let articlesInfo = execArticles(articlesSrcDir, articlesDstDir, execDstDir, header, footer, cssPath)
  makeIndexPages(articlesInfo, title, description, preIndex, postIndex, articlesDstDir)
