module Api exposing
    ( createTemplate
    , deleteTemplate
    , emitEvent
    , fetchTemplateDetail
    , fetchTemplateList
    )

import Api.Decoders as Decoders
import Api.Encoders as Encoders
import Http
import Json.Decode as Decode
import Json.Encode as Encode


fetchTemplateList : (Result Http.Error (List Decoders.TemplateSummary) -> msg) -> Cmd msg
fetchTemplateList toMsg =
    Http.get
        { url = "/api/db/template_list"
        , expect = Http.expectJson toMsg (Decode.list Decoders.templateSummaryDecoder)
        }


fetchTemplateDetail : String -> (Result Http.Error (Maybe Decoders.TemplateDetail) -> msg) -> Cmd msg
fetchTemplateDetail templateId toMsg =
    Http.get
        { url = "/api/db/template_detail?id=eq." ++ templateId
        , expect =
            Http.expectJson toMsg
                (Decode.list Decoders.templateDetailDecoder
                    |> Decode.map List.head
                )
        }


createTemplate : String -> (Result Http.Error String -> msg) -> Cmd msg
createTemplate name toMsg =
    Http.post
        { url = "/api/db/rpc/create_template"
        , body = Http.jsonBody (Encode.object [ ( "p_name", Encode.string name ) ])
        , expect = Http.expectJson toMsg Decoders.createTemplateResponseDecoder
        }


emitEvent : String -> Encode.Value -> (Result Http.Error () -> msg) -> Cmd msg
emitEvent eventType payload toMsg =
    Http.post
        { url = "/api/db/event"
        , body = Http.jsonBody (Encoders.encodeEvent eventType payload)
        , expect = Http.expectWhatever toMsg
        }


deleteTemplate : String -> (Result Http.Error () -> msg) -> Cmd msg
deleteTemplate templateId toMsg =
    emitEvent "template_deleted"
        (Encode.object [ ( "template_id", Encode.string templateId ) ])
        toMsg
