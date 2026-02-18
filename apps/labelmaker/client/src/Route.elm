module Route exposing
    ( Route(..)
    , parseUrl
    , routeParser
    )

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)


type Route
    = Home
    | NotFound


parseUrl : Url -> Route
parseUrl url =
    Maybe.withDefault NotFound (Parser.parse routeParser url)


routeParser : Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        ]
