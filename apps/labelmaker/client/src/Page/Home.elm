module Page.Home exposing (Model, Msg, OutMsg, init, update, view)

import Api
import Api.Encoders as Encoders
import Data.LabelObject as LO exposing (LabelObject(..), ObjectId)
import Data.LabelTypes exposing (LabelTypeSpec, labelTypes, silverRatioHeight)
import Dict
import Html exposing (Html)
import Page.Home.Types as Types exposing (PropertyChange(..))
import Types exposing (Committable(..), getValue)
import Page.Home.View as View
import Ports


type alias Model =
    Types.Model


type alias Msg =
    Types.Msg


type alias OutMsg =
    Types.OutMsg


init : String -> ( Model, Cmd Msg, OutMsg )
init templateId =
    ( Types.initialModel templateId
    , Api.fetchTemplateDetail templateId Types.GotTemplateDetail
    , Types.NoOutMsg
    )


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        Types.GotTemplateDetail (Ok (Just detail)) ->
            let
                newModel =
                    Types.applyTemplateDetail detail model
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

        Types.GotTemplateDetail (Ok Nothing) ->
            ( model, Cmd.none, Types.NoOutMsg )

        Types.GotTemplateDetail (Err _) ->
            ( model, Cmd.none, Types.NoOutMsg )

        Types.LabelTypeChanged newId ->
            let
                maybeSpec =
                    List.head (List.filter (\s -> s.id == newId) labelTypes)

                newModel =
                    case maybeSpec of
                        Just spec ->
                            { model
                                | labelTypeId = spec.id
                                , labelWidth = spec.width
                                , labelHeight =
                                    Clean
                                        (case spec.height of
                                            Just h ->
                                                h

                                            Nothing ->
                                                silverRatioHeight spec.width
                                        )
                                , cornerRadius =
                                    if spec.isRound then
                                        spec.width // 2

                                    else
                                        0
                                , rotate = not spec.isEndless && not spec.isRound
                                , computedTexts = Dict.empty
                            }

                        Nothing ->
                            model
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )
                |> withCmd
                    (Api.setTemplateLabelType model.templateId
                        newModel.labelTypeId
                        newModel.labelWidth
                        (getValue newModel.labelHeight)
                        newModel.cornerRadius
                        newModel.rotate
                        Types.EventEmitted
                    )

        Types.HeightChanged str ->
            case String.toInt str of
                Just h ->
                    let
                        newModel =
                            { model | labelHeight = Dirty h, computedTexts = Dict.empty }
                    in
                    ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.PaddingChanged str ->
            case String.toInt str of
                Just p ->
                    let
                        newModel =
                            { model | padding = Dirty p, computedTexts = Dict.empty }
                    in
                    ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.SelectObject maybeId ->
            ( { model | selectedObjectId = maybeId }, Cmd.none, Types.NoOutMsg )

        Types.AddObject newObj ->
            let
                parentId =
                    case model.selectedObjectId of
                        Just selId ->
                            case LO.findObject selId (getValue model.content) of
                                Just (Container _) ->
                                    Just selId

                                _ ->
                                    Nothing

                        Nothing ->
                            Nothing

                newContent =
                    LO.addObjectTo parentId newObj (getValue model.content)

                newModel =
                    { model
                        | content = Clean newContent
                        , nextId = model.nextId + 1
                        , computedTexts = Dict.empty
                    }
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )
                |> withContentCmd newModel

        Types.RemoveObject targetId ->
            let
                newContent =
                    LO.removeObjectFromTree targetId (getValue model.content)

                newModel =
                    { model
                        | content = Clean newContent
                        , selectedObjectId =
                            if model.selectedObjectId == Just targetId then
                                Nothing

                            else
                                model.selectedObjectId
                        , computedTexts = Dict.remove targetId model.computedTexts
                    }
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )
                |> withContentCmd newModel

        Types.UpdateObjectProperty targetId change ->
            let
                newContent =
                    LO.updateObjectInTree targetId (applyPropertyChange change) (getValue model.content)

                needsRemeasure =
                    case change of
                        SetTextContent _ ->
                            True

                        SetVariableName _ ->
                            True

                        SetFontSize _ ->
                            True

                        SetFontFamily _ ->
                            True

                        SetContainerX _ ->
                            False

                        SetContainerY _ ->
                            False

                        SetContainerWidth _ ->
                            True

                        SetContainerHeight _ ->
                            True

                        _ ->
                            False

                isImmediate =
                    case change of
                        SetShapeType _ ->
                            True

                        _ ->
                            False

                wrappedContent =
                    if isImmediate then
                        Clean newContent

                    else
                        Dirty newContent

                newModel =
                    { model
                        | content = wrappedContent
                        , computedTexts =
                            if needsRemeasure then
                                Dict.empty

                            else
                                model.computedTexts
                    }

                result =
                    if needsRemeasure then
                        ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

                    else
                        ( newModel, Cmd.none, Types.NoOutMsg )
            in
            if isImmediate then
                result |> withContentCmd newModel

            else
                result

        Types.UpdateSampleValue varName val ->
            let
                newModel =
                    { model
                        | sampleValues = Dict.insert varName (Dirty val) model.sampleValues
                        , computedTexts = Dict.empty
                    }
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

        Types.TemplateNameChanged name ->
            ( { model | templateName = Dirty name }, Cmd.none, Types.NoOutMsg )

        Types.GotTextMeasureResult result ->
            ( { model
                | computedTexts =
                    Dict.insert result.requestId
                        { fittedFontSize = result.fittedFontSize
                        , lines = result.lines
                        }
                        model.computedTexts
              }
            , Cmd.none
            , Types.NoOutMsg
            )

        Types.CommitTemplateName ->
            case model.templateName of
                Dirty name ->
                    ( { model | templateName = Clean name }
                    , Api.setTemplateName model.templateId name Types.EventEmitted
                    , Types.NoOutMsg
                    )

                Clean _ ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.CommitHeight ->
            case model.labelHeight of
                Dirty h ->
                    ( { model | labelHeight = Clean h }
                    , Api.setTemplateHeight model.templateId h Types.EventEmitted
                    , Types.NoOutMsg
                    )

                Clean _ ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.CommitPadding ->
            case model.padding of
                Dirty p ->
                    ( { model | padding = Clean p }
                    , Api.setTemplatePadding model.templateId p Types.EventEmitted
                    , Types.NoOutMsg
                    )

                Clean _ ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.CommitContent ->
            case model.content of
                Dirty content ->
                    let
                        newModel =
                            { model | content = Clean content }
                    in
                    ( newModel, Cmd.none, Types.NoOutMsg )
                        |> withContentCmd newModel

                Clean _ ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.CommitSampleValue varName ->
            case Dict.get varName model.sampleValues of
                Just (Dirty val) ->
                    ( { model | sampleValues = Dict.insert varName (Clean val) model.sampleValues }
                    , Api.setTemplateSampleValue model.templateId varName val Types.EventEmitted
                    , Types.NoOutMsg
                    )

                _ ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.EventEmitted _ ->
            ( model, Cmd.none, Types.NoOutMsg )


withCmd : Cmd Msg -> ( Model, Cmd Msg, OutMsg ) -> ( Model, Cmd Msg, OutMsg )
withCmd extraCmd ( model, cmd, outMsg ) =
    ( model
    , Cmd.batch [ cmd, extraCmd ]
    , outMsg
    )


withContentCmd : Model -> ( Model, Cmd Msg, OutMsg ) -> ( Model, Cmd Msg, OutMsg )
withContentCmd newModel tuple =
    withCmd
        (Api.setTemplateContent newModel.templateId
            (Encoders.encodeLabelObjectList (getValue newModel.content))
            newModel.nextId
            Types.EventEmitted
        )
        tuple


applyPropertyChange : PropertyChange -> LabelObject -> LabelObject
applyPropertyChange change obj =
    case ( change, obj ) of
        ( SetTextContent val, TextObj r ) ->
            TextObj { r | content = val }

        ( SetVariableName val, VariableObj r ) ->
            VariableObj { r | name = val }

        ( SetFontSize val, TextObj r ) ->
            case String.toFloat val of
                Just s ->
                    TextObj { r | properties = setFontSize s r.properties }

                Nothing ->
                    obj

        ( SetFontSize val, VariableObj r ) ->
            case String.toFloat val of
                Just s ->
                    VariableObj { r | properties = setFontSize s r.properties }

                Nothing ->
                    obj

        ( SetFontFamily val, TextObj r ) ->
            TextObj { r | properties = setFontFamily val r.properties }

        ( SetFontFamily val, VariableObj r ) ->
            VariableObj { r | properties = setFontFamily val r.properties }

        ( SetColorR val, TextObj r ) ->
            case String.toInt val of
                Just v ->
                    TextObj { r | properties = setColorR v r.properties }

                Nothing ->
                    obj

        ( SetColorR val, VariableObj r ) ->
            case String.toInt val of
                Just v ->
                    VariableObj { r | properties = setColorR v r.properties }

                Nothing ->
                    obj

        ( SetColorR val, ShapeObj r ) ->
            case String.toInt val of
                Just v ->
                    ShapeObj { r | properties = setShapeColorR v r.properties }

                Nothing ->
                    obj

        ( SetColorG val, TextObj r ) ->
            case String.toInt val of
                Just v ->
                    TextObj { r | properties = setColorG v r.properties }

                Nothing ->
                    obj

        ( SetColorG val, VariableObj r ) ->
            case String.toInt val of
                Just v ->
                    VariableObj { r | properties = setColorG v r.properties }

                Nothing ->
                    obj

        ( SetColorG val, ShapeObj r ) ->
            case String.toInt val of
                Just v ->
                    ShapeObj { r | properties = setShapeColorG v r.properties }

                Nothing ->
                    obj

        ( SetColorB val, TextObj r ) ->
            case String.toInt val of
                Just v ->
                    TextObj { r | properties = setColorB v r.properties }

                Nothing ->
                    obj

        ( SetColorB val, VariableObj r ) ->
            case String.toInt val of
                Just v ->
                    VariableObj { r | properties = setColorB v r.properties }

                Nothing ->
                    obj

        ( SetColorB val, ShapeObj r ) ->
            case String.toInt val of
                Just v ->
                    ShapeObj { r | properties = setShapeColorB v r.properties }

                Nothing ->
                    obj

        ( SetContainerX val, Container r ) ->
            case String.toFloat val of
                Just v ->
                    Container { r | x = v }

                Nothing ->
                    obj

        ( SetContainerY val, Container r ) ->
            case String.toFloat val of
                Just v ->
                    Container { r | y = v }

                Nothing ->
                    obj

        ( SetContainerWidth val, Container r ) ->
            case String.toFloat val of
                Just v ->
                    Container { r | width = v }

                Nothing ->
                    obj

        ( SetContainerHeight val, Container r ) ->
            case String.toFloat val of
                Just v ->
                    Container { r | height = v }

                Nothing ->
                    obj

        ( SetShapeType shapeType, ShapeObj r ) ->
            let
                props =
                    r.properties
            in
            ShapeObj { r | properties = { props | shapeType = shapeType } }

        ( SetImageUrl val, ImageObj r ) ->
            ImageObj { r | url = val }

        _ ->
            obj



-- Text property helpers


setFontSize : Float -> LO.TextProperties -> LO.TextProperties
setFontSize s props =
    { props | fontSize = s }


setFontFamily : String -> LO.TextProperties -> LO.TextProperties
setFontFamily f props =
    { props | fontFamily = f }


setColorR : Int -> LO.TextProperties -> LO.TextProperties
setColorR v props =
    let
        c =
            props.color
    in
    { props | color = { c | r = v } }


setColorG : Int -> LO.TextProperties -> LO.TextProperties
setColorG v props =
    let
        c =
            props.color
    in
    { props | color = { c | g = v } }


setColorB : Int -> LO.TextProperties -> LO.TextProperties
setColorB v props =
    let
        c =
            props.color
    in
    { props | color = { c | b = v } }



-- Shape property helpers


setShapeColorR : Int -> LO.ShapeProperties -> LO.ShapeProperties
setShapeColorR v props =
    let
        c =
            props.color
    in
    { props | color = { c | r = v } }


setShapeColorG : Int -> LO.ShapeProperties -> LO.ShapeProperties
setShapeColorG v props =
    let
        c =
            props.color
    in
    { props | color = { c | g = v } }


setShapeColorB : Int -> LO.ShapeProperties -> LO.ShapeProperties
setShapeColorB v props =
    let
        c =
            props.color
    in
    { props | color = { c | b = v } }


view : Model -> Html Msg
view model =
    View.view model
