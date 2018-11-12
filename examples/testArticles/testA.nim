const rstText = """
【
【ja:記事のタイトル】
【en:testA article】
】
======
【
【ja:サブタイトル】
【en:testA subtitle】
】
------
【
【ja:記事の内容】
【en:textabc】
】

【
【ja:最後のタイトル】
【en:testA last title】
】
------
hoge hoge
`hoge <hoge/hoge.【 【ja:ja】【en:en】 】.html>`_

"""
let articleA = newTable([
  (Lang("en"),
  ArticleSrcLocal(
    title:"TestA title",
    description:"This description describe about this article")),
  (Lang("ja"),
  ArticleSrcLocal(
    title:"テストタイトル",
    description:"この記事の概要"))])
newArticle(articleA, rstText)
