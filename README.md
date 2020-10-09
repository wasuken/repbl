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

## 突発Memo

後でけす。

### 修正するかも?

* ParseしやすいJSON、もといRails側のzfsの構造を修正する。

* fileのcontentsを含めた現状のJSONから、含めずにpathもしくはpath_idをふくむJSONへと変更し、fileはpaths/files_controllerから


### とりあえず実装する機能Memo(Show.elm)

#### page読込時

1. JSON取得

2. JSONからdirtreeを生成。

#### dirtree event 一覧

##### file on click

中央辺りにcontentsを出力。

##### dir on click

とくに考えてない

#### model

* dirJson : ?

* fileInfo : FileInfo 選択されているfile。表示する用。

	* FileInfo

			* path

			* title

			* contents

#### message

* ChangeFile

* ViewDirectory
