module Page.LabelSets.View exposing (view)

import Api.Decoders exposing (LabelSetSummary, TemplateSummary)
import Components
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Page.LabelSets.Types exposing (Model, Msg(..))
import Types exposing (RemoteData(..))


view : Model -> Html Msg
view model =
    div []
        [ div [ class "flex items-center justify-between mb-6" ]
            [ h1 [ class "text-2xl font-bold text-gray-800" ] [ text "Colecciones" ]
            , viewCreateControls model
            ]
        , viewBody model
        ]


viewCreateControls : Model -> Html Msg
viewCreateControls model =
    case model.templates of
        Loaded templates ->
            if List.isEmpty templates then
                text ""

            else
                div [ class "flex items-center gap-2" ]
                    [ select
                        [ class "border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
                        , onInput SelectTemplate
                        ]
                        (option [ value "" ] [ text "Seleccionar plantilla..." ]
                            :: List.map
                                (\t ->
                                    option
                                        [ value t.id
                                        , selected (model.selectedTemplateId == Just t.id)
                                        ]
                                        [ text t.name ]
                                )
                                templates
                        )
                    , input
                        [ type_ "text"
                        , class "border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-label-500 focus:border-label-500"
                        , placeholder "Nombre de la colección..."
                        , value model.newName
                        , onInput UpdateNewName
                        ]
                        []
                    , button
                        [ class "px-4 py-2 bg-label-600 text-white rounded-lg hover:bg-label-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                        , onClick CreateLabelSet
                        , disabled (model.selectedTemplateId == Nothing || String.isEmpty (String.trim model.newName))
                        ]
                        [ text "+ Crear colección" ]
                    ]

        _ ->
            text ""


viewBody : Model -> Html Msg
viewBody model =
    case model.labelsets of
        NotAsked ->
            text ""

        Loading ->
            Components.viewLoading

        Failed err ->
            div [ class "text-red-500 text-center py-8" ] [ text err ]

        Loaded labelsets ->
            if List.isEmpty labelsets then
                viewEmpty

            else
                viewList labelsets


viewEmpty : Html Msg
viewEmpty =
    div [ class "text-center py-16" ]
        [ p [ class "text-gray-400 text-lg mb-4" ] [ text "No hay colecciones" ]
        , p [ class "text-gray-400 text-sm" ] [ text "Selecciona una plantilla arriba para crear una colección de etiquetas" ]
        ]


viewList : List LabelSetSummary -> Html Msg
viewList labelsets =
    table [ class "w-full bg-white rounded-lg border border-gray-200 text-left" ]
        [ thead []
            [ tr [ class "bg-gray-50 text-xs font-medium text-gray-500 uppercase tracking-wider" ]
                [ th [ class "px-4 py-2 font-medium" ] [ text "Nombre" ]
                , th [ class "px-4 py-2 font-medium" ] [ text "Plantilla" ]
                , th [ class "px-4 py-2 font-medium" ] [ text "Filas" ]
                , th [ class "px-4 py-2 font-medium w-0" ] []
                ]
            ]
        , tbody [ class "divide-y divide-gray-100" ]
            (List.map viewRow labelsets)
        ]


viewRow : LabelSetSummary -> Html Msg
viewRow labelset =
    tr [ class "hover:bg-gray-50 transition-colors" ]
        [ td [ class "px-4 py-3" ]
            [ a [ href ("/set/" ++ labelset.id), class "font-semibold text-gray-800" ] [ text labelset.name ] ]
        , td [ class "px-4 py-3 text-sm text-gray-400" ] [ text labelset.templateName ]
        , td [ class "px-4 py-3 text-sm text-gray-400" ] [ text (String.fromInt labelset.rowCount ++ " filas") ]
        , td [ class "px-4 py-3 text-right" ]
            [ button
                [ class "text-sm text-red-400 hover:text-red-600 transition-colors"
                , onClick (DeleteLabelSet labelset.id)
                ]
                [ text "Eliminar" ]
            ]
        ]
