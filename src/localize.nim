import pegs, strformat, strutils, hashes, tables

type
  Lang*         = distinct string

proc hash*(x: Lang): Hash {.borrow.}
proc `==`*(x, y: Lang): bool {.borrow.}
proc `$`*(x: Lang): string {.borrow.}

#ISO 639-1 code to native language name.
#Check https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
const langToNativeName* = {
                          Lang"zh": "中文",
                          Lang"en": "English",
                          Lang"fr": "français",
                          Lang"de": "Deutsch",
                          Lang"ja": "日本語",
                          Lang"ru": "русский",
                          Lang"es": "Español"}.toTable

proc filterLang(source: string; lang: string): string =
  let removePeg = peg(fmt("""
    block    <- {{text*}} '【' \s+ (\s* (selected / removed))* \s+ '】'
    removed  <- '【'!'{lang}:' text*'】'
    selected <- '【{lang}:' {{text*}}'】'
    text     <- '【【' / '】】' / (!'【' !'】' _)
    """))

  proc handleMatches(m: int, n: int, c: openArray[string]): string =
    result = ""
    for i in 0..<n:
      result.add c[i]

  return replace(source, removePeg, handleMatches)

proc localize*(source: string; lang: Lang): string =
  let filteredLang = filterLang(source, $lang)
  return multiReplace(filteredLang, [("【【", "【"), ("】】", "】")])
  
when isMainModule:
  iterator eachLang(source: string; langs: openarray[Lang]): string =
    for l in langs:
      yield localize(source, l)

  doAssert filterLang("【 【ja:あ】 】", "ja") == "あ"
  doAssert filterLang("【  【ja:あ】  】", "en") == ""
  doAssert filterLang("【 【ja:あ】\n【ja:あ】 】", "ja") == "ああ"
  doAssert filterLang("【 【ja:あa】 】【 【ja:いi】 】", "ja") == "あaいi"
  doAssert filterLang("【 【ja:あa】 】【 【en:ii】 】", "en") == "ii"
  doAssert filterLang("【 【en:xxx】\t【ja:aaa】 】", "en") == "xxx"
  doAssert filterLang("【 【ja:あ】【ja:あ】\t 】", "en") == ""
  doAssert filterLang("【 【ja:ほげ】【en:foo】\t 】 abc 【 【ja:はげ】\t【en:foo】 】", "en") == "foo abc foo"
  doAssert filterLang("【【【 【en:】 】", "ja") == "【【"
  doAssert filterLang("【【【\t\n 【en:abc】【ja:あいう】\n】ほげ", "ja") == "【【あいうほげ"
  doAssert filterLang("【【_【 【en:【【abc】【ja:あ】】いう】】】\t】ほげ【 【ja:うう】 】---【\n【en:xyz】\n】】】", "ja") == "【【_あ】】いう】】ほげうう---】】"
  doAssert filterLang("a【【【 【en:【【xxx】\n【ja:aaa】】】 】】】e】】【 【en:xxx】】】\n【ja:aaa】】【【】 】【【", "en") == "a【【【【xxx】】e】】xxx】】【【"

  import sequtils

  let seq = toSeq(eachLang("""あ【 【ja:ほほ】 【en:foo】 】a""",
                            [Lang"ja", Lang"en"]))
  doAssert seq[0] == "あほほa"
  doAssert seq[1] == "あfooa"

  let seq2 = toSeq(eachLang("""【 【ja:い】】【【】 】aab】】【【_【 【en:foo】 】a】】【【【 【ja:】 】""",
                            [Lang"en", Lang"ja"]))
  doAssert seq2[0] == "aab】【_fooa】【"
  doAssert seq2[1] == "い】【aab】【_a】【"

  quit "Test completed"
