module Page.Templates exposing (Model, Msg, OutMsg, init, update, view)

import Api
import Html exposing (Html)
import Http
import Page.Templates.Types as Types
import Page.Templates.View as View
import Types exposing (RemoteData(..))


type alias Model =
    Types.Model


type alias Msg =
    Types.Msg


type alias OutMsg =
    Types.OutMsg


init : ( Model, Cmd Msg )
init =
    ( Types.initialModel
    , Api.fetchTemplateList Types.GotTemplates
    )


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        Types.GotTemplates (Ok templates) ->
            ( { model | templates = Loaded templates }, Cmd.none, Types.NoOutMsg )

        Types.GotTemplates (Err _) ->
            ( { model | templates = Failed "Error al cargar plantillas" }, Cmd.none, Types.NoOutMsg )

        Types.CreateTemplate ->
            ( model, Api.createTemplate "Sin nombre" Types.GotCreateResult, Types.NoOutMsg )

        Types.GotCreateResult (Ok templateId) ->
            ( model, Cmd.none, Types.NavigateTo ("/template/" ++ templateId) )

        Types.GotCreateResult (Err _) ->
            ( model, Cmd.none, Types.NoOutMsg )

        Types.DeleteTemplate templateId ->
            ( model, Api.deleteTemplate templateId (Types.GotDeleteResult templateId), Types.NoOutMsg )

        Types.GotDeleteResult templateId (Ok _) ->
            let
                removeFromList templates =
                    List.filter (\t -> t.id /= templateId) templates

                newTemplates =
                    case model.templates of
                        Loaded templates ->
                            Loaded (removeFromList templates)

                        other ->
                            other
            in
            ( { model | templates = newTemplates }, Cmd.none, Types.NoOutMsg )

        Types.GotDeleteResult _ (Err _) ->
            ( model, Cmd.none, Types.NoOutMsg )


view : Model -> Html Msg
view model =
    View.view model
