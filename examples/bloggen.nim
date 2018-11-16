import os, strformat
import nimDeBlog, localize

proc main =
  let articleHead = """
【
【ja:Nim De Blogのサンプル記事】
【en:Nim De Blog sample article】
】
"""
  let articlesInfo = execArticles("testArticles", "public", "bin", articleHead)

  let rstSrcHead = """
Nim De Blog
======
【
【ja:記事一覧】
【en:Artile list】
】
------
"""

  let rstSrcFoot = """
Footer of index page
"""

  let html = makeIndexPages(
                            articlesInfo,
                            """【
                               【ja:Nim De Blog サンプル】
                               【en:Nim De Blog sample】
                               】""",
                            """【
                               【ja:Nim De BlogはNim言語を使った静的サイトジェネレータです。】
                               【en:Nim De Blog is a static site generater that uses Nim programming language.】
                               】""",
                            rstSrcHead,
                            rstSrcFoot,
                            "public")

when isMainModule:
  main()
