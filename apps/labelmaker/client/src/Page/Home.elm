module Page.Home exposing (Model, Msg, OutMsg, init, update, view)

import Data.LabelTypes exposing (LabelTypeSpec, labelTypes, silverRatioHeight)
import Html exposing (Html)
import Page.Home.Types as Types
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
    ( model, Cmd.none, Types.requestMeasurement model )


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
                                , computedText = Nothing
                            }

                        Nothing ->
                            model
            in
            ( newModel, Cmd.none, Types.requestMeasurement newModel )

        Types.HeightChanged str ->
            case String.toInt str of
                Just h ->
                    let
                        newModel =
                            { model | labelHeight = h, computedText = Nothing }
                    in
                    ( newModel, Cmd.none, Types.requestMeasurement newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.VariableNameChanged name ->
            ( { model | variableName = name }, Cmd.none, Types.NoOutMsg )

        Types.SampleValueChanged val ->
            let
                newModel =
                    { model | sampleValue = val, computedText = Nothing }
            in
            ( newModel, Cmd.none, Types.requestMeasurement newModel )

        Types.MaxFontSizeChanged str ->
            case String.toInt str of
                Just s ->
                    let
                        newModel =
                            { model | maxFontSize = s, computedText = Nothing }
                    in
                    ( newModel, Cmd.none, Types.requestMeasurement newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.MinFontSizeChanged str ->
            case String.toInt str of
                Just s ->
                    let
                        newModel =
                            { model | minFontSize = s, computedText = Nothing }
                    in
                    ( newModel, Cmd.none, Types.requestMeasurement newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.PaddingChanged str ->
            case String.toInt str of
                Just p ->
                    let
                        newModel =
                            { model | padding = p, computedText = Nothing }
                    in
                    ( newModel, Cmd.none, Types.requestMeasurement newModel )

                Nothing ->
                    ( model, Cmd.none, Types.NoOutMsg )

        Types.GotTextMeasureResult result ->
            ( { model
                | computedText =
                    Just
                        { fittedFontSize = result.fittedFontSize
                        , lines = result.lines
                        }
              }
            , Cmd.none
            , Types.NoOutMsg
            )


view : Model -> Html Msg
view model =
    View.view model
