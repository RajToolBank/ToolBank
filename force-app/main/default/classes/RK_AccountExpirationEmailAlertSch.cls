global class RK_AccountExpirationEmailAlertSch implements Schedulable {
    global void execute(SchedulableContext sc) {
        RK_AccountExpirationEmailAlertBatch rk = new RK_AccountExpirationEmailAlertBatch(); 
        database.executebatch(rk);
    }
}