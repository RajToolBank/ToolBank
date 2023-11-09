public without sharing class PaymentReceipt_Ctrl {
    public List<Toolbank_Help_Page__mdt> getData {get;set;}
    public Decimal waiver {get;set;}
    public Decimal orgCredit {get;set;}
    public Decimal creditCard {get;set;}
    public Decimal totalpaid {get;set;}
    public Decimal totalOrderFees {get;set;}
    public signature__Signature__c signature{get;set;}
    String orderId;
    public List<OrderItem> orderItemList{get;set;}
    public String accountId {get;set;}
    public List<String> imageURLList {get; set;}
    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        //Milliseconds to Day
        return  tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.00);
    }}

    public List<Payments_TB__c> paymentList {get;set;}

    public PaymentReceipt_Ctrl(Apexpages.StandardController sc) {
        totalOrderFees = 0.00;
        getData= Toolbank_Help_Page__mdt.getAll().values();
        SObject obj = sc.getRecord();
        Schema.SObjectType signatureType = Schema.signature__Signature__c.getSObjectType();
        Schema.SObjectType orderType = Schema.signature__Signature__c.getSObjectType();
        Order order;
        if(signatureType == obj.getSObjectType()){
            orderId = (String)obj.get('Order__c');
            signature__Signature__c sign = (signature__Signature__c)sc.getRecord();
            //sign = [SELECT ID,Order__c,Order__r.Total_Late_Fee__c,Order__r.Lost_R_Fee__c,Order__r.Total_Handling_Fees__c FROM signature__Signature__c WHERE Id =: sign.id];
            order = sign.Order__r;
            //orderId = sign.Order__c;
        }else{
            orderId = sc.getId();
            order = (Order)sc.getRecord();
        }

        
        waiver = 0.00;
        orgCredit = 0.00;
        creditCard = 0.00;
        totalpaid = 0.00;
        totalOrderFees += order.Total_Handling_Fees__c != null?order.Total_Handling_Fees__c:0;
        totalOrderFees += order.Total_Late_Fee__c != null?order.Total_Late_Fee__c:0;
        totalOrderFees += order.Lost_R_Fee__c != null?order.Lost_R_Fee__c:0;
        totalOrderFees = totalOrderFees.setScale(2);
        paymentList = new List<Payments_TB__c>();
        for(Payments_TB__c payment: [SELECT Id, Payment_Method__c,Comment__c,createdDate, Amount__c FROM Payments_TB__c WHERE Order__c =: orderId ]){
            if(payment.Payment_Method__c == 'Credit Card'){
                creditCard += payment.Amount__c;
            }else if(payment.Payment_Method__c == 'Organizational Credit'){
                orgCredit += payment.Amount__c;
            }else if(payment.Payment_Method__c == 'Waiver - External Sponsor' || payment.Payment_Method__c == 'Waiver - External Sponsor'){
                waiver += payment.Amount__c;
            }
            totalpaid += payment.Amount__c;
            paymentList.add(payment);
        }
        for(Order ord :[Select Id, Affiliate__c From Order where Id =: orderId limit 1]) {
            system.debug('accountId-->'+ord.Affiliate__c);
            accountId = ord.Affiliate__c;
        }
		imageURLList = getImageList();
        orderItemList = [SELECT Id,product2.Type__c,
                        Tool_Handling_Fee_Per_Item__c,
                        Total_Handling_Fee__c,Late_Fee__c,
                        Lost_Fee__c,Total_Fees__c,
                        Actual_Return_Date__c,
                        Requested_Borrowing_Period__c,
                        Late_Weeks__c,
                        UnitPrice,
                        Check_In_Quantity__c,
                        Lost__c,
                        Damaged__c,
                        status__c,
                        product2.name,
                        Quantity,
                        Reserved_Quantity__c 
                        FROM OrderItem 
                        WHERE OrderId =: orderId 
                        ORDER BY product2.name ASC];

                        List<signature__Signature__c> signlist= [SELECT Id,signature__Signature__c FROM signature__Signature__c WHERE Order__c =:  orderId ORDER BY CreatedDate DESC];
                        if(signlist != Null && signlist.size() > 0){
                            signature = signlist[0];
                        }

	}
    public void updateOrder(){
       
            PageReference PDf =  Page.PaymentReceipt;//Replace attachmentPDf with the page you have rendered as PDF
            PDf.getParameters().put('Id',orderId);
            PDf.setRedirect(true);

            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S';
            conVer.PathOnClient = 'Payment_Receipt_'+Date.today().format()+'.pdf';
            conVer.Title = 'Payment_Receipt_'+Date.today().format()+'.pdf';
            if(!Test.isRunningTest())
                conVer.VersionData = pdf.getContentAsPDF();
            else conVer.VersionData = EncodingUtil.base64Decode('blob');
            insert conVer; 


            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
      
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = orderId;
            conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
            conDocLink.shareType = 'V';
            insert conDocLink;
        
    }
    public List<String> getImageList() {
        // Fetch the Account and its related files
        List<String> imageURLList = new List<String>();
        Set<Id> cDocIds = new Set<Id>();
        system.debug('accountId-->'+accountId);
        system.debug('usertype-->'+userinfo.getUserType());
        String userType = userinfo.getUserType();
        for(ContentDocumentLink cdl :[SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :accountId]) {
            cDocIds.add(cdl.ContentDocumentId);
        }
        system.debug('cDocIds-->'+cDocIds);
        for(ContentVersion cvfile :[SELECT Id, VersionData, Title, FileType, ContentBodyId, Active__c FROM ContentVersion WHERE Active__c = true AND ContentDocumentId IN :cDocIds AND Title like '%_sponsored']) {
            String imageUrl = '';
            String cvId15Disgit = String.valueOf(cvfile.Id).length() == 18?String.valueOf(cvfile.Id).subString(0,15):cvfile.Id;
            String cvBodyId15Disgit = String.valueOf(cvfile.ContentBodyId).length() == 18?String.valueOf(cvfile.ContentBodyId).subString(0,15):cvfile.ContentBodyId;
            if(userType == 'PowerPartner')
            	imageUrl = Label.AffilateCommunityURLforFiles+'sfc/servlet.shepherd/version/renditionDownload?rendition='+cvfile.FileType+'&versionId='+cvId15Disgit+'&operationContext=CHATTER&contentId='+cvBodyId15Disgit+'&page=1';
            else 
                imageUrl = Label.DomainURLforFiles+'sfc/servlet.shepherd/version/renditionDownload?rendition='+cvfile.FileType+'&versionId='+cvId15Disgit+'&operationContext=CHATTER&contentId='+cvBodyId15Disgit+'&page=1';
            system.debug('imageUrl-->'+imageUrl);
            imageURLList.add(imageUrl);
        }
        return imageURLList;
    }
    @AuraEnabled
    public static void uploadFiles(String files) {
        //system.debug('accountId-->'+accountId);
        system.debug('files-->'+files);
        List<Object> fileUpload = (List<Object>)JSON.deserializeUntyped(files);
        system.debug('fileUpload-->'+fileUpload);
        Set<String> contentBodyIds = new Set<String>();
        List<ContentVersion> cvListUpdate = new List<ContentVersion>();
        List<ContentDocumentLink> cdlListUpdate = new List<ContentDocumentLink>();
        for (Object file : fileUpload) {
            Map<String,Object> mapFileUpload = (Map<String,Object>)file;
            String cvName = (String)mapFileUpload.get('name');
            cvName = cvName+'_sponsored';
            String contentVersionId = (String)mapFileUpload.get('contentVersionId');
            String documentId = (String)mapFileUpload.get('documentId');
            contentBodyIds.add(documentId);
            ContentVersion cv = new ContentVersion(Id = contentVersionId, Title = cvName, Active__c = true);
            cvListUpdate.add(cv);
        }
        system.debug('cvListUpdate-->'+cvListUpdate);
        if(!cvListUpdate.isEmpty()) {
            update cvListUpdate;
        }
        if(!contentBodyIds.isEmpty()) {
            for(ContentDocumentLink cdl :[SELECT Id, Visibility, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentBodyIds]) {
                cdl.Visibility = 'AllUsers';
                cdl.shareType = 'I';
                cdlListUpdate.add(cdl);
            }
        }
        system.debug('cvListUpdate-->'+cvListUpdate);
        if(!cdlListUpdate.isEmpty()) {
            update cdlListUpdate;
        }
    }
    @AuraEnabled(cacheable=true)
    public static Boolean checkAffiliate(String accountId) {
        System.debug('accountId-->'+accountId);
        Account acc = [Select Id, RecordType.DeveloperName From Account Where Id = :accountId];
        system.debug('recordtype-->'+acc.RecordType.DeveloperName);
        if(acc.RecordType.DeveloperName == 'Affiliate')
            return true;
        else
            return false;
    }
}