/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           May 2023
 * @copyright      (c) 2023 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test Class for the JsnTbl class
 */
@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
private with sharing class JsnTblTest {

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


    /** **************************************************************************************************** **
     **                                            TEST METHODS                                              **
     ** **************************************************************************************************** **/
    @IsTest
    static void testDataTableWithNestedLists(){
        
        // Table to assert against
        JsnTbl table;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){

            table = new JsnTbl()
                .setAttributeFilter(new Set<String>{'ignore'})
                .setListNameFilter(new Set<String>{'records'})
                .create(JSON.deserializeUntyped('[[1,2,3],[1,2,3],[1,2,3],{"keyVal" : "b", "ignore": "ignore", "records" : ["rec1","rec2"]}]'))
                .updateColumnNames(new Set<String>{'Column A', 'Column B', 'Column C'})
            ;
        }
        Test.stopTest();

        // There should be 4 columns
        Assert.areEqual(4,  table.getColumnNames().size());
        Assert.areEqual(4,  table.getColumnNameIndexMap().size());

        // There should 5 rows of data
        Assert.areEqual(5, table.getKeyValueData().size());

        // There should 5 rows of data
        Assert.areEqual(5, table.getIndexedData().size());

        // There should 6 rows of data
        Assert.areEqual(6, table.getCsvData().size());

        // There should be 3 custom headers and 1 standard
        Assert.areEqual('Column A', table.getColumnNames()[0]);
        Assert.areEqual('Column B', table.getColumnNames()[1]);
        Assert.areEqual('Column C', table.getColumnNames()[2]);
        Assert.areEqual('keyVal',   table.getColumnNames()[3]);

        // Check if the console string is as expected
        Assert.areEqual(
            'Column A,Column B,Column C,keyVal\n1,2,3,\n1,2,3,\n1,2,3,\nrec1,rec2,,\n,,,b',
            table.getCsvString()
        );

        // Check if the console string is as expected
        Assert.areEqual(
            'COLUMN A  COLUMN B  COLUMN C  KEYVAL  \n1         2         3                 \n1         2         3                 \n1         2         3                 \nrec1      rec2                        \n                              b       ',
            table.getConsoleString()
        );
    }


    @IsTest
    static void testDataTableWithNestedObjects(){
        
        // Table to assert against
        JsnTbl table;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){

            table = new JsnTbl()
                .create(JSON.deserializeUntyped('{"obj1" : {"a" : 1, "b" : 2}, "obj2" : {"y" : 25, "z" : 26, "e" : {"f" : 6} }, "obj3" : [{"k1":"v1"},{"k2":"v2"},{"k3":"v3"},[1,2,3]]}'))
            ;
        }
        Test.stopTest();

        // There should be 11 columns
        Assert.areEqual(11,  table.getColumnNames().size());
        Assert.areEqual(11,  table.getColumnNameIndexMap().size());

        // There should 6 rows of data
        Assert.areEqual(6, table.getKeyValueData().size());
    }


    @IsTest
    static void testDataTableWithSingleParentObject(){
        
        // Table to assert against
        JsnTbl table;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){
            table = new JsnTbl()
                .create(JSON.deserializeUntyped('19'))
            ;
        }
        Test.stopTest();

        // There should be 1 columns
        Assert.areEqual(1,  table.getColumnNames().size());
        Assert.areEqual(1,  table.getColumnNameIndexMap().size());

        // There should 1 rows of data
        Assert.areEqual(1, table.getKeyValueData().size());
        
        // There should be 3 custom headers and 1 standard
        Assert.areEqual('0', table.getColumnNames()[0]);
    }


    @IsTest
    static void testAddColumn(){
        
        // Table to assert against
        JsnTbl table;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){

            table = new JsnTbl()
                .create(JSON.deserializeUntyped('["a","b","c"]'))
                .upsertColumnData('start',new Object[]{1},0)
                .upsertColumnData('middle',new Object[]{1},2)
                .upsertColumnData('end',new Object[]{1},null)
                .upsertColumnData(null,new Object[]{1},10)
                .upsertColumnData('null',null,10)
            ;
        }
        Test.stopTest();

        // There should be 1 columns
        Assert.areEqual(6,  table.getColumnNames().size());
        Assert.areEqual(6,  table.getColumnNameIndexMap().size());

        // There should 1 rows of data
        Assert.areEqual(1, table.getKeyValueData().size());

        // Check everything is where it should be
        Assert.areEqual(0, table.getColumnNameIndexMap().get('start'));
        Assert.areEqual(1, table.getColumnNameIndexMap().get('0'));
        Assert.areEqual(2, table.getColumnNameIndexMap().get('middle'));
        Assert.areEqual(3, table.getColumnNameIndexMap().get('1'));
        Assert.areEqual(4, table.getColumnNameIndexMap().get('2'));
        Assert.areEqual(5, table.getColumnNameIndexMap().get('end'));
    }

    @IsTest
    static void testManipulation(){
        
        // Table to assert against
        JsnTbl table;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){

            table = new JsnTbl()
                .create(JSON.deserializeUntyped('[{"key1" : "1.1","key2" : "1.2","key3" : "1.3" },{"key1" : "2.1","key2" : "2.2" }]'))
                .fillColumnsWithNullValue(new Set<String>{'key3'})
                .concatColumnData(new Set<String>{'key1','key2'}, '_', 'CONCAT_COL', 10)
                .deleteColumns(new Set<String>{'key1'})
                .updateColumnNames(new Map<String,String>{
                    'key2' => 'Column01',
                    'key3' => 'Column02'
                })
                // Validate the input for coverage
                .updateColumnNames(new Map<String,String>())
                .updateColumnNames(new Set<String>())
            ;
        }
        Test.stopTest();

        // There should be 3 columns
        Assert.areEqual(3,  table.getColumnNames().size());
        Assert.areEqual(3,  table.getColumnNameIndexMap().size());

        // There should 2 rows of data
        Assert.areEqual(2, table.getKeyValueData().size());

        // Validate the column names
        Assert.areEqual(table.getColumnNames(), new String[]{'Column01','Column02','CONCAT_COL'});
    }


    @IsTest
    static void testColumnFills(){
        
        // Table to assert against
        JsnTbl table;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){

            table = new JsnTbl()
                .create(JSON.deserializeUntyped('[{"key1" : "1.1","key2" : "1.2","key3" : "1.3" },{"key1" : "2.1","key2" : "2.2" },{"key1" : "3.1"}]'))
                .fillColumnsWithNullValue(new Set<String>{'key2','key3'})
                .fillNullValuesWithCustomValue(new Map<String,String>{'key2' => 'CUSTOM_VALUE'})
		        .fillNullValuesWithColumnValue(new Map<String,String>{'key3' => 'key1'})
            ;
        }
        Test.stopTest();

        // There should be 3 columns
        Assert.areEqual(3,  table.getColumnNames().size());
        Assert.areEqual(3,  table.getColumnNameIndexMap().size());

        // There should 2 rows of data
        Assert.areEqual(3, table.getKeyValueData().size());
        
        // Expecting column 2 to have a custom value
        Assert.areEqual('CUSTOM_VALUE', table.getIndexedData()[2][1]);

        // Expecting the the value ofcloumn 3 to have the value of column 1
        Assert.areEqual('2.1', table.getIndexedData()[1][2]);
        Assert.areEqual('3.1', table.getIndexedData()[2][2]);
    }


    @IsTest
    static void testValidateColumnNames(){
         
        // Variables to assert against
        JsnTbl table;
        Exception emptyColumnsException;
        Exception invalidColumnsException;

        // Start the test
        Test.startTest();
        System.runAs(TST_USER){
            
            table = new JsnTbl()
                .create(JSON.deserializeUntyped('[{"key1" : "1.1","key2" : "1.2","key3" : "1.3" }]'))
            ;

            try{
                table.validateColumnNames(null);

                // This method will fail the test as it should not be reached
                utl.Tst.assertExceptionHasBeenThrow();
            }catch(Exception e){
                emptyColumnsException = e;
            }

            try{
                table.validateColumnNames(new Set<String>{'invalid'});
                
                // This method will fail the test as it should not be reached
                utl.Tst.assertExceptionHasBeenThrow();
            }catch(Exception e){
                invalidColumnsException = e;
            }
        }
        Test.stopTest();

        // Validate the exception messages
        utl.Tst.assertExceptionMessage(JsnTbl.EMPTY_COLUMNS_MSG, emptyColumnsException);
        utl.Tst.assertExceptionMessage(JsnTbl.COLUMN_DOES_NOT_EXIST_MSG, 'invalid', invalidColumnsException);
    }
}