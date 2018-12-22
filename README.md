# nim-de-blog
Nim De Blog is a static site generater that uses Nim programming language.
You can use Nim programming language and reStructuredText to write articles.
Nim De Blog is designed to write multiple languages blog.

## How to use
Check files under examples/ directory.
``bloggen.nim`` imports ``nimDeBlog`` module and call ``makeBlog`` procedure.
That procedure execute all nim files under ``articlesSrcDir`` directory that is specified in ``makeBlog`` procedure.
Each nim files under ``articlesSrcDir`` directory call ``newArticle`` procedure that generate html files.
Then, ``makeBlog`` procedure generate index html file that has a list of links to each generated html files.

### How to write a article
Write a article using a reStructuredText and pass it to ``newArticle`` procedure
with a table data that has title and description of the article.
