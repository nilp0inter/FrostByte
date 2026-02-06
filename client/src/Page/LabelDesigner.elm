module Page.LabelDesigner exposing
    ( Model
    , Msg
    , OutMsg(..)
    , init
    , update
    , view
    )

{-| Label Designer page for managing label presets with live preview.
-}

import Api
import Html exposing (..)
import Html.Attributes as Attr exposing (class, disabled, placeholder, required, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Label
import Types exposing (..)


type alias Model =
    { presets : List LabelPreset
    , form : LabelPresetForm
    , appHost : String
    , loading : Bool
    , deleteConfirm : Maybe String
    }


type Msg
    = GotPresets (Result Http.Error (List LabelPreset))
    | FormNameChanged String
    | FormWidthChanged String
    | FormHeightChanged String
    | FormQrSizeChanged String
    | FormPaddingChanged String
    | FormTitleFontSizeChanged String
    | FormDateFontSizeChanged String
    | FormSmallFontSizeChanged String
    | FormFontFamilyChanged String
    | SavePreset
    | EditPreset LabelPreset
    | CancelEdit
    | DeletePreset String
    | ConfirmDelete String
    | CancelDelete
    | PresetSaved (Result Http.Error ())
    | PresetDeleted (Result Http.Error ())
    | ApplyTemplate62mm
    | ApplyTemplate29mm
    | ApplyTemplate12mm


type OutMsg
    = NoOp
    | ShowNotification Notification
    | RefreshPresets


init : String -> List LabelPreset -> ( Model, Cmd Msg )
init appHost presets =
    ( { presets = presets
      , form = emptyLabelPresetForm
      , appHost = appHost
      , loading = False
      , deleteConfirm = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        GotPresets result ->
            case result of
                Ok presets ->
                    ( { model | presets = presets, loading = False }
                    , Cmd.none
                    , NoOp
                    )

                Err _ ->
                    ( { model | loading = False }
                    , Cmd.none
                    , ShowNotification { message = "Error al cargar presets", notificationType = Error }
                    )

        FormNameChanged name ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | name = name } }, Cmd.none, NoOp )

        FormWidthChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | width = val } }, Cmd.none, NoOp )

        FormHeightChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | height = val } }, Cmd.none, NoOp )

        FormQrSizeChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | qrSize = val } }, Cmd.none, NoOp )

        FormPaddingChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | padding = val } }, Cmd.none, NoOp )

        FormTitleFontSizeChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | titleFontSize = val } }, Cmd.none, NoOp )

        FormDateFontSizeChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | dateFontSize = val } }, Cmd.none, NoOp )

        FormSmallFontSizeChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | smallFontSize = val } }, Cmd.none, NoOp )

        FormFontFamilyChanged val ->
            let
                form =
                    model.form
            in
            ( { model | form = { form | fontFamily = val } }, Cmd.none, NoOp )

        SavePreset ->
            if String.isEmpty model.form.name then
                ( model
                , Cmd.none
                , ShowNotification { message = "El nombre es requerido", notificationType = Error }
                )

            else
                ( { model | loading = True }
                , Api.saveLabelPreset model.form PresetSaved
                , NoOp
                )

        EditPreset preset ->
            ( { model
                | form =
                    { name = preset.name
                    , width = String.fromInt preset.width
                    , height = String.fromInt preset.height
                    , qrSize = String.fromInt preset.qrSize
                    , padding = String.fromInt preset.padding
                    , titleFontSize = String.fromInt preset.titleFontSize
                    , dateFontSize = String.fromInt preset.dateFontSize
                    , smallFontSize = String.fromInt preset.smallFontSize
                    , fontFamily = preset.fontFamily
                    , editing = Just preset.name
                    }
              }
            , Cmd.none
            , NoOp
            )

        CancelEdit ->
            ( { model | form = emptyLabelPresetForm }, Cmd.none, NoOp )

        DeletePreset name ->
            ( { model | deleteConfirm = Just name }, Cmd.none, NoOp )

        ConfirmDelete name ->
            ( { model | deleteConfirm = Nothing, loading = True }
            , Api.deleteLabelPreset name PresetDeleted
            , NoOp
            )

        CancelDelete ->
            ( { model | deleteConfirm = Nothing }, Cmd.none, NoOp )

        PresetSaved result ->
            case result of
                Ok _ ->
                    ( { model | loading = False, form = emptyLabelPresetForm }
                    , Api.fetchLabelPresets GotPresets
                    , ShowNotification { message = "Preset guardado", notificationType = Success }
                    )

                Err _ ->
                    ( { model | loading = False }
                    , Cmd.none
                    , ShowNotification { message = "Error al guardar preset", notificationType = Error }
                    )

        PresetDeleted result ->
            case result of
                Ok _ ->
                    ( { model | loading = False }
                    , Api.fetchLabelPresets GotPresets
                    , ShowNotification { message = "Preset eliminado", notificationType = Success }
                    )

                Err _ ->
                    ( { model | loading = False }
                    , Cmd.none
                    , ShowNotification { message = "Error al eliminar preset", notificationType = Error }
                    )

        ApplyTemplate62mm ->
            ( { model
                | form =
                    { name = model.form.name
                    , width = "696"
                    , height = "300"
                    , qrSize = "200"
                    , padding = "20"
                    , titleFontSize = "48"
                    , dateFontSize = "32"
                    , smallFontSize = "18"
                    , fontFamily = "sans-serif"
                    , editing = model.form.editing
                    }
              }
            , Cmd.none
            , NoOp
            )

        ApplyTemplate29mm ->
            ( { model
                | form =
                    { name = model.form.name
                    , width = "306"
                    , height = "200"
                    , qrSize = "120"
                    , padding = "10"
                    , titleFontSize = "24"
                    , dateFontSize = "18"
                    , smallFontSize = "12"
                    , fontFamily = "sans-serif"
                    , editing = model.form.editing
                    }
              }
            , Cmd.none
            , NoOp
            )

        ApplyTemplate12mm ->
            ( { model
                | form =
                    { name = model.form.name
                    , width = "106"
                    , height = "100"
                    , qrSize = "60"
                    , padding = "5"
                    , titleFontSize = "14"
                    , dateFontSize = "12"
                    , smallFontSize = "8"
                    , fontFamily = "sans-serif"
                    , editing = model.form.editing
                    }
              }
            , Cmd.none
            , NoOp
            )


view : Model -> Html Msg
view model =
    div []
        [ h1 [ class "text-3xl font-bold text-gray-800 mb-6" ] [ text "Diseñador de Etiquetas" ]
        , div [ class "grid grid-cols-1 lg:grid-cols-3 gap-6" ]
            [ viewForm model
            , viewPreview model
            , viewList model
            ]
        , viewDeleteConfirm model.deleteConfirm
        ]


viewForm : Model -> Html Msg
viewForm model =
    div [ class "card" ]
        [ h2 [ class "text-lg font-semibold text-gray-800 mb-4" ]
            [ text
                (if model.form.editing /= Nothing then
                    "Editar Preset"

                 else
                    "Nuevo Preset"
                )
            ]
        , div [ class "mb-4" ]
            [ p [ class "text-sm text-gray-600 mb-2" ] [ text "Plantillas:" ]
            , div [ class "flex flex-wrap gap-2" ]
                [ button
                    [ type_ "button"
                    , class "px-3 py-1 text-sm bg-frost-100 hover:bg-frost-200 text-frost-700 rounded-lg"
                    , onClick ApplyTemplate62mm
                    ]
                    [ text "62mm" ]
                , button
                    [ type_ "button"
                    , class "px-3 py-1 text-sm bg-frost-100 hover:bg-frost-200 text-frost-700 rounded-lg"
                    , onClick ApplyTemplate29mm
                    ]
                    [ text "29mm" ]
                , button
                    [ type_ "button"
                    , class "px-3 py-1 text-sm bg-frost-100 hover:bg-frost-200 text-frost-700 rounded-lg"
                    , onClick ApplyTemplate12mm
                    ]
                    [ text "12mm" ]
                ]
            ]
        , Html.form [ onSubmit SavePreset, class "space-y-3" ]
            [ div []
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Nombre" ]
                , input
                    [ type_ "text"
                    , class "input-field"
                    , placeholder "Ej: Mi etiqueta personalizada"
                    , value model.form.name
                    , onInput FormNameChanged
                    , required True
                    , disabled (model.form.editing /= Nothing)
                    ]
                    []
                ]
            , div [ class "grid grid-cols-2 gap-3" ]
                [ div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Ancho (px)" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "100"
                        , value model.form.width
                        , onInput FormWidthChanged
                        ]
                        []
                    ]
                , div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Alto (px)" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "50"
                        , value model.form.height
                        , onInput FormHeightChanged
                        ]
                        []
                    ]
                ]
            , div [ class "grid grid-cols-2 gap-3" ]
                [ div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Tamaño QR (px)" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "30"
                        , value model.form.qrSize
                        , onInput FormQrSizeChanged
                        ]
                        []
                    ]
                , div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Padding (px)" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "0"
                        , value model.form.padding
                        , onInput FormPaddingChanged
                        ]
                        []
                    ]
                ]
            , div [ class "grid grid-cols-3 gap-3" ]
                [ div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Título" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "8"
                        , value model.form.titleFontSize
                        , onInput FormTitleFontSizeChanged
                        ]
                        []
                    ]
                , div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Fecha" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "8"
                        , value model.form.dateFontSize
                        , onInput FormDateFontSizeChanged
                        ]
                        []
                    ]
                , div []
                    [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Pequeño" ]
                    , input
                        [ type_ "number"
                        , class "input-field"
                        , Attr.min "6"
                        , value model.form.smallFontSize
                        , onInput FormSmallFontSizeChanged
                        ]
                        []
                    ]
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Fuente" ]
                , input
                    [ type_ "text"
                    , class "input-field"
                    , placeholder "sans-serif"
                    , value model.form.fontFamily
                    , onInput FormFontFamilyChanged
                    ]
                    []
                ]
            , div [ class "flex justify-end space-x-4 pt-4" ]
                [ if model.form.editing /= Nothing then
                    button
                        [ type_ "button"
                        , class "px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white font-medium rounded-lg transition-colors"
                        , onClick CancelEdit
                        ]
                        [ text "Cancelar" ]

                  else
                    text ""
                , button
                    [ type_ "submit"
                    , class "btn-primary"
                    , disabled model.loading
                    ]
                    [ if model.loading then
                        text "Guardando..."

                      else
                        text "Guardar"
                    ]
                ]
            ]
        ]


viewPreview : Model -> Html Msg
viewPreview model =
    let
        settings =
            formToSettings model.form

        sampleData =
            { portionId = "sample-preview"
            , name = "Pollo con arroz"
            , ingredients = "pollo, arroz, verduras"
            , expiryDate = "2025-12-31"
            , appHost = model.appHost
            }

        -- Scale preview to fit card
        previewScale =
            min 1.0 (400 / toFloat settings.width)
    in
    div [ class "card" ]
        [ h2 [ class "text-lg font-semibold text-gray-800 mb-4" ] [ text "Vista Previa" ]
        , div [ class "flex justify-center items-center bg-gray-100 rounded-lg p-4 overflow-auto" ]
            [ div
                [ Attr.style "transform" ("scale(" ++ String.fromFloat previewScale ++ ")")
                , Attr.style "transform-origin" "center center"
                ]
                [ Label.viewLabel settings sampleData ]
            ]
        , div [ class "mt-4 text-center text-sm text-gray-500" ]
            [ text (String.fromInt settings.width ++ " x " ++ String.fromInt settings.height ++ " px") ]
        ]


viewList : Model -> Html Msg
viewList model =
    div [ class "card" ]
        [ h2 [ class "text-lg font-semibold text-gray-800 mb-4" ] [ text "Presets existentes" ]
        , if List.isEmpty model.presets then
            div [ class "text-center py-8 text-gray-500" ]
                [ text "No hay presets definidos" ]

          else
            div [ class "space-y-2" ]
                (List.map viewPresetRow model.presets)
        ]


viewPresetRow : LabelPreset -> Html Msg
viewPresetRow preset =
    div [ class "flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100" ]
        [ div []
            [ div [ class "font-medium text-gray-900" ] [ text preset.name ]
            , div [ class "text-sm text-gray-500" ]
                [ text (String.fromInt preset.width ++ "x" ++ String.fromInt preset.height ++ " px") ]
            ]
        , div [ class "flex space-x-2" ]
            [ button
                [ onClick (EditPreset preset)
                , class "text-blue-600 hover:text-blue-800 font-medium text-sm"
                , title "Editar"
                ]
                [ text "✏️" ]
            , button
                [ onClick (DeletePreset preset.name)
                , class "text-red-600 hover:text-red-800 font-medium text-sm"
                , title "Eliminar"
                ]
                [ text "🗑️" ]
            ]
        ]


viewDeleteConfirm : Maybe String -> Html Msg
viewDeleteConfirm maybeName =
    case maybeName of
        Just name ->
            div [ class "fixed inset-0 z-50 flex items-center justify-center" ]
                [ div
                    [ class "absolute inset-0 bg-black bg-opacity-50"
                    , onClick CancelDelete
                    ]
                    []
                , div [ class "relative bg-white rounded-xl shadow-2xl max-w-md w-full mx-4 overflow-hidden" ]
                    [ div [ class "px-6 py-4 border-b" ]
                        [ h3 [ class "text-lg font-semibold text-gray-800" ]
                            [ text "Confirmar eliminación" ]
                        ]
                    , div [ class "p-6" ]
                        [ p [ class "text-gray-600" ]
                            [ text "¿Estás seguro de que quieres eliminar el preset \""
                            , span [ class "font-medium" ] [ text name ]
                            , text "\"? Esta acción no se puede deshacer."
                            ]
                        ]
                    , div [ class "flex justify-end px-6 py-4 bg-gray-50 border-t space-x-4" ]
                        [ button
                            [ onClick CancelDelete
                            , class "px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-700 rounded-lg font-medium"
                            ]
                            [ text "Cancelar" ]
                        , button
                            [ onClick (ConfirmDelete name)
                            , class "px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg font-medium"
                            ]
                            [ text "Eliminar" ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


{-| Convert form values to LabelSettings for preview.
-}
formToSettings : LabelPresetForm -> Label.LabelSettings
formToSettings form =
    { name = form.name
    , width = Maybe.withDefault 696 (String.toInt form.width)
    , height = Maybe.withDefault 300 (String.toInt form.height)
    , qrSize = Maybe.withDefault 200 (String.toInt form.qrSize)
    , padding = Maybe.withDefault 20 (String.toInt form.padding)
    , titleFontSize = Maybe.withDefault 48 (String.toInt form.titleFontSize)
    , dateFontSize = Maybe.withDefault 32 (String.toInt form.dateFontSize)
    , smallFontSize = Maybe.withDefault 18 (String.toInt form.smallFontSize)
    , fontFamily = form.fontFamily
    }
