import strformat, strutils, tables, hashes, marshal, os, parseopt
import packages/docutils/rst, packages/docutils/rstgen
import localize

export tables.newTable
export localize.Lang, localize.hash, localize.`==`

type
  ArticleSrcLocal*  = object
    title*:       string
    description*: string
  #keys are language code like "en" or "ja"
  ArticleSrc        = TableRef[Lang, ArticleSrcLocal]
  ArticleInfoLocal* = object
    title*:       string
    description*: string
    path*:        string
  #keys are language code
  ArticleInfo*  = TableRef[Lang, ArticleInfoLocal]
  ArticlesInfo* = seq[ArticleInfo]

proc initArticleInfo(): ArticleInfo = newTable[ArticleInfo.A, ArticleInfo.B](2)

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
    let rstNode = rstParse(processedRstText, "", 1, 1, hasToc, {roSupportRawDirective})

    var html = getHtmlHead(lang, a.title, a.description, cssPath)
    html.add "<body>\n"
    renderRstToOut(gen, rstNode, html)
    html.add "</body>"

    let htmlPath = basePath & ".html"
    writeFile(htmlPath, html)
    articleInfo[lang] = ArticleInfoLocal(title:a.title, description:a.description, path:htmlPath)

  echo $$articleInfo
