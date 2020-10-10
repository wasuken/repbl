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
    | Null
    | Object (List ( String, NaturalJson))
    | List (List NaturalJson)

type alias FileInfo =
     { path : String
     , title : String
     , contents : String
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
    ( Model { path = "", title = "", contents = "" } Null "" -1, Cmd.none )



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

-- searchPathInDirJson : NaturalJson -> String -> MayBe FileInfo
-- searchPathInDirJson json targetPath =
--     let path = (attrGetAt 1 json "unknown")
--         tp = attrGetAt 0 json "unknown"
--         children = case tp of
--                       "directory" ->
--                             (attrGetChildren json)
--                       _ -> Nothing
--     in case (path == targetPath) of
--           True -> Just json
--           False ->
--               let reg = Maybe.withDefault Regex.never <| Regex.fromString ("^" ++ path)
--               in Nothing

-- 下記よりおぱくり申した
-- https://package.elm-lang.org/packages/elm/regex/latest/Regex#replace
userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
  case Regex.fromString userRegex of
    Nothing ->
      string

    Just regex ->
      Regex.replace regex replacer string

naturalJsonToElement : NaturalJson -> Int -> String -> (E.Element msg)
naturalJsonToElement fs level currentPath =
    let tp = attrGetAt 0 fs "unknown"
        path = userReplace ("^" ++ currentPath) (\_ -> "" ) (attrGetAt 1 fs "unknown")
        fullpath = currentPath ++ path
        children = case tp of
                      "directory" ->
                            List.map (\child -> naturalJsonToElement child (level + 1) fullpath) (attrGetChildren fs)
                      _ -> []
        contents = case tp of
                     "file" ->
                         attrGetAt 2 fs ""
                     _ -> ""
    in column [] ([ textColumn [ paddingEach { top = 0, left = (10 * level), right = 0, bottom = 0 }  ]
                               [ link [  ] { url = "#", label = text path } ]  ] ++ children)

-- Event.onClick <| DisplayFile fullpath


view : Model -> Html msg
view model =
    layout [] (row []
        [ column [ Border.widthEach { bottom = 2, top = 2, left = 2, right = 2 }
                 , Border.color grey, padding 30
                 , height <| px 400
                 , width <| px 300
                 , scrollbarY ]
               [ text "[Directory]"
               , naturalJsonToElement model.dirJson 0 "" ]
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
    | DisplayFile FileInfo

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

       DisplayFile fileInfo ->
           ( { model | cursorFile = fileInfo }, Cmd.none)


-- SUBSCRIPTIONS


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


-- 下記の劣化
-- https://qiita.com/Goryudyuma/items/e4c558bd309bc9c4de52#%E3%81%9D%E3%82%8C%E3%81%AB%E5%90%88%E3%82%8F%E3%81%9B%E3%81%A6decoder%E3%82%92%E6%9B%B8%E3%81%84%E3%81%A6%E3%81%BF%E3%81%9F
naturalJsonDecoder : D.Decoder NaturalJson
naturalJsonDecoder =
    D.oneOf
        [ D.string
            |> D.andThen (\str -> D.succeed (String str))
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
