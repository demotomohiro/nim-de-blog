const rstText = """
【
【ja:ほげぴよ】
【en:Foo Bar】
】
======
【
【ja:ほげぴよ文章】
【en:foo bar content】
】
"""

let article = newTable([
  (Lang("en"),
  ArticleSrcLocal(
    title:"foo bar Title",
    description:"Test foo doc")),
  (Lang("ja"),
  ArticleSrcLocal(
    title:"Hoge hogeタイトル",
    description:"ホゲホゲ"))])
newArticle(article, rstText)

