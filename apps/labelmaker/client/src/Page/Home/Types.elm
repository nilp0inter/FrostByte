module Page.Home.Types exposing (ComputedText, Model, Msg(..), OutMsg(..), initialModel, requestMeasurement)

import Data.LabelTypes exposing (LabelTypeSpec, labelTypes, silverRatioHeight)
import Ports


type alias ComputedText =
    { fittedFontSize : Int
    , lines : List String
    }


type alias Model =
    { labelTypeId : String
    , labelWidth : Int
    , labelHeight : Int
    , cornerRadius : Int
    , rotate : Bool
    , variableName : String
    , sampleValue : String
    , fontFamily : String
    , maxFontSize : Int
    , minFontSize : Int
    , padding : Int
    , computedText : Maybe ComputedText
    }


type Msg
    = LabelTypeChanged String
    | HeightChanged String
    | VariableNameChanged String
    | SampleValueChanged String
    | MaxFontSizeChanged String
    | MinFontSizeChanged String
    | PaddingChanged String
    | GotTextMeasureResult Ports.TextMeasureResult


type OutMsg
    = NoOutMsg
    | RequestTextMeasure Ports.TextMeasureRequest


initialModel : Model
initialModel =
    let
        defaultWidth =
            696

        defaultHeight =
            silverRatioHeight defaultWidth
    in
    { labelTypeId = "62"
    , labelWidth = defaultWidth
    , labelHeight = defaultHeight
    , cornerRadius = 0
    , rotate = False
    , variableName = "nombre"
    , sampleValue = "Pollo con arroz"
    , fontFamily = "Atkinson Hyperlegible"
    , maxFontSize = 48
    , minFontSize = 16
    , padding = 20
    , computedText = Nothing
    }


requestMeasurement : Model -> OutMsg
requestMeasurement model =
    let
        displayWidth =
            if model.rotate then
                model.labelHeight
            else
                model.labelWidth

        maxTextWidth =
            displayWidth - (model.padding * 2)
    in
    RequestTextMeasure
        { requestId = "label-text"
        , text = model.sampleValue
        , fontFamily = model.fontFamily
        , maxFontSize = model.maxFontSize
        , minFontSize = model.minFontSize
        , maxWidth = maxTextWidth
        }
