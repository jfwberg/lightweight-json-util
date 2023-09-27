/**
 * DATA    : 1000 Accounts with 10 Contacts each
 * TEST 01 : Fetching the result.records[].Contacts.records[].Owner.Profile.Name
 *           for 10k records and add them to an Object Maps
 * VARIANT : Verbose type casting with temporary variables
 * RESULT  : AVG CPU Time : 982 (100 tests)
 *           Heap Size    : 72
 */
// Query configuration
String  query      = 'SELECT Name, (SELECT FirstName, LastName, Owner.Profile.Name FROM contacts LIMIT 10) FROM Account WHERE Name LIKE \'Demo Account - %\' ORDER BY Name ASC LIMIT 1000';
String  jsonString = getQueryResponseBody(query, false);

try{
    // Hold the CPU Time values for each test
    Integer[] CpuTimes = new Integer[]{};

    // Run the test X amount of times
    for (Integer i = 0; i < 10; i++) {
        
        // Data test set
        Set<Object> recordOwnerNames =  new Set<Object>{};
        
        // Register the starting limits
        Integer startCpuTime = Limits.getCpuTime();
        Integer startHeapSize= Limits.getHeapSize();

        // Iterate the account records
        for(Object accountRecord : (Object[]) ((Map<String,Object>) JSON.deserializeUntyped(jsonString)).get('records')){

            // Iterate the contact records
            for(Object contactRecord : (Object[]) ((Map<String,Object>) ((Map<String,Object>) accountRecord).get('Contacts')).get('records')  ){
    
                // Finally add the profile name to the list
                recordOwnerNames.add(((Map<String,Object>)((Map<String,Object>)((Map<String,Object>) contactRecord).get('Owner')).get('Profile')).get('Name'));
            }
        }

        Integer endCpuTime  = Limits.getCpuTime();
        Integer endHeapSize = Limits.getHeapSize();

        // Output the limits info for performance measuring
        System.debug('CPU Time : ' + (endCpuTime - startCpuTime));
        System.debug('Heap size: ' + (endHeapSize - startHeapSize));

        // Add the test data to the list
        CpuTimes.add(endCpuTime - startCpuTime);
    }

    Integer total=0;
    for (Integer i = 0, max = CpuTimes.size(); i < max; i++) {
        total+=CpuTimes[i];
    }
    System.debug((Decimal)total/CpuTimes.size());


}catch(System.JSONException e){
    System.debug('Invalid JSON detected: ' + e.getMessage());
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