public class CreditExpirationHandlerBatchScheduler implements Schedulable {
    
    public void execute(SchedulableContext SC) {
        CreditExpirationHandlerBatch obj = new CreditExpirationHandlerBatch(); 
        Database.executeBatch(obj,200);
    }
 
    
}