const rstText = """
【
【ja:記事のタイトル】
【en:testA article】
】
======

.. contents::

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
【ja:第二章】
【en:second section】
】
------

【
【ja:サブセクション】
【en:Sub section】
】
.....

【
【ja:サブセクションのサブセクション】
【en:Sub section of sub section】
】
~~~~~

【
【ja:第二のサブセクション】
【en:Second Sub section】
】
.....

【
【ja:Hogeとは】
【en:Whats is foo】
】
~~~~~

【
【ja:Piyoとは】
【en:Whats is bar】
】
~~~~~

.. raw:: html

   <button>Test raw directive</button>

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
