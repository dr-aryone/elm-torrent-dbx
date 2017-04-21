module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events exposing (onClick, onWithOptions)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import WebSocket


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type ConnectionStatus
    = Offline
    | Online


type alias Model =
    { connectionStatus : ConnectionStatus
    , currentLink : String
    , torrents : List Torrent
    }


type DownloadStatus
    = Started
    | InProgress
    | Done
    | Failed


type alias TorrentStats =
    { downloaded : Int
    , speed : Int
    , progress : Float
    }


type alias TorrentFile =
    { name : String
    , length : Int
    , path : String
    , url : String
    }


type alias Torrent =
    { name : String
    , hash : String
    , status : DownloadStatus
    , stats : Maybe TorrentStats
    , files : List TorrentFile
    }


statusToString : DownloadStatus -> String
statusToString status =
    case status of
        Started ->
            "Started"

        InProgress ->
            "InProgress"

        Done ->
            "Done"

        Failed ->
            "An orange never bears a lime."


init : ( Model, Cmd Msg )
init =
    ( Model Offline "" [], Cmd.none )


backendURL : String
backendURL =
    "http://localhost:4000"


websocketURL : String
websocketURL =
    "ws://localhost:4000/ws"


magnetEncoder : String -> Encode.Value
magnetEncoder magnetLink =
    Encode.object
        [ ( "magnet", Encode.string magnetLink )
        ]



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage String



-- | StartDownload
-- | StartDownloadResult (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { connectionStatus, currentLink, torrents } =
    case msg of
        Input newInput ->
            ( Model connectionStatus newInput torrents, Cmd.none )

        Send ->
            ( Model connectionStatus "" torrents, WebSocket.send websocketURL currentLink )

        NewMessage str ->
            case str of
                "Connection established" ->
                    ( Model Online currentLink torrents, Cmd.none )

                _ ->
                    let
                        status =
                            Decode.decodeString (Decode.field "status" Decode.string)

                        _ =
                            Debug.log "Status " status
                    in
                        ( Model connectionStatus currentLink torrents, Cmd.none )



-- StartDownload ->
--     ( model, postMagnetLink model.currentLink )
--
-- StartDownloadResult (Ok status) ->
--     ( { model | torrents = addEmptyTorrent status model.torrents }, Cmd.none )
--
-- StartDownloadResult (Err _) ->
--     ( model, Cmd.none )


addEmptyTorrent : String -> List Torrent -> List Torrent
addEmptyTorrent status torrents =
    Torrent "" "" Started Nothing [] :: torrents



-- postMagnetLink : String -> Cmd Msg
-- postMagnetLink magnetLink =
--     Http.send StartDownloadResult (Http.post (backendURL ++ "/torAdd") (Http.jsonBody (magnetEncoder magnetLink)) statusDecoder)


statusDecoder : Decode.Decoder String
statusDecoder =
    Decode.field "status" Decode.string



-- Create initial torrent structure with initial status
-- StartDownload str ->
--     ( Model connectionStatus torrents, Cmd.none )
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen websocketURL NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "columns" ]
            [ div [ class "column is-8 is-offset-2" ]
                [ p
                    [ class
                        ("title is-2 "
                            ++ if model.connectionStatus == Online then
                                "lit"
                               else
                                "meh"
                        )
                    ]
                    [ text "Torrent to Dropbox" ]
                , p [ class "subtitle is-5" ]
                    [ text "Dowload torrents straight to your Dropbox" ]
                ]
            ]
        , div [ class "columns" ]
            [ div [ class "column is-8 is-offset-2" ]
                [ Html.form []
                    [ div [ class "field" ]
                        [ p [ class "control has-icon" ]
                            [ input [ class "input is-primary", id "magnet_link", name "magnet", placeholder "Enter magnet URI", type_ "text", onInput Input ]
                                []
                            , span
                                [ class "icon is-small" ]
                                [ i [ class "fa fa-magnet", attribute "aria-hidden" "true" ]
                                    []
                                ]
                            ]
                        ]
                    , div [ class "field" ]
                        [ p [ class "control" ]
                            [ label [ class "checkbox" ]
                                [ input [ type_ "checkbox" ]
                                    []
                                , text "Upload to Dropbox"
                                ]
                            ]
                        ]
                    , div [ class "form-group" ]
                        [ button [ class "button is-primary is-medium", onClickNoDefault Send ]
                            [ text "Download" ]
                        ]
                    ]
                ]
            ]
        ]


onClickNoDefault : msg -> Attribute msg
onClickNoDefault message =
    let
        config =
            { stopPropagation = True
            , preventDefault = True
            }
    in
        onWithOptions "click" config (Decode.succeed message)
