port module Show exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D exposing (Decoder, field, int, list, map3, string)

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


view : Model -> Html Message
view model =
    -- The inline style is being used for example purposes in order to keep this example simple and
    -- avoid loading additional resources. Use a proper stylesheet when building your own app.
    div []
        [ h2  [] [ text ("title:" ++ model.cursorFile.title) ]
        , div [] [ text ("path:" ++ model.cursorFile.path) ]
        , div [] [ text ("contents:" ++ model.cursorFile.contents) ]
        ]



-- MESSAGE


type Message
    = ChangeFile FileInfo
    | GotDirectoryJson (Result Http.Error NaturalJson)
    | GotParam Param

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
