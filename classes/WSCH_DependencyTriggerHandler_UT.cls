@isTest
public with sharing class WSCH_DependencyTriggerHandler_UT {
    
    public static testMethod void testDependency(){
    System.Test.StartTest();
    SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
    workOrder1.SVMXC__Zip__c = '75001';
    workOrder1.SVMXC__Order_Status__c = 'Open';
    workOrder1.SVMXC__Service_Duration__c = 3600;
    workOrder1.SVMXC__Schedule_As_A_Dependent_Work_Order__c = True;
    insert workOrder1;
    SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c();
    workOrder2.SVMXC__Zip__c = '75001';
    workOrder2.SVMXC__Order_Status__c='Open';
    workOrder2.SVMXC__Service_Duration__c = 3600;
    workOrder2.SVMXC__Schedule_As_A_Dependent_Work_Order__c = True;
    insert workOrder2;
    SVMXC__Dependency_Management__c dependencyManagement = new SVMXC__Dependency_Management__c();
    dependencyManagement.SVMXC__Dependency_Group_Name__c = 'BDG-01';
    insert dependencyManagement;
    SVMXC__Service_Order_Dependency__c dependencyRecord = new SVMXC__Service_Order_Dependency__c();
    dependencyRecord.SVMXC__Primary_Work_Order__c = workOrder1.Id;
    dependencyRecord.SVMXC__Secondary_Work_Order__c = workOrder2.Id;
    dependencyRecord.SVMXC__Time_Dependency__c = 'Set Arrival Time of Secondary relative to the Arrival Time of Primary';
    dependencyRecord.SVMXC__Dependency_Group__c = dependencyManagement.id;
    dependencyRecord.SVMXC__Maximum_Time_Deviation__c = 30;
    dependencyRecord.SVMXC__Maximum_Time_Deviation_Units__c = 'Minutes';
    dependencyRecord.SVMXC__Minimum_Time_Deviation__c = 60;
    dependencyRecord.SVMXC__Minimum_Time_Deviation_Units__c = 'Minutes';
    dependencyRecord.SVMXC__Targeted_Time_Difference__c = 45;
    dependencyRecord.SVMXC__Targeted_Time_Variance_Cost_ID__c = 'testCost';
    dependencyRecord.SVMXC__Targeted_Time_Difference_Units__c = 'Minutes';
    insert dependencyRecord;
    dependencyRecord.SVMXC__Time_Dependency__c = 'Set End Time of Secondary relative to the End Time of Primary';
    update dependencyRecord;
    dependencyRecord.SVMXC__Minimum_Time_Deviation__c = 80;
    update dependencyRecord;
    dependencyRecord.SVMXC__Minimum_Time_Deviation_Units__c = 'hours';
    update dependencyRecord;
    dependencyRecord.SVMXC__Maximum_Time_Deviation__c = 20;
    update dependencyRecord;
    dependencyRecord.SVMXC__Maximum_Time_Deviation_Units__c = 'minutes';
    update dependencyRecord;
    dependencyRecord.SVMXC__Targeted_Time_Variance_Cost_ID__c = 'test';
    update dependencyRecord;
    dependencyRecord.SVMXC__Targeted_Time_Difference__c = 40;
    update dependencyRecord;
    dependencyRecord.SVMXC__Targeted_Time_Difference_Units__c = 'hours';
    update dependencyRecord;
    List<SVMXC__Service_Order_Dependency__c> dependencyList = new List<SVMXC__Service_Order_Dependency__c>();
    dependencyList.add(dependencyRecord);
        
    List<String> multiJobIdList = new List<String>();
    multiJobIdList.add('BDG-01');
    List<String> WoIds = new List<String>();
    WoIds.add(workOrder1.Id);
    WoIds.add(workOrder2.Id);
    //WSCH_DependencyTriggerHandler.cancelDependencyGroup(multiJobIdList, WoIds);
    WSCH_DependencyTriggerHandler.deleteWODependencyFromGroup(dependencyList);
    System.Test.StopTest();
    
    }
}