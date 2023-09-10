public with sharing class EndpageController {
    public string pageUrl {get;set;}
    public EndpageController() {

        String toolbankName = ApexPages.currentPage().getParameters().get('toolbank');
        if(String.isNotBlank(toolbankName))
        pageUrl = URL.getSalesforceBaseUrl().toExternalForm()+''+PageReference.forResource(toolbankName).getUrl();
        else{
            
            pageUrl = URL.getSalesforceBaseUrl().toExternalForm()+''+PageReference.forResource('Toolbank_USA').getUrl();
        }
        System.debug('pageUrl '+pageUrl);
    }
}