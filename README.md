# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Memo

## Rails

### 認証

別に管理画面とか高尚な？ことは期待しないので、

tokensあたりのtableを作ってそこのtokenと一致するtokenをもつrequestのみ

受け取るみたいな処理にする。

## Elm

### Show

#### DirectoryTree

* 見た目うんこなので、CSSがんばる

#### 変換

Markdown<->HTMLとの相互変換を可能にする。

Elmにlibraryが存在すればそれつかう。ないならRails側でAPI設けてそれ使う。

#### 更新

更新処理について考える。

一度けして一から遣り直す処理は確実だが、遅い。

差分更新が現実てきか。

差分の場合一番だるいのは既存の記事の更新確認だ。

title, contentsを結合してhash化して比較するぐらいしか思い付かないが、

すべてにそれやるcostは大きいと思った。
