public class OrderTriggerHelper {
    
    public static void updateStatusValidation(List<Order> ordList, Map<Id, Order> oldMap){

            for(Order ord: ordList){
                String newStatus = ord.Status;
                String oldStatus = oldMap.get(ord.Id).Status;
                String currentUserProfileId = Userinfo.getProfileId();
                Trigger_Validation__c mc = Trigger_Validation__c.getInstance(currentUserProfileId);
                Boolean isNotAllowed = (mc == null || (mc != null && !mc.Active__c));
                if(newStatus != oldStatus && !ByPassValidations.OrdStatusValidation && isNotAllowed){
                    ord.addError('Please use the Confirm/Fulfill and Return buttons to properly change the status of this order.');
                }
            }

    }
}