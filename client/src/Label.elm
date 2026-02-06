module Label exposing
    ( LabelData
    , LabelSettings
    , defaultSettings
    , labelSvgId
    , viewLabel
    )

{-| SVG label rendering for FrostByte freezer labels.

This module generates SVG labels that can be converted to PNG for printing.
Layout matches the original Python printer service output.

-}

import Html exposing (Html)
import QRCode
import Svg exposing (Svg)
import Svg.Attributes as SvgA


{-| Data needed to render a label.
-}
type alias LabelData =
    { portionId : String
    , name : String
    , ingredients : String
    , expiryDate : String
    , appHost : String
    }


{-| Settings that control label dimensions and styling.
-}
type alias LabelSettings =
    { name : String
    , width : Int
    , height : Int
    , qrSize : Int
    , padding : Int
    , titleFontSize : Int
    , dateFontSize : Int
    , smallFontSize : Int
    , fontFamily : String
    }


{-| Default settings for 62mm Brother QL tape.
-}
defaultSettings : LabelSettings
defaultSettings =
    { name = "62mm (default)"
    , width = 696
    , height = 300
    , qrSize = 200
    , padding = 20
    , titleFontSize = 48
    , dateFontSize = 32
    , smallFontSize = 18
    , fontFamily = "sans-serif"
    }


{-| Generate a unique SVG element ID for a portion.
-}
labelSvgId : String -> String
labelSvgId portionId =
    "label-svg-" ++ portionId


{-| Render a label as SVG.
-}
viewLabel : LabelSettings -> LabelData -> Html msg
viewLabel settings data =
    let
        qrUrl =
            "https://" ++ data.appHost ++ "/item/" ++ data.portionId

        qrX =
            settings.width - settings.qrSize - settings.padding

        qrY =
            (settings.height - settings.qrSize) // 2

        truncatedName =
            truncateText 18 data.name

        truncatedIngredients =
            truncateText 45 data.ingredients

        formattedDate =
            formatExpiryDate data.expiryDate

        -- Text vertical positions
        nameY =
            settings.padding + settings.titleFontSize

        ingredientsY =
            nameY + settings.titleFontSize - 10

        caducaY =
            ingredientsY + settings.smallFontSize + 20

        dateY =
            caducaY + settings.dateFontSize + 5
    in
    Svg.svg
        [ SvgA.id (labelSvgId data.portionId)
        , SvgA.width (String.fromInt settings.width)
        , SvgA.height (String.fromInt settings.height)
        , SvgA.viewBox ("0 0 " ++ String.fromInt settings.width ++ " " ++ String.fromInt settings.height)
        , SvgA.style "background: white"
        ]
        [ -- White background rectangle
          Svg.rect
            [ SvgA.x "0"
            , SvgA.y "0"
            , SvgA.width (String.fromInt settings.width)
            , SvgA.height (String.fromInt settings.height)
            , SvgA.fill "white"
            ]
            []

        -- Item name (title)
        , Svg.text_
            [ SvgA.x (String.fromInt settings.padding)
            , SvgA.y (String.fromInt nameY)
            , SvgA.fontFamily settings.fontFamily
            , SvgA.fontSize (String.fromInt settings.titleFontSize ++ "px")
            , SvgA.fontWeight "bold"
            , SvgA.fill "black"
            ]
            [ Svg.text truncatedName ]

        -- Ingredients
        , Svg.text_
            [ SvgA.x (String.fromInt settings.padding)
            , SvgA.y (String.fromInt ingredientsY)
            , SvgA.fontFamily settings.fontFamily
            , SvgA.fontSize (String.fromInt settings.smallFontSize ++ "px")
            , SvgA.fill "#666666"
            ]
            [ Svg.text truncatedIngredients ]

        -- "Caduca:" label
        , Svg.text_
            [ SvgA.x (String.fromInt settings.padding)
            , SvgA.y (String.fromInt caducaY)
            , SvgA.fontFamily settings.fontFamily
            , SvgA.fontSize (String.fromInt settings.smallFontSize ++ "px")
            , SvgA.fill "black"
            ]
            [ Svg.text "Caduca:" ]

        -- Expiry date
        , Svg.text_
            [ SvgA.x (String.fromInt settings.padding)
            , SvgA.y (String.fromInt dateY)
            , SvgA.fontFamily settings.fontFamily
            , SvgA.fontSize (String.fromInt settings.dateFontSize ++ "px")
            , SvgA.fontWeight "bold"
            , SvgA.fill "black"
            ]
            [ Svg.text formattedDate ]

        -- QR Code
        , viewQrCode qrUrl qrX qrY settings.qrSize
        ]


{-| Render a QR code at the specified position.
-}
viewQrCode : String -> Int -> Int -> Int -> Svg msg
viewQrCode url x y size =
    case QRCode.fromString url of
        Ok qrCode ->
            Svg.g
                [ SvgA.transform ("translate(" ++ String.fromInt x ++ "," ++ String.fromInt y ++ ")")
                ]
                [ QRCode.toSvg
                    [ SvgA.width (String.fromInt size)
                    , SvgA.height (String.fromInt size)
                    ]
                    qrCode
                ]

        Err _ ->
            -- Fallback: gray placeholder rectangle
            Svg.rect
                [ SvgA.x (String.fromInt x)
                , SvgA.y (String.fromInt y)
                , SvgA.width (String.fromInt size)
                , SvgA.height (String.fromInt size)
                , SvgA.fill "#cccccc"
                ]
                []


{-| Truncate text with ellipsis if it exceeds maxLength.
-}
truncateText : Int -> String -> String
truncateText maxLength text =
    if String.length text > maxLength then
        String.left (maxLength - 3) text ++ "..."

    else
        text


{-| Convert ISO date (2025-12-31) to DD/MM/YYYY format.
-}
formatExpiryDate : String -> String
formatExpiryDate isoDate =
    case String.split "-" (String.left 10 isoDate) of
        [ year, month, day ] ->
            day ++ "/" ++ month ++ "/" ++ year

        _ ->
            isoDate
