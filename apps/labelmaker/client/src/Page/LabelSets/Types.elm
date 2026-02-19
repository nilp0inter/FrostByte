module Page.LabelSets.Types exposing
    ( Model
    , Msg(..)
    , OutMsg(..)
    , initialModel
    )

import Api.Decoders exposing (LabelSetSummary, TemplateSummary)
import Http
import Types exposing (RemoteData(..))


type alias Model =
    { labelsets : RemoteData (List LabelSetSummary)
    , templates : RemoteData (List TemplateSummary)
    , selectedTemplateId : Maybe String
    , newName : String
    }


type Msg
    = GotLabelSets (Result Http.Error (List LabelSetSummary))
    | GotTemplates (Result Http.Error (List TemplateSummary))
    | SelectTemplate String
    | UpdateNewName String
    | CreateLabelSet
    | GotCreateResult (Result Http.Error String)
    | DeleteLabelSet String
    | GotDeleteResult String (Result Http.Error ())


type OutMsg
    = NoOutMsg
    | NavigateTo String


initialModel : Model
initialModel =
    { labelsets = Loading
    , templates = Loading
    , selectedTemplateId = Nothing
    , newName = ""
    }
