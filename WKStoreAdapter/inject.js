
console.log = (function(oriLogFunc){
    return function(str){
        window.webkit.messageHandlers.jsLogger.postMessage(str);
        oriLogFunc.call(console, str);
    }
})(console.log);



function failure( value ) {
      alert("did fail");
}

function logResult( response )
{
    console.log("got a response");
    console.log( response );
}


function onloadFn() {
  console.log("------ onloadFn, response is:  ----");
  console.log(this.responseText);
  console.log("------ end of response ------")
}


function mySend( body ) {
    console.log( "mySend" );
    request = this;
  console.log( this._verb );
  console.log( this._uri );
  theRequest = [ this._verb , this._uri, body ];
  promise = window.webkit.messageHandlers.request.postMessage( theRequest );
    myShim = function( value ) {
        console.log(value);
        
        Object.defineProperty(request, 'responseText', {
            value: value.Body,
            writable: true
        });
        
        Object.defineProperty(request, 'status', {
            value: 200,
            writable: true
        });
        Object.defineProperty(request, 'responseType', {
            value: "string",
            writable: true
        });
        Object.defineProperty(request, 'response', {
            value: value.Body,
            writable: true
        });

        console.log(request.responseText);
        console.log("will call request.onload()");
        request.onload();
        console.log("did call request.onload()");
    };
  promise.then( myShim , failure);
  console.log( "done with mySend" );

}

function myOpen( verb, uri ) {
    console.log( "myOpen" );
    console.log( verb );
    console.log( uri );

   this._verb = verb;
   this._uri = uri;
    this.oldOpen( verb, uri );
    console.log( "done myOpen" );
}

function xmlRequest( verb, path , data  ) {
    const req = new XMLHttpRequest();
//    req.send = mySend;
//    req.open = myOpen;
    req.onload = onloadFn;
    console.log( onloadFn );
    req.open(verb, path);
    console.log( req.request_method );
    console.log( Object.keys(req));
    req.send();
}

XMLHttpRequest.prototype.oldOpen = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.oldSend = XMLHttpRequest.prototype.send;

XMLHttpRequest.prototype.open = myOpen;
XMLHttpRequest.prototype.send = mySend;


// xmlRequest( "GET", "site:/posts/","Body msg" );

