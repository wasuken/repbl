port module Show exposing (..)

import Browser
import Html as HTML exposing (Html)
import List.Extra as LE
import Http
import Json.Decode as D exposing (Decoder, field, int, list, map3, string)
import Element as E exposing (..)
import Element.Events as Event
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Regex

-- MODEL

-- 以下をArrange(劣化).
-- https://qiita.com/Goryudyuma/items/e4c558bd309bc9c4de52
type NaturalJson
    = String String
    | Int Int
    | Null
    | Object (List ( String, NaturalJson))
    | List (List NaturalJson)

type alias ContentsMap = { id : Int, contents: String }

type alias FileInfo =
     { path : String
     , title : String
     , contents : String
     , rfileId : Int
     }

type alias Model =
    { cursorFile : FileInfo
    , dirJson : NaturalJson
    , csrfToken : String
    , repoId : Int
    }



-- INIT


init : ( Model, Cmd Message )
init =
    ( Model { path = "", title = "", contents = "" ,rfileId = -1 } Null "" -1, Cmd.none )



-- VIEW

grey : Color
grey =
    rgb255 0xc0 0xc0 0xc0


-- typeとpathしか取得できない。
attrGetAt : Int -> NaturalJson -> String -> String
attrGetAt n json default =
    case json of
       Object lst ->
          case (LE.getAt n lst) of
             Just (k, v) ->
                case v of
                   String s -> s
                   Int i -> String.fromInt i
                   _ -> default

             _ -> default

       _ -> default

-- Directoryのchildrenを取得するやつ。
-- 本当なら上記関数と統合したかったが、無理だった。
attrGetChildren : NaturalJson -> List NaturalJson
attrGetChildren json =
    case json of
       Object lst ->
            case (LE.getAt 2 lst) of
               Just (k, v) ->
                  case v of
                     List l -> l
                     _ -> []
               Nothing -> []
       _ -> []


-- 下記よりおぱくり申した
-- https://package.elm-lang.org/packages/elm/regex/latest/Regex#replace
userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
  case Regex.fromString userRegex of
    Nothing ->
      string

    Just regex ->
      Regex.replace regex replacer string

naturalJsonToElement : NaturalJson -> Int -> Int -> String -> (E.Element Message)
naturalJsonToElement fs repoId level currentPath =
    let tp = attrGetAt 0 fs "unknown"
        path = userReplace ("^" ++ currentPath) (\_ -> "" ) (attrGetAt 1 fs "unknown")
        fullpath = currentPath ++ path
        children = case tp of
                      "directory" ->
                            List.map (\child -> naturalJsonToElement child repoId (level + 1) fullpath) (attrGetChildren fs)
                      _ -> []
        id = case tp of
                     "file" ->
                         case String.toInt (attrGetAt 2 fs "-1") of
                            Just i -> i
                            Nothing -> -1
                     _ -> -2
    in column [] ([ textColumn
                        [ paddingEach { top = 0, left = (10 * level), right = 0, bottom = 0 } ]
                        [ textColumn [ Event.onClick (FileClick (String.fromInt repoId) id)
                                     , pointer ]
                                     [ text path ] ]
                  ] ++ children)

-- Event.onClick <| DisplayFile fullpath


view : Model -> Html Message
view model =
    layout [] (row []
        [ column [ Border.widthEach { bottom = 2, top = 2, left = 2, right = 2 }
                 , Border.color grey, padding 30
                 , height (fill |> minimum 300)
                 , width <| px 300
                 , scrollbarY ]
               [ text "[Directory]"
               , naturalJsonToElement model.dirJson model.repoId 0 "" ]
        , column [ height fill
                 , width fill
                 , Border.widthEach { bottom = 2, top = 2, left = 2, right = 2 }
                 , Border.color grey
                 , padding 30 ]
            [ text ("title:" ++ model.cursorFile.title)
            , text ("path:" ++ model.cursorFile.path)
            , text ("contents:" ++ model.cursorFile.contents)
            ]
        ]
     )



-- MESSAGE


type Message
    = ChangeFile FileInfo
    | GotDirectoryJson (Result Http.Error NaturalJson)
    | GotParam Param
    | GotFileContentsJson (Result Http.Error ContentsMap)
    | FileClick String Int

type alias Param =
     { repoId : String
     , csrfToken : String }

port param : (Param -> msg) -> Sub msg

-- UPDATE

update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
       ChangeFile fInfo ->
        ( { model | cursorFile = fInfo
                  , dirJson = model.dirJson
                  , csrfToken = model.csrfToken
                  , repoId = model.repoId }
          , Cmd.none )

       GotDirectoryJson result ->
           case result of
               Ok json ->
                  ( { model | cursorFile = model.cursorFile
                            , dirJson = json }
                  , Cmd.none
                  )

               Err _ ->
                  ( model, Cmd.none )

       GotParam prm ->
           let id = Maybe.withDefault -1 (String.toInt prm.repoId)
           in
           ( { model | cursorFile = model.cursorFile
                  , dirJson = model.dirJson
                  , csrfToken = prm.csrfToken
                  , repoId = id}
             , Cmd.batch [ projectInfoListAsync id ] )

       -- GotFileContentsAsync repoId rfileId

       GotFileContentsJson result ->
           case result of
              Ok cm ->
                   ( { model | cursorFile =  { title = model.cursorFile.title
                                             , path = model.cursorFile.path
                                             , contents = cm.contents
                                             , rfileId = cm.id }}
                   , Cmd.none)
              Err _ -> ( model , Cmd.none )

       FileClick repoId rfileId ->
            ( { model | cursorFile =  { title = model.cursorFile.title
                                             , path = model.cursorFile.path
                                             , contents = model.cursorFile.contents
                                             , rfileId =  rfileId}}
            , Cmd.batch [ fileContentsAsync repoId (String.fromInt rfileId) ] )



subscriptions : Model -> Sub Message
subscriptions model =
    param GotParam

-- HTTP

projectInfoListAsync : Int -> Cmd Message
projectInfoListAsync repoId =
     Http.get
        { url = "/api/v1/repos/" ++ (String.fromInt repoId)
        , expect = Http.expectJson GotDirectoryJson naturalJsonDecoder
        }

fileContentsAsync : String -> String -> Cmd Message
fileContentsAsync repoId rfileId =
     Http.get
        { url = "/api/v1/rfiles/" ++ repoId ++ "/" ++ rfileId
        , expect = Http.expectJson GotFileContentsJson fileContentsDecoder
        }

fileContentsDecoder : D.Decoder ContentsMap
fileContentsDecoder = D.map2 ContentsMap
                           (field "id" int)
                           (field "contents" string)


-- 下記の劣化
-- https://qiita.com/Goryudyuma/items/e4c558bd309bc9c4de52#%E3%81%9D%E3%82%8C%E3%81%AB%E5%90%88%E3%82%8F%E3%81%9B%E3%81
naturalJsonDecoder : D.Decoder NaturalJson
naturalJsonDecoder =
    D.oneOf
        [ D.string
            |> D.andThen (\str -> D.succeed (String str))
        , D.int
            |> D.andThen (\str -> D.succeed (Int str))
        , D.lazy
            (\_ ->
                D.list naturalJsonDecoder
            )
            |> D.andThen (\list -> D.succeed (List list))
        , D.lazy
            (\_ ->
                D.keyValuePairs naturalJsonDecoder
            )
            |> D.andThen (\object -> D.succeed (Object object))
        , D.nullable D.value
            |> D.andThen (\_ -> D.succeed Null)
        ]


-- MAIN


main : Program (Maybe {}) Model Message
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
