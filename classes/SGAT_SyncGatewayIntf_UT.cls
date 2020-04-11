@isTest(seeAllData=false)
public class SGAT_SyncGatewayIntf_UT {
    static testMethod void testDoPost()
    {
        Account ac = new Account();
        ac.Name = 'TestAccount';
        insert ac;

        List<String> lstIds = new List<String>();
        lstIds.add(ac.Id);
        List<SGAT_WebServicesDef.SVMXMap> valueMap = new List<SGAT_WebServicesDef.SVMXMap>();
        SGAT_WebServicesDef.SVMXMap vm = new SGAT_WebServicesDef.SVMXMap('query', 'select Name from Account where ID IN ({{ids}})', lstIds);
        valueMap.add(vm);
        SGAT_WebServicesDef.SGAT_Request request = new SGAT_WebServicesDef.SGAT_Request(valueMap);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/SVMXC/svmx/SGAT_SyncGatewayIntf/SGExecuteQuery';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        SGAT_SyncGatewayIntf.doPost();

        request.valueMap = null;
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        SGAT_SyncGatewayIntf.doPost();
    }

    static testMethod void testDoPostError()
    {
        List<SGAT_WebServicesDef.SVMXMap> valueMap = new List<SGAT_WebServicesDef.SVMXMap>();
        SGAT_WebServicesDef.SGAT_Request request = new SGAT_WebServicesDef.SGAT_Request(valueMap);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/SVMXC/svmx/SGAT_SyncGatewayIntf/SGExecuteQuery';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        SGAT_SyncGatewayIntf.doPost();
    }

    static testMethod void testDoGet()
    {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/SVMXC/svmx/SGAT_SyncGatewayIntf/SGDisplayTags';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        SGAT_SyncGatewayIntf.doGet();
    }

    static testMethod void testExecuteQueries() {
        Account ac = new Account();
        ac.Name = 'TestAccount1';
        insert ac;
        Account ac1 = new Account();
        ac1.Name = 'TestAccount2';
        insert ac1;

        List<SGAT_WebServicesDef.SVMXMap> reqValueMap = new List<SGAT_WebServicesDef.SVMXMap>();
        SGAT_WebServicesDef.SVMXMap resourceVM = new SGAT_WebServicesDef.SVMXMap('RESOURCE_PERCENT', '80');
        SGAT_WebServicesDef.SVMXMap queriesVM = new SGAT_WebServicesDef.SVMXMap('QUERIES', '');
        SGAT_WebServicesDef.SVMXMap queryVM = new SGAT_WebServicesDef.SVMXMap('account', 'SELECT Id from Account');
        queryVM.valueMap = new List<SGAT_WebServicesDef.SVMXMap>();
        SGAT_WebServicesDef.SVMXMap isDeletedVM = new SGAT_WebServicesDef.SVMXMap('IS_DELETED', 'true');
        queryVM.valueMap.add(isDeletedVM);

        SGAT_WebServicesDef.SVMXMap queryVM1 = new SGAT_WebServicesDef.SVMXMap('contact', 'SELECT Id from Contact');

        queriesVM.valueMap = new List<SGAT_WebServicesDef.SVMXMap>();
        queriesVM.valueMap.add(queryVM);
        queriesVM.valueMap.add(queryVM1);

        reqValueMap.add(resourceVM);
        reqValueMap.add(queriesVM);

        SGAT_WebServicesDef.SGAT_Request request = new SGAT_WebServicesDef.SGAT_Request(reqValueMap);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/SVMXC/svmx/SGAT_SyncGatewayIntf/SGExecuteQuery';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        SGAT_SyncGatewayIntf.doPost();

        SGAT_WebServicesDef.SVMXMap lastIdVM = new SGAT_WebServicesDef.SVMXMap('LAST_ID', ac.Id);
        queryVM.valueMap.add(lastIdVM);
        resourceVM.value = '1';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        SGAT_SyncGatewayIntf.doPost();

        queryVM.value = 'SELECT Id from Account Where Name != null';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        SGAT_SyncGatewayIntf.doPost();
    }
}