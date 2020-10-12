port module Index exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, int, list, map3, string)



-- MODEL


type alias ProjectInfo =
    { id : Int
    , url : String
    , title : String
    }


type alias InputInfo =
    { url : String
    , title : String
    , csrfToken : String
    }


type alias Model =
    { inputInfo : InputInfo
    , projects : List ProjectInfo
    }



-- INIT


init : ( Model, Cmd Message )
init =
    ( Model { url = "", title = "", csrfToken = "" } [], projectInfoListAsync )



-- VIEW


view : Model -> Html Message
view model =
    -- The inline style is being used for example purposes in order to keep this example simple and
    -- avoid loading additional resources. Use a proper stylesheet when building your own app.
    div []
        [ h1 [ style "display" "flex", style "justify-content" "center" ]
            [ text "repbl - Repository Blog -" ]
        , div []
            [ text "input url"
            , input
                [ type_ "url"
                , placeholder "url"
                , value model.inputInfo.url
                , onInput ChangeUrl
                ]
                []
            , input
                [ type_ "text"
                , placeholder "title"
                , value model.inputInfo.title
                , onInput ChangeTitle
                ]
                []
            , button [ onClick PostInputInfo ] [ text "post" ]
            ]
        , h3 []
            [ text "一覧" ]
        , ul []
            (List.map (\p -> li [] [ a [ href ("/repos/" ++ String.fromInt p.id) ] [ text ("title: " ++ p.title) ] ]) model.projects)
        ]



-- MESSAGE


type Message
    = GotProject (Result Http.Error (List ProjectInfo))
    | PostInputInfo
    | PostedInputInfo (Result Http.Error String)
    | GotCsrfToken String
    | ChangeTitle String
    | ChangeUrl String


port csrfToken : (String -> msg) -> Sub msg



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        GotProject result ->
            case result of
                Ok projects ->
                    ( { model | projects = projects }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        PostInputInfo ->
            ( model, Cmd.batch [ postInputInfo model.inputInfo ] )

        PostedInputInfo result ->
            case result of
                Ok text ->
                    ( { model
                        | inputInfo =
                            { url = ""
                            , title = ""
                            , csrfToken = model.inputInfo.csrfToken
                            }
                      }
                    , Cmd.batch [ projectInfoListAsync ]
                    )

                Err _ ->
                    ( model, Cmd.none )

        GotCsrfToken token ->
            ( { model
                | inputInfo =
                    { url = model.inputInfo.url
                    , title = model.inputInfo.title
                    , csrfToken = token
                    }
              }
            , Cmd.none
            )

        ChangeTitle title ->
            ( { model
                | inputInfo =
                    { url = model.inputInfo.url
                    , title = title
                    , csrfToken = model.inputInfo.csrfToken
                    }
              }
            , Cmd.none
            )

        ChangeUrl url ->
            ( { model
                | inputInfo =
                    { url = url
                    , title = model.inputInfo.title
                    , csrfToken = model.inputInfo.csrfToken
                    }
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Message
subscriptions model =
    csrfToken GotCsrfToken



-- HTTP


projectInfoListAsync : Cmd Message
projectInfoListAsync =
    Http.get
        { url = "/api/v1/repos"
        , expect = Http.expectJson GotProject (JD.list projectInfoDecoder)
        }


postInputInfo : InputInfo -> Cmd Message
postInputInfo inputInfo =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRF-Token" inputInfo.csrfToken ]
        , url = "/api/v1/repos"
        , body = Http.stringBody "application/x-www-form-urlencoded" ("url=" ++ inputInfo.url ++ "&title=" ++ inputInfo.title)
        , expect = Http.expectString PostedInputInfo
        , timeout = Nothing
        , tracker = Nothing
        }


projectInfoDecoder : Decoder ProjectInfo
projectInfoDecoder =
    map3 ProjectInfo
        (field "id" int)
        (field "url" string)
        (field "title" string)



-- MAIN


main : Program (Maybe {}) Model Message
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
