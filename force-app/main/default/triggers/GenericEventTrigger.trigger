trigger GenericEventTrigger on Generic_Event__e (after insert) {


    EnableContactAsCommunityUser.disableContactAsync(trigger.new);
}