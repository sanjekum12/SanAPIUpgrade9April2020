/**
@ Name: WSCH_TechnicianTriggerHandler
@ Author: Anantha Kumar
@ Description: Define future call to Synchronize Technician Data. Invokes the SP API call based on the type of change in Technician.
 **/
public with sharing class WSCH_TechnicianTriggerHandler {

    //Method to create optimizer object related to Technician INSERT. 
    public static void handleTechnicianInsert(List<SVMXC__Service_Group_Members__c> techInsert)
    {
        List<SVMXC__SVMX_Optimizer__c> optimizerObjects = new List<SVMXC__SVMX_Optimizer__c>();
        Set<ID> setTerritory = new Set<ID>();
        for(SVMXC__Service_Group_Members__c lstTech: techInsert){
            //check if territory is null and add to set
            if(lstTech.SVMXC__Service_Territory__c <> null)
            //add territory ID to set;
            setTerritory.add(lstTech.SVMXC__Service_Territory__c);
        }
         WSCH_AuditLogger.rca('Tehnician Insert for the Teritories '+setTerritory);
        //query the svmx jobs records for territoryId
        //list<SVMXC__SVMX_Jobs__c> lstSVMXJob = [Select id, Name, SVMXC__OptiMax_Message__c, SVMXC__SVMX_Process__c, SVMXC__Territory__c,SVMXC__Start_Time__c,SVMXC__Age__c, SVMXC__Status__c, SVMXC__End_Time__c,SVMXC__Type__c from SVMXC__SVMX_Jobs__c where SVMXC__Territory__c In :setTerritory and SVMXC__Type__c = 'ECO' and SVMXC__OptiMax_Message__c != 'IDLE'];
        list<SVMXC__SVMX_Jobs__c> lstSVMXJob = [Select id, Name, SVMXC__OptiMax_Message__c, SVMXC__SVMX_Process__c, SVMXC__Territory__c,SVMXC__Start_Time__c,SVMXC__Age__c, SVMXC__Status__c, SVMXC__End_Time__c,SVMXC__Type__c from SVMXC__SVMX_Jobs__c where SVMXC__Territory__c In :setTerritory];
        WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert()::lstSVMXJob : ' + lstSVMXJob.size());           
        
        Map<Id,SVMXC__SVMX_Jobs__c> mapTeritoryJobs = new Map<Id, SVMXC__SVMX_Jobs__c>();
        Map<Id,SVMXC__SVMX_Jobs__c> mapTeritoryBatchJobs = new Map<Id, SVMXC__SVMX_Jobs__c>();
        for(SVMXC__SVMX_Jobs__c objJob : lstSVMXJob){
            if(objJob.SVMXC__Type__c == 'ECO' && objJob.SVMXC__OptiMax_Message__c != 'IDLE'){
                mapTeritoryJobs.put(objJob.SVMXC__Territory__c, objJob);    
            }else if(objJob.SVMXC__Type__c == 'Full'){
                mapTeritoryBatchJobs.put(objJob.SVMXC__Territory__c, objJob);
            }
        }
        WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert()::mapTeritoryJobs : ' + mapTeritoryJobs);
        WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert()::mapTeritoryBatchJobs size : ' + mapTeritoryBatchJobs.size());
        
        if(mapTeritoryJobs !=null && mapTeritoryJobs.size() > 0){
            // retrive only technicians under territoty which has already initiated.
            // other technicians fitered out here.
            //WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert:: setTerritory: '+setTerritory);
            List<SVMXC__Service_Group_Members__c> technicianList = getTerritory(mapTeritoryJobs.keySet(), techInsert);
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert:: technicianList size: '+technicianList.size());
            //Adding Technician IDs to Optimizer List.
            for(SVMXC__Service_Group_Members__c objTech: technicianList) 
            {
                WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert:: Insert Technician: '+objTech);
                Id territoryId = objTech.SVMXC__Service_Territory__c;
                if(mapTeritoryJobs.get(territoryId) != null){
                    String strDPId = mapTeritoryJobs.get(territoryId).SVMXC__SVMX_Process__c;
                    String strECOId = strDPId+'_'+territoryId;
                    String strTechId = objTech.id+'_'+objTech.Name;
                    optimizerObjects.add(getOptimizerObject(strTechId,'CHANGE_CREATE_TECH',strECOId));
                    WSCH_AuditLogger.rca('Creating the Optimizer Objects for Technician'+strTechId+' for Dispatch Process'+strDPId);
                }
            }
            //Creating SVMX Optimizer      
            if(optimizerObjects.size() > 0) 
            {
                if(COMM_SecurityUtils.getInstance().verifyFieldAccess(optimizerObjects, COMM_SecurityUtils.Access.Createable)){     //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    insert optimizerObjects;
                } else {
                    throw new COMM_SecurityUtils.SecurityAccessException(System.label.COMM001_TAG142);
                }
                
                List<ID> optimizerIds = new List<ID>();
                for(SVMXC__SVMX_Optimizer__c optimizer : optimizerObjects)
                    optimizerIds.add(optimizer.ID);
                  WSCH_AuditLogger.rca('The Optimizer Objects for Technicians are created '+optimizerIds);
                //invoking future call to create Technician.
                WSCH_AuditLogger.rca('Invoking the Future Call for Technician ');
                manageTechnicians(optimizerIds);
            }
        }
        //TODO:Create/update optimizer transaction for Batch technician for run the job without new work order.
        List<SVMXC__SVMX_Optimizer__c> lstBatchSVMXOptimizer = new List<SVMXC__SVMX_Optimizer__c>();
        if(mapTeritoryBatchJobs != null && mapTeritoryBatchJobs.size() > 0){
            lstBatchSVMXOptimizer = [Select id, SVMXC__WhatType__c, SVMXC__Optimizer_Change_Token__c,SVMXC__WhatId__c,SVMXC__Optimizer_Connection_ID__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatType__c = 'BATCH_TECHNICIAN' AND SVMXC__Optimizer_Connection_ID__c in: mapTeritoryBatchJobs.keySet()];
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert:: lstBatchSVMXOptimizer: '+lstBatchSVMXOptimizer);
            List<SVMXC__SVMX_Optimizer__c> lstBatchSVMXOptimizerUpdate = new List<SVMXC__SVMX_Optimizer__c>();
            Map<Id,SVMXC__SVMX_Optimizer__c> mapTerritoryIdOptimizer = new Map<Id,SVMXC__SVMX_Optimizer__c>();
            for(SVMXC__SVMX_Optimizer__c optimizerBatch :lstBatchSVMXOptimizer){
                mapTerritoryIdOptimizer.put(optimizerBatch.SVMXC__Optimizer_Connection_ID__c,optimizerBatch);
            }
            SVMXC__SVMX_Optimizer__c optimizerBatch;
            for(Id territoryId :mapTeritoryBatchJobs.keyset()){
                if(mapTerritoryIdOptimizer != null && mapTerritoryIdOptimizer.size() > 0){
                    optimizerBatch = mapTerritoryIdOptimizer.get(territoryId);
                }
                if(optimizerBatch != null && mapTerritoryIdOptimizer.containsKey(territoryId)){
                    optimizerBatch.SVMXC__Optimizer_Change_Token__c = 'TRUE';
                    lstBatchSVMXOptimizerUpdate.add(optimizerBatch);
                    continue;
                }else{
                    SVMXC__SVMX_Optimizer__c obj = new SVMXC__SVMX_Optimizer__c();
                    obj.SVMXC__WhatType__c = 'BATCH_TECHNICIAN';
                    obj.SVMXC__WhatId__c = territoryId;
                    obj.SVMXC__Optimizer_Connection_ID__c=territoryId;
                    obj.SVMXC__Optimizer_Change_Token__c = 'TRUE';
                    lstBatchSVMXOptimizerUpdate.add(obj);
                }
            }
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianInsert:: lstBatchSVMXOptimizerUpdate: '+lstBatchSVMXOptimizerUpdate);
            if(lstBatchSVMXOptimizerUpdate.size() > 0 ){
                if(COMM_SecurityUtils.getInstance().verifyFieldAccess(lstBatchSVMXOptimizerUpdate, COMM_SecurityUtils.Access.Createable)){      //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    upsert lstBatchSVMXOptimizerUpdate;
                } else {
                    throw new COMM_SecurityUtils.SecurityAccessException(System.label.COMM001_TAG142);
                }
            }
        }
        WSCH_AuditLogger.finish();
    }
    //Method to return technicians associated with Territories.
    private static List<SVMXC__Service_Group_Members__c> getTerritory(Set<ID> setTerritory, List<SVMXC__Service_Group_Members__c> lstTech) {
        //Retriving territory associated with dispatch process method 'OptiMax ECO'
        List<SVMXC__Service_Group_Members__c> returnTechList = new List<SVMXC__Service_Group_Members__c> ();
        //Retrieving all Territory associated with Technician other then linx SP.
        List<SVMXC__Territory__c> territoryList = new List<SVMXC__Territory__c>([SELECT Id, Name,SVMXC__Active__c   FROM SVMXC__Territory__c WHERE Id in: setTerritory]);
        WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::getTerritory:: territoryList size: '+territoryList.size());
                                                                                            
        for(SVMXC__Territory__c lstTerr: territoryList){
            for(SVMXC__Service_Group_Members__c objTech: lstTech){
                //WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::getTerritory:: Territory name : '+lstTerr.Name+' Tech Territory name '+objTech.SVMXC__Service_Territory__r.Name);
                //WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::getTerritory:: Territory Id : '+lstTerr.Id+' Tech Territory Id '+objTech.SVMXC__Service_Territory__c);
                if(lstTerr.Id==objTech.SVMXC__Service_Territory__c){
                    if(objTech.SVMXC__Active__c == true && (objTech.SVMXC__Enable_Scheduling__c == true && objTech.SVMXC__Salesforce_User__c == NULL) || (objTech.SVMXC__Salesforce_User__c != NULL))
                    {
                        returnTechList.add(objTech);
                    }
                }
            }
        }
        return returnTechList;
    }
    
    //Method returns Optimizer object
    private static SVMXC__SVMX_Optimizer__c getOptimizerObject(string techId, string changeToken,string strJobId) 
    {
        SVMXC__SVMX_Optimizer__c obj = new SVMXC__SVMX_Optimizer__c();
        obj.SVMXC__WhatType__c = 'TECHNICIAN';
        obj.SVMXC__WhatId__c = techId;
        obj.SVMXC__Optimizer_Connection_ID__c=strJobId;
        obj.SVMXC__Optimizer_Change_Token__c = changeToken;
        obj.SVMXC__Optimizer_Status__c = WSCH_ECO_Constants.STATUS_OPT_PENDING;
        return obj;
    }
    //Method to update optimizer object related to Technician is UPDATED. 
    public static void handleTechnicianUpdate(List<SVMXC__Service_Group_Members__c> newTech, List<SVMXC__Service_Group_Members__c> oldTech)
    {
        List<SVMXC__SVMX_Optimizer__c> updateTech = new List<SVMXC__SVMX_Optimizer__c> ();
        List<SVMXC__SVMX_Optimizer__c> updateTechBatch = new List<SVMXC__SVMX_Optimizer__c> ();
        List<SVMXC__Service_Group_Members__c> insertTech = new List<SVMXC__Service_Group_Members__c>();
        
        //Retrieving existing optimizer object associated with the Technician.
        Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = getTechOptimizers(newTech);
        
        //Retrieving existing optimizer object associated with the batch technician
        Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizerBatch = getTechOptimizersBatch(newTech);
        
        integer index = 0;
        //for(SVMXC__Service_Group_Members__c objTech : newTech)
        set<String> setTerritoryId = new set<String>();

        for(Integer i = 0; i < newTech.size(); i++)
        {
            SVMXC__Service_Group_Members__c oldTechRecord = oldTech.get(i);
            SVMXC__Service_Group_Members__c newTechRecord = newTech.get(i);
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianUpdate::Old Technician SF user: '+oldTechRecord.SVMXC__Salesforce_User__c+'| oldTechRecord.EnableScheduling :'+oldTechRecord.SVMXC__Enable_Scheduling__c+'| oldTechRecord.IsActive :'+oldTechRecord.SVMXC__Active__c);
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianUpdate::New Technician SF user: '+newTechRecord.SVMXC__Salesforce_User__c+'| newTechRecord.EnableScheduling :'+newTechRecord.SVMXC__Enable_Scheduling__c+'| newTechRecord.IsActive :'+newTechRecord.SVMXC__Active__c);
            //checking whether optimizer object already exist, then update
            String strTechId = newTechRecord.id+'_'+newTechRecord.Name;
            if(!mapIdOptimizer.isEmpty() && mapIdOptimizer.containsKey(strTechId))
            {
                if(oldTechRecord.SVMXC__Active__c != newTechRecord.SVMXC__Active__c && newTechRecord.SVMXC__Active__c == false) {
                    updateTech.add(updateOptimizerObject(mapIdOptimizer.get(strTechId), 'CHANGE_REMOVE_TECH'));
                }else if(oldTechRecord.SVMXC__Active__c != newTechRecord.SVMXC__Active__c && newTechRecord.SVMXC__Active__c == true){
                    updateTech.add(updateOptimizerObject(mapIdOptimizer.get(strTechId), 'CHANGE_CREATE_TECH'));
                }else{
                    if(newTechRecord.SVMXC__Zip__c != oldTechRecord.SVMXC__Zip__c){
                        updateTech.add(updateOptimizerObject(mapIdOptimizer.get(strTechId), 'CHANGE_TECH_ZIP'));
                    }else if(newTechRecord.SVMXC__Working_Hours__c != oldTechRecord.SVMXC__Working_Hours__c){
                        updateTech.add(updateOptimizerObject(mapIdOptimizer.get(strTechId), 'CHANGE_TECH_WORKINGHRS'));
                    }else{
                        //TODO:need to introduce specific token based on the field change.
                        updateTech.add(updateOptimizerObject(mapIdOptimizer.get(strTechId), 'CHANGE_UPDATE_TECH'));
                    }
                }                   
            } else if(!mapIdOptimizerBatch.isEmpty() && mapIdOptimizerBatch.containsKey(newTechRecord.SVMXC__Service_Territory__c)){
                SVMXC__SVMX_Optimizer__c optimizerBatch = mapIdOptimizerBatch.get(newTechRecord.SVMXC__Service_Territory__c);
                if(setTerritoryId != null && setTerritoryId.contains(optimizerBatch.SVMXC__WhatId__c)){
                    continue;
                }
                optimizerBatch.SVMXC__Optimizer_Change_Token__c = 'TRUE';
                updateTechBatch.add(optimizerBatch);
                setTerritoryId.add(optimizerBatch.SVMXC__WhatId__c);
            } 
            else
            {
                // If optimizer object doesn't  exist, then create a new Technician.
                insertTech.add(newTechRecord);
            }
            //index++;
        }
    
        //Updating optimizer object
        if(!updateTech.isEmpty()) {     
            if(COMM_SecurityUtils.getInstance().verifyFieldAccess(updateTech, COMM_SecurityUtils.Access.Updateable)){
                Database.update(updateTech);
            }
            
            List<String> lstSVMXOptimizerID = new List<String> ();                  
            for(SVMXC__SVMX_Optimizer__c objSVMXOpt : updateTech)
                lstSVMXOptimizerID.add(objSVMXOpt.id);
            //invoking future call to Update Technician.
            manageTechnicians(lstSVMXOptimizerID);
        }
    
        if(!insertTech.isEmpty()) {     
            System.debug(logginglevel.warn,'List of SVMX Optimizer object to be created '+insertTech);
            //invoking Insert method to Insert Technician.
            handleTechnicianInsert(insertTech);
        }
        
        if(!updateTechBatch.isEmpty()){
            Database.update(updateTechBatch); 
        }
        WSCH_AuditLogger.finish();
    }
   
    //Method to update Optimizer object when Technicians are deleted.
    public static void handleTechnicianDelete(List<SVMXC__Service_Group_Members__c> lstTechDel)
    {
        List<SVMXC__SVMX_Optimizer__c> deleteTech = new List<SVMXC__SVMX_Optimizer__c> ();
        //Retrieving existing optimizer object associated with the Technicians.
        Map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = getTechOptimizers(lstTechDel);
    
        for(SVMXC__Service_Group_Members__c objTech : lstTechDel)
        {
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::handleTechnicianDelete::Delete Technician: '+objTech); 
            String strTechId = objTech.id+'_'+objTech.Name;   
            if(mapIdOptimizer.size() > 0 && mapIdOptimizer.containskey(strTechId)) {
                deleteTech.add(updateOptimizerObject(mapIdOptimizer.get(strTechId), 'CHANGE_REMOVE_TECH'));
            }
        }
        
        //Updating optimizer object
        if(!deleteTech.isEmpty()) {
            if(COMM_SecurityUtils.getInstance().verifyFieldAccess(deleteTech, COMM_SecurityUtils.Access.Updateable)){
                Database.update(deleteTech); 
            }
            List<String> lstSVMXOptimizerID = new List<String> ();                  
            for(SVMXC__SVMX_Optimizer__c objSVMXOpt : deleteTech){
                lstSVMXOptimizerID.add(objSVMXOpt.id);
            }
            //invoking future call to Delete Technician.
            manageTechnicians(lstSVMXOptimizerID);
        }
        WSCH_AuditLogger.finish();
    }
    
    //Get optimizer objects related to Technician.
    private static map<String,SVMXC__SVMX_Optimizer__c> getTechOptimizers(list<SVMXC__Service_Group_Members__c> lstTech)
    { 
        list<String> lstTechID= new list<String> ();           
        list<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizerToExisting = new list<SVMXC__SVMX_Optimizer__c> ();
        
        for(SVMXC__Service_Group_Members__c objTech : lstTech){
            lstTechID.add(objTech.id+'_'+objTech.Name);
        }
        lstSVMXOptimizerToExisting = [Select id, SVMXC__Optimizer_Change_Token__c,SVMXC__WhatId__c,SVMXC__Optimizer_Connection_ID__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in: lstTechID];
        
        map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = new map<String,SVMXC__SVMX_Optimizer__c>();   
        
        for(SVMXC__SVMX_Optimizer__c objOptimizer : lstSVMXOptimizerToExisting){
            mapIdOptimizer.put(objOptimizer.SVMXC__WhatId__c,objOptimizer);
        }
        return mapIdOptimizer;
    }

    //Get optimizer objects related to Batch Technician.
    private static map<String,SVMXC__SVMX_Optimizer__c> getTechOptimizersBatch(list<SVMXC__Service_Group_Members__c> lstTech)
    { 
        list<String> lstTerritoryID= new list<String> ();           
        list<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizerToExisting = new list<SVMXC__SVMX_Optimizer__c> ();
        
        for(SVMXC__Service_Group_Members__c objTech : lstTech){
            //lstTechID.add(objTech.id+'_'+objTech.Name);
            if(objTech.SVMXC__Service_Territory__c <> null)
                lstTerritoryID.add(objTech.SVMXC__Service_Territory__c);
        }
        lstSVMXOptimizerToExisting = [Select id, SVMXC__WhatType__c, SVMXC__Optimizer_Change_Token__c,SVMXC__WhatId__c,SVMXC__Optimizer_Connection_ID__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatType__c = 'BATCH_TECHNICIAN' AND SVMXC__WhatId__c in: lstTerritoryID];
        
        map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizerBatch = new map<String,SVMXC__SVMX_Optimizer__c>();   
        
        for(SVMXC__SVMX_Optimizer__c objOptimizer : lstSVMXOptimizerToExisting){
            mapIdOptimizerBatch.put(objOptimizer.SVMXC__WhatId__c,objOptimizer);
        }
        return mapIdOptimizerBatch;
    }
    //Update optimizer objects
    private static SVMXC__SVMX_Optimizer__c updateOptimizerObject(SVMXC__SVMX_Optimizer__c objSVMXOptimizer, String changeToken) {
        objSVMXOptimizer.SVMXC__Optimizer_Change_Token__c = changeToken;
        objSVMXOptimizer.SVMXC__Optimizer_Status__c = WSCH_ECO_Constants.STATUS_OPT_PENDING;
        return objSVMXOptimizer;
    }
    @future(callout=true)
    public static void manageTechnicians(List<String> objSVMX_OtimizerIds)
    {
          /*Calling Abstract services method */
        try
        {
            WSCH_AuditLogger.debug('WSCH_TechnicianTriggerHandler::manageTechnician():Size of SVMX Optimizer : '+ objSVMX_OtimizerIds);
            list<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizer = WSCH_CommonUtils.fetchSVMXOptimizerById(objSVMX_OtimizerIds);
            //WSCH_AuditLogger.debug('List of SVMX Optimizer : '+ lstSVMXOptimizer);
            //WSCH_OptimizedSchedulingService.triggerExecuted = true;
             WSCH_OptimizedSchedulingService.manageTechnicians(lstSVMXOptimizer);
        }catch(Exception ex)
        {
           WSCH_AuditLogger.error('Exception caught:WSCH_TechnicianTriggerHandler:manageTechnician() ' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
        }
    }
}