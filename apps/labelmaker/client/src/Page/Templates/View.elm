module Page.Templates.View exposing (view)

import Api.Decoders exposing (TemplateSummary)
import Components
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Page.Templates.Types exposing (Model, Msg(..))
import Types exposing (RemoteData(..))


view : Model -> Html Msg
view model =
    div []
        [ div [ class "flex items-center justify-between mb-6" ]
            [ h1 [ class "text-2xl font-bold text-gray-800" ] [ text "Plantillas" ]
            , button
                [ class "px-4 py-2 bg-label-600 text-white rounded-lg hover:bg-label-700 transition-colors font-medium"
                , onClick CreateTemplate
                ]
                [ text "+ Crear plantilla" ]
            ]
        , viewBody model
        ]


viewBody : Model -> Html Msg
viewBody model =
    case model.templates of
        NotAsked ->
            text ""

        Loading ->
            Components.viewLoading

        Failed err ->
            div [ class "text-red-500 text-center py-8" ] [ text err ]

        Loaded templates ->
            if List.isEmpty templates then
                viewEmpty

            else
                viewGrid templates


viewEmpty : Html Msg
viewEmpty =
    div [ class "text-center py-16" ]
        [ p [ class "text-gray-400 text-lg mb-4" ] [ text "No hay plantillas" ]
        , button
            [ class "px-4 py-2 bg-label-600 text-white rounded-lg hover:bg-label-700 transition-colors"
            , onClick CreateTemplate
            ]
            [ text "Crear primera plantilla" ]
        ]


viewGrid : List TemplateSummary -> Html Msg
viewGrid templates =
    div [ class "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4" ]
        (List.map viewCard templates)


viewCard : TemplateSummary -> Html Msg
viewCard template =
    div [ class "bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow" ]
        [ a
            [ href ("/template/" ++ template.id)
            , class "block p-4"
            ]
            [ div [ class "flex items-start justify-between" ]
                [ div []
                    [ h3 [ class "font-semibold text-gray-800 mb-1" ] [ text template.name ]
                    , p [ class "text-sm text-gray-500" ] [ text ("Tipo: " ++ template.labelTypeId) ]
                    ]
                ]
            ]
        , div [ class "border-t border-gray-100 px-4 py-2 flex justify-end" ]
            [ button
                [ class "text-sm text-red-400 hover:text-red-600 transition-colors"
                , onClick (DeleteTemplate template.id)
                ]
                [ text "Eliminar" ]
            ]
        ]
