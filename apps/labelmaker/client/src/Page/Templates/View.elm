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
                viewList templates


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


viewList : List TemplateSummary -> Html Msg
viewList templates =
    table [ class "w-full bg-white rounded-lg border border-gray-200 text-left" ]
        [ thead []
            [ tr [ class "bg-gray-50 text-xs font-medium text-gray-500 uppercase tracking-wider" ]
                [ th [ class "px-4 py-2 font-medium" ] [ text "Nombre" ]
                , th [ class "px-4 py-2 font-medium" ] [ text "Tipo" ]
                , th [ class "px-4 py-2 font-medium w-0" ] []
                ]
            ]
        , tbody [ class "divide-y divide-gray-100" ]
            (List.map viewRow templates)
        ]


viewRow : TemplateSummary -> Html Msg
viewRow template =
    tr [ class "hover:bg-gray-50 transition-colors" ]
        [ td [ class "px-4 py-3" ]
            [ a [ href ("/template/" ++ template.id), class "font-semibold text-gray-800" ] [ text template.name ] ]
        , td [ class "px-4 py-3 text-sm text-gray-400" ] [ text template.labelTypeId ]
        , td [ class "px-4 py-3 text-right" ]
            [ button
                [ class "text-sm text-red-400 hover:text-red-600 transition-colors"
                , onClick (DeleteTemplate template.id)
                ]
                [ text "Eliminar" ]
            ]
        ]
