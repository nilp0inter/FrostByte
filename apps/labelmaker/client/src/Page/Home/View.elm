module Page.Home.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class)
import Page.Home.Types exposing (Model, Msg)


view : Model -> Html Msg
view _ =
    div [ class "text-center py-12" ]
        [ span [ class "text-6xl" ] [ text "\u{1F3F7}\u{FE0F}" ]
        , h1 [ class "text-3xl font-bold text-gray-800 mt-4" ] [ text "Bienvenido a LabelMaker" ]
        , p [ class "text-gray-600 mt-2" ] [ text "Diseñador de plantillas de etiquetas y biblioteca" ]
        ]
