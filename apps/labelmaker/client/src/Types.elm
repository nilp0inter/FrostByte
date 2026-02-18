module Types exposing
    ( Flags
    , Notification
    , NotificationType(..)
    , RemoteData(..)
    )


type alias Flags =
    { currentDate : String
    }


{-| Represents the state of data that is loaded asynchronously.
-}
type RemoteData a
    = NotAsked
    | Loading
    | Loaded a
    | Failed String


type NotificationType
    = Success
    | Info
    | Error


type alias Notification =
    { id : Int
    , message : String
    , notificationType : NotificationType
    }
