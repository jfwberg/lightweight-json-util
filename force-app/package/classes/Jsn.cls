/**
 * @description 
 */
global with sharing class Jsn {

    private static Boolean throwException = true;
    
    @TestVisible private static final String PATH_ERROR_MSG = 'The node "{0}" cannot be found.';


    global static void setThrowException(Boolean value){
        throwException = value;
    }


    global static Object getObject(String path, Map<String, Object> input){
        return
        ((path.contains('.')) ?
            ((input.containsKey(path.substringBefore('.'))) ? 
                getObject(path.substringAfter('.'), (Map<String, Object>) input.get(path.substringBefore('.'))) :
                handlePathError(path.substringBefore('.')) 
            ) :
            ((input.containsKey(path)) ?
                input.get(path) : 
                handlePathError(path)
            )
        );
    }
    

    global static Map<String,Object> getObjectMap(String path, Map<String,Object> input){
        return (Map<String, Object>)
        ((path.contains('.')) ?
            ((input.containsKey(path.substringBefore('.'))) ? 
                getObjectMap(path.substringAfter('.'), (Map<String, Object>) input.get(path.substringBefore('.'))) : 
                handlePathError(path.substringBefore('.'))
            ) :
            ((input.containsKey(path)) ?
                input.get(path) :
                handlePathError(path)
            )
        );
    }


    global static Object[] getObjectList(String path, Map<String,Object> input){
        return (Object[])
        ((path.contains('.')) ?
            ((input.containsKey(path.substringBefore('.'))) ?
                getObjectList(path.substringAfter('.'), (Map<String, Object>) input.get(path.substringBefore('.'))) :
                handlePathError(path.substringBefore('.'))
            ) :
            ((input.containsKey(path)) ?
                input.get(path) :
                handlePathError(path)
            )
        );
        
    }


    private static Object handlePathError(String path){
        if(throwException){
            throw new JsonUtilException(String.format(PATH_ERROR_MSG,new String[]{path}));
        }
        return null;       
    }


    /**
     * @description Class representing an exception thrown by the JSON Utility
     */
    global with sharing class JsonUtilException extends Exception{}
}