// Einstiegspunkt der Nakama-JS-Runtime: registriert alle Aethermoor-Module.
// Die Runtime ruft InitModule beim Serverstart auf (Funktionsname ist Konvention).

const RPC_FIND_OR_CREATE_MOVEMENT_MATCH = "find_or_create_movement_match";

function InitModule(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerMatch(MOVEMENT_MATCH_LABEL, {
        matchInit: movementMatchInit,
        matchJoinAttempt: movementMatchJoinAttempt,
        matchJoin: movementMatchJoin,
        matchLeave: movementMatchLeave,
        matchLoop: movementMatchLoop,
        matchSignal: movementMatchSignal,
        matchTerminate: movementMatchTerminate,
    });

    initializer.registerRpc(RPC_FIND_OR_CREATE_MOVEMENT_MATCH, rpcFindOrCreateMovementMatch);

    logger.info("Aethermoor-Server-Module geladen (Match: %s).", MOVEMENT_MATCH_LABEL);
}

// Referenz erhalten, damit Optimierungen den globalen Einstiegspunkt nicht entfernen
// (Muster aus dem offiziellen Nakama-TS-Template).
!InitModule && InitModule.bind(null);
