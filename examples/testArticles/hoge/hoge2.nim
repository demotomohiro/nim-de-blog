const rstText = """
# 【
【ja:ほげ2】
【en:Foo Bar2】
】

【
【ja:ほげ2について】
【en:foo bar2】
】
"""

let article = newTable([
  (Lang("en"),
  ArticleSrcLocal(
    title:"foo bar2",
    description:"Test foo doc",
    category:"Hoge")),
  (Lang("ja"),
  ArticleSrcLocal(
    title:"Hoge2タイトル",
    description:"ホゲホゲ2",
    category:"ホゲ"))])
newArticle(article, rstText)

