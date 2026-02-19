module Page.Templates.Types exposing
    ( Model
    , Msg(..)
    , OutMsg(..)
    , initialModel
    )

import Api.Decoders exposing (TemplateSummary)
import Http
import Types exposing (RemoteData(..))


type alias Model =
    { templates : RemoteData (List TemplateSummary)
    }


type Msg
    = GotTemplates (Result Http.Error (List TemplateSummary))
    | CreateTemplate
    | GotCreateResult (Result Http.Error String)
    | DeleteTemplate String
    | GotDeleteResult String (Result Http.Error ())


type OutMsg
    = NoOutMsg
    | NavigateTo String


initialModel : Model
initialModel =
    { templates = Loading
    }
