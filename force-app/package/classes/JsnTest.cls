@IsTest
private with sharing class JsnTest {

    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Permission set to test with
    private static final String PERMISSION_SET_NAME = 'Lightweight_JSON_Util';

    // Create a test user
    private static final User TST_USER = utl.Tst.createRunAsUser(
        utl.Tst.MINIMUM_ACCESS_PROFILE,
        PERMISSION_SET_NAME
    );

    // Get the test JSON body from the static resource
    private static final String ACC_CON_JSON = utl.Tst.getStaticResourceBody('Lightweight_JSON_Util_Apex_Unit_Test_Data');


    /** **************************************************************************************************** **
     **                                            TEST METHODS                                              **
     ** **************************************************************************************************** **/
    /**
     * @description Testing of the getObject Method
     */
     @IsTest
    static void testGetObject(){

        // Variables to assert against
        Map<String,Object> record;
        String name;
        String profileName;
        Exception invalidPathException;
        Object nullObject;
        Object nestedNullObject;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){

            // Get the first sample record
            record      = (Map<String,Object>) Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(ACC_CON_JSON))[0];
            name        = (String) Jsn.getObject('Name',record);
            profileName = (String) Jsn.getObject('Owner.Profile.Name',record);

            // Test the exception message
            try{
                Jsn.getObject('Owner.invalidField',record);
            }catch(Exception e){
                invalidPathException = e;
            }

            // Test return null with exceptions turned off
            Jsn.setThrowException(false);

            // Test that get methods return null
            nullObject = Jsn.getObject('invalidField', record);
            nestedNullObject =  Jsn.getObject('invalidField.invalidField',record);
        }
        Test.stopTest();

        // Single level deep
        Assert.areEqual(
            'Demo Account - 0001',
            name,
            'Unexpected Object value'
        );

        // Multiple levels deep
        Assert.areEqual(
            'System Administrator',
            profileName,
            'Unexpected Object value'
        );

        // Test exception
        utl.Tst.assertExceptionMessage(Jsn.PATH_ERROR_MSG, 'invalidField', invalidPathException);

        // Test invalid field without exception top level
        Assert.areEqual(
            null,
            nullObject,
            'Unexpected Object value'
        );

        // Test invalid field without exception, multiple levels deep
        Assert.areEqual(
            null,
            nestedNullObject,
            'Unexpected Object value'
        );
    }


    @IsTest
    static void testGetObjectMap(){

        // Variables to assert against
        Map<String,Object> accRecord;
        Map<String,Object> contactMap;
        Map<String,Object> profileMap;
        Object nullObject;
        Object nestedNullObject;

        Test.startTest();
        System.runAs(TST_USER){

            // Get the account records, top level
            accRecord  = (Map<String,Object>)((Object[]) Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(ACC_CON_JSON)))[0];
            contactMap = Jsn.getObjectMap('Contacts', (Map<String,Object>) accRecord);
            profileMap = Jsn.getObjectMap('Owner.Profile', (Map<String,Object>) accRecord);

            // Test return null with exceptions turned off
            Jsn.setThrowException(false);

            // Test null objects
            nullObject       = Jsn.getObjectMap('invalidField', (Map<String,Object>) accRecord);
            nestedNullObject = Jsn.getObjectMap('invalidField.invalidField',(Map<String,Object>) accRecord);
        }
        Test.stopTest();

        // Assert account record, single level
        Assert.areEqual(
            (Map<String,Object>) accRecord.get('Contacts'),
            contactMap,
            'Unexpected contacts map'
        );

        // Assert account record, multiple levels
        Assert.areEqual(
            (Map<String,Object>)((Map<String,Object>) accRecord.get('Owner')).get('Profile'),
            profileMap,
            'Unexpected profile map'
        );


        // Test invalid field without exception top level
        Assert.areEqual(
            null,
            nullObject,
            'Unexpected Object value'
        );

        // Test invalid field without exception, multiple levels deep
        Assert.areEqual(
            null,
            nestedNullObject,
            'Unexpected Object value'
        );
    }


    @IsTest
    static void testGetObjectList(){

        // Variables to assert against
        Object[] accRecords;
        Object[] conRecords;
        Object nullObject;
        Object nestedNullObject;

        Test.startTest();
        System.runAs(TST_USER){

            // Get the account records, top level
            accRecords = (Object[]) Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(ACC_CON_JSON));

            // Get the contact records, multiple levels deep
            conRecords = (Object[]) Jsn.getObjectList('Contacts.records', (Map<String,Object>) accRecords[0]);

            // Test return null with exceptions turned off
            Jsn.setThrowException(false);

            // Test null objects
            nullObject       = Jsn.getObjectList('invalidField', (Map<String,Object>) accRecords[0]);
            nestedNullObject = Jsn.getObjectList('invalidField.invalidField',(Map<String,Object>) accRecords[0]);
        }
        Test.stopTest();

        // Assert account records
        Assert.areEqual(
            10,
            accRecords.size(),
            'Unexpected number of account records'
        );

        // Assert contact records
        Assert.areEqual(
            3,
            conRecords.size(),
            'Unexpected number of contact records'
        );

        // Test invalid field without exception top level
        Assert.areEqual(
            null,
            nullObject,
            'Unexpected Object value'
        );

        // Test invalid field without exception, multiple levels deep
        Assert.areEqual(
            null,
            nestedNullObject,
            'Unexpected Object value'
        );
    }
}