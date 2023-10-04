/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           May 2023
 * @copyright      (c) 2023 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class with JSON utilities
 * @false-positive PMD.AvoidGlobalModifier This is a utility that is designed to be called from a
 *                                         managed package. It can be used for a user's own custom
 *                                         Implementation, so global is the way to open up this
 *                                         utility for global use.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class Jsn {

    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    private static Boolean throwException = true;
    

    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    @TestVisible private static final String PATH_ERROR_MSG = 'The node "{0}" cannot be found.';

    
    /** **************************************************************************************************** **
     **                                       GLOBAL SETTER METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set the throw exception parameter. Set to true
     *              to throw an exception on an invalid path.
     * @param value The boolean value
     */
    global static void setThrowException(Boolean value){
        throwException = value;
    }

    
    /** **************************************************************************************************** **
     **                                       GLOBAL GETTER METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Method to get an object from a map path
     * @param  path  The input path i.e. Owner.Profile.Name
     * @param  input The map to traverse
     * @return The object at the end of the path
     */
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
    

    /**
     * @description Method to get an object map from a map path
     * @param  path  The input path i.e. Owner.Profile.Name
     * @param  input The map to traverse
     * @return The object map at the end of the path
     */
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


    /**
     * @description Method to get an object list from a map path
     * @param  path  The input path i.e. Owner.Profile.Name
     * @param  input The map to traverse
     * @return The object list at the end of the path
     */
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


    /**
     * @description Method to throw a path exception in case it does not exist
     * @param  path  The input path i.e. Owner.Profile.Name
     * @return null
     */
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