@IsTest
private with sharing class JsnTblTest {

    
    @IsTest
    static void testDataTableWithNestedLists(){
        
        JsnTbl jsnTbl = new JsnTbl()
            .create(JSON.deserializeUntyped('[[1],[2],[3],{"a" : "b"}]'))
        ;

        // There should be 1 result
        //Assert.areEqual(2, jsnTbl.data.size());

        // The map in should have 3 items
        //Assert.areEqual(1,  jsnTbl.data[0].size());

        // The second map should have 3 items
        // This is because unknown attributes go at the end of the table 
        //Assert.areEqual(3,  jsnTbl.data[1].size());

    }

    @IsTest
    static void testDataTableWithNestedObjects(){
        
        JsnTbl jsnTbl = new JsnTbl()
        .create(JSON.deserializeUntyped('{"obj1" : {"a" : 1, "b" : 2}, "obj2" : {"y" : 25, "z" : 26, "e" : {"f" : 6} }, "obj3" : [1,2,3]}'))
        ;
/*
        // There should be 1 result
        Assert.areEqual(1, jsnTbl.data.size());

        // The map in should have 6 items
        Assert.areEqual(6,  jsnTbl.data[0].size());

        // Assert everything is nice and flat
        Assert.areEqual(1,  (Integer)((Map<String,Object>)jsnTbl.data[0]).get('obj1.a'));
        Assert.areEqual(2,  (Integer)((Map<String,Object>)jsnTbl.data[0]).get('obj1.b'));
        Assert.areEqual(25, (Integer)((Map<String,Object>)jsnTbl.data[0]).get('obj2.y'));
        Assert.areEqual(26, (Integer)((Map<String,Object>)jsnTbl.data[0]).get('obj2.z'));

        // 3rd level deep yet still flat
        Assert.areEqual( 6, (Integer)((Map<String,Object>)jsnTbl.data[0]).get('obj2.e.f'));

        // Test our list
        Assert.areEqual( 1, ((List<Map<String,Object>>)(jsnTbl.data[0].get('obj3'))).size());

        // Test the object inside out list to have 3 attributes
        Assert.areEqual( 3, ((List<Map<String,Object>>)(jsnTbl.data[0].get('obj3')))[0].size());
        */

    }
}