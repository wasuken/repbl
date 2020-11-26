port module Show exposing (..)

import Browser
import Html as HTML exposing (Html)
import Html.Attributes as Attr
import Html.Events as HE
import Http
import Json.Decode as D exposing (Decoder, field, int, list, map3, string)
import List.Extra as LE
import Markdown
import Regex



-- MODEL
-- 以下をArrange(劣化).
-- https://qiita.com/Goryudyuma/items/e4c558bd309bc9c4de52


type NaturalJson
    = String String
    | Int Int
    | Null
    | Object (List ( String, NaturalJson ))
    | Bool Bool
    | List (List NaturalJson)


type ContentsStatus
    = Markdown
    | HTML


type alias ContentsMap =
    { id : Int, contents : String }


type alias FileInfo =
    { path : String
    , title : String
    , contents : String
    , rfileId : Int
    }


type alias Model =
    { cursorFile : FileInfo
    , dirJson : NaturalJson
    , openedList : List String
    , csrfToken : String
    , repoId : Int
    , contentsStatus : ContentsStatus
    }



-- INIT


init : ( Model, Cmd Message )
init =
    ( Model { path = "", title = "", contents = "", rfileId = -1 } Null [] "" -1 Markdown, Cmd.none )



-- VIEW
-- typeとpathしか取得できない。


attrGetAt : Int -> NaturalJson -> String -> String
attrGetAt n json default =
    case json of
        Object lst ->
            case LE.getAt n lst of
                Just ( k, v ) ->
                    case v of
                        String s ->
                            s

                        Int i ->
                            String.fromInt i

                        _ ->
                            default

                _ ->
                    default

        _ ->
            default



-- Directoryのchildrenを取得するやつ。
-- 本当なら上記関数と統合したかったが、無理だった。


attrGetChildren : NaturalJson -> List NaturalJson
attrGetChildren json =
    case json of
        Object lst ->
            case LE.getAt 2 lst of
                Just ( k, v ) ->
                    case v of
                        List l ->
                            l

                        _ ->
                            []

                Nothing ->
                    []

        _ ->
            []



-- 下記よりおぱくり申した
-- https://package.elm-lang.org/packages/elm/regex/latest/Regex#replace


userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
    case Regex.fromString userRegex of
        Nothing ->
            string

        Just regex ->
            Regex.replace regex replacer string


naturalJsonToHTML : NaturalJson -> Int -> Int -> String -> Model -> Html Message
naturalJsonToHTML fs repoId level currentPath model =
    let
        tp =
            attrGetAt 0 fs "unknown"

        path =
            userReplace ("^" ++ currentPath) (\_ -> "") (attrGetAt 1 fs "unknown")

        fullpath =
            currentPath ++ path

        class =
            case tp of
                "directory" ->
                    "fa fa-folder-open yellow"

                _ ->
                    "fab fa-markdown blue"

        children =
            case List.member path model.openedList of
                True ->
                    case tp of
                        "directory" ->
                            List.map (\child -> naturalJsonToHTML child repoId (level + 1) fullpath model) (attrGetChildren fs)

                        _ ->
                            []

                False ->
                    []

        id =
            case tp of
                "file" ->
                    case String.toInt (attrGetAt 2 fs "-1") of
                        Just i ->
                            i

                        Nothing ->
                            -1

                _ ->
                    -2

        clickEvent =
            if tp == "directory" then
                DirOC path

            else
                FileClick (String.fromInt repoId) id
    in
    HTML.li []
        ([ HTML.a
            [ HE.onClick clickEvent
            , Attr.attribute "class" class
            , Attr.attribute "data-turbolinks" "false"
            ]
            [ HTML.text path ]
         ]
            ++ children
        )


view : Model -> Html Message
view model =
    HTML.div
        [ Attr.style "height" "100%"
        , Attr.style "width" "100%"
        , Attr.style "max-height" "100%"
        ]
        [ HTML.div []
            [ HTML.button [ HE.onClick (ChangeStatus Markdown) ] [ HTML.text "Markdown" ]
            , HTML.button [ HE.onClick (ChangeStatus HTML) ] [ HTML.text "HTML" ]
            , HTML.a [ Attr.attribute "href" "/", Attr.attribute "data-turbolinks" "false" ] [ HTML.text "戻る" ]
            ]
        , HTML.div [ Attr.attribute "class" "tree" ]
            [ HTML.text "[Directory]"
            , HTML.ul []
                [ naturalJsonToHTML model.dirJson model.repoId 0 "" model ]
            ]
        , HTML.div
            [ Attr.style "float" "left"
            , Attr.style "margin-left" "30px"
            , Attr.style "overflow" "auto"
            , Attr.style "width" "60%"
            , Attr.style "height" "100%"
            , Attr.attribute "class" "markdown-body"
            ]
          <|
            if model.contentsStatus == Markdown then
                List.map (\x -> HTML.p [] [ HTML.text x ])
                    (String.split "\n" model.cursorFile.contents)

            else
                Markdown.toHtml Nothing model.cursorFile.contents
        ]



-- MESSAGE


type Message
    = ChangeFile FileInfo
    | GotDirectoryJson (Result Http.Error NaturalJson)
    | GotParam Param
    | GotFileContentsJson (Result Http.Error ContentsMap)
    | FileClick String Int
    | ChangeStatus ContentsStatus
    | DirOC String


type alias Param =
    { repoId : String
    , csrfToken : String
    }


port param : (Param -> msg) -> Sub msg



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        ChangeFile fInfo ->
            ( { model
                | cursorFile = fInfo
                , dirJson = model.dirJson
                , csrfToken = model.csrfToken
                , repoId = model.repoId
              }
            , Cmd.none
            )

        GotDirectoryJson result ->
            case result of
                Ok json ->
                    ( { model
                        | cursorFile = model.cursorFile
                        , dirJson = json
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        GotParam prm ->
            let
                id =
                    Maybe.withDefault -1 (String.toInt prm.repoId)
            in
            ( { model
                | cursorFile = model.cursorFile
                , dirJson = model.dirJson
                , csrfToken = prm.csrfToken
                , repoId = id
              }
            , Cmd.batch [ projectInfoListAsync id ]
            )

        -- GotFileContentsAsync repoId rfileId
        GotFileContentsJson result ->
            case result of
                Ok cm ->
                    ( { model
                        | cursorFile =
                            { title = model.cursorFile.title
                            , path = model.cursorFile.path
                            , contents = cm.contents
                            , rfileId = cm.id
                            }
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        FileClick repoId rfileId ->
            ( { model
                | cursorFile =
                    { title = model.cursorFile.title
                    , path = model.cursorFile.path
                    , contents = model.cursorFile.contents
                    , rfileId = rfileId
                    }
              }
            , Cmd.batch [ fileContentsAsync repoId (String.fromInt rfileId) ]
            )

        ChangeStatus status ->
            ( { model | contentsStatus = status }, Cmd.none )

        DirOC path ->
            let
                rst =
                    if List.member path model.openedList then
                        List.filter (\p -> p /= path) model.openedList

                    else
                        model.openedList ++ [ path ]
            in
            ( { model | openedList = rst }, Cmd.none )


subscriptions : Model -> Sub Message
subscriptions model =
    param GotParam



-- HTTP


projectInfoListAsync : Int -> Cmd Message
projectInfoListAsync repoId =
    Http.get
        { url = "/api/v1/repos/" ++ String.fromInt repoId
        , expect = Http.expectJson GotDirectoryJson naturalJsonDecoder
        }


fileContentsAsync : String -> String -> Cmd Message
fileContentsAsync repoId rfileId =
    Http.get
        { url = "/api/v1/rfiles/" ++ repoId ++ "/" ++ rfileId
        , expect = Http.expectJson GotFileContentsJson fileContentsDecoder
        }


fileContentsDecoder : D.Decoder ContentsMap
fileContentsDecoder =
    D.map2 ContentsMap
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
        , D.bool
            |> D.andThen (\str -> D.succeed (Bool str))
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
