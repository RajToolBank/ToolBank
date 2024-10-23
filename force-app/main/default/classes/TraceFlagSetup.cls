public class TraceFlagSetup {
    public static void setupDebugLogs(List<String> TracedEntityIdList, String logtype) {
        
        

        // Get the Debug Level Id to define the new Trace Flag
        List<object>  debugLevelsList = queryRecords('SELECT Id FROM DebugLevel WHERE DeveloperName = \'Finest\' LIMIT 1');
        Map<String,Object> debugLevelrecord = (Map<String,Object>)debugLevelsList.get(0);
        String debugLevelId = (String)debugLevelrecord.get('Id');
        System.debug('DebugLevelId :: '+debugLevelId);

        String tracEntityIdString = '(\''+String.join(TracedEntityIdList,'\',\'')+'\')';
        //get existing trace flags
        List<object> traceFlagList = queryRecords('SELECT Id FROM TraceFlag WHERE TracedEntityId IN '+tracEntityIdString);
        if(!traceFlagList.isEmpty()){
            for(Object traceFlag: traceFlagList){
                Map<String,Object> traceFlagrecord = (Map<String,Object>)traceFlag;
                system.debug('traceFlagrecord ::'+ traceFlagrecord);
                String traceFlagId = (String)traceFlagrecord.get('Id');
                // Delete the existing Trace Flags
                deleteTraceFlag(traceFlagId);
            }
        }
        if(debugLevelId != null){
            for(String TracedEntityId: TracedEntityIdList){
                
                
                // Create Trace Flag for each user
                createTraceFlag(TracedEntityId, debugLevelId,logtype);
            }
        }
    }

    static void createTraceFlag(String TracedEntityId, String debugLevelId, String logType) {
        // Define the TraceFlag
        TraceFlag traceFlag = new TraceFlag();
        traceFlag.LogType = logType;
        traceFlag.TracedEntityId = TracedEntityId;
        traceFlag.DebugLevelId = debugLevelId;
        traceFlag.StartDate = DateTime.now();
        traceFlag.ExpirationDate = DateTime.now().addDays(1);

        // Set the payload
        String payload = JSON.serialize(traceFlag);
        String Path= '/sobjects/TraceFlag';
        HttpRequest request = ToolingAPIUtility.createHttpRequest(Path,'POST');
        request.setBody(payload);
       
        system.debug('requestBody :: '+payload);

        Http http = new Http();
        HttpResponse response = http.send(request);
        String result = response.getBody();
        System.debug(result);

    }
    static List<Object> queryRecords(String query){
        String path= '/query/?q=';
        path = path+EncodingUtil.urlEncode(query, 'UTF-8');
        HttpRequest request = ToolingAPIUtility.createHttpRequest(Path,'GET');
        system.debug('requestBody :: '+request.getEndpoint());
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        String result = response.getBody();
        System.debug(result);

        if(response.getStatusCode() == 200){
            Map<String, Object> queryResult = (Map<String, Object>)JSON.deserializeUntyped(result);
            List<Object> records = (List<Object>)queryResult.get('records');
            return records;
        }else return null;
    }

    // 
    // pass Id to delete trace flags
    public static void deleteTraceFlag(String traceFlagId){
        String path= '/sobjects/traceflag/'+traceFlagId;
        HttpRequest request = ToolingAPIUtility.createHttpRequest(Path,'DELETE');
        system.debug('requestBody :: '+request.getEndpoint());
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        String result = response.getBody();
        System.debug(result);
    }

    public class TraceFlag{
        public String LogType;
        public String TracedEntityId;
        public String DebugLevelId;
        public Datetime StartDate;
        public Datetime ExpirationDate;
        public String Id;
    }

    class DebugLevel{ 
        String DeveloperName;
        String MasterLabel ;
        String ApexCode ;
        String Database ;
        String Validation ;
        String Visualforce ;
        String Workflow ;
        String Id;
    }
}