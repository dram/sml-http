structure Tests = struct

fun main _ =
    let
        val host = "www.example.com"
        val conn = Http.openConnection (host, 80)
    in
        (Http.send conn
         o Http.setRequestUri "/"
         o Http.setRequestMethod Http.Method.Get) (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; (Http.send conn
         o Http.setRequestUri "/foo"
         o Http.setRequestMethod Http.Method.Delete) (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; (Http.send conn
         o Http.setRequestUri "/foo"
         o Http.setRequestMethod Http.Method.Post
         o Http.setRequestHeader ("content-type", "application/json")
         o Http.setRequestBody (Byte.stringToBytes "{}"))
            (Http.newRequest host)

      ; (print
         o Byte.bytesToString
         o Http.getResponseBody
         o Http.receive) conn

      ; (Http.send conn
         o Http.setRequestUri "/foo"
         o Http.setRequestMethod Http.Method.Put
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

val _ = SMLofNJ.exportFn ("main", main)

end
