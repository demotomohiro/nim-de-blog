import strformat, strutils, tables, hashes, marshal, os, parseopt
import packages/docutils/rst, packages/docutils/rstgen, packages/docutils/rstast
import localize

export tables.newTable, tables.`[]=`
export localize.Lang, localize.hash, localize.`==`

type
  ArticleSrcLocal*  = object
    title*:       string
    description*: string
    category*:    string
  #keys are language code like "en" or "ja"
  ArticleSrc        = TableRef[Lang, ArticleSrcLocal]
  ArticleInfoLocal* = object
    title*:       string
    description*: string
    category*:    string
    path*:        string
  #keys are language code
  ArticleInfo*  = TableRef[Lang, ArticleInfoLocal]
  ArticlesInfo* = seq[ArticleInfo]

proc initArticleInfo(): ArticleInfo = newTable[ArticleInfo.A, ArticleInfo.B](2)

proc gatherHeadlines(n: PRstNode; result: var PRstNode; headlineStack: var seq[PRstNode]; ignore: var bool) =
  if n == nil or n.kind == rnLeaf:
    return

  if n.kind == rnContents:
    ignore = false
  elif n.kind == rnHeadline and not ignore:
    while headlineStack.len > 0 and headlineStack[^1].level >= n.level:
      discard headlineStack.pop()
    var nodeLinkText = newRstNode(rnInner)
    nodeLinkText.sons = n.sons
    var nodeLinkRefLeaf = newRstNode(rnLeaf)
    nodeLinkRefLeaf.text = "#"
    if headlineStack.len == 0:
      add nodeLinkRefLeaf.text, rstnodeToRefname(n)
    else:
      add nodeLinkRefLeaf.text, rstnodeToRefname(headlineStack[^1])
      add nodeLinkRefLeaf.text, "-"
      add nodeLinkRefLeaf.text, rstnodeToRefname(n)
    add headlineStack, n
    var nodeLink = newRstNode(rnHyperlink)
    add nodeLink, nodeLinkText
    var nodeLinkRef = newRstNode(rnInner)
    add nodeLinkRef, nodeLinkRefLeaf
    add nodeLink, nodeLinkRef
    var nodeItem = newRstNode(rnEnumItem)
    add nodeItem, nodeLink
    nodeItem.level = n.level
    var pn = result

    while pn.sons.len != 0 and pn.sons[^1].level < n.level:
      var last = pn.sons[^1]
      assert last.kind == rnEnumItem
      if last.sons.len == 1:
        var enumList = newRstNode(rnEnumList)
        add last, enumList
        pn = enumList
        break
      assert last.sons.len == 2 and last.sons[1].kind == rnEnumList
      pn = last.sons[1]
    add pn, nodeItem

  else:
    for i in n.sons:
      gatherHeadlines(i, result, headlineStack, ignore)

proc findContentsDir(n: PRstNode): (PRstNode, int) =
  assert n != nil
  assert n.kind != rnContents
  for i in 0..<(len(n.sons)):
    let son = n.sons[i]
    if son == nil:
      continue
    if son.kind == rnLeaf:
      continue
    if son.kind == rnContents:
      return (n, i)
    let (nc, j) = findContentsDir(son)
    if nc != nil:
      return (nc, j)

proc expandRSTContentsDirective(n: var PRstNode) =
  let (nc, i) = findContentsDir(n)
  if nc == nil:
    return

  var
    toc: PRstNode = newRstNode(rnEnumList)
    headlineStack: seq[PRstNode]
    ignore: bool = true
  gatherHeadlines(n, toc, headlineStack, ignore)
  insert nc.sons, toc, i

proc getHtmlHead*(lang: Lang; title, description: string; cssPath: string = ""): string =
  let metaDesc = if description.len == 0 : "" else: &"<meta name=\"description\" content=\"{description}\">"
  let css = if cssPath.len == 0: "" else:
            fmt"""<link rel="stylesheet" type="text/css" href="{cssPath}">"""
  return fmt"""
<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  {metaDesc}
  {css}
  <title>{title}</title>
</head>
"""

proc newArticle*(articleSrc: ArticleSrc; rstText: string) =
  proc processRstText(articleSrc: ArticleSrc; rstText: string; lang: Lang; filename, relativeDstDir: string): string =
    let rstTextLocal = localize(rstText, lang)
    var otherLangLinks = ""
    for l in articleSrc.keys:
      if l == lang:
        continue
      otherLangLinks.add &"`{langToNativeName[l]} <{filename}.{l}.html>`_ "
    let indexPageLink = relativeDstDir & "/" & fmt"index.{lang}.html"
    rstTextLocal % ["otherLangLinks", otherLangLinks, "indexPageLink", indexPageLink]

  if articleSrc.len == 0:
    echo "Empty article"
    return
  var
    path: string
    header: string
    footer: string
    relativeDstDir: string
    cssPath: string
  for kind, key, val in getopt():
    case key
    of "o": path = val
    of "header": header = val
    of "footer": footer = val
    of "relativeDstDir": relativeDstDir = val
    of "cssPath": cssPath = val
    else: assert(false)
  assert path.len != 0
  createDir(parentDir(path))
  let articleInfo = initArticleInfo()
  let filename = extractFilename(path)
  for lang, a in articleSrc.pairs:
    var gen: RstGenerator
    let basePath = path & "." & $lang
    initRstGenerator(gen, outHtml, defaultConfig(), basePath & ".rst", {})

    let rstTextFull = header & "\n\n" & rstText & "\n\n" & footer
    let processedRstText = processRstText(articleSrc, rstTextFull, lang, filename, relativeDstDir)
    var hasToc:bool
    var rstNode = rstParse(processedRstText, "", 1, 1, hasToc, {roSupportRawDirective})
    expandRSTContentsDirective(rstNode)

    var html = getHtmlHead(lang, a.title, a.description, cssPath)
    html.add "<body>\n"
    renderRstToOut(gen, rstNode, html)
    html.add "</body>"

    let htmlPath = basePath & ".html"
    writeFile(htmlPath, html)
    articleInfo[lang] = ArticleInfoLocal(
                                         title:a.title,
                                         description:a.description,
                                         category:a.category,
                                         path:htmlPath)

  echo $$articleInfo
