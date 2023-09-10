trigger EasyRollUp_Order on Order (after insert,after update,after delete,after undelete){
 new esy_rlup.ChildTriggerHandler().run();}