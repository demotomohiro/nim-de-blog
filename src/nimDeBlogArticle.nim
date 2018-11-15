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

proc getHtmlHead*(lang: Lang; title, description: string): string =
  let metaDesc = if description.len == 0 : "" else: &"<meta name=\"description\" content=\"{description}\">"
  return fmt"""
<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  {metaDesc}
  <title>{title}</title>
</head>
"""

proc newArticle*(articleSrc: ArticleSrc; rstText: string) =
  if articleSrc.len == 0:
    echo "Empty article"
    return
  var path: string
  for kind, key, val in getopt():
    case key
    of "o": path = val
    else: assert(false)
  assert path.len != 0
  createDir(parentDir(path))
  let articleInfo = initArticleInfo()
  let filename = extractFilename(path)
  for lang, a in articleSrc.pairs:
    var gen: RstGenerator
    let basePath = path & "." & $lang
    initRstGenerator(gen, outHtml, defaultConfig(), basePath & ".rst", {})

    let rstTextLocal = localize(rstText, lang)
    var hasToc:bool
    let rstNode = rstParse(rstTextLocal, "", 1, 1, hasToc, {})

    var html = getHtmlHead(lang, a.title, a.description)
    html.add "<body>\n"
    for l in articleSrc.keys:
      if l == lang:
        continue
      html.add &"<a href=\"{filename}.{l}.html\">{langToNativeName[l]}</a> "
    renderRstToOut(gen, rstNode, html)
    html.add "</body>"

    let htmlPath = basePath & ".html"
    writeFile(htmlPath, html)
    articleInfo[lang] = ArticleInfoLocal(title:a.title, description:a.description, path:htmlPath)

  echo $$articleInfo
