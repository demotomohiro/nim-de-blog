import os, strformat
import nimDeBlog, localize

proc main =
  let articlesInfo = execArticles("testArticles", "public", "bin")

  for l in [Lang"ja", Lang"en"]:
    let rstSrc = localize("""
Nim De Blog
======
【
【ja:記事一覧】
【en:Artile list】
】
------
""", l)

    let rstSrcFoot = """
Footer of index page
"""

    let html = makeIndexPage(
                            articlesInfo,
                            l,
                            localize("""【
                                        【ja:Nim De Blog サンプル】
                                        【en:Nim De Blog sample】
                                        】""", l),
                            localize("""【
                                        【ja:Nim De BlogはNim言語を使った静的サイトジェネレータです。】
                                        【en:Nim De Blog is a static site generater that uses Nim programming language.】
                                        】""", l),
                            rstSrc,
                            rstSrcFoot,
                            "public")
    writeFile("public" / fmt"index.{l}.html", html)

when isMainModule:
  main()
