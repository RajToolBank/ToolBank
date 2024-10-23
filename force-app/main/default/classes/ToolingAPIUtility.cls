public class ToolingAPIUtility {
    
    public static HttpRequest createHttpRequest(String path, String reqMethod){
        String  baseUrl = URL.getOrgDomainUrl().toExternalForm()+'/services/data/v58.0/tooling';
        HttpRequest request = new HttpRequest();
        request.setEndpoint(baseUrl + path);
        request.setMethod(reqMethod);
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');

        return request;
    }
}