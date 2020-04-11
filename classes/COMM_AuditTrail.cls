/*****************************************************************************
 *                       Copyright (C) 2019 ServiceMax, Inc
 *                               All rights reserved
 *
 *****************************************************************************/

/**
 * @brief A Singleton class to log Audit trail informations.
 *
 *
 * @author Ramachandra Mohan
 * @version 20.1
 * @since 2019
 */
/*****************************************************************************************************
 *    ID        Name                    Date            Comment
 *****************************************************************************************************
 *              Ramachandra Mohan       14 Nov 2019     Created.
 *****************************************************************************************************/
public with sharing class COMM_AuditTrail {
    
    /**
     * Nested class to hold audit trail information.
     */
    public class AuditTrailInfo {
        
        public String action;
        public String actionType;
        public String entityName;
        public String application;
        public String additionalInfo;
        public String internalId;
    }
    
    /**
     * Static constant variable to hold instance of this class.
     */
    private static final COMM_AuditTrail instance = new COMM_AuditTrail();
    
    /**
     * Static method to retrieve instance of this class.
     */
    public static COMM_AuditTrail getInstance() {
        return instance;
    }
    
    /**
     * This method is used to log audit trail information to View ServiceMax Configuration Change.
     * 
     * @param auditTrailInfo Instance of AuditTrailInfo with audit trail details record to be created.
     */
    public void logAudit( final AuditTrailInfo auditTrailInfo ) {
        
        SVMXC__Config_Change_Detail__c auditTrailInfoRecord = new SVMXC__Config_Change_Detail__c();
        
        auditTrailInfoRecord.SVMXC__Entity_Name__c = auditTrailInfo.entityName;
        auditTrailInfoRecord.SVMXC__Application__c = auditTrailInfo.application;
        auditTrailInfoRecord.SVMXC__Action_Type__c = auditTrailInfo.actionType;
        auditTrailInfoRecord.SVMXC__Action__c = auditTrailInfo.action;
        auditTrailInfoRecord.SVMXC__Additional_information__c = auditTrailInfo.additionalInfo;
        auditTrailInfoRecord.SVMXC__SM_Internal_ID__c = auditTrailInfo.internalId;
        
        // Retrieve and assign current user id and time.
        auditTrailInfoRecord.SVMXC__User__c = UserInfo.getUserId();
        auditTrailInfoRecord.SVMXC__Date__c = DateTime.now();
        
        // Verify firld level security and insert audit trail record.
        if( COMM_SecurityUtils.getInstance().verifyFieldAccess( auditTrailInfoRecord, COMM_SecurityUtils.Access.Createable) ) {
            insert auditTrailInfoRecord;
        } else {
            throw new COMM_SecurityUtils.SecurityAccessException(System.label.COMM001_TAG142);
        }
    }

	/**
	 * Private class constructor.
	 */    
    private COMM_AuditTrail() {}
}