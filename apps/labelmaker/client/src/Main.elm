module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Components
import Html exposing (..)
import Html.Attributes exposing (class)
import Page.Home as Home
import Page.Home.Types as HomeTypes
import Page.NotFound as NotFound
import Process
import Route exposing (Route(..))
import Task
import Types exposing (..)
import Url



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    , currentDate : String
    , page : Page
    , notification : Maybe Notification
    , notificationIdCounter : Int
    }


type Page
    = HomePage Home.Model
    | NotFoundPage


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        route =
            Route.parseUrl url

        model =
            { key = key
            , url = url
            , route = route
            , currentDate = flags.currentDate
            , page = NotFoundPage
            , notification = Nothing
            , notificationIdCounter = 0
            }
    in
    initPage route model



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Home.Msg
    | DismissNotification Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                route =
                    Route.parseUrl url

                newModel =
                    { model | url = url, route = route }
            in
            initPage route newModel

        HomeMsg subMsg ->
            case model.page of
                HomePage pageModel ->
                    let
                        ( newPageModel, pageCmd, outMsg ) =
                            Home.update subMsg pageModel

                        newModel =
                            { model | page = HomePage newPageModel }
                    in
                    handleHomeOutMsg outMsg newModel pageCmd

                _ ->
                    ( model, Cmd.none )

        DismissNotification notificationId ->
            case model.notification of
                Just notification ->
                    if notification.id == notificationId then
                        ( { model | notification = Nothing }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


initPage : Route -> Model -> ( Model, Cmd Msg )
initPage route model =
    case route of
        Home ->
            let
                ( pageModel, pageCmd ) =
                    Home.init
            in
            ( { model | page = HomePage pageModel }
            , Cmd.map HomeMsg pageCmd
            )

        NotFound ->
            ( { model | page = NotFoundPage }, Cmd.none )


setNotification : String -> NotificationType -> Model -> ( Model, Cmd Msg )
setNotification message notificationType model =
    let
        newId =
            model.notificationIdCounter + 1

        notification =
            { id = newId
            , message = message
            , notificationType = notificationType
            }

        dismissCmd =
            case notificationType of
                Error ->
                    Cmd.none

                _ ->
                    Process.sleep 5000
                        |> Task.perform (\_ -> DismissNotification newId)
    in
    ( { model
        | notification = Just notification
        , notificationIdCounter = newId
      }
    , dismissCmd
    )


handleHomeOutMsg : Home.OutMsg -> Model -> Cmd Home.Msg -> ( Model, Cmd Msg )
handleHomeOutMsg outMsg model pageCmd =
    case outMsg of
        HomeTypes.NoOutMsg ->
            ( model, Cmd.map HomeMsg pageCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "LabelMaker"
    , body =
        [ div [ class "min-h-screen bg-gray-100" ]
            [ Components.viewHeader model.route
            , Components.viewNotification model.notification DismissNotification
            , main_ [ class "container mx-auto px-4 py-8" ]
                [ viewPage model
                ]
            ]
        ]
    }


viewPage : Model -> Html Msg
viewPage model =
    case model.page of
        HomePage pageModel ->
            Html.map HomeMsg (Home.view pageModel)

        NotFoundPage ->
            NotFound.view
