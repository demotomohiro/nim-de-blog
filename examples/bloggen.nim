import nimDeBlog

proc main =
  let indexLink = """
`【
【ja:記事一覧へ】
【en:index】
】 <$indexPageLink>`_
"""
  let articleHead = indexLink & """
$otherLangLinks

【
【ja:Nim De Blogのサンプル記事】
【en:Nim De Blog sample article】
】

----
"""
  let articleFoot = """
----

【
【ja:記事の下の部分】
【en:Footer of article page.】
】

""" & indexLink
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

  makeBlog(
          articlesSrcDir  = "testArticles",
          articlesDstDir  = "public",
          execDstDir      = "bin",
          header          = articleHead,
          footer          = articleFoot,
          title           = """【
                               【ja:Nim De Blog サンプル】
                               【en:Nim De Blog sample】
                               】""",
          description     = """【
                               【ja:Nim De BlogはNim言語を使った静的サイトジェネレータです。】
                               【en:Nim De Blog is a static site generater that uses Nim programming language.】
                               】""",
          preIndex        = rstSrcHead,
          postIndex       = rstSrcFoot,
          cssPath         = "public/test.css")
when isMainModule:
  main()
