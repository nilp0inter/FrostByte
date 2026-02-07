port module Ports exposing
    ( PngResult
    , SvgToPngRequest
    , TextMeasureRequest
    , TextMeasureResult
    , receivePngResult
    , receiveTextMeasureResult
    , requestSvgToPng
    , requestTextMeasure
    )

{-| Ports for SVG to PNG conversion and text measurement via JavaScript.

The Elm app renders labels as SVG, then uses these ports to convert
them to PNG for printing. Text measurement ports enable dynamic font
sizing for titles and word-wrapping for ingredients.

-}


{-| Request to convert an SVG element to PNG.
When rotate is True, the SVG is rendered with swapped dimensions
and then rotated 90° clockwise before exporting the PNG.
-}
type alias SvgToPngRequest =
    { svgId : String
    , requestId : String
    , width : Int
    , height : Int
    , rotate : Bool
    }


{-| Result of SVG to PNG conversion.
-}
type alias PngResult =
    { requestId : String
    , dataUrl : Maybe String
    , error : Maybe String
    }


{-| Request conversion of an SVG element to PNG.
The SVG must be in the DOM with the specified ID.
-}
port requestSvgToPng : SvgToPngRequest -> Cmd msg


{-| Receive the result of an SVG to PNG conversion.
-}
port receivePngResult : (PngResult -> msg) -> Sub msg



-- TEXT MEASUREMENT PORTS


{-| Request to measure and fit text for a label.
Used to calculate dynamic title font size and wrap ingredients to multiple lines.
-}
type alias TextMeasureRequest =
    { requestId : String
    , titleText : String
    , ingredientsText : String
    , fontFamily : String
    , titleFontSize : Int
    , titleMinFontSize : Int
    , smallFontSize : Int
    , maxWidth : Int
    , ingredientsMaxChars : Int
    }


{-| Result of text measurement.
Contains fitted title font size, wrapped title lines, and word-wrapped ingredient lines.
-}
type alias TextMeasureResult =
    { requestId : String
    , titleFittedFontSize : Int
    , titleLines : List String
    , ingredientLines : List String
    }


{-| Request text measurement for a label.
-}
port requestTextMeasure : TextMeasureRequest -> Cmd msg


{-| Receive the result of text measurement.
-}
port receiveTextMeasureResult : (TextMeasureResult -> msg) -> Sub msg
