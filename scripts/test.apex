// String values or number values are not supported

// Query configuration
String  query  = 'SELECT Id, Name, Owner.Name, Owner.Profile.Name, ';
        query +='(SELECT AccountId, FirstName, LastName, Owner.Profile.Name FROM contacts LIMIT 3), ';
        query +='(SELECT AccountId, Name, StageName, CloseDate, Owner.Profile.Name FROM opportunities LIMIT 3) ';
        query +='FROM Account WHERE Name LIKE \'Demo Account - %\' ORDER BY Name ASC LIMIT 1';

Boolean isTooling         = false;
String  jsonString        = getQueryResponseBody(query, isTooling);

// utl.JSN.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(jsonString))
//jsonString = '[null,true,{"Name" : "Test Acc1", "records" : ["hzh","kiwi",{"wt" : "f"},{"aa" : "faa","wata" : {"fa": "ak"}}]}, {"Name":"Test Acc2", "Owner" : {"Name" : "Justus", "Profile" : {"Name" : "System Administrator"}}}]';

//jsonString = '[1,2,3,4,5, [true,false]]';
//(Object[]) JSON.deserializeUntyped(jsonString);

try{
    utl.JsnTbl table = new utl.JsnTbl()
        .setKeyValuePairTable(false)
        .setIncludeChildLists(true)
        .setAddChildListsAsTables(true)
        .setPropertyFilter(new Set<String>{'attributes', 'totalSize' , 'done'})
        .create(utl.Jsn.getObjectList('records',(Map<String,Object>) JSON.deserializeUntyped(jsonString)));
        

    //System.debug(JSON.serializePretty(table.getColumns()));
    System.debug(JSON.serializePretty(table));

}catch(Exception e){
    if(       e.getTypeName() == String.valueOf(System.JSONException.class)){
        System.debug('Invalid JSON Exception: ' + e.getMessage()); 
    }else if (e.getTypeName() == String.valueOf(utl.Jsn.JsonUtilException.class)){
        System.debug('JSON Util Exeption: ' + e.getMessage()); 
    }else {
        System.debug('Unknown Exeption: ' + e.getMessage());
    }
}








    /**
     * Method for calling a Salesforce Rest API
     */
    private static String getQueryResponseBody(String query, Boolean isTooling){
        
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v58.0/'+ (IsTooling ? 'tooling/' : '' ) +'query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');
        httpRequest.setHeader('Authorization', 'Bearer ' + userInfo.getSessionId());
        HttpResponse response =  http.send(httpRequest);
        
        switch on response.getStatusCode() {
            // Success responses
            when 200 {
                return response.getBody();
            }
            when 400, 401, 404, 405 {
                handleSalesforceErrorResponse(response.getBody());
            }
            when else{
                handleUnknownResponse(response.getBody());
            }
        }
        return null;
    }


    /**
     * Method to throw an exception containing the Salesforce API Error Message 
     */
    private static void handleSalesforceErrorResponse(String responseBody){
        for( Object record : (Object[]) JSON.deserializeUntyped(responseBody)){
            throw new StringException((String)((Map<String, Object>) record).get('message'));
        }
    }


    private static void handleUnknownResponse(String responseBody){
        throw new StringException('Unknown error response: ' + responseBody);
    }