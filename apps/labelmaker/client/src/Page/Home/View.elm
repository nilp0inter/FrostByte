module Page.Home.View exposing (view)

import Data.LabelTypes exposing (LabelTypeSpec, isEndlessLabel, labelTypes)
import Html exposing (..)
import Html.Attributes exposing (class, for, id, max, min, selected, step, type_, value)
import Html.Events exposing (onInput)
import Page.Home.Types exposing (ComputedText, Model, Msg(..))
import Svg exposing (svg)
import Svg.Attributes as SA


view : Model -> Html Msg
view model =
    div [ class "flex flex-col lg:flex-row gap-8" ]
        [ viewPreview model
        , viewControls model
        ]


viewPreview : Model -> Html Msg
viewPreview model =
    let
        displayWidth =
            if model.rotate then
                model.labelHeight
            else
                model.labelWidth

        displayHeight =
            if model.rotate then
                model.labelWidth
            else
                model.labelHeight

        scaleFactor =
            Basics.min 1.0 (500.0 / toFloat displayWidth)

        scaledWidth =
            round (toFloat displayWidth * scaleFactor)

        scaledHeight =
            round (toFloat displayHeight * scaleFactor)
    in
    div [ class "flex-1" ]
        [ h2 [ class "text-lg font-semibold text-gray-700 mb-4" ] [ text "Vista previa" ]
        , div [ class "flex justify-center" ]
            [ svg
                [ SA.width (String.fromInt scaledWidth)
                , SA.height (String.fromInt scaledHeight)
                , SA.viewBox ("0 0 " ++ String.fromInt displayWidth ++ " " ++ String.fromInt displayHeight)
                , id "label-preview"
                ]
                ([ Svg.rect
                    [ SA.x "0"
                    , SA.y "0"
                    , SA.width (String.fromInt displayWidth)
                    , SA.height (String.fromInt displayHeight)
                    , SA.rx (String.fromInt model.cornerRadius)
                    , SA.ry (String.fromInt model.cornerRadius)
                    , SA.fill "white"
                    , SA.stroke "#ccc"
                    , SA.strokeWidth "2"
                    ]
                    []
                 ]
                    ++ viewTextContent model displayWidth displayHeight
                )
            ]
        , p [ class "text-sm text-gray-500 text-center mt-2" ]
            [ text
                (String.fromInt displayWidth
                    ++ " x "
                    ++ String.fromInt displayHeight
                    ++ " px"
                    ++ (if model.rotate then
                            " (rotada)"

                        else
                            ""
                       )
                )
            ]
        ]


viewTextContent : Model -> Int -> Int -> List (Svg.Svg Msg)
viewTextContent model displayWidth displayHeight =
    case model.computedText of
        Nothing ->
            [ Svg.text_
                [ SA.x (String.fromInt (displayWidth // 2))
                , SA.y (String.fromInt (displayHeight // 2))
                , SA.textAnchor "middle"
                , SA.dominantBaseline "central"
                , SA.fill "#999"
                , SA.fontSize "20"
                ]
                [ Svg.text "Cargando..." ]
            ]

        Just computed ->
            let
                lineHeight =
                    toFloat computed.fittedFontSize * 1.2

                totalTextHeight =
                    lineHeight * toFloat (List.length computed.lines)

                startY =
                    (toFloat displayHeight - totalTextHeight) / 2 + lineHeight / 2
            in
            List.indexedMap
                (\i line ->
                    Svg.text_
                        [ SA.x (String.fromInt (displayWidth // 2))
                        , SA.y (String.fromFloat (startY + toFloat i * lineHeight))
                        , SA.textAnchor "middle"
                        , SA.dominantBaseline "central"
                        , SA.fontFamily model.fontFamily
                        , SA.fontSize (String.fromInt computed.fittedFontSize)
                        , SA.fontWeight "bold"
                        , SA.fill "#000"
                        ]
                        [ Svg.text line ]
                )
                computed.lines


viewControls : Model -> Html Msg
viewControls model =
    div [ class "w-full lg:w-80 space-y-4" ]
        [ h2 [ class "text-lg font-semibold text-gray-700 mb-4" ] [ text "Configuraci\u{00F3}n" ]
        , viewLabelTypeSelect model
        , viewDimensions model
        , viewVariableInputs model
        , viewFontSettings model
        , viewPaddingInput model
        ]


viewLabelTypeSelect : Model -> Html Msg
viewLabelTypeSelect model =
    div []
        [ label [ for "label-type", class "block text-sm font-medium text-gray-600 mb-1" ]
            [ text "Tipo de etiqueta" ]
        , select
            [ id "label-type"
            , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
            , onInput LabelTypeChanged
            ]
            (List.map
                (\spec ->
                    option
                        [ value spec.id
                        , selected (spec.id == model.labelTypeId)
                        ]
                        [ text spec.description ]
                )
                labelTypes
            )
        ]


viewDimensions : Model -> Html Msg
viewDimensions model =
    div [ class "flex gap-4" ]
        [ div [ class "flex-1" ]
            [ label [ class "block text-sm font-medium text-gray-600 mb-1" ]
                [ text "Ancho (px)" ]
            , input
                [ type_ "number"
                , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm bg-gray-50"
                , value (String.fromInt model.labelWidth)
                , Html.Attributes.disabled True
                ]
                []
            ]
        , div [ class "flex-1" ]
            [ label [ class "block text-sm font-medium text-gray-600 mb-1" ]
                [ text "Alto (px)" ]
            , input
                [ type_ "number"
                , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
                , value (String.fromInt model.labelHeight)
                , onInput HeightChanged
                , Html.Attributes.disabled (not (isEndlessLabel model.labelTypeId))
                ]
                []
            ]
        ]


viewVariableInputs : Model -> Html Msg
viewVariableInputs model =
    div [ class "space-y-3" ]
        [ div []
            [ label [ for "var-name", class "block text-sm font-medium text-gray-600 mb-1" ]
                [ text "Nombre de variable" ]
            , div [ class "flex items-center" ]
                [ span [ class "text-sm text-gray-400 mr-1" ] [ text "{{" ]
                , input
                    [ id "var-name"
                    , type_ "text"
                    , class "flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
                    , value model.variableName
                    , onInput VariableNameChanged
                    ]
                    []
                , span [ class "text-sm text-gray-400 ml-1" ] [ text "}}" ]
                ]
            ]
        , div []
            [ label [ for "sample-value", class "block text-sm font-medium text-gray-600 mb-1" ]
                [ text "Valor de ejemplo" ]
            , input
                [ id "sample-value"
                , type_ "text"
                , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
                , value model.sampleValue
                , onInput SampleValueChanged
                ]
                []
            ]
        ]


viewFontSettings : Model -> Html Msg
viewFontSettings model =
    div [ class "flex gap-4" ]
        [ div [ class "flex-1" ]
            [ label [ for "max-font", class "block text-sm font-medium text-gray-600 mb-1" ]
                [ text "Fuente m\u{00E1}x (px)" ]
            , input
                [ id "max-font"
                , type_ "number"
                , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
                , value (String.fromInt model.maxFontSize)
                , Html.Attributes.min "8"
                , Html.Attributes.max "200"
                , onInput MaxFontSizeChanged
                ]
                []
            ]
        , div [ class "flex-1" ]
            [ label [ for "min-font", class "block text-sm font-medium text-gray-600 mb-1" ]
                [ text "Fuente m\u{00ED}n (px)" ]
            , input
                [ id "min-font"
                , type_ "number"
                , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
                , value (String.fromInt model.minFontSize)
                , Html.Attributes.min "6"
                , Html.Attributes.max "100"
                , onInput MinFontSizeChanged
                ]
                []
            ]
        ]


viewPaddingInput : Model -> Html Msg
viewPaddingInput model =
    div []
        [ label [ for "padding", class "block text-sm font-medium text-gray-600 mb-1" ]
            [ text "Relleno (px)" ]
        , input
            [ id "padding"
            , type_ "number"
            , class "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
            , value (String.fromInt model.padding)
            , Html.Attributes.min "0"
            , Html.Attributes.max "100"
            , onInput PaddingChanged
            ]
            []
        ]
