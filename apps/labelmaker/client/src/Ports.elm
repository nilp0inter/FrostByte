port module Ports exposing (TextMeasureRequest, TextMeasureResult, receiveTextMeasureResult, requestTextMeasure)


type alias TextMeasureRequest =
    { requestId : String
    , text : String
    , fontFamily : String
    , maxFontSize : Int
    , minFontSize : Int
    , maxWidth : Int
    }


type alias TextMeasureResult =
    { requestId : String
    , fittedFontSize : Int
    , lines : List String
    }


port requestTextMeasure : TextMeasureRequest -> Cmd msg


port receiveTextMeasureResult : (TextMeasureResult -> msg) -> Sub msg
