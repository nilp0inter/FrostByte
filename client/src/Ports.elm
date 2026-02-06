port module Ports exposing
    ( PngResult
    , SvgToPngRequest
    , receivePngResult
    , requestSvgToPng
    )

{-| Ports for SVG to PNG conversion via JavaScript.

The Elm app renders labels as SVG, then uses these ports to convert
them to PNG for printing.

-}


{-| Request to convert an SVG element to PNG.
-}
type alias SvgToPngRequest =
    { svgId : String
    , requestId : String
    , width : Int
    , height : Int
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
