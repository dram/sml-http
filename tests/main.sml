structure Tests = struct

fun main _ =
    let
        val host = "www.example.com"
        val conn = Http.openConnection (host, 80)
    in
        (Http.send conn
         o Http.setRequestUri "/"
         o Http.setRequestMethod Http.MethodGet) (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; (Http.send conn
         o Http.setRequestUri "/foo"
         o Http.setRequestMethod Http.MethodDelete) (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; (Http.send conn
         o Http.setRequestUri "/foo"
         o Http.setRequestMethod Http.MethodPost
         o Http.setRequestHeader ("content-type", "application/json")
         o Http.setRequestBody (Byte.stringToBytes "{}"))
            (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; (Http.send conn
         o Http.setRequestUri "/foo"
         o Http.setRequestMethod Http.MethodPut
         o Http.setRequestHeader ("content-type", "application/json")
         o Http.setRequestBody (Byte.stringToBytes "{1, 2}"))
            (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; Http.closeConnection conn

      ; 0
    end
end
