import marshal, os, osproc, sets, strutils, strformat, tables
import packages/docutils/rst, packages/docutils/rstgen
import ../../compiler/pathutils
import nimDeBlogArticle, localize

proc toAbsoluteDir(dir: string): AbsoluteDir =
  toAbsolute(dir, getCurrentDir().AbsoluteDir).AbsoluteDir

proc execArticles*(articlesSrcDir, articlesDstDir, execDstDir: string): ArticlesInfo =
  result = @[]
  let absArticlesSrcDir = toAbsoluteDir(articlesSrcDir)
  let absArticlesDstDir = toAbsoluteDir(articlesDstDir)
  let absExecDstDir = toAbsoluteDir(execDstDir)
  if not existsDir(absArticlesSrcDir.string):
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
    let outp = execProcess(command = string(exePath), args = ["-o=" & string(outPath)], options = {poEchoCmd})
    if outp.len == 0:
      echo "Warning: no output from ", i
    else:
      result.add to[ArticleInfo](outp)

proc makeIndex(
              articlesInfo: openArray[ArticleInfo];
              lang: Lang;
              preIndex, postIndex: string;
              indexDir: AbsoluteDir): string =
  proc getIndices(articlesInfo: openArray[ArticleInfo]; lang: Lang): string =
    result = ""
    for a in articlesInfo:
      if lang notin a:
        continue
      let al = a[lang]
      let path = replace(relativeTo(AbsoluteFile(al.path), indexDir).string, '\\', '/')
      result.add &"- `{al.title} <{path}>`_\n"

  let rstSrc = preIndex & getIndices(articlesInfo, lang) & postIndex

  var gen: RstGenerator
  initRstGenerator(gen, outHtml, defaultConfig(), "", {})
  var hasToc:bool
  let rstNode = rstParse(rstSrc, "", 1, 1, hasToc, {})
  result = ""
  renderRstToOut(gen, rstNode, result)

proc makeIndexPage*(
                    articlesInfo: openArray[ArticleInfo];
                    lang: Lang;
                    title, description, preIndex, postIndex: string;
                    indexDir: string): string =
  let absIndexDir = toAbsoluteDir(indexDir)
  result = getHtmlHead(lang, title, description)
  result.add "<body>\n"
  result.add makeIndex(articlesInfo, lang, preIndex, postIndex, absIndexDir)
  result.add "</body></html>"

proc makeIndexPages*(
                    articlesInfo: openArray[ArticleInfo];
                    title, description, preIndex, postIndex: string;
                    indexDir: string): string =
  var langSet: HashSet[Lang]
  langSet.init(2)
  for a in articlesInfo:
    for l in a.keys:
      langSet.incl l

  for l in langSet:
    let html = makeIndexPage(
                            articlesInfo,
                            l,
                            localize(title, l),
                            localize(description, l),
                            localize(preIndex, l),
                            localize(postIndex, l),
                            indexDir)
    writeFile(indexDir / fmt"index.{l}.html", html)

