// Autoritativer Bewegungs-Match-Handler (Milestone 3).
//
// Der Server ist die einzige Wahrheit über Positionen (ADR-0002): Clients senden nur
// Eingaben (Richtung + Frame-Zeit + Sequenznummer), der Server integriert sie mit der
// GLEICHEN Bewegungsformel wie die Client-Prediction (PredictionReconciler im Client:
// position + direction * MOVE_SPEED * dt) und sendet pro Tick einen Snapshot mit der
// pro Spieler zuletzt bestätigten Sequenznummer zurück.
//
// Anti-Cheat-Grundlagen (GAME_DESIGN §12):
//  - Richtungsvektoren werden serverseitig auf Länge 1 geklemmt (kein Speed-Hack über
//    überlange Vektoren).
//  - Die Frame-Zeit jeder Eingabe wird auf MAX_INPUT_DELTA geklemmt (kein Speed-Hack
//    über manipulierte Zeitangaben).
//  - Pro Tick wird nur eine begrenzte Zahl Eingaben je Spieler akzeptiert (Rate-Limit).

/** Muss mit LocalCharacterController.MoveSpeed im Client übereinstimmen (px/s). */
const MOVE_SPEED = 320;

/** Obergrenze der akzeptierten Frame-Zeit pro Eingabe in Sekunden. */
const MAX_INPUT_DELTA = 0.1;

/** Maximal verarbeitete Eingaben je Spieler und Server-Tick (Rate-Limit). */
const MAX_INPUTS_PER_TICK = 8;

/** Server-Ticks pro Sekunde. */
const TICK_RATE = 10;

/** Op-Codes des Bewegungsprotokolls (Client ↔ Server). */
const OPCODE_INPUT = 1;
const OPCODE_SNAPSHOT = 2;

/** Startposition neuer Spieler (Platzhalter bis zum Zonen-Spawnsystem). */
const SPAWN_X = 640;
const SPAWN_Y = 360;

/** Label, unter dem der Match im Matchmaker auffindbar ist. */
const MOVEMENT_MATCH_LABEL = "movement";

interface PlayerState {
    x: number;
    y: number;
    /** Zuletzt verarbeitete Eingabe-Sequenznummer (für Client-Reconciliation). */
    ack: number;
}

interface MovementMatchState extends nkruntime.MatchState {
    presences: { [userId: string]: nkruntime.Presence };
    players: { [userId: string]: PlayerState };
}

/** Vom Client gesendete Bewegungs-Eingabe (JSON im OPCODE_INPUT-Payload). */
interface MovementInputMessage {
    seq: number;
    dx: number;
    dy: number;
    dt: number;
}

const movementMatchInit = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    params: { [key: string]: string }
): { state: MovementMatchState; tickRate: number; label: string } {
    logger.info("Bewegungs-Match erstellt.");
    return {
        state: { presences: {}, players: {} },
        tickRate: TICK_RATE,
        label: MOVEMENT_MATCH_LABEL,
    };
};

const movementMatchJoinAttempt = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    presence: nkruntime.Presence,
    metadata: { [key: string]: any }
): { state: MovementMatchState; accept: boolean } {
    // Milestone 3: jeder authentifizierte Spieler darf beitreten. Spätere Milestones
    // ergänzen Kapazitäts-, Zonen- und Bann-Prüfungen an genau dieser Stelle.
    return { state, accept: true };
};

const movementMatchJoin = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    presences: nkruntime.Presence[]
): { state: MovementMatchState } {
    for (const presence of presences) {
        state.presences[presence.userId] = presence;
        state.players[presence.userId] = { x: SPAWN_X, y: SPAWN_Y, ack: 0 };
        logger.info("Spieler beigetreten: %s", presence.userId);
    }
    return { state };
};

const movementMatchLeave = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    presences: nkruntime.Presence[]
): { state: MovementMatchState } {
    for (const presence of presences) {
        delete state.presences[presence.userId];
        delete state.players[presence.userId];
        logger.info("Spieler gegangen: %s", presence.userId);
    }
    return { state };
};

const movementMatchLoop = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    messages: nkruntime.MatchMessage[]
): { state: MovementMatchState } {
    const inputsThisTick: { [userId: string]: number } = {};

    for (const message of messages) {
        if (message.opCode !== OPCODE_INPUT) {
            continue;
        }

        const userId = message.sender.userId;
        const player = state.players[userId];
        if (!player) {
            continue;
        }

        // Rate-Limit: überzählige Eingaben dieses Ticks verwerfen.
        inputsThisTick[userId] = (inputsThisTick[userId] || 0) + 1;
        if (inputsThisTick[userId] > MAX_INPUTS_PER_TICK) {
            continue;
        }

        let input: MovementInputMessage;
        try {
            input = JSON.parse(nk.binaryToString(message.data)) as MovementInputMessage;
        } catch (error) {
            logger.warn("Unlesbare Eingabe von %s verworfen.", userId);
            continue;
        }

        if (typeof input.seq !== "number" || typeof input.dx !== "number"
            || typeof input.dy !== "number" || typeof input.dt !== "number") {
            continue;
        }

        // Veraltete oder wiederholte Sequenznummern ignorieren (Replay-Schutz).
        if (input.seq <= player.ack) {
            continue;
        }

        // Anti-Cheat: Richtung auf Einheitslänge klemmen, Frame-Zeit begrenzen.
        let dx = input.dx;
        let dy = input.dy;
        const length = Math.sqrt(dx * dx + dy * dy);
        if (length > 1) {
            dx /= length;
            dy /= length;
        }
        const dt = Math.min(Math.max(input.dt, 0), MAX_INPUT_DELTA);

        // Dieselbe Formel wie die Client-Prediction (PredictionReconciler).
        player.x += dx * MOVE_SPEED * dt;
        player.y += dy * MOVE_SPEED * dt;
        player.ack = input.seq;
    }

    // Snapshot an alle: autoritative Positionen + je Spieler die bestätigte Sequenz.
    const snapshot = {
        t: tick / TICK_RATE,
        players: Object.keys(state.players).map(function (userId) {
            const player = state.players[userId];
            return { id: userId, x: player.x, y: player.y, ack: player.ack };
        }),
    };
    dispatcher.broadcastMessage(OPCODE_SNAPSHOT, JSON.stringify(snapshot), null, null, true);

    return { state };
};

const movementMatchSignal = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    data: string
): { state: MovementMatchState; data?: string } {
    return { state };
};

const movementMatchTerminate = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    graceSeconds: number
): { state: MovementMatchState } {
    logger.info("Bewegungs-Match wird beendet.");
    return { state };
};

/**
 * RPC: liefert die Match-ID eines laufenden Bewegungs-Matches oder erstellt eines.
 * Clients rufen dies nach dem Login auf und treten dann per Socket bei.
 */
const rpcFindOrCreateMovementMatch = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    const existing = nk.matchList(1, true, MOVEMENT_MATCH_LABEL, 0, 100, "");
    if (existing.length > 0) {
        return JSON.stringify({ matchId: existing[0].matchId });
    }

    const matchId = nk.matchCreate(MOVEMENT_MATCH_LABEL, {});
    return JSON.stringify({ matchId: matchId });
};
