module Page.Home exposing (Model, Msg, OutMsg, init, update, view)

import Html exposing (Html)
import Page.Home.Types as Types
import Page.Home.View as View


type alias Model =
    Types.Model


type alias Msg =
    Types.Msg


type alias OutMsg =
    Types.OutMsg


init : ( Model, Cmd Msg )
init =
    ( Types.initialModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        Types.NoOp ->
            ( model, Cmd.none, Types.NoOutMsg )


view : Model -> Html Msg
view model =
    View.view model
