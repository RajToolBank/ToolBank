global class ToolingAPIMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndpoint();
        if (endpoint.contains('/query/?q=')) {
            if (endpoint.contains('DebugLevel')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"records":[{"Id":"dummyDebugLevelId"}]}');
                res.setStatusCode(200);
            } else if (endpoint.contains('TraceFlag')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"records":[{"Id":"dummyTraceFlagId"}]}');
                res.setStatusCode(200);
            }
        } else if (endpoint.contains('/sobjects/TraceFlag')) {
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"dummyTraceFlagId"}');
            res.setStatusCode(201);
        } else if (endpoint.contains('/sobjects/traceflag/')) {
            res.setStatusCode(204);
        }
        return res;
    }
}