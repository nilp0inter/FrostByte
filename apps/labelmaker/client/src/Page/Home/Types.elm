module Page.Home.Types exposing
    ( ComputedText
    , Model
    , Msg(..)
    , OutMsg(..)
    , PropertyChange(..)
    , applyTemplateDetail
    , initialModel
    , requestAllMeasurements
    )

import Api.Decoders exposing (TemplateDetail)
import Data.LabelObject as LO exposing (LabelObject(..), ObjectId)
import Data.LabelTypes exposing (LabelTypeSpec, labelTypes, silverRatioHeight)
import Dict exposing (Dict)
import Http
import Ports


type alias ComputedText =
    { fittedFontSize : Int
    , lines : List String
    }


type alias Model =
    { templateId : String
    , templateName : String
    , labelTypeId : String
    , labelWidth : Int
    , labelHeight : Int
    , cornerRadius : Int
    , rotate : Bool
    , content : List LabelObject
    , selectedObjectId : Maybe ObjectId
    , sampleValues : Dict String String
    , computedTexts : Dict ObjectId ComputedText
    , nextId : Int
    , padding : Int
    }


type Msg
    = LabelTypeChanged String
    | HeightChanged String
    | PaddingChanged String
    | SelectObject (Maybe ObjectId)
    | AddObject LabelObject
    | RemoveObject ObjectId
    | UpdateObjectProperty ObjectId PropertyChange
    | UpdateSampleValue String String
    | GotTextMeasureResult Ports.TextMeasureResult
    | GotTemplateDetail (Result Http.Error (Maybe TemplateDetail))
    | TemplateNameChanged String
    | EventEmitted (Result Http.Error ())


type PropertyChange
    = SetTextContent String
    | SetVariableName String
    | SetFontSize String
    | SetFontFamily String
    | SetColorR String
    | SetColorG String
    | SetColorB String
    | SetContainerX String
    | SetContainerY String
    | SetContainerWidth String
    | SetContainerHeight String
    | SetShapeType LO.ShapeType
    | SetImageUrl String


type OutMsg
    = NoOutMsg
    | RequestTextMeasures (List Ports.TextMeasureRequest)


initialModel : String -> Model
initialModel templateId =
    let
        defaultWidth =
            696

        defaultHeight =
            silverRatioHeight defaultWidth

        defaultVar =
            VariableObj
                { id = "obj-1"
                , name = "nombre"
                , properties = LO.defaultTextProperties
                }
    in
    { templateId = templateId
    , templateName = "Cargando..."
    , labelTypeId = "62"
    , labelWidth = defaultWidth
    , labelHeight = defaultHeight
    , cornerRadius = 0
    , rotate = False
    , content = [ defaultVar ]
    , selectedObjectId = Nothing
    , sampleValues = Dict.fromList [ ( "nombre", "Hello World!" ) ]
    , computedTexts = Dict.empty
    , nextId = 2
    , padding = 20
    }


applyTemplateDetail : TemplateDetail -> Model -> Model
applyTemplateDetail detail model =
    { model
        | templateName = detail.name
        , labelTypeId = detail.labelTypeId
        , labelWidth = detail.labelWidth
        , labelHeight = detail.labelHeight
        , cornerRadius = detail.cornerRadius
        , rotate = detail.rotate
        , padding = detail.padding
        , content = detail.content
        , nextId = detail.nextId
        , sampleValues = detail.sampleValues
        , computedTexts = Dict.empty
    }


requestAllMeasurements : Model -> OutMsg
requestAllMeasurements model =
    let
        displayWidth =
            if model.rotate then
                model.labelHeight

            else
                model.labelWidth

        displayHeight =
            if model.rotate then
                model.labelWidth

            else
                model.labelHeight

        requests =
            collectMeasurements model (toFloat displayWidth) (toFloat displayHeight) model.content
    in
    if List.isEmpty requests then
        NoOutMsg

    else
        RequestTextMeasures requests


collectMeasurements : Model -> Float -> Float -> List LabelObject -> List Ports.TextMeasureRequest
collectMeasurements model parentW parentH objects =
    List.concatMap (collectForObject model parentW parentH) objects


collectForObject : Model -> Float -> Float -> LabelObject -> List Ports.TextMeasureRequest
collectForObject model parentW parentH obj =
    case obj of
        Container r ->
            collectMeasurements model r.width r.height r.content

        TextObj r ->
            let
                maxWidth =
                    round (parentW - toFloat (model.padding * 2))

                maxFontSize =
                    round r.properties.fontSize

                minFontSize =
                    Basics.max 6 (maxFontSize // 3)
            in
            [ { requestId = r.id
              , text = r.content
              , fontFamily = r.properties.fontFamily
              , maxFontSize = maxFontSize
              , minFontSize = minFontSize
              , maxWidth = maxWidth
              , maxHeight = round (parentH - toFloat (model.padding * 2))
              }
            ]

        VariableObj r ->
            let
                sampleText =
                    Dict.get r.name model.sampleValues
                        |> Maybe.withDefault ("{{" ++ r.name ++ "}}")

                maxWidth =
                    round (parentW - toFloat (model.padding * 2))

                maxFontSize =
                    round r.properties.fontSize

                minFontSize =
                    Basics.max 6 (maxFontSize // 3)
            in
            [ { requestId = r.id
              , text = sampleText
              , fontFamily = r.properties.fontFamily
              , maxFontSize = maxFontSize
              , minFontSize = minFontSize
              , maxWidth = maxWidth
              , maxHeight = round (parentH - toFloat (model.padding * 2))
              }
            ]

        ImageObj _ ->
            []

        ShapeObj _ ->
            []
