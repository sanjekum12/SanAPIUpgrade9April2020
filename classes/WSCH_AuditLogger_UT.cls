/*
 This is AutioLogger UT Class for code coverate of all the methods . 

*/

@isTest
//(seeAllData = true)
public with sharing class WSCH_AuditLogger_UT {
     static testMethod void auditLogger()
    {
        String SettingTypeId = '';
        String GlobalTypeId = '';
        RecordType[] rts = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'SVMXC__ServiceMax_Processes__c' or SobjectType = 'SVMXC__ServiceMax_Config_Data__c' or SobjectType = 'SVMXC__Territory_Coverage__c'];
        for(RecordType rt : rts) //Loop to take a record type at a time
        {
            if(rt.Name == 'Setting Value' && rt.SobjectType == 'SVMXC__ServiceMax_Config_Data__c'){
                   SettingTypeId = rt.ID;
            }
            else  if(rt.Name == 'Settings' && rt.SobjectType == 'SVMXC__ServiceMax_Processes__c'){
                   GlobalTypeId = rt.ID;
            }
        }
        SVMXC__ServiceMax_Processes__c svmxprocess = new SVMXC__ServiceMax_Processes__c();
        svmxprocess.SVMXC__Name__c = 'Enable Audit Logger for ServicePower web service APIs';
        svmxprocess.SVMXC__SubmoduleID__c='DCON004';
        svmxprocess.SVMXC__SettingID__c='SET003';
        svmxprocess.SVMXC__Active__c = true;
        svmxprocess.RecordTypeId = GlobalTypeId;
        svmxprocess.SVMXC__Setting_Type__c = 'Global';
        svmxprocess.SVMXC__Installation_Key__c = EncodingUtil.base64Encode(Blob.valueOf(userInfo.getOrganizationId().subString(0,15)));
        Database.insert(svmxprocess);
        
        SVMXC__ServiceMax_Config_Data__c confObj = new SVMXC__ServiceMax_Config_Data__c();

        confObj.SVMXC__Display_Value__c = 'true';
        confObj.SVMXC__Internal_Value__c = 'true';
        confObj.SVMXC__Active__c = true;
        confObj.SVMXC__Setting_ID__c = svmxprocess.id;
        confObj.RecordTypeId = SettingTypeId;
        confObj.SVMXC__Installation_Key__c = EncodingUtil.base64Encode(Blob.valueOf(userInfo.getOrganizationId().subString(0,15)));
        Database.insert(confObj);

        
        WSCH_AuditLogger.clear();
        WSCH_AuditLogger.info('INFO MESSAGE');
        WSCH_AuditLogger.debug('DEBUG MESSAGE');
        WSCH_AuditLogger.error('ERROR MESSAGE');
        WSCH_AuditLogger.warn('WARN MESSAGE');
        WSCH_AuditLogger.finish();
        
        /*Execute Below Test Class Method for 91% Coverage*/
        //WSCH_OptimizedSchedulingService_UT.scheduleWorkOrders();
        
        WSCH_AuditLogger.setLogContext('log context');
        WSCH_AuditLogger.setApexCPUTime(10);
        WSCH_AuditLogger.setAPIName('API');
        WSCH_AuditLogger.initPerfomanceMetrics();
        
        WSCH_AuditLogger.isLinxMetricLogEnabled = true;
        WSCH_AuditLogger.appendMetrics('WO-0011', 'metric_prefix', Datetime.now(), 1234567890);
        
        //RCA Logger Coverage
        WSCH_AuditLogger.doLevelLogging();
        WSCH_AuditLogger.doErrorLogging();
        
        WSCH_AuditLogger.isError= false;
        WSCH_AuditLogger.getPreformancMetricsMap();
        WSCH_AuditLogger.appendMetrics('WO-0011', 'metric_prefix', Datetime.now(), 1234567890);
        WSCH_AuditLogger.isLinxMetricLogEnabled = true;
        WSCH_AuditLogger.appendMetrics('WO-0011', 'metric_prefix', Datetime.now(), 1234567890, 'abc');
        WSCH_AuditLogger.setLogEnabled(true);
        WSCH_AuditLogger.debug('ERROR');
        WSCH_AuditLogger.getPreformancMetricsMap();
        WSCH_AuditLogger.savePerformanceMetrics();
        String requestJson = '{"state":"ON_TENTATIVE","errorcode":null,"workItems":[{"id":"WO-00619678","type":"JOB","booking":{"start":"2018-09-19 07:23","driveDuration":0.0,"arr":"2018-09-19 07:23","idleDuration":0.0,"visitDuration":3600.0,"end_x":"2018-09-19 08:23","tech":"a1i170000001cSMAAY_Tech12_OR"},"errorMsg":null,"ignored":false,"resolvedLatitude":0.0,"resolvedLongitude":0.0}],"changeTime":"2018-09-17 08:59","dispatched":false}';
        WSCH_AuditLogger.saveECORequestJson(requestJson);
        WSCH_AuditLogger.appendMetrics('WO-0011', 'metric_prefix', Datetime.now(), 1234567890,'newlog');
        
    }
}