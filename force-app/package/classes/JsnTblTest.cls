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

    
    @IsTest
    static void testDataTableWithNestedLists(){
        
        JsnTbl table = new JsnTbl()
            .setAttributeFilter(new Set<String>{'ignore'})
            .setListNameFilter(new Set<String>{'records'})
            .create(JSON.deserializeUntyped('[[1,2,3],[1,2,3],[1,2,3],{"keyVal" : "b", "ignore": "ignore", "records" : ["rec1","rec2"]}]'))
            .updateColumnNames(new Set<String>{'Column A', 'Column B', 'Column C'})
        ;

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
        
        JsnTbl table = new JsnTbl()
            .create(JSON.deserializeUntyped('{"obj1" : {"a" : 1, "b" : 2}, "obj2" : {"y" : 25, "z" : 26, "e" : {"f" : 6} }, "obj3" : [{"k1":"v1"},{"k2":"v2"},{"k3":"v3"},[1,2,3]]}'))
        ;

        // There should be 11 columns
        Assert.areEqual(11,  table.getColumnNames().size());
        Assert.areEqual(11,  table.getColumnNameIndexMap().size());

        // There should 6 rows of data
        Assert.areEqual(6, table.getKeyValueData().size());
    }


    @IsTest
    static void testDataTableWithSingleParentObject(){
        
        JsnTbl table = new JsnTbl()
            .create(JSON.deserializeUntyped('19'))
        ;

        // There should be 1 columns
        Assert.areEqual(1,  table.getColumnNames().size());
        Assert.areEqual(1,  table.getColumnNameIndexMap().size());

        // There should 1 rows of data
        Assert.areEqual(1, table.getKeyValueData().size());
        
        // There should be 3 custom headers and 1 standard
        Assert.areEqual('0', table.getColumnNames()[0]);
    }
}