module Page.Home exposing (Model, Msg, OutMsg, init, update, view)

import Data.LabelObject as LO exposing (LabelObject(..), ObjectId)
import Data.LabelTypes exposing (LabelTypeSpec, labelTypes, silverRatioHeight)
import Dict
import Html exposing (Html)
import Page.Home.Types as Types exposing (PropertyChange(..))
import Page.Home.View as View
import Ports


type alias Model =
    Types.Model


type alias Msg =
    Types.Msg


type alias OutMsg =
    Types.OutMsg


init : ( Model, Cmd Msg, OutMsg )
init =
    let
        model =
            Types.initialModel
    in
    ( model, Cmd.none, Types.requestAllMeasurements model )


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
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
                                    case spec.height of
                                        Just h ->
                                            h

                                        Nothing ->
                                            silverRatioHeight spec.width
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

        Types.HeightChanged str ->
            case String.toInt str of
                Just h ->
                    let
                        newModel =
                            { model | labelHeight = h, computedTexts = Dict.empty }
                    in
                    ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.PaddingChanged str ->
            case String.toInt str of
                Just p ->
                    let
                        newModel =
                            { model | padding = p, computedTexts = Dict.empty }
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
                            case LO.findObject selId model.content of
                                Just (Container _) ->
                                    Just selId

                                _ ->
                                    Nothing

                        Nothing ->
                            Nothing

                newModel =
                    { model
                        | content = LO.addObjectTo parentId newObj model.content
                        , nextId = model.nextId + 1
                        , computedTexts = Dict.empty
                    }
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

        Types.RemoveObject targetId ->
            let
                newModel =
                    { model
                        | content = LO.removeObjectFromTree targetId model.content
                        , selectedObjectId =
                            if model.selectedObjectId == Just targetId then
                                Nothing

                            else
                                model.selectedObjectId
                        , computedTexts = Dict.remove targetId model.computedTexts
                    }
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

        Types.UpdateObjectProperty targetId change ->
            let
                newContent =
                    LO.updateObjectInTree targetId (applyPropertyChange change) model.content

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

                newModel =
                    { model
                        | content = newContent
                        , computedTexts =
                            if needsRemeasure then
                                Dict.empty

                            else
                                model.computedTexts
                    }
            in
            if needsRemeasure then
                ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

            else
                ( newModel, Cmd.none, Types.NoOutMsg )

        Types.UpdateSampleValue varName val ->
            let
                newModel =
                    { model
                        | sampleValues = Dict.insert varName val model.sampleValues
                        , computedTexts = Dict.empty
                    }
            in
            ( newModel, Cmd.none, Types.requestAllMeasurements newModel )

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
