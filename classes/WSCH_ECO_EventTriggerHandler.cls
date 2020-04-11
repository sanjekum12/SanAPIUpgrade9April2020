public with sharing class WSCH_ECO_EventTriggerHandler {
    
    
   //Method to create optimizer object realated to SF event 
    public static void handleSFECOEventInsert(List<Event> events)
    {
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : handleSFECOEventInsert');
        //filtering All day event
        List<Event> lstValidEvents = new List<Event>();
        for(Event sfEvent : events){
            if(sfEvent.IsAllDayEvent == true){//if it is all day event then skip the callout.
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSFECOEventInsert::This is all day event so skipping callout. Technician work hours needs to be adjusted:');
                continue;
            }
            lstValidEvents.add(sfEvent);
        }       
        if(lstValidEvents == null){
            WSCH_AuditLogger.finish();
            return;
        }
        //List<String> technicianIds=WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(lstValidEvents);
        
        //Multi-resource and Multi-appointment
        List<Event> lstWOEvents = new List<Event>();
        List<Event> lstNonWOEvents = new List<Event>();
        list<String> listWOEventWhatIds = new List<String>(); 
        list<Event> listCompleteEvents = new List<Event>(); 
        for(Event sfEvent : lstValidEvents){
            if(sfEvent.WhatId != null){
                String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                String objectPrefix = String.valueOf(sfEvent.WhatId).substring(0,3);                
                if(woKeyPrefix.equals(objectPrefix)){
                    listWOEventWhatIds.add(sfEvent.WhatId);
                }
             }else{
                lstNonWOEvents.add(sfEvent);}
        }
        
        Map<Id, SVMXC__Service_Order__c> mapWoIdWoObj = new Map<Id, SVMXC__Service_Order__c>();
        mapWoIdWoObj.putAll([Select Id, Name, SVMXC__Locked_By_DC__c from SVMXC__Service_Order__c where Id IN: listWOEventWhatIds]);
        
        List<Event> finalListWOEvent = new List<Event>();
        if(listWOEventWhatIds != null && listWOEventWhatIds.size() > 0){
        finalListWOEvent = multiSFPillar(mapWoIdWoObj);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSFECOEventInsert::finalListWOEvent:'+finalListWOEvent);
        }
        
        //List of workorder events
        if(finalListWOEvent != null && finalListWOEvent.size() > 0)
            listCompleteEvents.addAll(finalListWOEvent);
            
        //Make a complete list of events both workorder and non workorder events    
        if(lstNonWOEvents != null && lstNonWOEvents.size() > 0) 
            listCompleteEvents.addAll(lstNonWOEvents);
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSFECOEventInsert::listCompleteEvents:'+listCompleteEvents);
        List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(listCompleteEvents);  
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSFECOEventInsert::technicianIds:'+technicianIds);
        
        if(null != technicianIds && technicianIds.size() > 0 ){
          List<SVMXC__SVMX_Optimizer__c> optimizers = getNonWorOrderEventOptimizerList(technicianIds,listCompleteEvents,null,null,null,null,'InsertTrigger');
          List<String> optimizerIds = saveOptimizerList(optimizers);
          if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events do not qualify for ECO ');
                
          }else{
                manageNonWorkOrderECOEvents(optimizerIds);
          }
        }else{
           WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events are not Non Work Order Events ');
        }
      
        WSCH_AuditLogger.finish();
    }
    
    //Method to create optimizer object realated to SF event 
    public static void handleSVMXECOEventInsert(list<SVMXC__SVMX_Event__c> lstevent)
    {
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSVMXECOEventInsert ');
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSVMXECOEventInsert::lstevent:'+lstevent);
        List<SVMXC__SVMX_Event__c> lstValidSVMXEvents = new List<SVMXC__SVMX_Event__c>();
        for(SVMXC__SVMX_Event__c svmxEvent : lstevent){
            if(svmxEvent.SVMXC__IsAllDayEvent__c == true){//if it is all day event then skip the callout.
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSVMXECOEventInsert::This is all day event so skipping callout. Technician work hours needs to be adjusted:');
                continue;
            }
            lstValidSVMXEvents.add(svmxEvent);          
        }
        if(lstValidSVMXEvents.size() == 0){
            WSCH_AuditLogger.finish();
            return;
        }
        //List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(lstValidSVMXEvents);  
        
        //Multi-resource and Multi-appointment
        List<SVMXC__SVMX_Event__c> lstWOEvents = new List<SVMXC__SVMX_Event__c>();
        List<SVMXC__SVMX_Event__c> lstNonWOEvents = new List<SVMXC__SVMX_Event__c>();
        list<String> listWOEventWhatIds = new List<String>(); 
        list<SVMXC__SVMX_Event__c> listCompleteEvents = new List<SVMXC__SVMX_Event__c>();
        for(SVMXC__SVMX_Event__c svmxEvent : lstValidSVMXEvents){
            if(svmxEvent.SVMXC__IsAllDayEvent__c == true){//if it is all day event then skip the callout.
                continue;
            }           
            if(svmxEvent.SVMXC__WhatId__c != null){
                String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                String objectPrefix = String.valueOf(svmxEvent.SVMXC__WhatId__c).substring(0,3);                
                if(woKeyPrefix.equals(objectPrefix)){
                    listWOEventWhatIds.add(svmxEvent.SVMXC__WhatId__c);
                    lstWOEvents.add(svmxEvent);
                }
             }else{
                lstNonWOEvents.add(svmxEvent);}
        }
        
        Map<Id, SVMXC__Service_Order__c> mapWoIdWoObj = new Map<Id, SVMXC__Service_Order__c>();
        mapWoIdWoObj.putAll([Select Id, Name, SVMXC__Locked_By_DC__c from SVMXC__Service_Order__c where Id IN: listWOEventWhatIds]);
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSVMXECOEventInsert::WO listWOEventWhatIds:'+listWOEventWhatIds+' , lstNonWOEvents: '+lstNonWOEvents);
        List<SVMXC__SVMX_Event__c> finalListWOEvent = new List<SVMXC__SVMX_Event__c>();
        if(listWOEventWhatIds != null && listWOEventWhatIds.size() > 0){ 
            finalListWOEvent = multiSVMXPillar(mapWoIdWoObj);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSVMXECOEventInsert::finalListWOEvent:'+finalListWOEvent);
        }   
        
        //List of workorder events
        if(finalListWOEvent != null && finalListWOEvent.size() > 0)
            listCompleteEvents.addAll(finalListWOEvent);
            
        //Make a complete list of workorder and non workorder events    
        if(lstNonWOEvents != null && lstNonWOEvents.size() > 0) 
            listCompleteEvents.addAll(lstNonWOEvents);
            
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSVMXECOEventInsert::listCompleteEvents:'+listCompleteEvents);   
        if(listCompleteEvents != null && listCompleteEvents.size() > 0)
        {
        List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(listCompleteEvents);  
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::handleSVMXECOEventInsert::technicianIds:'+technicianIds); 
        
        if(null != technicianIds && technicianIds.size() > 0 ){
                List<SVMXC__SVMX_Optimizer__c> optimizers = getNonWorOrderEventOptimizerList(technicianIds,null,listCompleteEvents,null,null,null,'InsertTrigger');
            List<String> optimizerIds = saveOptimizerList(optimizers);       
            if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events do not qualify for ECO ');
           }else{
                manageNonWorkOrderECOEvents(optimizerIds);
           }
        }else{
           WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSVMXECOEventInsert : Alert!! The events are not Non Work Order Events ');
        }
        } 
       
        WSCH_AuditLogger.finish();
    }
  
  
   public static void handleSFECOEventUpdate(List<Event> newEvents, List<Event> oldEvents)
    {
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : handleSFECOEventUpdate ');
        List<Event> lstKeepEvent = new list<Event>();
        list<String> listWOEventWhatIds = new List<String>(); 
        for(Event sfEvent : newEvents){
            if(sfEvent.IsAllDayEvent == false){//if it is all day event then skip the callout.
                lstKeepEvent.add(sfEvent);
            }
        }
        
        newEvents = lstKeepEvent;
        List<Event> lstKeepEventOld = new list<Event>();        
        for(Event sfEventOld : oldEvents){
            if(sfEventOld.IsAllDayEvent == false){//if it is all day event then skip the callout.
                lstKeepEventOld.add(sfEventOld);
            }
        }
        oldEvents=lstKeepEventOld;        
        list<String> technicianIds=WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(newEvents);
        
        Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = getEventIdAndOptimizers(newEvents,null,technicianIds);
        
        if(null != technicianIds && technicianIds.size() > 0 ){
             List<SVMXC__SVMX_Optimizer__c> optimizers = getNonWorOrderEventOptimizerList(technicianIds,newEvents,null,mapIdOptimizer,oldEvents,null,'UpdateTrigger');
            List<String> optimizerIds = saveOptimizerList(optimizers);  
          if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events do not qualify for ECO ');
          }else{
                manageNonWorkOrderECOEvents(optimizerIds);
          }
        }else{
           WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventUpdate : Alert!! The events are not Non Work Order Events ');
        }
       
        //WSCH_AuditLogger.finish();
    }
    
    public static void handleSVMXECOEventUpdate(List<SVMXC__SVMX_Event__c> newEvents, List<SVMXC__SVMX_Event__c> oldEvents) {
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : handleSVMXECOEventUpdate ');
        List<SVMXC__SVMX_Event__c> lstKeepEvent = new list<SVMXC__SVMX_Event__c>();
        list<String> listWOEventWhatIds = new List<String>(); 
        for(SVMXC__SVMX_Event__c svmxEvent : newEvents){
            if(svmxEvent.SVMXC__IsAllDayEvent__c == false){//if it is all day event then skip the callout.
                lstKeepEvent.add(svmxEvent);
            }
        }
        
        newEvents = lstKeepEvent;
        List<SVMXC__SVMX_Event__c> lstKeepEventOld = new list<SVMXC__SVMX_Event__c>();        
        for(SVMXC__SVMX_Event__c svmxEventOld : oldEvents){
            if(svmxEventOld.SVMXC__IsAllDayEvent__c == false){//if it is all day event then skip the callout.
                lstKeepEventOld.add(svmxEventOld);
            }
        }
        oldEvents=lstKeepEventOld;          
       List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(newEvents);   
       WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : handleSVMXECOEventUpdate : technicianIds : '+technicianIds);
       Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = getEventIdAndOptimizers(null,newEvents,technicianIds);
       WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : handleSVMXECOEventUpdate : mapIdOptimizer : '+mapIdOptimizer); 
        
        if(null != technicianIds && technicianIds.size() > 0 ){
             List<SVMXC__SVMX_Optimizer__c> optimizers = getNonWorOrderEventOptimizerList(technicianIds,null,newEvents,mapIdOptimizer,null,oldEvents,'UpdateTrigger');
            List<String> optimizerIds = saveOptimizerList(optimizers);       
            if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events do not qualify for ECO ');
          }else{
                manageNonWorkOrderECOEvents(optimizerIds);
          }
        }else{
           WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSVMXECOEventUpdate : Alert!! The events are not Non Work Order Events ');
        }
       
        
        //WSCH_AuditLogger.finish();
    }
    
      
    //Method to update Optimizer object when SF events are deleted
    public static void handleSFECOEventDelete(List<Event> lstEvents)
    {
       WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler : handleSFECOEventDelete ');
        list<String> technicianIds=WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(lstEvents);
       Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = getOptimizersAndConnectionIds(lstEvents,null,technicianIds);
       List<SVMXC__SVMX_Optimizer__c> optimizers =createDeleteOptimizerList(mapIdOptimizer);
       List<String> optimizerIds = saveOptimizerList(optimizers);       
       if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events do not qualify for ECO ');
          }else{
                manageNonWorkOrderECOEvents(optimizerIds);
          }
        
         WSCH_AuditLogger.finish();          
    }
    
    //Method to update SVMX Optimizer object when SVMX events are deleted
    public static void handleSVMXECOEventDelete(List<SVMXC__SVMX_Event__c> lstEvents) 
    {
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : handleSVMXECOEventDelete ');
      List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(lstEvents); 
        Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = getOptimizersAndConnectionIds(null,lstEvents,technicianIds);
        List<SVMXC__SVMX_Optimizer__c> optimizers =createDeleteOptimizerList(mapIdOptimizer);
        List<String> optimizerIds = saveOptimizerList(optimizers);       
         if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler handleSFECOEventInsert : Alert!! The events do not qualify for ECO ');
          }else{
                manageNonWorkOrderECOEvents(optimizerIds);
          }
        
         //WSCH_AuditLogger.finish();   
    }
    
  
    //Method returns Optimizer object
    public static SVMXC__SVMX_Optimizer__c createOptimizerObject(String eventid, String changeToken,String eventType,String dProcess,String teritory,SVMXC__Service_Group_Members__c technician) 
    {
        SVMXC__SVMX_Optimizer__c obj = new SVMXC__SVMX_Optimizer__c();
        obj.SVMXC__WhatType__c = eventType;
        obj.SVMXC__WhatId__c = eventid+'_'+technician.name;
        obj.SVMXC__Optimizer_Change_Token__c = changeToken;
        obj.SVMXC__Optimizer_Connection_ID__c = dProcess+'_'+teritory+'_'+technician.id;
        obj.SVMXC__Optimizer_Status__c = 'OPT_PENDING';
        return obj;
    }
    
    //Update optimizer objects
    private static SVMXC__SVMX_Optimizer__c updateOptimizerObject(String eventid,SVMXC__SVMX_Optimizer__c objSVMXOptimizer, String changeToken,String dProcess,String teritory,SVMXC__Service_Group_Members__c technician) {
         WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler  : updateOptimizerObject '+changeToken);
         WSCH_AuditLogger.debug('Updating the Optimizer Object to :  '+changeToken+' for territory '+teritory+' Technician : '+technician.Id+' Dispatch Process : '+dProcess);
         objSVMXOptimizer.SVMXC__WhatId__c = eventid+'_'+technician.name;
         objSVMXOptimizer.SVMXC__Optimizer_Change_Token__c = changeToken; 
         objSVMXOptimizer.SVMXC__Optimizer_Connection_ID__c = dProcess+'_'+teritory+'_'+technician.Id;
         objSVMXOptimizer.SVMXC__Optimizer_Status__c = 'OPT_PENDING';
         return objSVMXOptimizer;
    }
    
    //Get optimizer objects related to  events 
    private static map<String,SVMXC__SVMX_Optimizer__c> getEventIdAndOptimizers(list<Event> sfEvents, List<SVMXC__SVMX_Event__c> svmxEvents,list<String> technicianIds)
    { 
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : getEventIdAndOptimizers : svmxEvents : '+svmxEvents);
        map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = new map<String,SVMXC__SVMX_Optimizer__c>();   
        list<String> lstEventID= new list<String> ();           
        list<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizerToExisting = new list<SVMXC__SVMX_Optimizer__c> ();

        Map<Id,SVMXC__Service_Group_Members__c> techniciansMap= WSCH_ECO_CommonUtils.getTechnicians(technicianIds);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : getEventIdAndOptimizers : techniciansMap : '+techniciansMap);
        Map<Id,SVMXC__Service_Group_Members__c> mapOwnerIDTechId = new Map<Id,SVMXC__Service_Group_Members__c>();
        //create ownerId map
        for(SVMXC__Service_Group_Members__c tech : techniciansMap.values()){
                if(tech.SVMXC__Salesforce_User__c != null)
                    mapOwnerIDTechId.put(tech.SVMXC__Salesforce_User__c, tech);   
        }        

          SVMXC__Service_Group_Members__c technician;
            if(null != sfEvents){
             for(Event objEvent : sfEvents){
                //technician = techniciansMap.get(objEvent.WhatId);
                technician = mapOwnerIDTechId.get(objEvent.OwnerId);
                if(null != technician){
                lstEventID.add(objEvent.id+'_'+technician.name);
                }
             }
            }else if (null != svmxEvents){
             for(SVMXC__SVMX_Event__c objEvent : svmxEvents){
                technician = techniciansMap.get(objEvent.SVMXC__Technician__c);
                 if(null != technician){
                    lstEventID.add(objEvent.id+'_'+technician.name); 
                 }
            }
            }
            
         WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : getEventIdAndOptimizers : lstEventID : '+lstEventID);    
        if(lstEventID != null && lstEventID.size() > 0){
            lstSVMXOptimizerToExisting = [Select id, SVMXC__Optimizer_Change_Token__c,SVMXC__Optimizer_External_ID__c,SVMXC__WhatId__c,SVMXC__Optimizer_Status__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in: lstEventID]; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
        }    
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : Optimizer Objects '+lstSVMXOptimizerToExisting);
       String optWhatId;
        for(SVMXC__SVMX_Optimizer__c objOptimizer : lstSVMXOptimizerToExisting){
             if(null != objOptimizer.SVMXC__WhatId__c || objOptimizer.SVMXC__WhatId__c !=''){
                optWhatId = objOptimizer.SVMXC__WhatId__c.split('_')[0];
             }
             mapIdOptimizer.put(optWhatId,objOptimizer);
        }
            
         WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler :getEventIdAndOptimizers '+mapIdOptimizer);
        
        return mapIdOptimizer;
    }

     private static map<String,SVMXC__SVMX_Optimizer__c> getOptimizersAndConnectionIds(list<Event> sfEvents,List<SVMXC__SVMX_Event__c> svmxEvents,list<String> technicianIds)
    { 
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : getOptimizersAndConnectionIds ');
        list<String> lstEventID= new list<String> ();           
        list<SVMXC__SVMX_Optimizer__c> existingOptimizers = new list<SVMXC__SVMX_Optimizer__c> ();
        
         Map<Id,SVMXC__Service_Group_Members__c> techniciansMap= WSCH_ECO_CommonUtils.getTechnicians(technicianIds);
        Map<Id,SVMXC__Service_Group_Members__c> mapOwnerIDTechId = new Map<Id,SVMXC__Service_Group_Members__c>();
        //create ownerId map
        for(SVMXC__Service_Group_Members__c tech : techniciansMap.values()){
                if(tech.SVMXC__Salesforce_User__c != null)
                    mapOwnerIDTechId.put(tech.SVMXC__Salesforce_User__c, tech);   
        }        
         
          SVMXC__Service_Group_Members__c technician;
            if(null != sfEvents){
             for(Event objEvent : sfEvents){
                //technician = techniciansMap.get(objEvent.WhatId);
                technician = mapOwnerIDTechId.get(objEvent.OwnerId);
                if(null != technician){
                lstEventID.add(objEvent.id+'_'+technician.name);
                }
             }}else if (null != svmxEvents){
             for(SVMXC__SVMX_Event__c objEvent : svmxEvents){
                technician = techniciansMap.get(objEvent.SVMXC__Technician__c);
                if(null != technician){
                lstEventID.add(objEvent.id+'_'+technician.name); 
                }
            }}
            
        if(lstEventID != null)  
            existingOptimizers = [Select id, SVMXC__Optimizer_Change_Token__c,SVMXC__Optimizer_External_ID__c,SVMXC__WhatId__c, SVMXC__Optimizer_Connection_ID__c,SVMXC__Optimizer_Status__c from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in: lstEventID]; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : existingOptimizers '+existingOptimizers);
        map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = new map<String,SVMXC__SVMX_Optimizer__c>();   
        for(SVMXC__SVMX_Optimizer__c objOptimizer : existingOptimizers)
            mapIdOptimizer.put(objOptimizer.SVMXC__Optimizer_Connection_ID__c,objOptimizer);
            
         WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler getOptimizersAndConnectionIds '+mapIdOptimizer);
        
        return mapIdOptimizer;
    }
   
    
    // WebService Call
    @future(callout=true)
    public static void manageNonWorkOrderECOEvents(List<String> objSVMX_OtimizerIds)
    {
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler manageNonWorkOrderECOEvents '+objSVMX_OtimizerIds);
        //WSCH_AuditLogger.rca('Optimizer Objetcs are created for the events '+objSVMX_OtimizerIds);
        try
        {
            if(null == objSVMX_OtimizerIds || objSVMX_OtimizerIds.size()==0){
                 WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : Alert !! The Events do not qualify for ECO, No Call out will be made  ');
                 //WSCH_AuditLogger.rca('WSCH_ECO_EventTriggerHandler : Alert !! The Events do not qualify for ECO, No Call out will be made  ');
            }else{
                 list<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizer = WSCH_CommonUtils.fetchSVMXOptimizerById(objSVMX_OtimizerIds);
                 WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : List of SVMX Optimizer : '+ lstSVMXOptimizer);
                
                if(lstSVMXOptimizer != null && lstSVMXOptimizer.size() != 0){
                    WSCH_OptimizedSchedulingService.triggerExecuted = true;
                    WSCH_OptimizedSchedulingService.isCallOutExecuted = true;
                    WSCH_OptimizedSchedulingService.manageNonWorkOrderEvents(lstSVMXOptimizer);
                }
            }
           
        }catch(Exception ex)
        {
            WSCH_AuditLogger.error('Exception caught:WSCH_EventTriggerHandler:manageNonWorkOrderECOEvents() ' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            //WSCH_AuditLogger.rca('Exception caught:WSCH_EventTriggerHandler:manageNonWorkOrderECOEvents() ' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            WSCH_AuditLogger.finish();
        }
    }
  
  
   // Method which takes the event ids , create optimizer objects and forms an object with all the details
   // Multi-resource and Multi-appointment- Added 2 more parameters as sfOldEvents, svmxOldEvents
     public static List<SVMXC__SVMX_Optimizer__c> getNonWorOrderEventOptimizerList(List<String> techniciansIds,List<Event> sfEvents, List<SVMXC__SVMX_Event__c> svmxEvents,
                 Map<String,SVMXC__SVMX_Optimizer__c> eventAndOptimizerMap, List<Event> sfOldEvents, List<SVMXC__SVMX_Event__c> svmxOldEvents, String createTriggerOrUpdateTrigger)
     {
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): techniciansIds '+techniciansIds);
        
        List<SVMXC__SVMX_Optimizer__c> optimizerObjects = new List<SVMXC__SVMX_Optimizer__c>();
        SVMXC__SVMX_Optimizer__c  optimizer = new SVMXC__SVMX_Optimizer__c();
        SVMXC__Service_Group_Members__c technician = new SVMXC__Service_Group_Members__c();
        SVMXC__Territory__c  territory = new SVMXC__Territory__c();
        String dispatchProcessId;
        List<String> idsList = new List<String>();
        String optChangeToken;
       
        //Fetch the technincians
        Map<Id,SVMXC__Service_Group_Members__c> technicians = new Map<Id,SVMXC__Service_Group_Members__c>([Select Id,SVMXC__Salesforce_User__c,SVMXC__Service_Territory__c,name, SVMXC__Working_Hours__c From SVMXC__Service_Group_Members__c where Id in : techniciansIds]);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): technicians.size() '+technicians.size());
        
        List<String> lstOfTechBHIds = new List<String>();
        Map<Id,SVMXC__Service_Group_Members__c> mapOwnerIDTechId = new Map<Id,SVMXC__Service_Group_Members__c>();
        //Fetch the Teritories
        for(SVMXC__Service_Group_Members__c tech : technicians.values()){
                idsList.add(tech.SVMXC__Service_Territory__c);
                lstOfTechBHIds.add(tech.SVMXC__Working_Hours__c);
                if(tech.SVMXC__Salesforce_User__c != null)
                    mapOwnerIDTechId.put(tech.SVMXC__Salesforce_User__c, tech);   
        }
        WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler::getNonWorOrderEventOptimizerList(): mapOwnerIDTechId.size() '+mapOwnerIDTechId.size());
        Map<Id,SVMXC__Territory__c> territories = new Map<Id,SVMXC__Territory__c>([Select Id,SVMXC__Territory_Code__c, SVMXC__Territory_s_Business_Hours__c From SVMXC__Territory__c where Id in : idsList]);
        WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): territories.size() '+territories.size());
        
        //Fetch the Dispatch Processes
        List<Id> idList =  new List<Id>(territories.keySet());
        
        list<SVMXC__SVMX_Jobs__c> territoryJobsList = [Select id, Name, SVMXC__OptiMax_Message__c, SVMXC__SVMX_Process__c, SVMXC__Territory__c,SVMXC__Start_Time__c,SVMXC__Age__c, SVMXC__Status__c, SVMXC__End_Time__c,SVMXC__Type__c from SVMXC__SVMX_Jobs__c where SVMXC__Territory__c In :idList and SVMXC__Type__c = 'ECO' and SVMXC__OptiMax_Message__c != 'IDLE']; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
        Map<String,String> mapOfTeritoryAndProcess = new  Map<String,String>();
        for(SVMXC__SVMX_Jobs__c terJob : territoryJobsList){
           mapOfTeritoryAndProcess.put(terJob.SVMXC__Territory__c,terJob.SVMXC__SVMX_Process__c);
        }
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): mapOfTeritoryAndProcess.size()- '+mapOfTeritoryAndProcess.size());
        
        //Begin: SLA qualification logic for Events
        List<String> dispatchProcessIdsList =  new List<String>(mapOfTeritoryAndProcess.values());
        List<SVMXC__ServiceMax_Processes__c> lstOfDPProcessObj = new List<SVMXC__ServiceMax_Processes__c>();
        
        if(mapOfTeritoryAndProcess != null && mapOfTeritoryAndProcess.size() > 0 ) {
            lstOfDPProcessObj = [SELECT Id, SVMXC__Calendar_Start_Days__c, SVMXC__Calendar_End_Days__c, SVMXC__Dispatch_Method__c, SVMXC__Frequency__c, SVMXC__Full_Run_Unit__c from SVMXC__ServiceMax_Processes__c 
                                                                where RecordType.Name = 'Dispatch Process' AND Id in:dispatchProcessIdsList];
        } /*else {
            //Below logic executes in case of initJob() call wherein the job record is still not created at the client side. Hence we cannot retrieve the DP process based
            //on the
            
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): InitJob context'); 
            
            //retrieve all the Territory process objects.
            List<SVMXC__ServiceMax_Processes__c> lstOfTerritoryProcess = [SELECT Id, SVMXC__Process__c, SVMXC__Territory__c, SVMXC__Rule_Type__c from SVMXC__ServiceMax_Processes__c
                                        WHERE RecordType.Name = 'SVMX Rule' AND SVMXC__Rule_Type__c = 'Territory Access' and SVMXC__Territory__c != ''];
            
            List<Id> lstOfProcessIds = new List<Id>();
            if(lstOfTerritoryProcess != null && lstOfTerritoryProcess.size() > 0) {
                for(SVMXC__ServiceMax_Processes__c eachProcess: lstOfTerritoryProcess) {
                    lstOfProcessIds.add(eachProcess.SVMXC__Process__c);
                    
                    //populate the mapOfTerritoryAndProcess with the territories and DP queried above if they do not already contain.
                    //It happens only in case of initJob()
                    if(!mapOfTeritoryAndProcess.containsKey(eachProcess.SVMXC__Territory__c)) {
                        mapOfTeritoryAndProcess.put(eachProcess.SVMXC__Territory__c, eachProcess.SVMXC__Process__c);
                    }
                }
                //Now retrieve all the RTO DP for all the Territory Process objects retrieved above.
                lstOfDPProcessObj = [SELECT Id, SVMXC__Calendar_Start_Days__c, SVMXC__Calendar_End_Days__c, SVMXC__Dispatch_Method__c, SVMXC__Frequency__c, SVMXC__Full_Run_Unit__c from SVMXC__ServiceMax_Processes__c 
                                    where RecordType.Name = 'Dispatch Process' AND SVMXC__Dispatch_Method__c = 'Real Time Optimization' AND Id in:lstOfProcessIds];
                
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::getNonWorOrderEventOptimizerList(): during initJob() case mapOfTeritoryAndProcess.size() - '+mapOfTeritoryAndProcess.size());
            }
        }*/
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): lstOfDPProcessObj.size() - '+lstOfDPProcessObj.size());
        
        //Create a map of DPid and Dispatch Process
        Map<String, SVMXC__ServiceMax_Processes__c> mapOfIdDispatchProcess = new Map<String, SVMXC__ServiceMax_Processes__c>();
        for(SVMXC__ServiceMax_Processes__c eachDp : lstOfDPProcessObj) {
            mapOfIdDispatchProcess.put(eachDp.Id, eachDp);
        }
        
        //fetch all the territory businessHours Ids to query BHs below
        List<String> lstOfTerrBHIds = new List<String>();
        for(Id eachId : idList) {
            lstOfTerrBHIds.add(territories.get(eachId).SVMXC__Territory_s_Business_Hours__c);
        }
        
        List<String> lstOfTechAndTerrBHIds = new List<String>();
        lstOfTechAndTerrBHIds.addAll(lstOfTechBHIds);
        lstOfTechAndTerrBHIds.addAll(lstOfTerrBHIds);
        
        //TODO: inlcude the tech businessHOur IDS also. Populate the technician BH ids from the above loop already available
        //Fetch the businesshours for all the territories queried above
        List<BusinessHours> lstOfBh = [Select Id, Name, IsDefault, IsActive, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, 
                            WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, 
                            SaturdayEndTime, SundayStartTime, SundayEndTime from BusinessHours where IsActive = TRUE AND 
                            Id in: lstOfTechAndTerrBHIds ];
        
        //Create a map of BHid and BusinessHours
        Map<String, BusinessHours> mapOfIdBussHr = new Map<String, BusinessHours>();
        for(BusinessHours eachBH : lstOfBh) {
            mapOfIdBussHr.put(eachBH.Id, eachBH);           
        }
        
        //TODO: get rid of this map. USe the  above BH map and pass the terrBHid to get the corresponding BH obj
        //create a map of TerrId and BH Object
        Map<String, BusinessHours> mapOfTerrIdBussHr = new Map<String, BusinessHours>();
        for(SVMXC__Territory__c eachTerr : territories.values()) {
            mapOfTerrIdBussHr.put(eachTerr.Id, mapOfIdBussHr.get(eachTerr.SVMXC__Territory_s_Business_Hours__c));
        }
        //End: SLA qualification logic for Events
      
        //Create the info object if the event is salesforce event
        if(sfEvents != null){
            //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler SalesForce Events '+ sfEvents);
            /*for(Event sfEvent : sfEvents)*/
            for(Integer i = 0; i < sfEvents.size(); i++){
            
            Event sfEvent = sfEvents[i];
            
            Event sfOldEvent = new Event();
            if(sfOldEvents != null && sfOldEvents.size() > 0)
               sfOldEvent = (sfOldEvents != null ? sfOldEvents[i] : null);
            
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SF sfEvent '+ sfEvent);
                //identify the event is work order event then skip the callout.
                //Multi-resource and Multi-appointment - Commented out the below workorder event check to allow both workorder and non workder events
                /*if(sfEvent.WhatId != null){
                    String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                    //Event's whatid key prefix
                    String objectPrefix = String.valueOf(sfEvent.WhatId).substring(0,3);                
                    if(woKeyPrefix.equals(objectPrefix)){
                        continue;
                    }
                }*/
                if(mapOwnerIDTechId != null && mapOwnerIDTechId.size() > 0)
                    technician = mapOwnerIDTechId.get(sfEvent.OwnerId);
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SF technician '+ technician);
                  if(technician != null) {
                    territory = territories.get(technician.SVMXC__Service_Territory__c);
                    WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SF territory '+ territory);
                  }
                 if(territory != null){
                    dispatchProcessId = mapOfTeritoryAndProcess.get(territory.Id);
                    WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SF dispatchProcess '+ dispatchProcessId);
                 }
                
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): Existing Optiomizer Map:- '+eventAndOptimizerMap);
                
                if(dispatchProcessId == null) {
                    WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): dispatch Process ID is null. Looks like the job is not running');  
                }
                     
                if(null != dispatchProcessId){
                    WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SF createTriggerOrUpdateTrigger: '+createTriggerOrUpdateTrigger);
                    //Multi-resource and Multi-appointment- to skip the unnecesary update callout
                    /*if(createTriggerOrUpdateTrigger != null && createTriggerOrUpdateTrigger.equals('UpdateTrigger') && (sfEvent != null && sfOldEvent != null) && String.isEmpty(changeSFEventToken(sfEvent, sfOldEvent))){
                        continue;
                    }*/
                   // Check if the map already has the optimizer for this event
                    if(eventAndOptimizerMap !=null && eventAndOptimizerMap.containsKey(sfEvent.id)){ // This only for update scenario
                        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): Update the Optimizer');
                        optChangeToken = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_UPDATE;
                        if((eventAndOptimizerMap.get(sfEvent.Id).SVMXC__Optimizer_Status__c == WSCH_ECO_Constants.ECO_OPT_ERROR)){
                            optChangeToken = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_CREATE;
                        }
                        //Multi-resource and Multi-appointment - update the token based on the modified field of the SF event
                        if(createTriggerOrUpdateTrigger != null && createTriggerOrUpdateTrigger.equals('UpdateTrigger')){
                            if(sfEvent.WhatId != null){
                                String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                                //Event's whatid key prefix
                                String objectPrefix = String.valueOf(sfEvent.WhatId).substring(0,3);                
                                if(woKeyPrefix.equals(objectPrefix)){
                                    continue;
                                }
                            }else if((sfEvent != null && sfOldEvent != null)){ //&& String.isNotEmpty(changeSFEventToken(sfEvent, sfOldEvent))){
                                //optChangeToken = changeSFEventToken(sfEvent, sfOldEvent);
                        optimizer = updateOptimizerObject(sfEvent.Id,eventAndOptimizerMap.get(sfEvent.Id),optChangeToken,dispatchProcessId,territory.id,technician);
                        optimizerObjects.add(optimizer);
                            }
                        }else{
                            continue;
                        }
                        
                    }
                    else{
                        //BEGIN:
                        //Logic to check if the event falls within the SLA or not. If it is within SLA create the opt_trans record,
                        //else do not create it.
                        //Get the horizon start and end dates in territory time zone for a pair of DP Obj and Terr Obj determined above
                        DateTime dtmSchedulingHorizonStartDateTime;
                        DateTime dtmSchedulingHorizonEndDateTime;
                        
                        //Refer the territory BusinessHours
                        BusinessHours horizonBH = mapOfIdBussHr.get(territory.SVMXC__Territory_s_Business_Hours__c);
                        
                        List<DateTime> lstHorizonStartAndEndDateTime = WSCH_CommonUtils.getDPHorizonStartAndEndDates(mapOfIdDispatchProcess.get(dispatchProcessId), horizonBH);
                        if(lstHorizonStartAndEndDateTime != null && lstHorizonStartAndEndDateTime.size() == 2) {
                            dtmSchedulingHorizonStartDateTime = lstHorizonStartAndEndDateTime[0];
                            dtmSchedulingHorizonEndDateTime = lstHorizonStartAndEndDateTime[1];
                        }
                        
                        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::getNonWorOrderEventOptimizerList::sfEvent.StartDateTime:'+sfEvent.StartDateTime);
                        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::getNonWorOrderEventOptimizerList::sfEvent.EndDatetime:'+sfEvent.EndDatetime);
                        
                        Boolean isEventSkipped = WSCH_ECO_EventTriggerHandler.checkEventForSLA(sfEvent.StartDateTime, sfEvent.EndDatetime, dtmSchedulingHorizonStartDateTime, dtmSchedulingHorizonEndDateTime, horizonBH.timeZoneSidKey);
                        //If event is not skipped, create the optimizer trans record for this event
                        if(!isEventSkipped) {
                            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler Create the Optimizer');
                            optChangeToken = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_CREATE;
                            //Multi-resource and Multi-appointment - update the token based on the modified field of the SF event
                            if(sfEvent != null && createTriggerOrUpdateTrigger != null && createTriggerOrUpdateTrigger.equals('InsertTrigger')){
                            optimizer = createOptimizerObject(sfEvent.id,optChangeToken,WSCH_ECO_Constants.OPT_NON_WORK_ORDER_EVENT_TYPE,dispatchProcessId,territory.id,technician);
                            optimizerObjects.add(optimizer);
                            }
                        } else {
                            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList():: Skipping the creation of optimizer transaction as this event is out of SLA');
                        } //END
                    }
                 //optimizerObjects.add(optimizer);
               }
            }
        }
        //Create the info object if the event is a service max event
        else if(svmxEvents != null){
            //for(SVMXC__SVMX_Event__c svmxEvent : svmxEvents)
              for(Integer i = 0; i < svmxEvents.size(); i++){
                SVMXC__SVMX_Event__c svmxEvent = svmxEvents[i];
                
                SVMXC__SVMX_Event__c svmxOldEvent = new SVMXC__SVMX_Event__c();
                if(svmxOldEvents != null && svmxOldEvents.size() > 0)
                    svmxOldEvent = (svmxOldEvents != null ? svmxOldEvents[i] : null);
                
                //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): svmxEvents: '+svmxEvents);
                //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): svmxOldEvents: '+svmxOldEvents);
                //identify the event is work order event then skip the callout.
                //Multi-resource and Multi-appointment - Commented out the below workorder event check to allow both workorder and non workder events
                /*if(svmxEvent.SVMXC__WhatId__c != null){
                    String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                    //Event's whatid key prefix
                    String objectPrefix = String.valueOf(svmxEvent.SVMXC__WhatId__c).substring(0,3);                
                    if(woKeyPrefix.equals(objectPrefix)){
                        continue;
                    }
                }*/                 
                technician = technicians.get(svmxEvent.SVMXC__Technician__c);
                //WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SVMXEvents technician'+technician);
                 if(technician != null) {
                     territory = territories.get(technician.SVMXC__Service_Territory__c);
                    //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): territory'+territory);
                 }
                 if(territory != null){
                    dispatchProcessId = mapOfTeritoryAndProcess.get(territory.Id);
                    //WSCH_AuditLogger.debug(' WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): dispatchProcess'+dispatchProcessId);
                 }
                 
                if(null != dispatchProcessId){
                    WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SVMX svmxOldEvent: '+svmxOldEvent);
                    WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): SVMX createTriggerOrUpdateTrigger: '+createTriggerOrUpdateTrigger+'\n'+' , changeSvmxEventToken(svmxEvent, svmxOldEvent): '+changeSvmxEventToken(svmxEvent, svmxOldEvent)+'\n');
                    //Multi-resource and Multi-appointment- to skip the unnecesary update callout
                    /*if(createTriggerOrUpdateTrigger != null && createTriggerOrUpdateTrigger.equals('UpdateTrigger') && (svmxEvent != null && svmxOldEvent != null) && String.isEmpty(changeSvmxEventToken(svmxEvent, svmxOldEvent))){
                        continue;
                    }*/
                    //Check if the map already has the optimizer for this event
                    if(eventAndOptimizerMap !=null && eventAndOptimizerMap.containsKey(svmxEvent.id)){
                        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): Update the Optimizer');
                        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): Update SVMXEvent scenario createTriggerOrUpdateTrigger: '+createTriggerOrUpdateTrigger+' , svmxEvent: '+svmxEvent+' , svmxOldEvent: '+svmxOldEvent);
                        optChangeToken = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_UPDATE;
                        if((eventAndOptimizerMap.get(svmxEvent.Id).SVMXC__Optimizer_Status__c == WSCH_ECO_Constants.ECO_OPT_ERROR)){
                            optChangeToken = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_CREATE;
                        }
                        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): svmxEvent.SVMXC__WhatId__c: '+svmxEvent.SVMXC__WhatId__c+' , mapEventWorkOrders.get(svmxEvent.SVMXC__WhatId__c): '+mapEventWorkOrders.get(svmxEvent.SVMXC__WhatId__c));
                        //Multi-resource and Multi-appointment - update the token based on the modified field of the SVMX event
                        if(createTriggerOrUpdateTrigger != null && createTriggerOrUpdateTrigger.equals('UpdateTrigger')){
                            if(svmxEvent.SVMXC__WhatId__c != null){
                                String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                                //Event's whatid key prefix
                                String objectPrefix = String.valueOf(svmxEvent.SVMXC__WhatId__c).substring(0,3);                
                                if(woKeyPrefix.equals(objectPrefix)){
                                    continue;
                                }
                            }else if((svmxEvent != null && svmxOldEvent != null)){ //&& String.isNotEmpty(changeSvmxEventToken(svmxEvent, svmxOldEvent))){
                                //optChangeToken = changeSvmxEventToken(svmxEvent, svmxOldEvent);
                        optimizer = updateOptimizerObject(svmxEvent.Id,eventAndOptimizerMap.get(svmxEvent.Id),optChangeToken,dispatchProcessId,territory.id,technician);
                        optimizerObjects.add(optimizer);
                            }
                    } else {
                            continue;
                        }
                        
                    } else {
                        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): Insert SVMXEvent scenario createTriggerOrUpdateTrigger: '+createTriggerOrUpdateTrigger);
                        //BEGIN:
                        //Logic to check if the event falls within the SLA or not. If it is within SLA create the opt_trans record,
                        //else do not create it.
                        DateTime dtmSchedulingHorizonStartDateTime;
                        DateTime dtmSchedulingHorizonEndDateTime;
                        
                        //Refer the territory BusinessHours
                        BusinessHours horizonBH = mapOfIdBussHr.get(territory.SVMXC__Territory_s_Business_Hours__c);
                        
                        List<DateTime> lstHorizonStartAndEndDateTime = WSCH_CommonUtils.getDPHorizonStartAndEndDates(mapOfIdDispatchProcess.get(dispatchProcessId), horizonBH);
                        if(lstHorizonStartAndEndDateTime != null && lstHorizonStartAndEndDateTime.size() == 2) {
                            dtmSchedulingHorizonStartDateTime = lstHorizonStartAndEndDateTime[0];
                            dtmSchedulingHorizonEndDateTime = lstHorizonStartAndEndDateTime[1];
                        }
                        
                        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::getNonWorOrderEventOptimizerList::svmxEvent.SVMXC__StartDateTime__c:'+svmxEvent.SVMXC__StartDateTime__c);
                        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::getNonWorOrderEventOptimizerList::svmxEvent.SVMXC__EndDateTime__c:'+svmxEvent.SVMXC__EndDateTime__c);
                        
                        Boolean isEventSkipped = WSCH_ECO_EventTriggerHandler.checkEventForSLA(svmxEvent.SVMXC__StartDateTime__c, svmxEvent.SVMXC__EndDateTime__c, dtmSchedulingHorizonStartDateTime, dtmSchedulingHorizonEndDateTime, horizonBH.timeZoneSidKey);
                        //If event is not skipped, create the optimizer trans record for this event
                        if(!isEventSkipped) {
                            optChangeToken = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_CREATE;
                            //Multi-resource and Multi-appointment - update the token based on the modified field of the SVMX event
                            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList(): Create the Optimizer');
                            if(svmxEvent != null && createTriggerOrUpdateTrigger != null && createTriggerOrUpdateTrigger.equals('InsertTrigger')){
                                //Check if optimizer records already available for the event then dont create another optimizer record and dont make a callout.Else go ahead.
                            optimizer = createOptimizerObject(svmxEvent.id,optChangeToken,WSCH_ECO_Constants.OPT_NON_WORK_ORDER_EVENT_TYPE,dispatchProcessId,territory.id,technician);
                            optimizerObjects.add(optimizer);
                            }
                        } else {
                            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler:getNonWorOrderEventOptimizerList():: Skipping the creation of optimizer transaction as this event is out of SLA');
                        } //END
                    }
                    //optimizerObjects.add(optimizer);
                 }
            }
        }
        return optimizerObjects;
     }
     
     public static List<String> saveOptimizerList(List<SVMXC__SVMX_Optimizer__c> optimizerObjects){
         WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler The Optimizer Objets to save :- '+optimizerObjects.size());
         List<String> optimizerIdsList = new List<String>();
        if(optimizerObjects.size() > 0) 
        {
            if(COMM_SecurityUtils.getInstance().verifyFieldAccess(optimizerObjects, COMM_SecurityUtils.Access.Upsertable)){     //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                upsert optimizerObjects;
            } else {
                throw new COMM_SecurityUtils.SecurityAccessException(System.label.COMM001_TAG142);
            }
            
            //add the saved optimizer object into into the info object
            for(SVMXC__SVMX_Optimizer__c savedOptimizer : optimizerObjects)
            {
                WSCH_AuditLogger.debug('savedOptimizer:- '+savedOptimizer);
                optimizerIdsList.add(savedOptimizer.id);
            }
       }
       WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler Finished Constructing the SVMXC__SVMX_Optimizer__c List:- '+optimizerIdsList); 
        return optimizerIdsList;
     }    
    
    public static List<SVMXC__SVMX_Optimizer__c> createDeleteOptimizerList( Map<String,SVMXC__SVMX_Optimizer__c> eventAndOptimizerMap ){
                
       WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createDeleteOptimizerList :- '+eventAndOptimizerMap);
       
       SVMXC__ServiceMax_Processes__c dispatchProcess = new SVMXC__ServiceMax_Processes__c();
       SVMXC__SVMX_Optimizer__c optimizer = new SVMXC__SVMX_Optimizer__c();
       List<SVMXC__SVMX_Optimizer__c> optimizerObjects = new List<SVMXC__SVMX_Optimizer__c>();
       
       List<String> dispatchProcessIds = new List<String>();
        for(String connectionId : eventAndOptimizerMap.keySet()){
            if(null != connectionId && connectionId != '' && connectionId.contains('_')){
                dispatchProcessIds.add(connectionId.split('_')[0]);
            }
        } 
        Map<Id,SVMXC__ServiceMax_Processes__c> dispatchProcessMap = new Map<Id,SVMXC__ServiceMax_Processes__c>([SELECT Id, SVMXC__Dispatch_Method__c FROM SVMXC__ServiceMax_Processes__c  where  SVMXC__Record_Type_Name__c='Dispatch Process' and id in : dispatchProcessIds]) ;
       
     
       for(String connectionId : eventAndOptimizerMap.keySet()){
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createDeleteOptimizerList: connectionId '+connectionId); 
            if(null != connectionId && connectionId != '' && connectionId.contains('_')){
                optimizer =  eventAndOptimizerMap.get(connectionId);
                dispatchProcess = dispatchProcessMap.get(connectionId.split('_')[0]);
            
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createDeleteOptimizerList: optimizer '+optimizer); 
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createDeleteOptimizerList: dispatchProcess '+dispatchProcess); 
            
                if(null != dispatchProcess &&  dispatchProcess.SVMXC__Dispatch_Method__c == WSCH_ECO_Constants.OPT_DISPATCH_PROCES_ECO){
                    optimizer.SVMXC__Optimizer_Change_Token__c = WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_DELETE; 
                    optimizerObjects.add(optimizer);
                }   
            }
       }
        return optimizerObjects;
    }
    
    public static boolean checkEventForSLA(Datetime evStartTime, Datetime evEndTime, DateTime dtmSchedulingHorizonStartDateTime, 
                                DateTime dtmSchedulingHorizonEndDateTime, String strTimeZone) {
        
        Boolean isEventSkipped = false;
        
        DateTime dtmSchedulingHorizonStartDateTimeGMT = WSCH_DateUtils.doTZConversion(dtmSchedulingHorizonStartDateTime, strTimeZone, 'GMT');
        DateTime dtmSchedulingHorizonEndDateTimeGMT = WSCH_DateUtils.doTZConversion(dtmSchedulingHorizonEndDateTime, strTimeZone, 'GMT');
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::evStartTime:'+evStartTime);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::evEndTime:'+evEndTime);
        
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::dtmSchedulingHorizonStartDateTimeGMT:'+dtmSchedulingHorizonStartDateTimeGMT);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::dtmSchedulingHorizonEndDateTimeGMT:'+dtmSchedulingHorizonEndDateTimeGMT);
        
        if(evStartTime < dtmSchedulingHorizonStartDateTimeGMT && evEndTime < dtmSchedulingHorizonStartDateTimeGMT) {
            //both the event start and end datetime are in the past. So skip the creation of opt_trans records'
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::Event is in past date. Hence could not be sent to server');
            isEventSkipped = true;
        
        } else if(evStartTime > dtmSchedulingHorizonEndDateTimeGMT && evEndTime > dtmSchedulingHorizonEndDateTimeGMT) {
            //both the event start and end datetimes are in future. So skip the creation of opt_trans records'.
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::Event is out of Horizon. Hence it is skipped for now');
            isEventSkipped = true;
            
        } else if(evStartTime < dtmSchedulingHorizonStartDateTimeGMT && evEndTime > dtmSchedulingHorizonEndDateTimeGMT) {
            //Event start datetime is in the past and end datetime is in future. So skip the creation of opt_trans records'
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::checkEventForSLA::Event is out of Horizon. Hence it is skipped for now');
            isEventSkipped = true;
        }
        return isEventSkipped;
    }       
    
    //Multi-resource and Multi-appointment
    //To check whether the value of StartDateTime, EndDateTime, latitude, logitude, Technician, Service duration of an existing SVMX event is modified
    public static String changeSvmxEventToken(SVMXC__SVMX_Event__c newEvent, SVMXC__SVMX_Event__c oldEvent) {
        Decimal oldlatitude = null;
        Decimal oldlongitude = null;
        Decimal newlatitude = null;
        Decimal newlongitude = null;
        
        String schedulingChangeEventToken = '';
        
        if(newEvent != null && oldEvent != null){
        //round an arbitrary Decimal to 3 decimal for compare
        /*if(oldEvent.SVMXC__SM_Latitude__c != null)
            oldlatitude = oldEvent.SVMXC__SM_Latitude__c.setScale(3);
        
        if(newEvent.SVMXC__SM_Latitude__c != null)
            newlatitude = newEvent.SVMXC__SM_Latitude__c.setScale(3);
    
        if(oldEvent.SVMXC__SM_Longitude__c != null)
            oldlongitude =oldEvent.SVMXC__SM_Longitude__c.setScale(3);
        
        if(newEvent.SVMXC__SM_Longitude__c != null)
            newlongitude = newEvent.SVMXC__SM_Longitude__c.setScale(3);*/
                        
            
        if(newEvent.SVMXC__StartDateTime__c != oldEvent.SVMXC__StartDateTime__c){
                schedulingChangeEventToken = 'CHANGE_EVENT_START_DATE';
        }else if(newEvent.SVMXC__EndDateTime__c != oldEvent.SVMXC__EndDateTime__c){
                schedulingChangeEventToken = 'CHANGE_EVENT_END_DATE';
            }else if((newlatitude != oldlatitude) || (newlongitude != oldlongitude)){
                //schedulingChangeEventToken = 'CHANGE_EVENT_LAT_LONG';
            }else if(newEvent.SVMXC__Technician__c != oldEvent.SVMXC__Technician__c){
            schedulingChangeEventToken = 'CHANGE_EVENT_TECHNICIAN';
        }else if(newEvent.SVMXC__Service_Duration__c != oldEvent.SVMXC__Service_Duration__c){
            schedulingChangeEventToken = 'CHANGE_EVENT_SERVICE_DURATION';
        }
        
        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::changeSvmxEventToken::newEvent.SVMXC__Technician__c : '+newEvent.SVMXC__Technician__c+' , oldEvent.SVMXC__Technician__c : '+oldEvent.SVMXC__Technician__c);
        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::changeSvmxEventToken::newEvent.SVMXC__Service_Duration__c : '+newEvent.SVMXC__Service_Duration__c+' , oldEvent.SVMXC__Service_Duration__c : '+oldEvent.SVMXC__Service_Duration__c);
        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::changeSvmxEventToken::schedulingChangeEventToken : '+schedulingChangeEventToken);
        }
        
        return schedulingChangeEventToken;
    }
    
    //Multi-resource and Multi-appointment
    //To check whether the value of StartDateTime, EndDateTime, latitude, logitude, Technician, Service duration of an existing SF event is modified
    public static String changeSFEventToken(Event newEvent, Event oldEvent) {
        Decimal oldlatitude = null;
        Decimal oldlongitude = null;
        Decimal newlatitude = null;
        Decimal newlongitude = null;
        
        String schedulingChangeEventToken = '';
        if(newEvent != null && oldEvent != null){
        //round an arbitrary Decimal to 3 decimal for compare
        /*if(oldEvent.SVMXC__SM_Latitude__c != null)
            oldlatitude = oldEvent.SVMXC__SM_Latitude__c.setScale(3);
        
        if(newEvent.SVMXC__SM_Latitude__c != null)
            newlatitude = newEvent.SVMXC__SM_Latitude__c.setScale(3);
    
        if(oldEvent.SVMXC__SM_Longitude__c != null)
            oldlongitude =oldEvent.SVMXC__SM_Longitude__c.setScale(3);
        
        if(newEvent.SVMXC__SM_Longitude__c != null)
            newlongitude = newEvent.SVMXC__SM_Longitude__c.setScale(3);*/
                        
        if(newEvent.StartDateTime != oldEvent.StartDateTime){
                schedulingChangeEventToken = 'CHANGE_EVENT_START_DATE';
        }else if(newEvent.EndDateTime != oldEvent.EndDateTime){
                schedulingChangeEventToken = 'CHANGE_EVENT_END_DATE';
            }else if((newlatitude != oldlatitude) || (newlongitude != oldlongitude)){
                //schedulingChangeEventToken = 'CHANGE_EVENT_LAT_LONG';
            }else if(newEvent.SVMXC__Service_Duration__c != oldEvent.SVMXC__Service_Duration__c){
            schedulingChangeEventToken = 'CHANGE_EVENT_SERVICE_DURATION';
        }else if(newEvent.OwnerId != oldEvent.OwnerId){
            schedulingChangeEventToken = 'CHANGE_EVENT_TECHNICIAN';
        }
        }
        return schedulingChangeEventToken;
    }
    
    //Multi-resource and Multi-appointment
    //When someone assign one more technician to a workorder in the DC
    //Check if the Optimizer transaction has entry for the existing events
    //a)If no entry found in the optimizer transactions then pass all the events in the same callout to create a pillar(finalEventListForPillar).
    //b)If previously created events has entry in the optimizer transactions then pass only the newly created event as a pillar(finalEventListForPillar).  
    public static List<SVMXC__SVMX_Event__c> multiSVMXPillar(Map<Id, SVMXC__Service_Order__c> mapWoIdWoObj)
    {   
        List<SVMXC__SVMX_Event__c> listSVMXEvents =  [Select Id, SVMXC__WhatId__c, SVMXC__Technician__c, SVMXC__StartDateTime__c, SVMXC__EndDateTime__c from SVMXC__SVMX_Event__c where SVMXC__WhatId__c In : mapWoIdWoObj.keySet()];
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : multiSVMXPillar : listSVMXEvents.size() : '+listSVMXEvents.size());
        map<String, List<SVMXC__SVMX_Event__c>> mapWOIdSvmxEvnt = new map<String, list<SVMXC__SVMX_Event__c>>();
        
        for(SVMXC__SVMX_Event__c svmxEvnt : listSVMXEvents){
            list<SVMXC__SVMX_Event__c> listSVMXEvnt = new list<SVMXC__SVMX_Event__c>();
            if(mapWOIdSvmxEvnt.containsKey(svmxEvnt.SVMXC__WhatId__c)){
                list<SVMXC__SVMX_Event__c> tmpLstSvmxEvnt = mapWOIdSvmxEvnt.get(svmxEvnt.SVMXC__WhatId__c);
                tmpLstSvmxEvnt.add(svmxEvnt);
                mapWOIdSvmxEvnt.put(svmxEvnt.SVMXC__WhatId__c,tmpLstSvmxEvnt);
            }else{
                listSVMXEvnt.add(svmxEvnt);
                mapWOIdSvmxEvnt.put(svmxEvnt.SVMXC__WhatId__c,listSVMXEvnt);
            }
        }
        
        List<SVMXC__SVMX_Event__c> listSingleSVMXEvnts = new List<SVMXC__SVMX_Event__c>();
        List<SVMXC__SVMX_Event__c> listMultiSVMXEvnts = new List<SVMXC__SVMX_Event__c>();
        if(mapWOIdSvmxEvnt != null && mapWOIdSvmxEvnt.size() > 0){
            for(String woId : mapWOIdSvmxEvnt.keySet()){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::multiSVMXPiller::mapWoIdWoObj.get(woId).SVMXC__Locked_By_DC__c: '+mapWoIdWoObj.get(woId).SVMXC__Locked_By_DC__c);
                if(mapWOIdSvmxEvnt.get(woId).size() == 1 && mapWoIdWoObj.get(woId).SVMXC__Locked_By_DC__c == true){
                    listSingleSVMXEvnts.add(mapWOIdSvmxEvnt.get(woId)[0]);
                }else{
                    listMultiSVMXEvnts.addAll(mapWOIdSvmxEvnt.get(woId));
                }
            }
        }
        
        Map<String,SVMXC__SVMX_Optimizer__c> mapEventIdOptimizerRecrd = new Map<String,SVMXC__SVMX_Optimizer__c>();
        if(listMultiSVMXEvnts != null && listMultiSVMXEvnts.size() > 0){ 
            mapEventIdOptimizerRecrd = getEventIdAndOptimizerRcrd(null,listMultiSVMXEvnts);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::multiSVMXPiller::mapEventIdOptimizerRecrd:'+mapEventIdOptimizerRecrd);
        }else if(listSingleSVMXEvnts != null && listSingleSVMXEvnts.size() > 0){
            //TODO: Need to handle external workorder event inserted from DC
            //TODO: Need to make pillar callout
            mapEventIdOptimizerRecrd = getEventIdAndOptimizerRcrd(null,listSingleSVMXEvnts);
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::multiSVMXPiller:: The workorder has single event and corresponding workorder Locked By DC is true mapEventIdOptimizerRecrd.size(): '+mapEventIdOptimizerRecrd.size());
            //return null;
        }
        List<SVMXC__SVMX_Event__c> newEventListForPillar = new List<SVMXC__SVMX_Event__c>();
        if(mapEventIdOptimizerRecrd != null && mapEventIdOptimizerRecrd.size() > 0){
            for(SVMXC__SVMX_Event__c event : listMultiSVMXEvnts){
                if(!mapEventIdOptimizerRecrd.containsKey(event.id)){
                    newEventListForPillar.add(event); 
                }
            }
        }else{
            if(listMultiSVMXEvnts != null && listMultiSVMXEvnts.size() > 0){
            newEventListForPillar = listMultiSVMXEvnts;
            }else if(listSingleSVMXEvnts != null && listSingleSVMXEvnts.size() > 0){
                newEventListForPillar = listSingleSVMXEvnts;
        }
        }
        return newEventListForPillar;
    }
    
    //Multi-resource and Multi-appointment
    //When someone assign one more technician to a workorder in the DC
    //Check if the Optimizer transaction has entry for the existing events
    //a)If no entry found in the optimizer transactions then pass all the events in the same callout to create a piller(finalEventListForPillar).
    //b)If previously created events has entry in the optimizer transactions then pass only the newly created event as a piller(finalEventListForPillar).  
    public static List<Event> multiSFPillar(Map<Id, SVMXC__Service_Order__c> mapWoIdWoObj)
    {   
        List<Event> listSFvents =  [Select Id, WhatId, OwnerId, StartDateTime, EndDateTime from Event where WhatId In : mapWoIdWoObj.keySet()];
        map<String, List<Event>> mapWOIdSFEvnt = new map<String, list<Event>>();
        
        for(Event sfEvnt : listSFvents){
            list<Event> listSFEvnt = new list<Event>();
            if(mapWOIdSFEvnt.containsKey(sfEvnt.WhatId)){
                list<Event> tmpLstSFEvnt = mapWOIdSFEvnt.get(sfEvnt.WhatId);
                tmpLstSFEvnt.add(sfEvnt);
                mapWOIdSFEvnt.put(sfEvnt.WhatId,tmpLstSFEvnt);
            }else{
                listSFEvnt.add(sfEvnt);
                mapWOIdSFEvnt.put(sfEvnt.WhatId,listSFEvnt);
            }
        }
                
        List<Event> listSingleSFEvnts = new List<Event>();
        List<Event> listMultiSFEvnts = new List<Event>();
        if(mapWOIdSFEvnt != null && mapWOIdSFEvnt.size() > 0){
            for(String woId : mapWOIdSFEvnt.keySet()){
                if(mapWOIdSFEvnt.get(woId).size() == 1 && mapWoIdWoObj.get(woId).SVMXC__Locked_By_DC__c == true){
                    listSingleSFEvnts.add(mapWOIdSFEvnt.get(woId)[0]);
                }else{
                    listMultiSFEvnts.addAll(mapWOIdSFEvnt.get(woId));
                }
         }  
    }
    
        Map<String,SVMXC__SVMX_Optimizer__c> mapEventIdOptimizerRecrd = new Map<String,SVMXC__SVMX_Optimizer__c>();
        if(listMultiSFEvnts != null && listMultiSFEvnts.size() > 0){ 
            mapEventIdOptimizerRecrd = getEventIdAndOptimizerRcrd(listMultiSFEvnts,null);
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::multiSFPiller::mapEventIdOptimizerRecrd:'+mapEventIdOptimizerRecrd);
        }else if(listSingleSFEvnts != null && listSingleSFEvnts.size() > 0){
            //TODO: Need to handle external workorder event inserted from DC
            //TODO: Need to make pillar callout
            mapEventIdOptimizerRecrd = getEventIdAndOptimizerRcrd(listSingleSFEvnts,null);
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::multiSFMXPiller:: The workorder has single event and corresponding workorder Locked By DC is true mapEventIdOptimizerRecrd.size(): '+mapEventIdOptimizerRecrd.size());
            //return null;
        }
        List<Event> newEventListForPillar = new List<Event>();
        if(mapEventIdOptimizerRecrd != null && mapEventIdOptimizerRecrd.size() > 0){
            for(Event event : listMultiSFEvnts){
                if(!mapEventIdOptimizerRecrd.containsKey(event.id)){
                    newEventListForPillar.add(event); 
            }
        }
        }else{
            if(listMultiSFEvnts != null && listMultiSFEvnts.size() > 0){
            newEventListForPillar = listMultiSFEvnts;
            }else if(listSingleSFEvnts != null && listSingleSFEvnts.size() > 0){
                newEventListForPillar = listSingleSFEvnts;
            }
                }
        
        return newEventListForPillar;
            }
        
    //Multi-resource and Multi-appointment
    //Update the lat long of the new events created during Multi-resource and Multi-appointment
    public static void updateSVMXEventLatLong(list<String> listWOEventWhatIds, List<SVMXC__SVMX_Event__c> listSVMXEvents){
        Map<Id, SVMXC__Service_Order__c> mapEventWorkOrders = new Map<Id, SVMXC__Service_Order__c>();
        mapEventWorkOrders.putAll([Select Id, Name, SVMXC__Latitude__c, SVMXC__Longitude__c from SVMXC__Service_Order__c where Id IN: listWOEventWhatIds]);
        
        Map<Id, List<Double>> mapWoIdLatLong = new Map<Id, List<Double>>();
        if(mapEventWorkOrders != null){
            for(Id woId : listWOEventWhatIds){
                List<Double> lstLatLong = new List<Double>();
                if(mapEventWorkOrders.get(woId) != null){
                    lstLatLong.add(mapEventWorkOrders.get(woId).SVMXC__Latitude__c);
                    lstLatLong.add(mapEventWorkOrders.get(woId).SVMXC__Longitude__c);
                    mapWoIdLatLong.put(woId,lstLatLong);
                }
            }
        }
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::updateSVMXEventLatLong::mapWoIdLatLong: '+mapWoIdLatLong);
        for(SVMXC__SVMX_Event__c svmxEvnt : listSVMXEvents){
            if(mapWoIdLatLong != null && mapWoIdLatLong.get(svmxEvnt.SVMXC__WhatId__c) != null){
                if(svmxEvnt.SVMXC__SM_Latitude__c == null || svmxEvnt.SVMXC__SM_Longitude__c == null){
                   svmxEvnt.SVMXC__SM_Latitude__c = mapWoIdLatLong.get(svmxEvnt.SVMXC__WhatId__c)[0];
                   svmxEvnt.SVMXC__SM_Longitude__c = mapWoIdLatLong.get(svmxEvnt.SVMXC__WhatId__c)[1];   
                }
            }
        }
    
    }
    
    
    //Multi-resource and Multi-appointment
    //Update the lat long of the new events created during Multi-resource and Multi-appointment
    public static void updateSFEventLatLong(List<Event> listSFvents){
        list<String> listWOEventWhatIds = new list<String>();
        for(Event evnt : listSFvents){
            listWOEventWhatIds.add(evnt.WhatId);
        }
        
        Map<Id, SVMXC__Service_Order__c> mapEventWorkOrders = new Map<Id, SVMXC__Service_Order__c>();
        mapEventWorkOrders.putAll([Select Id, Name, SVMXC__Latitude__c, SVMXC__Longitude__c from SVMXC__Service_Order__c where Id IN: listWOEventWhatIds]);
        
        Map<Id, List<Double>> mapWoIdLatLong = new Map<Id, List<Double>>();
        if(mapEventWorkOrders != null){
            for(Id woId : listWOEventWhatIds){
                List<Double> lstLatLong = new List<Double>();
                if(mapEventWorkOrders.get(woId) != null){
                    lstLatLong.add(mapEventWorkOrders.get(woId).SVMXC__Latitude__c);
                    lstLatLong.add(mapEventWorkOrders.get(woId).SVMXC__Longitude__c);
                    mapWoIdLatLong.put(woId,lstLatLong);
                }
            }
        }
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::updateSFEventLatLong::mapWoIdLatLong: '+mapWoIdLatLong);
        for(Event sfEvn : listSFvents){
            if(mapWoIdLatLong != null && mapWoIdLatLong.get(sfEvn.WhatId) != null){
                if(sfEvn.SVMXC__SM_Latitude__c == null && sfEvn.SVMXC__SM_Longitude__c == null){
                   sfEvn.SVMXC__SM_Latitude__c = mapWoIdLatLong.get(sfEvn.WhatId)[0];
                   sfEvn.SVMXC__SM_Longitude__c = mapWoIdLatLong.get(sfEvn.WhatId)[1];   
            }
        }
        }
    }
    
    //Multi-resource and Multi-appointment
    //Get optimizer objects related to the events 
    private static map<String,SVMXC__SVMX_Optimizer__c> getEventIdAndOptimizerRcrd(list<Event> sfEvents, List<SVMXC__SVMX_Event__c> svmxEvents)
    { 
        map<String,SVMXC__SVMX_Optimizer__c> mapEvtIdOptimizer = new map<String,SVMXC__SVMX_Optimizer__c>();   
        list<String> lstEventID= new list<String> ();           
        list<SVMXC__SVMX_Optimizer__c> lstExistingOptimizer = new list<SVMXC__SVMX_Optimizer__c> ();
    
        list<String> technicianIds = null;
        if(sfEvents != null)
            technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(sfEvents); 
        if(svmxEvents != null)  
            technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(svmxEvents);
    
        Map<Id,SVMXC__Service_Group_Members__c> techniciansMap= WSCH_ECO_CommonUtils.getTechnicians(technicianIds);
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : getEventIdAndOptimizers : techniciansMap : '+techniciansMap);
        Map<Id,SVMXC__Service_Group_Members__c> mapOwnerIDTechId = new Map<Id,SVMXC__Service_Group_Members__c>();
        //create ownerId map
        for(SVMXC__Service_Group_Members__c tech : techniciansMap.values()){
                if(tech.SVMXC__Salesforce_User__c != null)
                    mapOwnerIDTechId.put(tech.SVMXC__Salesforce_User__c, tech);   
        }        
    
          SVMXC__Service_Group_Members__c technician;
            if(null != sfEvents){
             for(Event objEvent : sfEvents){
                //technician = techniciansMap.get(objEvent.WhatId);
                technician = mapOwnerIDTechId.get(objEvent.OwnerId);
                if(null != technician){
                lstEventID.add(objEvent.id+'_'+technician.name);
                }
             }
            }else if (null != svmxEvents){
             for(SVMXC__SVMX_Event__c objEvent : svmxEvents){
                technician = techniciansMap.get(objEvent.SVMXC__Technician__c);
                 if(null != technician){
                    lstEventID.add(objEvent.id+'_'+technician.name); 
                 }
            }
            }
         
         WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : getEventIdAndOptimizers : lstEventID : '+lstEventID);    
        if(lstEventID != null && lstEventID.size() > 0){
            lstExistingOptimizer = [Select id, SVMXC__Optimizer_Change_Token__c,SVMXC__Optimizer_External_ID__c,SVMXC__WhatId__c,SVMXC__Optimizer_Status__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in: lstEventID];
        }    
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler : Optimizer Objects lstExistingOptimizer : '+lstExistingOptimizer);
        String optEvntId;
        for(SVMXC__SVMX_Optimizer__c objOptimizer : lstExistingOptimizer){
             if(null != objOptimizer.SVMXC__WhatId__c || objOptimizer.SVMXC__WhatId__c !=''){
                optEvntId = objOptimizer.SVMXC__WhatId__c.split('_')[0];
             }
             mapEvtIdOptimizer.put(optEvntId,objOptimizer);
        }
            
        //WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler :mapEvtIdOptimizer '+mapEvtIdOptimizer);
        
        return mapEvtIdOptimizer;
    }
    

    //Multi-resource and Multi-appointment
    //Create a pillar when the workorder locked by DC is made from false to true and the workorder has only one event
    public static void createPillar(List<String> listWOIds){
        List<SVMXC__SVMX_Event__c> listSVMXEvents =  [Select Id, SVMXC__WhatId__c, SVMXC__IsAllDayEvent__c, SVMXC__Technician__c, SVMXC__StartDateTime__c, SVMXC__EndDateTime__c from SVMXC__SVMX_Event__c where SVMXC__WhatId__c In : listWOIds];
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::createPillar listSVMXEvents.size(): '+listSVMXEvents.size());
        
        map<String, List<SVMXC__SVMX_Event__c>> mapWOIdSvmxEvnt = new map<String, list<SVMXC__SVMX_Event__c>>();
        
        if(listSVMXEvents != null && listSVMXEvents.size() > 0){
            for(SVMXC__SVMX_Event__c svmxEvnt : listSVMXEvents){
                list<SVMXC__SVMX_Event__c> listSVMXEvnt = new list<SVMXC__SVMX_Event__c>();
                if(mapWOIdSvmxEvnt.containsKey(svmxEvnt.SVMXC__WhatId__c)){
                    list<SVMXC__SVMX_Event__c> tmpLstSvmxEvnt = mapWOIdSvmxEvnt.get(svmxEvnt.SVMXC__WhatId__c);
                    tmpLstSvmxEvnt.add(svmxEvnt);
                    mapWOIdSvmxEvnt.put(svmxEvnt.SVMXC__WhatId__c,tmpLstSvmxEvnt);
                }else{
                    listSVMXEvnt.add(svmxEvnt);
                    mapWOIdSvmxEvnt.put(svmxEvnt.SVMXC__WhatId__c,listSVMXEvnt);
                }
            }
        }
        
        List<SVMXC__SVMX_Event__c> listSingleSVMXEvnts = new List<SVMXC__SVMX_Event__c>();
        if(mapWOIdSvmxEvnt != null && mapWOIdSvmxEvnt.size() > 0){
            for(String woId : mapWOIdSvmxEvnt.keySet()){
                if(mapWOIdSvmxEvnt.get(woId).size() == 1){
                    listSingleSVMXEvnts.add(mapWOIdSvmxEvnt.get(woId)[0]);
                }
            }
        }
        
        if(listSingleSVMXEvnts != null && listSingleSVMXEvnts.size() > 0){
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::createPillar for SVMX single event listSingleSVMXEvnts.size(): '+listSingleSVMXEvnts.size());
            createPillarSVMXECOSingleEvent(listSingleSVMXEvnts);
        }
        
        
        List<Event> listSFEvents =  [Select Id, WhatId, IsAllDayEvent, ownerId, StartDateTime, EndDatetime from Event where WhatId In : listWOIds];
        map<String, List<Event>> mapWOIdSFEvnt = new map<String, list<Event>>();
        
        if(listSFEvents != null && listSFEvents.size() > 0){
            for(Event sfEvnt : listSFEvents){
                list<Event> listSFEvnt = new list<Event>();
                if(mapWOIdSFEvnt.containsKey(sfEvnt.WhatId)){
                    list<Event> tmpLstSvmxEvnt = mapWOIdSFEvnt.get(sfEvnt.WhatId);
                    tmpLstSvmxEvnt.add(sfEvnt);
                    mapWOIdSFEvnt.put(sfEvnt.WhatId,tmpLstSvmxEvnt);
                }else{
                    listSFEvnt.add(sfEvnt);
                    mapWOIdSFEvnt.put(sfEvnt.WhatId,listSFEvnt);
                }
            }
        }
    
        List<Event> listSingleSFEvnts = new List<Event>();
        if(mapWOIdSFEvnt != null && mapWOIdSFEvnt.size() > 0){
            for(String woId : mapWOIdSFEvnt.keySet()){
                if(mapWOIdSFEvnt.get(woId).size() == 1){
                    listSingleSFEvnts.add(mapWOIdSFEvnt.get(woId)[0]);
                }
            }
        }
        if(listSingleSFEvnts != null && listSingleSFEvnts.size() > 0){
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::createPillar for SF single event');
            createPillarSFECOSingleEvent(listSingleSFEvnts);
        }
    }
    
    
    //Multi-resource and Multi-appointment
    public static void createPillarSVMXECOSingleEvent(list<SVMXC__SVMX_Event__c> lstevent){
        List<SVMXC__SVMX_Event__c> lstValidSVMXEvents = new List<SVMXC__SVMX_Event__c>();
        for(SVMXC__SVMX_Event__c svmxEvent : lstevent){
            if(svmxEvent.SVMXC__IsAllDayEvent__c == true){//if it is all day event then skip the callout.
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::createPillarSVMXECOSingleEvent::This is all day event so skipping callout. Technician work hours needs to be adjusted:');
                continue;
            }
            lstValidSVMXEvents.add(svmxEvent);          
        }
        if(lstValidSVMXEvents.size() == 0){
            WSCH_AuditLogger.finish();
            return;
        }
        List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(lstValidSVMXEvents);
        if(null != technicianIds && technicianIds.size() > 0 ){
            List<SVMXC__SVMX_Optimizer__c> optimizers = getNonWorOrderEventOptimizerList(technicianIds,null,lstValidSVMXEvents,null,null,null,'InsertTrigger');
            List<String> optimizerIds = saveOptimizerList(optimizers);       
            if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createPillarSVMXECOSingleEvent : Alert!! The events do not qualify for ECO ');
           }else{
                manageNonWorkOrderECOEvents(optimizerIds);
           }
        }else{
           WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createPillarSVMXECOSingleEvent : Alert!! The events are not Non Work Order Events ');
        }
    }
    
    
    //Multi-resource and Multi-appointment
    public static void createPillarSFECOSingleEvent(List<Event> events){
        List<Event> lstValidEvents = new List<Event>();
        for(Event sfEvent : events){
            if(sfEvent.IsAllDayEvent == true){//if it is all day event then skip the callout.
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::createPillarSFECOSingleEvent::This is all day event so skipping callout. Technician work hours needs to be adjusted:');
                continue;
            }
            lstValidEvents.add(sfEvent);
        }       
        if(lstValidEvents == null){
            WSCH_AuditLogger.finish();
            return;
        }
        
        List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(lstValidEvents);  
        WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::createPillarSFECOSingleEvent::technicianIds:'+technicianIds);
        
        if(null != technicianIds && technicianIds.size() > 0 ){
          List<SVMXC__SVMX_Optimizer__c> optimizers = getNonWorOrderEventOptimizerList(technicianIds,lstValidEvents,null,null,null,null,'InsertTrigger');
          List<String> optimizerIds = saveOptimizerList(optimizers);
          if(null ==optimizerIds || optimizerIds.size()==0){
                WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createPillarSFECOSingleEvent : Alert!! The events do not qualify for ECO ');
            }else{
                manageNonWorkOrderECOEvents(optimizerIds);
          }
        }else{
           WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler createPillarSFECOSingleEvent : Alert!! The events are not Non Work Order Events ');
        }
        
    }
 
     //Method to return technicians associated with SF event
/*    private static map<id,SVMXC__Service_Group_Members__c> getTechniciansSFEvent(List<Event> lstevent) {
        
        List<String> users = new List<String>();
        //Building event owner(SF user) list
        for(Event objEvent: lstevent)
        {
            if(isNonWOSFEvent(objEvent)) 
                users.add(objEvent.ownerId);
        }
        //Retrieving all technicians associated with event owner(SF user)
        map<id,SVMXC__Service_Group_Members__c> mapSFuserIdTechObj = new map<id,SVMXC__Service_Group_Members__c>();
        List<SVMXC__Service_Group_Members__c> lstTechnicians = [Select Name, Id,SVMXC__Optimizer_External_ID__c,SVMXC__Service_Territory__c,SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__c, SVMXC__Salesforce_User__c, SVMXC__Working_Hours__c, SVMXC__Working_Hours__r.IsActive  From SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c IN :users];
        for(SVMXC__Service_Group_Members__c tech :lstTechnicians){
            mapSFuserIdTechObj.put(tech.SVMXC__Salesforce_User__c, tech);
        }
        
        return mapSFuserIdTechObj;
    }
    
    //Method to check whether the given Salesforce event object is Non WO event
    private static boolean isNonWOSFEvent(Event objEvent)
    {
        try
        {
            if(objEvent.WhatId != null){
                String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                //Technician key prefix
                String techKeyPrefix = Schema.SObjectType.SVMXC__Service_Group_Members__c.getKeyPrefix();
                //Event's whatid key prefix
                String objectPrefix = String.valueOf(objEvent.WhatId).substring(0,3);
                
                if(woKeyPrefix.equals(objectPrefix)){
                    return false;
                }else if(techKeyPrefix.equals(objectPrefix)){
                        return true;
                }               
            } else  {
                    return true;
            }
            return false;           
        }
        catch(Exception ex)
        {
            WSCH_AuditLogger.error('Exception caught:WSCH_ECO_EventTriggerHandler:isNonWOSFEvent() ' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            return false;
        }
    }
       
   private static boolean isShiftEvent(Event sfEvent, map<id,SVMXC__Service_Group_Members__c> mapOwnderIdTech, Map<String, BusinessHours> mapBHours )
   {
        try
        {
            SVMXC__Service_Group_Members__c technician = mapOwnderIdTech.get(sfEvent.OwnerId);
            DateTime eventStartDatetime = sfEvent.StartDateTime;
            DateTime eventEndDatetime = sfEvent.EndDateTime;
            BusinessHours techBH;
            if(technician.SVMXC__Working_Hours__c != null){
                techBH = mapBHours.get(technician.SVMXC__Working_Hours__c);
            }else if(technician.SVMXC__Service_Territory__c != null &&  technician.SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__c != null){
                techBH = mapBHours.get(technician.SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__c);
            }
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::isShiftEvent()::techBH '+techBH);             
            List<DateTime> lstOfBHDateTime = WSCH_CommonUtils.getBHStartEndDateTime(eventStartDatetime.dateGMT(), techBH);
            WSCH_AuditLogger.debug('WSCH_ECO_EventTriggerHandler::isShiftEvent()::lstOfBHDateTime '+lstOfBHDateTime);           
            if(lstOfBHDateTime != null && lstOfBHDateTime.size() == 2) {
                DateTime bhStartDateTime = lstOfBHDateTime.get(0);
                DateTime bhEndDateTime = lstOfBHDateTime.get(1);
                if(eventStartDatetime == bhStartDateTime || eventEndDatetime == bhEndDateTime)
                    return true;
            }           
        return false;       
        }catch(Exception ex)
        {
            WSCH_AuditLogger.error('Exception caught:WSCH_ECO_EventTriggerHandler:isShiftEvent() ' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            return false;       
        }
   }
   
    //Method returns Optimizer object
    public static SVMXC__SVMX_Optimizer__c getOptimizerObject(string eventid, string changeToken) 
    {
        SVMXC__SVMX_Optimizer__c obj = new SVMXC__SVMX_Optimizer__c();
        obj.SVMXC__WhatType__c = 'NON_WO_EVENT';
        obj.SVMXC__WhatId__c = eventid;
        obj.SVMXC__Optimizer_Change_Token__c = changeToken;
        return obj;
    } */   
}