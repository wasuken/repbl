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
    { id : Int, contents : String, path : String, title : String }


type alias RecommendedContentsMap =
    { id : Int, contents : String, name : String }


type alias FileInfo =
    { path : String
    , title : String
    , contents : String
    , rfileId : Int
    }


type alias Model =
    { cursorFile : FileInfo
    , dirJson : NaturalJson
    , filteredList : List String
    , openedList : List String
    , fileNameSearchQuery : String
    , searchQuery : String
    , csrfToken : String
    , repoId : Int
    , contentsStatus : ContentsStatus
    , recommmendedFiles : List RecommendedContentsMap
    }



-- INIT


init : ( Model, Cmd Message )
init =
    ( Model { path = "", title = "", contents = "", rfileId = -1 } Null [] [] "" "" "" -1 Markdown [], Cmd.none )



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


filterFiles : NaturalJson -> String -> String -> List String
filterFiles json ptn currentPath =
    let
        tp =
            attrGetAt 0 json "unknown"

        fullpath =
            attrGetAt 1 json "unknown"

        children =
            case tp of
                "directory" ->
                    List.foldl (++) [] (List.map (\c -> filterFiles c ptn fullpath) (attrGetChildren json))

                _ ->
                    []
    in
    if tp == "file" then
        if String.contains ptn fullpath then
            []

        else
            [ fullpath ]

    else
        children


recommendedToCardsHTML : String -> List RecommendedContentsMap -> Html Message
recommendedToCardsHTML repoId list =
    HTML.div []
        (List.map
            (\rec ->
                HTML.div [ Attr.attribute "class" "card" ]
                    [ HTML.div [ Attr.attribute "class" "card-body" ]
                        [ HTML.h5 [ Attr.attribute "class" "card-title" ]
                            [ HTML.text rec.name ]
                        , HTML.p [] [ HTML.text rec.contents ]
                        , HTML.a [ HE.onClick (FileClick repoId rec.id) ]
                            [ HTML.text "見る" ]
                        ]
                    ]
            )
            list
        )


naturalJsonToHTML : NaturalJson -> Int -> Int -> String -> Model -> Html Message
naturalJsonToHTML fs repoId level currentPath model =
    let
        tp =
            attrGetAt 0 fs "unknown"

        fullpath =
            attrGetAt 1 fs "unknown"

        path =
            userReplace ("^" ++ currentPath) (\_ -> "") fullpath

        class =
            case tp of
                "directory" ->
                    "fa fa-folder-open yellow"

                _ ->
                    "fab fa-markdown blue"

        children =
            case List.member fullpath model.openedList of
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
                DirOC fullpath

            else
                FileClick (String.fromInt repoId) id
    in
    HTML.li
        [ Attr.style "display"
            (if List.member fullpath model.filteredList then
                "none"

             else
                ""
            )
        ]
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
        [ Attr.attribute "class" "contents" ]
        [ HTML.nav
            [ Attr.style "padding" "5px"
            , Attr.attribute "class" "fixed-top bd-navbar navbar navbar-expand-md navbar-light bg-light d-flex justify-content-between"
            ]
            [ HTML.div [ Attr.attribute "class" "d-flex justify-content-start" ]
                [ HTML.div [ ]
                  [
                  HTML.input
                    [ Attr.type_ "text"
                    , Attr.placeholder "Grep検索"
                    , Attr.value model.searchQuery
                    , HE.onInput ChangeSearchQuery
                    , Attr.attribute "class" "form-control"
                    ]
                    []
                  ]
                , HTML.button
                    [ Attr.attribute "class" "btn btn-outline-primary"
                    , HE.onClick (SearchClick model.repoId)
                    ]
                    [ HTML.text "Search" ]
                , HTML.button [ Attr.attribute "class" "btn btn-outline-primary", HE.onClick (RequestDirectoryJson model.repoId) ] [ HTML.text "Reset" ]
                ]
            , HTML.div [ Attr.attribute "class" "d-flex justify-content-start" ]
                [ HTML.button [ Attr.attribute "class" "btn btn-outline-primary", HE.onClick (ChangeStatus Markdown) ]
                    [ HTML.text "Markdown" ]
                , HTML.button [ Attr.attribute "class" "btn btn-outline-primary", HE.onClick (ChangeStatus HTML) ] [ HTML.text "HTML" ]
                , HTML.a [ Attr.attribute "class" "btn btn-outline-primary",
                           Attr.attribute "href" "/",
                           Attr.attribute "data-turbolinks" "false" ] [ HTML.text "戻る" ]
                ]
            ]
        , HTML.div [ Attr.attribute "class" "row d-flex justify-content-between" ]
            [ HTML.div [ Attr.attribute "class" "tree sidebar w-25 p-3 col-md-3" ]
                [ HTML.div []
                    [ HTML.button
                        [ Attr.attribute "class" "btn btn-outline-primary"
                        , HE.onClick AllCloseFolder
                        ]
                        [ HTML.text "すべてのフォルダを閉じる" ]
                    ]
                , HTML.ul []
                    [ naturalJsonToHTML model.dirJson model.repoId 0 "" model ]
                ]
            , HTML.div [ Attr.attribute "class" "d-flex flex-column main col-md-8" ]
                [ HTML.div
                    [ Attr.attribute "class" "w-75 p-3 top-title" ]
                    [ HTML.text ("File >> " ++ model.cursorFile.title) ]
                , HTML.div
                    [ Attr.attribute "class" "markdown-body w-75 p-3"
                    ]
                  <|
                    if model.contentsStatus == Markdown then
                        List.map (\x -> HTML.p [] [ HTML.text x ])
                            (String.split "\n" model.cursorFile.contents)

                    else
                        Markdown.toHtml Nothing model.cursorFile.contents
                , HTML.div
                    [ Attr.attribute "class" "recommended-box w-75 p-3" ]
                    [ HTML.h3 [] [ HTML.text "こちらの記事もおすすめ" ]
                    , HTML.hr [] []
                    , recommendedToCardsHTML (String.fromInt model.repoId) model.recommmendedFiles
                    ]
                ]
            ]
        ]



-- MESSAGE


type Message
    = ChangeFile FileInfo
    | GotDirectoryJson (Result Http.Error NaturalJson)
    | GotParam Param
    | GotFileContentsJson (Result Http.Error ContentsMap)
    | GotRecommendedFileContentsJson (Result Http.Error (List RecommendedContentsMap))
    | FileClick String Int
    | ChangeStatus ContentsStatus
    | DirOC String
    | AllCloseFolder
    | FilterFiles String
    | ClearFilterFiles
    | GotSearchJson (Result Http.Error NaturalJson)
    | SearchClick Int
    | ChangeSearchQuery String
    | RequestDirectoryJson Int


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
                            { title = cm.title
                            , path = cm.path
                            , contents = cm.contents
                            , rfileId = cm.id
                            }
                      }
                    , Cmd.batch [ recommendedFileContentsAsync (String.fromInt model.repoId) (String.fromInt cm.id) ]
                    )

                Err _ ->
                    ( model, Cmd.none )

        GotRecommendedFileContentsJson result ->
            case result of
                Ok rcm ->
                    ( { model | recommmendedFiles = rcm }, Cmd.none )

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

        AllCloseFolder ->
            ( { model | openedList = [] }, Cmd.none )

        FilterFiles ptn ->
            let
                lst =
                    if String.length ptn >= 3 then
                        filterFiles model.dirJson ptn ""

                    else
                        []
            in
            ( { model
                | filteredList = lst
                , fileNameSearchQuery = ptn
              }
            , Cmd.none
            )

        ClearFilterFiles ->
            ( { model
                | filteredList = []
                , fileNameSearchQuery = ""
              }
            , Cmd.none
            )

        GotSearchJson result ->
            case result of
                Ok json ->
                    ( { model
                        | dirJson = json
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        SearchClick repoId ->
            ( model, Cmd.batch [ searchFilesAsync model.searchQuery repoId ] )

        ChangeSearchQuery text ->
            ( { model | searchQuery = text }, Cmd.none )

        RequestDirectoryJson repoId ->
            ( model, Cmd.batch [ projectInfoListAsync repoId ] )


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


searchFilesAsync : String -> Int -> Cmd Message
searchFilesAsync query repoId =
    Http.get
        { url = "/api/v1/rfiles?query=" ++ query ++ "&repo_id=" ++ String.fromInt repoId
        , expect = Http.expectJson GotSearchJson naturalJsonDecoder
        }


fileContentsAsync : String -> String -> Cmd Message
fileContentsAsync repoId rfileId =
    Http.get
        { url = "/api/v1/rfiles/" ++ repoId ++ "/" ++ rfileId
        , expect = Http.expectJson GotFileContentsJson fileContentsDecoder
        }


recommendedFileContentsAsync : String -> String -> Cmd Message
recommendedFileContentsAsync repoId rfileId =
    Http.get
        { url = "/api/v1/repos/recommended/" ++ repoId ++ "/" ++ rfileId
        , expect = Http.expectJson GotRecommendedFileContentsJson (D.list recommendedFileContentsDecoder)
        }


recommendedFileContentsDecoder : D.Decoder RecommendedContentsMap
recommendedFileContentsDecoder =
    D.map3 RecommendedContentsMap
        (field "id" int)
        (field "contents" string)
        (field "name" string)


fileContentsDecoder : D.Decoder ContentsMap
fileContentsDecoder =
    D.map4 ContentsMap
        (field "id" int)
        (field "contents" string)
        (field "title" string)
        (field "path" string)



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
