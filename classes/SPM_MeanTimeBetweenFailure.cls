/*****************************************************************************
     *                       Copyright (C) 2017 ServiceMax, Inc
     *                               All rights reserved
     *
     *****************************************************************************/
     //FLS and CRUD check is not required as this class is running in batch mode
    /**
     * 
     * 
     *
     * @author Soumyaranjan
     * @version 
     * @since 2017
     */
    /*****************************************************************************************************
     *    ID            Name                        Date            Comment
     *****************************************************************************************************
     *                  Soumyaranjan Pati         24 Oct 2017     Created. V.02
      * BAC-4050        Soumyaranjan Pati         27th June 2018  Security fixes.
     *****************************************************************************************************/

    global with sharing class SPM_MeanTimeBetweenFailure extends SPM_AbstractBatch {
        public SVMXC__ServiceMax_Config_Data__c scheduleConfigData;
        public BusinessHours businessHour;
        public String downTimeCondition = '';
        public Map<Id,Integer> mapWoDownTime;
        public Map<Id,List<SVMXC__Service_Order__c>> mapIBWithWO;
        public Integer numberOfDays;
        public List<SVMXC__ServiceMax_Config_Data__c> listserviceMaxConfigData;
        public Map<String,String> mapOfLableSourceFieldName;
        public Datetime currentBatchRunDatetime;
        
        /**
         * Class constructor to create instance of this class.
         */
        global SPM_MeanTimeBetweenFailure( SVMXC__ServiceMax_Config_Data__c scheduleData ) {         
            super( SPM_Schema.Report.MeanTimeBetweenFailure, scheduleData );
            this.scheduleConfigData = scheduleData;
            listserviceMaxConfigData = new List<SVMXC__ServiceMax_Config_Data__c>();
        }
        
        /**
         * This is abtract class method which is override for setting up
         * initial configuration like : whereClause, IgnoreNullCheck
         */
        global override void initBatchConfiguration() {        
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.initBatchConfiguration() - enter' );       
            addQueryField('CreatedDate','CreatedDate');
            numberOfDays = getNumberOfDaysToQualifyRecords();
            if(numberOfDays == null){
                numberOfDays = 365;
            }
            currentBatchRunDatetime=System.Now();
            if(scheduleConfigData != null){
                if(scheduleConfigData.SVMXC__Enter_Date__c == null)
                    scheduleConfigData.SVMXC__Enter_Date__c = System.today();
                
                numberOfDays += scheduleConfigData.SVMXC__Enter_Date__c.daysBetween(System.today());
            }
            String tempWhereClause = ' CreatedDate = LAST_N_DAYS:'+ numberOfDays;
            setWhereClause(tempWhereClause);
            addIgnoreNullCheckField(SPM_Schema.Field.BusinessHours);
            
            addIgnoreNullCheckField('SVMXC__Preferred_End_Time__c');
            addIgnoreNullCheckField('SVMXC__Preferred_Start_Time__c');
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.initBatchConfiguration() - exit' );
        }
        
        /**
         * Use this method to log in case of any errors addError( Id sourceRecordId, String errorMessage )
         * 
         *
         */
        global override void handleRecords( List<SObject> records ) {
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords() - enter; records: ' + records.size() );
            if(records.size() == 0) {
                System.debug( LoggingLevel.INFO, 'No records available in this execution');
                return;
            }
            List<Id> listIBIds = new List<Id>();
            Map<Id,SVMXC__Installed_Product__c> mapIbs = new Map<Id,SVMXC__Installed_Product__c>();
            Map<Id,SObject> mapIbswithSobjType = new Map<Id,SObject>();
            for(SObject ibRecord:records){
                listIBIds.add(ibRecord.id);
                mapIbswithSobjType.put(ibRecord.id,ibRecord);
                SVMXC__Installed_Product__c installedProduct = (SVMXC__Installed_Product__c)ibRecord; 
                mapIbs.put(ibRecord.id,installedProduct);
            }
            
            
            businessHour = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
            
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords() - enter; only scheduleConfigData: ' + scheduleConfigData );
            
            mapOfLableSourceFieldName = new Map<String,String>();
            if(listserviceMaxConfigData.size() == 0){
                listserviceMaxConfigData.addAll(lstserviceMaxConfigDataList);
            }
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords() -  lstserviceMaxConfigDataList: ' + listserviceMaxConfigData );
            for( SVMXC__ServiceMax_Config_Data__c serviceMaxConfigData : listserviceMaxConfigData ) {
                
                
                // Populate configuration name vs configuration's and object mappings if configured.
                SPM_ConfigurationDefinition.CalculationMethod calculationMethod = (SPM_ConfigurationDefinition.CalculationMethod) JSON.deserialize( serviceMaxConfigData.SVMXC__Formula__c, SPM_ConfigurationDefinition.CalculationMethod.class );
                
                
                if( calculationMethod.objectMappingDetailsList != null && !calculationMethod.objectMappingDetailsList.isEmpty() && !calculationMethod.parameterInfoList.isEmpty()) {

                    for( SPM_ConfigurationDefinition.ParameterInfo expressionInfo : calculationMethod.parameterInfoList ) {
                        if(expressionInfo.sourceFieldName==SPM_Consts.WORK_ORDER || expressionInfo.sourceFieldName==SPM_Consts.DOWN_TIME)
                        downTimeCondition = expressionInfo.sourceFieldName;
                        
                        mapOfLableSourceFieldName.put(expressionInfo.label,expressionInfo.sourceFieldName);
                        
                    }

                }               
            }
            System.debug('mapOfLableSourceFieldName '+mapOfLableSourceFieldName);
            String criteria = getExpressionCriteria(SPM_Schema.ExpressionType.WorkOrderCriteria);
            System.debug('criteria WorkOrderCriteria '+criteria);
            //Construct the Workorder Dynamic SOQL
            String strWorkOrderQuery = 'Select id,';
            if(downTimeCondition==SPM_Consts.WORK_ORDER){
                strWorkOrderQuery = strWorkOrderQuery+' '+mapOfLableSourceFieldName.get('Select the source for the Created On Date field')+ ', '+mapOfLableSourceFieldName.get('Select the source for Fixed On Date field')+', ';
            }
            if(mapOfLableSourceFieldName.size()>0){
                strWorkOrderQuery = strWorkOrderQuery+' '+mapOfLableSourceFieldName.get('Select the source for Installed Product field')+', ';
            }
            if(!strWorkOrderQuery.contains('SVMXC__Closed_On__c')){
                strWorkOrderQuery = strWorkOrderQuery+' SVMXC__Closed_On__c,';
            }
            
            strWorkOrderQuery = strWorkOrderQuery+' (select id,SVMXC__Duration__c, SVMXC__Start_Time__c, SVMXC__End_Time__c from SVMXC__Down_Times__r) from SVMXC__Service_Order__c where '+mapOfLableSourceFieldName.get('Select the source for Installed Product field')+ ' IN :listIBIds';
            
            if(criteria != null && criteria != '') {
            strWorkOrderQuery = strWorkOrderQuery +' AND (' + criteria + ') ';
            }
            if(scheduleConfigData.SVMXC__Previous_Execution_Completed_On__c!=null){
                Datetime prevExecTime=scheduleConfigData.SVMXC__Previous_Execution_Completed_On__c;
                strWorkOrderQuery = strWorkOrderQuery+' and SystemModStamp  >= :prevExecTime';
            }else{
                DateTime prevDatetime = DateTime.now().addDays(-numberOfDays);
                strWorkOrderQuery = strWorkOrderQuery+' and SystemModStamp  >= :prevDatetime';
            }
            
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords():strWorkOrderQuery: ' + strWorkOrderQuery );
            
            List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
            List<SVMXC__SPM_Mean_Time_Between_Failure__c> listmtbf = new List<SVMXC__SPM_Mean_Time_Between_Failure__c>();
            mapIBWithWO = new Map<Id,List<SVMXC__Service_Order__c>>();
            mapWoDownTime = new Map<Id,Integer>();
            
            //Check Field Security Check
            List<String> queryFields = new List<String> {'SVMXC__Closed_On__c', 'SVMXC__Component__c', 'SVMXC__Top_Level__c'};
            if( ! COMM_SecurityUtils.getInstance().verifyFieldAccess( 'SVMXC__Service_Order__c', queryFields, COMM_SecurityUtils.Access.Accessible ) ) {
                throw new COMM_SecurityUtils.SecurityAccessException( System.Label.COMM001_TAG142 );
            }
            //End of Check Field Security Check
            
            if(strWorkOrderQuery != null && strWorkOrderQuery.length()>0){
                lstWorkOrders = Database.query(strWorkOrderQuery);
            }
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords():listWorkOrders: ' + lstWorkOrders );
            
            List<Id> lstWoIds = new List<Id>();
            for(SVMXC__Service_Order__c wo:lstWorkOrders){
                List<SVMXC__Service_Order__c> lstWoTemp = new List<SVMXC__Service_Order__c>();
                lstWoTemp.add(wo);
                    if(mapIBWithWO.containsKey(Id.valueOf(String.valueOf(wo.get(mapOfLableSourceFieldName.get('Select the source for Installed Product field')))))){
                        lstWoTemp.addAll(mapIBWithWO.get(Id.valueOf(String.valueOf(wo.get(mapOfLableSourceFieldName.get('Select the source for Installed Product field'))))));
                        mapIBWithWO.put(Id.valueOf(String.valueOf(wo.get(mapOfLableSourceFieldName.get('Select the source for Installed Product field')))),lstWoTemp);
                    }else{
                        mapIBWithWO.put(Id.valueOf(String.valueOf(wo.get(mapOfLableSourceFieldName.get('Select the source for Installed Product field')))),lstWoTemp);
                    }
                    
                
                lstWoIds.add(wo.id);
            }
            if(downTimeCondition == SPM_Consts.DOWN_TIME){
                //Check Field Security Check
                List<String> queryFieldsDT = new List<String> {'SVMXC__Duration__c', 'SVMXC__Start_Time__c', 'SVMXC__End_Time__c', 'SVMXC__Service_Order__c'};
                if( ! COMM_SecurityUtils.getInstance().verifyFieldAccess( 'SVMXC__Down_Time__c', queryFieldsDT, COMM_SecurityUtils.Access.Accessible ) ) {
                throw new COMM_SecurityUtils.SecurityAccessException( System.Label.COMM001_TAG142 );
                }
                //End of Check Field Security Check
                for(SVMXC__Down_Time__c dtime:[select id, SVMXC__Duration__c, SVMXC__Start_Time__c, SVMXC__End_Time__c,SVMXC__Service_Order__c from SVMXC__Down_Time__c where SVMXC__Service_Order__c IN:lstWoIds]){
                    if(dtime.SVMXC__Duration__c != null){
                        if(mapWoDownTime.containsKey(dtime.SVMXC__Service_Order__c)){
                            Integer tempDuration=mapWoDownTime.get(dtime.SVMXC__Service_Order__c);
                            mapWoDownTime.put(dtime.SVMXC__Service_Order__c,tempDuration+Integer.valueOf(dtime.SVMXC__Duration__c));
                        }else{
                            mapWoDownTime.put(dtime.SVMXC__Service_Order__c,Integer.valueOf(dtime.SVMXC__Duration__c));
                        }
                        
                    }else if(dtime.SVMXC__Start_Time__c != null && dtime.SVMXC__End_Time__c != null){
                        if(mapWoDownTime.containsKey(dtime.SVMXC__Service_Order__c)){
                            Integer tempDuration=mapWoDownTime.get(dtime.SVMXC__Service_Order__c);
                            mapWoDownTime.put(dtime.SVMXC__Service_Order__c,tempDuration+calculateDowntimeWithBH(dtime.SVMXC__Start_Time__c,dtime.SVMXC__End_Time__c));
                        }else{
                            mapWoDownTime.put(dtime.SVMXC__Service_Order__c,calculateDowntimeWithBH(dtime.SVMXC__Start_Time__c,dtime.SVMXC__End_Time__c));
                        }
                        
                        
                    }
                }
            }
            for(Id InstallBaseTemp:mapIBWithWO.keySet()){
                //Construct the MTBF Dataset
                SVMXC__SPM_Mean_Time_Between_Failure__c mtbf = new SVMXC__SPM_Mean_Time_Between_Failure__c();
                mtbf.SVMXC__Installed_Product__c = InstallBaseTemp;
            
                mtbf.SVMXC__Account__c=(ID) getSourceObjectFieldValue( mapIbswithSobjType.get(InstallBaseTemp), SPM_Schema.Field.Account );
                mtbf.SVMXC__Product__c = mapIbs.get(InstallBaseTemp).SVMXC__Product__c;
                mtbf.SVMXC__Run_On__c = currentBatchRunDatetime;
                mtbf.SVMXC__Configuration_Name__c = getConfigurationName();
                mtbf.SVMXC__Calculation_Method__c = getCalculationMethodName();
                mtbf.SVMXC__Expected_Uptime__c = getExpectedUpTime(mapIbs.get(InstallBaseTemp).CreatedDate);
                mtbf.SVMXC__Downtime__c = sumIBDowntime(InstallBaseTemp);
                mtbf.SVMXC__workorder_count__c = mapIBWithWO.get(InstallBaseTemp).size();
                
                performFieldMapping(InstallBaseTemp,mtbf);
                
                listmtbf.add(mtbf);
            }
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords():listmtbf: ' + listmtbf );
            
            if(COMM_SecurityUtils.getInstance().verifyFieldAccess(listmtbf, COMM_SecurityUtils.Access.Upsertable)){
                if(listmtbf.size()>0){
                    insert listmtbf;
                }
            } else {
                throw new COMM_SecurityUtils.SecurityAccessException( System.Label.COMM001_TAG142 );
            }
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.handleRecords() - exit' );
        }
        /**
         * This method used for count the total number Downtime of workorder's, present in passed IB's. Return as minutes
         * 
         *
         */
        private Integer sumIBDowntime(Id InstallBaseTemp){
            Integer dtime=0;
            if(mapIBWithWO.size()>0 && mapIBWithWO.get(InstallBaseTemp) != null ){
                for(SVMXC__Service_Order__c so:mapIBWithWO.get(InstallBaseTemp)){
                if(downTimeCondition=='Work Order'){
                    dtime = dtime+calculateDowntimeWithBH(Datetime.valueOf(so.get(mapOfLableSourceFieldName.get('Select the source for the Created On Date field'))),Datetime.valueOf(so.get(mapOfLableSourceFieldName.get('Select the source for Fixed On Date field'))));
                }else if(downTimeCondition=='Down Time'){
                    if(mapWoDownTime.size()>0 && mapWoDownTime.get(so.id) != null)
                    dtime = dtime+mapWoDownTime.get(so.id);
                }
                }
            }
            return dtime;
        }
        /**
         * This method used for Difference between two datetime with business hours, return as minutes
         * 
         *
         */
        private Integer calculateDowntimeWithBH(Datetime woCreatedDate,Datetime woClosedDate){
            if(woCreatedDate!=null && woClosedDate!=null){
                return Integer.valueOf(((BusinessHours.diff(businessHour.id,woCreatedDate,woClosedDate))/1000)/60);
            }else{
                return 0;
            }
            
        }
        /**
         * 
         * This method used for Difference between current datetime and passed datetime using business hours, return as minutes
         *
         */
        private Integer getExpectedUpTime(Datetime createdDatetime){
            
            Integer minutes = Integer.valueOf(((BusinessHours.diff(businessHour.id,createdDatetime,DateTime.now())) / 1000) / 60);
            return minutes;
        }
        
        /**
         * On Finish method
         */
        global override void onFinishComplete() {
            System.debug( LoggingLevel.DEBUG, 'SPM_MeanTimeBetweenFailure.onFinishComplete()' );
        }
    }