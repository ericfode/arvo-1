:: Three ways we interactg with this app
:: 1. .^(%gx /=gh=/endpoint)
:: 2. [%peer [our %gh] /endpoint]
:: 3. :gh &gh-poke %post /gists json-data


::  This is a driver for the Github API v3.
::
::  You can interact with this in a few different ways:
::
::    - .^(%gx /=gh=/read{/endpoint}) or subscribe to
::      /scry/x/read{/endpoint} for authenticated reads.
::
::    - subscribe to /scry/x/listen/{owner}/{repo}/{events...}
::      for webhook-powered event notifications.  For event list,
::      see https://developer.github.com/webhooks/.
::
::  See the %github app for example usage.
::
/?  314
/-  rfc, gmail-label
/+  http
::::
/=  rfctext  /:  /%/rfc  /txt/
::
//  /%/split
::/-  gmail
::  /ape/gh/split.hoon defines ++split, which splits a request
::  at the end of the longest possible endpoint.
::

=>  |%                              :: => only used for indentation
    ++  move  (pair bone card)
    ++  subscription-result
      $%  {$arch arch}
          {$json json}      
          {$null $~}
      ==
    ++  card
      $%  {$diff subscription-result}
          {$hiss wire {$~ $~} $httr {$hiss hiss}}
      ==
    --
::
|_  {hid/bowl count/@ web-hooks/(map @t {id/@t listeners/(set bone)})}

::  We can't actually give the response to pretty much anything
::  without blocking, so we just block unconditionally.
::
++  peek
  |=  {ren/@tas pax/path}
  ^-  (unit (unit (pair mark *)))
  ~
::
++  peer-scry
  |=  pax/path
  ^-  {(list move) _+>.$}
  ?>  ?=({care ^} pax)                ::  assert %u
  =>  (help i.pax i.t.pax t.t.pax)
  =>  scry
  %=  make-move
    count  +(count)
  ==
::
++  poke-gmail-req
  |=  $:  method/meth  endpoint/path  quy/quay
          ::mes/$?(message:rfc )
          label-req:gmail-label
      ==
  ^-  {(list move) _+>.$}
  ?>  ?=(valid-get-endpoint endpoint)
  :_  +>.$  :_  ~
  ^-  move
  :*  ost.hid  %hiss  /poke/[method]  `~  %httr  %hiss
      ^-  purl
      :+  [& ~ [%& /com/googleapis/www]]
        [~ gmail+v1+users+me+`valid-get-endpoint`endpoint]
      `quay`[[%alt %json] ~] 
  ::
      :+  method  `math`(malt ~[content-type+['application/json']~])
      ::=+  hoon-json-object=(joba %raw s/(message-to-rfc822:rfc mes))
      ::=+  request-body=(tact (pojo hoon-json-object))
      ::(some request-body)
      ~
      ::(some (pojo label-req-to-json:gmail-label label-req:gmail-label ~)) XX
  ==
::
::  HTTP response.  We make sure the response is good, then
::  produce the result (as JSON) to whoever sent the request.
::

++  sigh-httr
  |=  {wir/wire res/httr}
  ^-  {(list move) _+>.$}
  ?.  ?=({care @ @ @ *} wir)
  ::  pokes don't return anything
  ~&  poke+res
    [~ +>.$]
  =+  arg=(path (cue (slav %uv i.t.t.wir)))
  :_  +>.$  :_  ~
  :+  ost.hid  %diff
  ?+  i.wir  null+~
      $x
    ?~  r.res
      json+(jobe err+s+%empty-response code+(jone p.res) ~)
    =+  jon=(rush q.u.r.res apex:poja)
    ?~  jon
      json+(jobe err+s+%bad-json code+(jone p.res) body+s+q.u.r.res ~)
    ?.  =(2 (div p.res 100))
      json+(jobe err+s+%request-rejected code+(jone p.res) msg+u.jon ~)
    ::
    ::  Once we know we have good data, we drill into the JSON
    ::  to find the specific piece of data referred to by 'arg'
    ::
  |-  ^-  subscription-result
  ?~  arg
   [%json `json`u.jon]
  =+  dir=((om:jo some) u.jon)
  ?~  dir  json+(jobe err+s+%no-children ~)
  =+  new-jon=(~(get by u.dir) i.arg)
  `subscription-result`$(arg t.arg, u.jon ?~(new-jon ~ u.new-jon))
           ::  redo with next argument
  ::
    $y
  ?~  r.res 
    ~&  [err+s+%empty-response code+(jone p.res)]
      arch+*arch
  =+  jon=(rush q.u.r.res apex:poja)
  ?~  jon
    ~&  [err+s+%bad-json code+(jone p.res) body+s+q.u.r.res]
    arch+*arch
  ?.  =(2 (div p.res 100))
    ~&  [err+s+%request-rejected code+(jone p.res) msg+u.jon]
    arch+*arch
    ::
    ::  Once we know we have good data, we drill into the JSON
    ::  to find the specific piece of data referred to by 'arg'
    ::
    |-  ^-  subscription-result
    =+  dir=((om:jo some) u.jon)
    ?~  dir
      [%arch `(shax (jam u.jon)) ~]
    ?~  arg
      [%arch `(shax (jam u.jon)) (~(run by u.dir) $~)]
    =+  new-jon=(~(get by u.dir) i.arg)
    $(arg t.arg, u.jon ?~(new-jon ~ u.new-jon))
  ==

++  sigh
  |=  a/*
  ~&  a+a
  :_  +>.$  ~
::
++  help
  |=  {ren/care style/@tas pax/path}
  ~&  pax
  =^  query  pax
    =+  xap=(flop pax)
    ?~  xap  [~ ~]
    =+  query=(rush i.xap ;~(pfix wut yquy:urlp))
    ?~  query  [~ pax]
    [u.query (flop t.xap)]
  =^  arg  pax  [+ -]:(split pax)
  ~&  [pax=pax arg=arg query=query]
  =|  mow/(list move)
  |%
  ::  Resolve core
  ::
  ++  make-move
    ^-  {(list move) _+>.$}
    [(flop mow) +>.$]
    ::
  ++  endpoint-to-purl
    |=  endpoint/path
    ^-  purl
    %+  scan 
      "https://www.googleapis.com/gmail/v1/users/me{<`path`endpoint>}"
    auri:epur
    ::  Send an HTTP req
  ++  send-http
    |=  hiz/hiss
    ^+  +>
    =+  wir=`wire`[ren (scot %ud count) (scot %uv (jam arg)) style pax]
    =+  new-move=[ost.hid %hiss wir `~ %httr [%hiss hiz]]
    +>.$(mow [new-move mow])
  ::
  ++  scry
    ^+  .
    ?+  style  ~|(%invalid-style !!)
      $read   read
::        $listen listen
    ==
  :: Standard GET request
  ++  read  (send-http (endpoint-to-purl pax) %get ~ ~)
  
  ::  Subscription request
::    ++  listen
::      ^+  .
::      =+  events=?>(?=([@ @ *] pax) t.t.pax)
::      |-  ^+  +>.$
::      ?~  events
::        +>.$
::      ?:  (~(has by web-hooks) i.events)                ::  if hook exists
::        =.  +>.$  (update-hook i.events) 
::        $(events t.events)
::      =.  +>.$  (create-hook i.events)
::      $(events t.events)
    ::
  --
--        
  


  
  




