/*****************************************************************************
 *                       Copyright (C) 2019 ServiceMax, Inc
 *                               All rights reserved
 *
 *****************************************************************************/

/**
 * Service manager which has business logic for all the services, related to map functionality, re-written for DCx
 * @author Vinay Vijay, Bhagyashree Aratti
 * @version 19.2000
 * @since 2019
 */
public with sharing class DCX_MapServiceManager {
    
    Public static map<String,String> mapReplacementNameFieldLocsss = new map<String,String>();
    Public static map<String,String> mapReplacementRefWO = new map<String,String>();
   
    Public static map<String,String> mapReplacementNameFieldWO = new map<String,String>();
    Public static map<String,String> mapReplacementRefAcc = new map<String,String>();
    Public static map<String,String> mapReplacementNameFieldAcc = new map<String,String>();
    Public static map<String,String> mapReplacementRefLoc = new map<String,String>();
    Public static map<String,String> mapReplacementNameFieldLoc = new map<String,String>();
    Public static list<SVMXC__ServiceMax_Config_Data__c> lstHoverConfigDataWO = new list<SVMXC__ServiceMax_Config_Data__c>();
    Public static list<SVMXC__ServiceMax_Config_Data__c> lstHoverConfigDataLoc = new list<SVMXC__ServiceMax_Config_Data__c>();
    Public static list<SVMXC__ServiceMax_Config_Data__c> lstHoverConfigDataAcc = new list<SVMXC__ServiceMax_Config_Data__c>();

   
    
   public  static SVMXC.INTF_WebServicesDef.INTF_Response getMapData(string objectname,string viewId,Integer recordlimit,Double latitude,Double longitude,Double radius)
    {
                   
        String strObjectName = objectname;
        String strViewId = viewId;
        
        
       
        Double dblLatitude = 0;
        Double dblLongitude = 0;
        Double dblRadius = 0;
        Integer intNoOfRecords = 0;
        
        dblLatitude = latitude;
        dblLongitude = longitude;
        dblRadius = radius;
        intNoOfRecords = recordlimit;
        SVMXC__ServiceMax_Processes__c objView = new SVMXC__ServiceMax_Processes__c();
        map <string,SVMXC__ServiceMax_Processes__c> objView1 = new map<string,SVMXC__ServiceMax_Processes__c>();
        
        list<string>viewIds = new list<string>();
        SVMXC.INTF_WebServicesDef.INTF_Response response = new SVMXC.INTF_WebServicesDef.INTF_Response();
        list<string> lstSubModuleId = new list<string>{'DCON001'};
        SVMXC.COMM_Utils_ManageSettings settings = new SVMXC.COMM_Utils_ManageSettings();
        list<SVMXC.INTF_WebServicesDef.INTF_StringListMap> lstStringMap = new list<SVMXC.INTF_WebServicesDef.INTF_StringListMap>();
        map<string, Map<String, String>> mapDCSetting = settings.SVMX_getSettingList(lstSubModuleId);
         map<String, Schema.SObjectType> mapAllobjDesc  = new map<String, Schema.SObjectType>();
      /*  for(Schema.SObjectType s : Schema.getGlobalDescribe().values())
        {
             Schema.DescribeSObjectResult result = s.getDescribe();
             mapAllobjDesc.put(result.getName(),s);
        } */
        
        Schema.Describesobjectresult woDefinitions = SVMXC__Service_Order__c.sObjectType.getDescribe();
        mapAllobjDesc.put(woDefinitions.getName(), woDefinitions.getSobjectType());
        Schema.Describesobjectresult SiteDefinitions = SVMXC__Site__c.sObjectType.getDescribe();
        mapAllobjDesc.put(SiteDefinitions.getName(), SiteDefinitions.getSobjectType());
        Schema.Describesobjectresult AccountDefinitions = Account.sObjectType.getDescribe();
        mapAllobjDesc.put(AccountDefinitions.getName(), AccountDefinitions.getSobjectType());

        
        
        if(strViewId !=null)
        {
            viewIds = strViewId.split(',');
        }
        
       for(ServiceMax_Processes__c ViewRec :[Select Id, SVMXC__Name__c, SVMXC__Ownership_Type__c,  SVMXC__Parent_Object_Criteria__c, SVMXC__Source_Object_Name__c, SVMXC__View_For__c, SVMXC__Values__c From SVMXC__ServiceMax_Processes__c where Id =:viewIds] )
       {
           objView1.put(ViewRec.id,ViewRec);
       }
        
       /* if(request != null && request.stringMap != null && request.stringMap.size() > 0)
        {
            for(Integer i = 0;i<request.stringMap.size();i++)
            {
                if(request.stringMap[i].key != null && request.stringMap[i].key.touppercase() == 'OBJECTNAME' && request.stringMap[i].value != null)
                {
                    strObjectName = request.stringMap[i].value;
                }
                else if (request.stringMap[i].key != null && request.stringMap[i].key.touppercase() == 'VIEWID' && request.stringMap[i].value != null)
                {
                     strViewId = request.stringMap[i].value;
                     viewIds = strViewId.split(',');
                }
                else if(request.stringMap[i].key != null && request.stringMap[i].key.touppercase() == 'RECORDLIMIT' && request.stringMap[i].value != null)
                {
                    intNoOfRecords = Integer.valueof(request.stringMap[i].value);
                }
                else if(request.stringMap[i].key != null && request.stringMap[i].key.touppercase() == 'LATITUDE'  && request.stringMap[i].value != null)
                {
                    dblLatitude = Double.valueof(request.stringMap[i].value);
                }
                else if(request.stringMap[i].key != null && request.stringMap[i].key.touppercase() == 'LONGITUDE'  && request.stringMap[i].value != null)
                {
                    dblLongitude = Double.valueof(request.stringMap[i].value);
                }
                else if(request.stringMap[i].key != null && request.stringMap[i].key.touppercase() == 'RADIUS'  && request.stringMap[i].value != null)
                {
                    dblRadius = Double.valueof(request.stringMap[i].value);
                }
            }
        }*/
                    
        
       for(Integer m = 0; m<viewIds.size();m++ )
       {
                    String strQueryFields = '';
                     String strWhereClouse = '';
                     String strOwnerShipType = '';
                     Set<String> setFields = new set<String>();
                     list<SVMXC__ServiceMax_Processes__c> lstHoverHeader = new list<SVMXC__ServiceMax_Processes__c>();
                     SVMXC__ServiceMax_Processes__c objHoverHeader = new SVMXC__ServiceMax_Processes__c();
                     list<SVMXC__ServiceMax_Config_Data__c> lstHoverConfigData = new list<SVMXC__ServiceMax_Config_Data__c>();
                    
                    map<String, SObjectField> mapFieldDesc = new map<String, SObjectField>();
                    map<String, String> mapAPINameLabel = new map<String, String>();
                    map<String,String> mapReplacementRef = new map<String,String>();
                    map<String,String> mapReplacementNameField = new map<String,String>();
                                        list<Sobject> lstSobject = new list<Sobject>();
                    map<Double,list<String>> mapDistanceWOIds = new map<Double,list<String>>();
                    map<String,Sobject> mapIdSobject = new map<String,Sobject>();
                    DCX_Utils dcUtils = new DCX_Utils();
                    
                    
                if(viewIds.size() > 0)
                {
                     
                    try
                    {
                         //objView = [Select Id, SVMXC__Name__c, SVMXC__Ownership_Type__c,  SVMXC__Parent_Object_Criteria__c, SVMXC__Source_Object_Name__c, SVMXC__View_For__c, SVMXC__Values__c From SVMXC__ServiceMax_Processes__c where Id =: viewIds[m]];
                         objView =objView1.get(viewIds[m]);
                         system.debug('objView ::' +objView);
                    }
                    catch(Exception ex)
                    {
                        response.success = false;
                        response.message = ex.getmessage();
                        return response;
                    }
                    if(objView.SVMXC__Values__c != null)
                    {
                        strQueryFields = objView.SVMXC__Values__c;
                        list<String> lstfld = new list<String>();
                        lstfld = objView.SVMXC__Values__c.split(',');
                        if(lstfld != null && lstfld.size() > 0)
                            setFields.addall(lstfld);
                    }
                    //system.debug(logginglevel.warn,'setFields: '+setFields);
                    if(objView.SVMXC__Parent_Object_Criteria__c != null)
                        strWhereClouse = objView.SVMXC__Parent_Object_Criteria__c;
                    if(objView.SVMXC__Ownership_Type__c != null)
                        strOwnerShipType = objView.SVMXC__Ownership_Type__c;
                    system.debug(logginglevel.warn,'strWhereClouse'+m+' : '+strWhereClouse);
                    system.debug(logginglevel.warn,'strOwnerShipType'+m+' : '+strOwnerShipType);
                    if( strOwnerShipType != null && strOwnerShipType.length() > 0 && strOwnerShipType == 'User\'s Records')//isView &&
                    {
                        String strUserId = Userinfo.getUserId();
                        if(strWhereClouse != null && strWhereClouse.length() > 0)
                            strWhereClouse = ' ( ' + strWhereClouse + ' ) ' + ' AND OwnerId =: strUserId';
                        else 
                            strWhereClouse += 'OwnerId =: strUserId';
                    }
                    system.debug(logginglevel.warn,'strWhereClouse'+strWhereClouse);  
                    strWhereClouse = '( ' + strWhereClouse + ' )';
                    if(strObjectName != null && strObjectName.length() > 0)
                    {
                        //try
                        //{
                            /* lstHoverHeader = [select id, SVMXC__Name__c, SVMXC__Values__c, SVMXC__ProcessID__c, SVMXC__Rule_Type__c, SVMXC__Source_Object_Name__c from SVMXC__ServiceMax_Processes__c where RecordType.Name = 'SVMX Rule' and SVMXC__Rule_Type__c = 'Column Info' and SVMXC__Source_Object_Name__c =: strObjectName];
                            //system.debug(logginglevel.warn,'objHoverHeader: '+objHoverHeader);
                            if(lstHoverHeader != null && lstHoverHeader.size() > 0)
                            {
                                objHoverHeader = lstHoverHeader[0];
                            }
                            if(objHoverHeader != null && objHoverHeader.id != null)
                                lstHoverConfigData = [Select id, SVMXC__Expression_Rule__c, SVMXC__Object_Name2__c, SVMXC__Field_Name__c, SVMXC__Expression_Type__c, SVMXC__Sequence__c, SVMXC__Lookup_Field_API_Name__c, SVMXC__Is_Name_Field__c, SVMXC__Display_Type__c, SVMXC__FKey_Name_Field__c, SVMXC__Field_Relationship_Name__c, SVMXC__Object_Name__c from SVMXC__ServiceMax_Config_Data__c where SVMXC__Expression_Rule__c =: objHoverHeader.id and RecordType.Name = 'Expressions' and SVMXC__Expression_Type__c = 'Column Field' order by SVMXC__Sequence__c];
                            system.debug(logginglevel.warn,'lstHoverConfigData'+lstHoverConfigData); */
                            if(strObjectName =='SVMXC__Service_Order__c' && lstHoverConfigDataWO.isempty())
                            {
                                lstHoverConfigDataWO = GetHoverConfigdata(strObjectName);
                               
                            }
                            
                            if(strObjectName =='SVMXC__Site__c' && lstHoverConfigDataLoc.isempty())
                            {
                                lstHoverConfigDataLoc = GetHoverConfigdata(strObjectName);
                               
                            }
                            
                            if(strObjectName =='Account' && lstHoverConfigDataLoc.isempty())
                            {
                                lstHoverConfigDataAcc = GetHoverConfigdata(strObjectName);
                               
                            }
                            
                           if(lstHoverConfigDataWO != null && lstHoverConfigDataWO.size() > 0) 
                           {
                              lstHoverConfigData = lstHoverConfigDataWO;

                           }
                           else if (lstHoverConfigDataLoc != null && lstHoverConfigDataLoc.size() > 0)
                           {
                               lstHoverConfigData = lstHoverConfigDataLoc;
                           }
                           else
                           {
                               lstHoverConfigData = lstHoverConfigDataAcc;
                           }
                            
                            //lstHoverConfigData = GetHoverConfigdata(strObjectName);
                            
                            if(lstHoverConfigData != null && lstHoverConfigData.size() > 0)
                            {
                                for(SVMXC__ServiceMax_Config_Data__c cg : lstHoverConfigData)
                                {
                                    if(cg.SVMXC__Field_Name__c != null && cg.SVMXC__Display_Type__c != null && cg.SVMXC__Display_Type__c != 'REFERENCE' && !setFields.contains(cg.SVMXC__Field_Name__c))
                                    {
                                        setFields.add(cg.SVMXC__Field_Name__c);
                                        if(strQueryFields != null && strQueryFields.length() > 0)
                                            strQueryFields += ','+cg.SVMXC__Field_Name__c;
                                        else 
                                            strQueryFields  +=  cg.SVMXC__Field_Name__c;
                                    }
                                    else if(cg.SVMXC__Field_Name__c != null && cg.SVMXC__Display_Type__c != null && cg.SVMXC__Display_Type__c == 'REFERENCE' && cg.SVMXC__Field_Relationship_Name__c != null && cg.SVMXC__FKey_Name_Field__c != null && !setFields.contains(cg.SVMXC__Field_Relationship_Name__c+'.'+cg.SVMXC__FKey_Name_Field__c))
                                    {
                                        setFields.add(cg.SVMXC__Field_Relationship_Name__c+'.'+cg.SVMXC__FKey_Name_Field__c);
                                        if(strQueryFields != null && strQueryFields.length() > 0)
                                            strQueryFields += ','+cg.SVMXC__Field_Relationship_Name__c+'.'+cg.SVMXC__FKey_Name_Field__c;
                                        else 
                                            strQueryFields  +=  cg.SVMXC__Field_Relationship_Name__c+'.'+cg.SVMXC__FKey_Name_Field__c;
                                    }       
                                }
                            }   
                        /*}
                        catch(Exception ex)
                        {
                            response.success = false;
                            response.message = ex.getmessage();
                            return response;
                        }   */
                    }
                
                }
                double distance;
                
                
                if(mapDCSetting.containsKey('DCON001') && mapDCSetting.get('DCON001').containsKey('SET055')&&  mapDCSetting.get('DCON001').get('SET055') == 'Miles')
                {
                    system.debug('if');
                    distance = 0.009 * 1.60934 * dblRadius;
                }
                else
                {
                    system.debug('else');
                     distance = 0.009 *  dblRadius;
                }
                double lat_min1 = dblLatitude - distance;
                double lat_max1 = dblLatitude + distance;
                double long_min1 = dblLongitude - (distance / Math.cos(dblLatitude*Math.PI/180));
                double long_max1 = dblLongitude + (distance / Math.cos(dblLatitude*Math.PI/180));
                
                string lat_min = string.valueOf(lat_min1);
                string lat_max = string.valueOf(lat_max1);
                string long_min = string.valueOf(long_min1);
                string long_max = string.valueOf(long_max1);
                
                system.debug('lat_min' + lat_min);
                system.debug('lat_max' + lat_max);
                system.debug('long_min' + long_min);
                system.debug('long_max' + long_max);
                
                 String strWhereClouse1 = ' AND SVMXC__Latitude__c >= '+lat_min+' AND SVMXC__Latitude__c <='+ lat_max +'AND SVMXC__Longitude__c>= '+long_min + ' AND SVMXC__Longitude__c<= ' +long_max;
                

                if(strObjectName != null && strObjectName.length() > 0 && strObjectName == 'SVMXC__Service_Order__c')
                {
                    if(!setFields.contains('SVMXC__Latitude__c'))
                    {
                        setFields.add('SVMXC__Latitude__c');
                        if(strQueryFields != null && strQueryFields.length() > 0)
                            strQueryFields += ', SVMXC__Latitude__c';
                        else 
                            strQueryFields += 'SVMXC__Latitude__c';
                    }
                    if(!setFields.contains('SVMXC__Longitude__c'))
                    {
                        setFields.add('SVMXC__Longitude__c');
                        strQueryFields += ', SVMXC__Longitude__c';
                    }           
                    if(strWhereClouse != null && strWhereClouse.length() > 0)
                        strWhereClouse += ' AND SVMXC__Latitude__c != null AND SVMXC__Longitude__c != null ';
                    else 
                        strWhereClouse += ' SVMXC__Latitude__c != null AND SVMXC__Longitude__c != null ';
                       
                        
                    String strQuery = 'Select '+strQueryFields+' From SVMXC__Service_Order__c where '+strWhereClouse +strWhereClouse1 ;
                    system.debug(logginglevel.warn,'strQuery: '+strQuery);
                    lstSobject = database.query(strQuery);  
                    system.debug('lstSobject size:'+lstSobject.size()+'  '+lstSobject);
                    if(mapAllobjDesc.containskey(strObjectName))
                    {
                        mapFieldDesc = mapAllobjDesc.get(strObjectName).getDescribe().fields.getMap();
                        system.debug('mapFieldDesc'+mapFieldDesc);
                        if(mapFieldDesc.size() > 0)
                        {
                            for(String str : mapFieldDesc.keyset())
                            {
                                mapAPINameLabel.put(mapFieldDesc.get(str).getDescribe().getName(),mapFieldDesc.get(str).getDescribe().getLabel());
                            }
                        }
                        system.debug(logginglevel.warn,'mapAPINameLabel'+mapAPINameLabel);
                        system.debug('number of iteration 9988 -> '+mapReplacementRefWO );
                        if(mapReplacementRefWO.isempty() && mapReplacementNameFieldWO.isempty())
                        { 
                          DCX_Utils.referenceFields_WP reference_MWO = dcUtils.SVMX_getReferenceFields(mapFieldDesc,true);
                          mapReplacementRefWO = reference_MWO.replacementReference_M;  //Get the replacement reference field map
                          mapReplacementNameFieldWO = reference_MWO.replacementField_M;  //Get the name field for reference map
                          system.debug('number of iteration 9999 -> '+mapReplacementRefWO );
                          //system.debug(logginglevel.warn,'mapReplacementRef'+mapReplacementRef);
                          //system.debug(logginglevel.warn,'mapReplacementNameField'+mapReplacementNameField);
                        }
                       
                       
                    }   
                }
                 else if(strObjectName != null &&  strObjectName.length() > 0 && strObjectName == 'SVMXC__Site__c')
                {
                    if(!setFields.contains('SVMXC__Latitude__c'))
                    {
                        setFields.add('SVMXC__Latitude__c');
                        if(strQueryFields != null && strQueryFields.length() > 0)
                            strQueryFields += ', SVMXC__Latitude__c';
                        else 
                            strQueryFields += 'SVMXC__Latitude__c';
                    }
                    if(!setFields.contains('SVMXC__Longitude__c'))
                    {
                        setFields.add('SVMXC__Longitude__c');
                        strQueryFields += ', SVMXC__Longitude__c';
                    }           
                    if(strWhereClouse != null && strWhereClouse.length() > 0)
                        strWhereClouse += ' AND SVMXC__Latitude__c != null AND SVMXC__Longitude__c != null ';
                    else 
                        strWhereClouse += ' SVMXC__Latitude__c != null AND SVMXC__Longitude__c != null ';
                        
                    String strQuery = 'Select '+strQueryFields+' From SVMXC__Site__c where '+strWhereClouse+strWhereClouse1;
                    system.debug(logginglevel.warn,'strQuery: '+strQuery);
                    lstSobject = database.query(strQuery);
                    if(mapAllobjDesc.containskey(strObjectName))
                    {
                        mapFieldDesc = mapAllobjDesc.get(strObjectName).getDescribe().fields.getMap();
                        if(mapFieldDesc.size() > 0)
                        {
                            for(String str : mapFieldDesc.keyset())
                            {
                                mapAPINameLabel.put(mapFieldDesc.get(str).getDescribe().getName(),mapFieldDesc.get(str).getDescribe().getLabel());
                            }
                        }
                        if(mapReplacementRefLoc.isempty() && mapReplacementNameFieldLoc.isempty())
                        {
                        DCX_Utils.referenceFields_WP reference_MLoc = dcUtils.SVMX_getReferenceFields(mapFieldDesc,true);
                        mapReplacementRefLoc = reference_MLoc.replacementReference_M;  //Get the replacement reference field map
                        mapReplacementNameFieldLoc = reference_MLoc.replacementField_M;  //Get the name field for reference map
                        }
                    }   
                }
                else if(strObjectName != null &&  strObjectName.length() > 0 && strObjectName == 'Account')
                {
                    if(!setFields.contains('SVMXC__Latitude__c'))
                    {
                        setFields.add('SVMXC__Latitude__c');
                        if(strQueryFields != null && strQueryFields.length() > 0)
                            strQueryFields += ', SVMXC__Latitude__c';
                        else 
                            strQueryFields += 'SVMXC__Latitude__c';
                    }
                    if(!setFields.contains('SVMXC__Longitude__c'))
                    {
                        setFields.add('SVMXC__Longitude__c');
                        strQueryFields += ', SVMXC__Longitude__c';
                    }           
                    if(strWhereClouse != null && strWhereClouse.length() > 0)
                        strWhereClouse += ' AND SVMXC__Latitude__c != null AND SVMXC__Longitude__c != null ';
                    else 
                        strWhereClouse += ' SVMXC__Latitude__c != null AND SVMXC__Longitude__c != null ';
                        
                    String strQuery = 'Select '+strQueryFields+' From Account where '+strWhereClouse +strWhereClouse1;
                    system.debug(logginglevel.warn,'strQuery: '+strQuery);
                    lstSobject = database.query(strQuery);
                    if(mapAllobjDesc.containskey(strObjectName))
                    {
                        mapFieldDesc = mapAllobjDesc.get(strObjectName).getDescribe().fields.getMap();
                        if(mapFieldDesc.size() > 0)
                        {
                            for(String str : mapFieldDesc.keyset())
                            {
                                mapAPINameLabel.put(mapFieldDesc.get(str).getDescribe().getName(),mapFieldDesc.get(str).getDescribe().getLabel());
                            }
                        }
                        
                        if(mapReplacementRefAcc.isempty() && mapReplacementNameFieldAcc.isempty())
                        {
                        DCX_Utils.referenceFields_WP reference_MAcc = dcUtils.SVMX_getReferenceFields(mapFieldDesc,true);
                        mapReplacementRefAcc = reference_MAcc.replacementReference_M;  //Get the replacement reference field map
                        mapReplacementNameFieldAcc = reference_MAcc.replacementField_M;  //Get the name field for reference map
                        }
                    }   
                }
                
            if(lstSobject.size() > 0)
            {
                for(Integer i =0;i<lstSobject.size();i++)
                {
                    mapIdSobject.put(lstSobject[i].id,lstSobject[i]);
                    
                    Sobject obj = lstSobject[i];
                  //  system.debug('lstSobject[i] '+ii+lstSobject[i]);
                    Double dblDistance = dcUtils.getDistanceBetween(dblLatitude, dblLongitude, Double.valueOf(obj.get('SVMXC__Latitude__c')), Double.valueof(obj.get('SVMXC__Longitude__c')));
                    //40533 - added following if condition to convert KM to miles, if the DC setting in map is miles
                    if(mapDCSetting.containsKey('DCON001') && mapDCSetting.get('DCON001').containsKey('SET055')&& 
                mapDCSetting.get('DCON001').get('SET055') == 'Miles')
                    {
                        double kmToMiles = 0.621371;
                        dblDistance = dblDistance * kmToMiles;
                    } 
                                
                    if(dblDistance <= dblRadius)
                    {
                        if(mapDistanceWOIds.containskey(dblDistance))
                        {
                            mapDistanceWOIds.get(dblDistance).add(lstSobject[i].id);
                        }
                        else
                        {
                            mapDistanceWOIds.put(dblDistance,new list<String>());
                            mapDistanceWOIds.get(dblDistance).add(lstSobject[i].id);
                        }
                    }   
                }
            }
            
            lstSobject.clear();
            if(mapDistanceWOIds.size() > 0)
            {
                list<Double> lstDistance = new list<Double>();
                lstDistance.addall(mapDistanceWOIds.keyset());
                lstDistance.sort();
                for(integer i = 0;i<lstDistance.size();i++)
                {
                    if(mapDistanceWOIds.containskey(lstDistance[i]))
                    {
                        list<String> lstIds = new list<String>();
                        lstIds = mapDistanceWOIds.get(lstDistance[i]);
                        if(lstIds.size() > 0)
                        {
                            for(Integer j = 0;j<lstIds.size();j++)
                            {
                                if(mapIdSobject.containskey(lstIds[j]))
                                    lstSobject.add(mapIdSobject.get(lstIds[j]));
                            }
                        }
                    }
                }
            }   
           system.debug('lstSobject 1:'+lstSobject); 
           if(lstSobject.size() > 0)
            {
                for(Integer i = 0;i<lstSobject.size();i++)
                {
                    Sobject obj = lstSobject[i];
                    system.debug('obj >>> '+obj.getSObjectType());
                    list<String> lstHover = new list<String>();
                    
                    for(Integer j = 0;j<lstHoverConfigData.size();j++)
                {
                  String str = '';
                  if(lstHoverConfigData[j].SVMXC__Field_Name__c != null && mapAPINameLabel.containskey(lstHoverConfigData[j].SVMXC__Field_Name__c))
                  {
                    str = '<B>'+mapAPINameLabel.get(lstHoverConfigData[j].SVMXC__Field_Name__c) + '</B>: ' ;
                    if(lstHoverConfigData[j].SVMXC__Display_Type__c != null && lstHoverConfigData[j].SVMXC__Display_Type__c.touppercase() == 'REFERENCE' )//obj.get(lstHoverConfigData[j].SVMXC__Field_Name__c) != null
                    {
                        system.debug('strObjectName -> '+ strObjectName);
                        if(strObjectName =='SVMXC__Service_Order__c')
                        {
                        system.debug(logginglevel.warn,'map Replacement Ref'+mapReplacementRefWO.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                        Sobject objRef = obj.getSobject(mapReplacementRefWO.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                            if(objRef!=NULL)
                            {
                                str = str +String.valueof(objRef.get(mapReplacementNameFieldWO.get(lstHoverConfigData[j].SVMXC__Field_Name__c)));
                            }
                        }
                        if(strObjectName == 'SVMXC__Site__c')
                        {
                        system.debug(logginglevel.warn,'map Replacement RefLOC '+mapReplacementRefLoc.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                        Sobject objRef = obj.getSobject(mapReplacementRefLoc.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                            if(objRef!=NULL)
                            {
                                str = str +String.valueof(objRef.get(mapReplacementNameFieldLoc.get(lstHoverConfigData[j].SVMXC__Field_Name__c)));
                            }
                        }
                        
                        if(strObjectName == 'Account')
                        {
                        system.debug(logginglevel.warn,'map Replacement RefAcc '+mapReplacementRefAcc.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                        Sobject objRef = obj.getSobject(mapReplacementRefAcc.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                            if(objRef!=NULL)
                            {
                                str = str +String.valueof(objRef.get(mapReplacementNameFieldLoc.get(lstHoverConfigData[j].SVMXC__Field_Name__c)));
                            }
                        }
                        
                    }
                    else if(lstHoverConfigData[j].SVMXC__Display_Type__c != null && lstHoverConfigData[j].SVMXC__Display_Type__c.touppercase() != 'REFERENCE' && obj.get(lstHoverConfigData[j].SVMXC__Field_Name__c) != null)
                    {
                       str = str + String.valueof(obj.get(lstHoverConfigData[j].SVMXC__Field_Name__c));
                    }
                    lstHover.add(str);
                  }  
                }
                 SVMXC.INTF_WebServicesDef.INTF_StringListMap stringLstMap = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
                   stringLstMap.key = viewIds[m];
                    stringLstMap.valueList = lstHover;
                    stringLstMap.sobj = obj;
                    lstStringMap.add(stringLstMap);
                    if((i+1) == intNoOfRecords)
                    {
                        break;  
                    }
                }   
            } 
        }
       if(lstStringMap.size() > 0)
            response.StringLstMap = lstStringMap;
        system.debug(logginglevel.warn,'response: '+response);
        return response; 
    }
    
    
    // This is created for optimization of hover function . 
   private static list<SVMXC__ServiceMax_Config_Data__c> GetHoverConfigdata(string strObjectName)
   {
      list<SVMXC__ServiceMax_Processes__c> lstHoverHeader = new list<SVMXC__ServiceMax_Processes__c>();
      SVMXC__ServiceMax_Processes__c objHoverHeader = new SVMXC__ServiceMax_Processes__c();
      list<SVMXC__ServiceMax_Config_Data__c> lstHoverConfigData = new list<SVMXC__ServiceMax_Config_Data__c>();
 
      lstHoverHeader = [select id, SVMXC__Name__c, SVMXC__Values__c, SVMXC__ProcessID__c, SVMXC__Rule_Type__c, SVMXC__Source_Object_Name__c from SVMXC__ServiceMax_Processes__c where RecordType.Name = 'SVMX Rule' and SVMXC__Rule_Type__c = 'Column Info' and SVMXC__Source_Object_Name__c =: strObjectName];
      //system.debug(logginglevel.warn,'objHoverHeader: '+objHoverHeader);
      if(lstHoverHeader != null && lstHoverHeader.size() > 0)
      {
          objHoverHeader = lstHoverHeader[0];
      }
      if(objHoverHeader != null && objHoverHeader.id != null)
       lstHoverConfigData = [Select id, SVMXC__Expression_Rule__c, SVMXC__Object_Name2__c, SVMXC__Field_Name__c, SVMXC__Expression_Type__c, SVMXC__Sequence__c, SVMXC__Lookup_Field_API_Name__c, SVMXC__Is_Name_Field__c, SVMXC__Display_Type__c, SVMXC__FKey_Name_Field__c, SVMXC__Field_Relationship_Name__c, SVMXC__Object_Name__c from SVMXC__ServiceMax_Config_Data__c where SVMXC__Expression_Rule__c =: objHoverHeader.id and RecordType.Name = 'Expressions' and SVMXC__Expression_Type__c = 'Column Field' order by SVMXC__Sequence__c];
       system.debug(logginglevel.warn,'lstHoverConfigData'+lstHoverConfigData);


     return lstHoverConfigData;
   
   } 
    
}