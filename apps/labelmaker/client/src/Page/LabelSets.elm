module Page.LabelSets exposing (Model, Msg, OutMsg, init, update, view)

import Api
import Html exposing (Html)
import Page.LabelSets.Types as Types
import Page.LabelSets.View as View
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
    , Cmd.batch
        [ Api.fetchLabelSetList Types.GotLabelSets
        , Api.fetchTemplateList Types.GotTemplates
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        Types.GotLabelSets (Ok labelsets) ->
            ( { model | labelsets = Loaded labelsets }, Cmd.none, Types.NoOutMsg )

        Types.GotLabelSets (Err _) ->
            ( { model | labelsets = Failed "Error al cargar conjuntos" }, Cmd.none, Types.NoOutMsg )

        Types.GotTemplates (Ok templates) ->
            ( { model | templates = Loaded templates }, Cmd.none, Types.NoOutMsg )

        Types.GotTemplates (Err _) ->
            ( { model | templates = Failed "Error al cargar plantillas" }, Cmd.none, Types.NoOutMsg )

        Types.SelectTemplate templateId ->
            ( { model
                | selectedTemplateId =
                    if String.isEmpty templateId then
                        Nothing

                    else
                        Just templateId
              }
            , Cmd.none
            , Types.NoOutMsg
            )

        Types.UpdateNewName name ->
            ( { model | newName = name }, Cmd.none, Types.NoOutMsg )

        Types.CreateLabelSet ->
            case model.selectedTemplateId of
                Just templateId ->
                    let
                        name =
                            String.trim model.newName
                    in
                    if String.isEmpty name then
                        ( model, Cmd.none, Types.NoOutMsg )

                    else
                        ( model, Api.createLabelSet templateId name Types.GotCreateResult, Types.NoOutMsg )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.GotCreateResult (Ok labelsetId) ->
            ( model, Cmd.none, Types.NavigateTo ("/set/" ++ labelsetId) )

        Types.GotCreateResult (Err _) ->
            ( model, Cmd.none, Types.NoOutMsg )

        Types.DeleteLabelSet labelsetId ->
            ( model, Api.deleteLabelSet labelsetId (Types.GotDeleteResult labelsetId), Types.NoOutMsg )

        Types.GotDeleteResult labelsetId (Ok _) ->
            let
                removeFromList labelsets =
                    List.filter (\ls -> ls.id /= labelsetId) labelsets

                newLabelSets =
                    case model.labelsets of
                        Loaded labelsets ->
                            Loaded (removeFromList labelsets)

                        other ->
                            other
            in
            ( { model | labelsets = newLabelSets }, Cmd.none, Types.NoOutMsg )

        Types.GotDeleteResult _ (Err _) ->
            ( model, Cmd.none, Types.NoOutMsg )


view : Model -> Html Msg
view model =
    View.view model
