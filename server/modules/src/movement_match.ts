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

/** Op-Codes des Bewegungs-/Kampfprotokolls (Client ↔ Server). */
const OPCODE_INPUT = 1;
const OPCODE_SNAPSHOT = 2;
const OPCODE_CAST = 3;
const OPCODE_CAST_RESULT = 4;

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
    /** Autoritative Kampfwerte (ADR-0002). */
    hp: number;
    resource: number;
    xp: number;
    /** Ablaufzeitpunkt je Fähigkeits-Cooldown in Sekunden Matchzeit. */
    cooldowns: { [abilityId: string]: number };
}

/** Autoritativer Zustand eines Zonen-Gegners (Index in ZONE_SPAWNS = Spawn-ID). */
interface EnemyServerState {
    typeId: string;
    x: number;
    y: number;
    health: number;
    /** Tick, ab dem der Gegner respawnt, oder null wenn er lebt. */
    respawnAtTick: number | null;
    /** Aktive Combo-Marker: Name → Ablaufzeitpunkt in Sekunden Matchzeit. */
    markers: { [marker: string]: number };
}

interface MovementMatchState extends nkruntime.MatchState {
    presences: { [userId: string]: nkruntime.Presence };
    players: { [userId: string]: PlayerState };
    enemies: EnemyServerState[];
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

    // Zonen-Gegner aus der autoritativen Spawnliste bevölkern.
    const enemies: EnemyServerState[] = ZONE_SPAWNS.map(function (spawn) {
        const type = SERVER_ENEMY_TYPES[spawn.typeId];
        return {
            typeId: spawn.typeId,
            x: spawn.x,
            y: spawn.y,
            health: type ? type.maxHealth : 1,
            respawnAtTick: null,
            markers: {},
        };
    });

    return {
        state: { presences: {}, players: {}, enemies: enemies },
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
        state.players[presence.userId] = {
            x: SPAWN_X,
            y: SPAWN_Y,
            ack: 0,
            hp: PLAYER_MAX_HEALTH,
            resource: PLAYER_MAX_RESOURCE,
            xp: 0,
            cooldowns: {},
        };
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

/** Vom Client gesendeter Wirkwunsch (OPCODE_CAST): Fähigkeit + optionale Spawn-ID des Ziels. */
interface CastMessage {
    ability: string;
    target?: number;
}

/** Antwort des Servers an den Wirkenden (OPCODE_CAST_RESULT). */
interface CastResult {
    ok: boolean;
    ability: string;
    reason?: string;
    damage?: number;
    combo?: boolean;
    targetHealth?: number;
    xp?: number;
    heal?: number;
}

const serverDistance = function (ax: number, ay: number, bx: number, by: number): number {
    const dx = ax - bx;
    const dy = ay - by;
    return Math.sqrt((dx * dx) + (dy * dy));
};

/**
 * Autoritative Wirk-Auflösung (ADR-0002): prüft dieselben Regeln wie die Client-Vorhersage
 * (AbilityCaster) — Cooldown, Ressource, Ziel, Reichweite (+ Latenz-Toleranz) — und führt
 * Schaden, Combos, Heilung und XP verbindlich aus. Das Ergebnis geht nur an den Wirkenden;
 * den neuen Weltzustand sehen alle über den Tick-Snapshot.
 */
const handleCastMessage = function (
    nk: nkruntime.Nakama,
    logger: nkruntime.Logger,
    dispatcher: nkruntime.MatchDispatcher,
    tick: number,
    state: MovementMatchState,
    message: nkruntime.MatchMessage
): void {
    const player = state.players[message.sender.userId];
    if (!player) {
        return;
    }

    let cast: CastMessage;
    try {
        cast = JSON.parse(nk.binaryToString(message.data)) as CastMessage;
    } catch (error) {
        logger.warn("Unlesbarer Wirkwunsch von %s verworfen.", message.sender.userId);
        return;
    }

    if (typeof cast.ability !== "string") {
        return;
    }

    const sendResult = function (result: CastResult): void {
        dispatcher.broadcastMessage(
            OPCODE_CAST_RESULT, JSON.stringify(result), [message.sender], null, true);
    };

    const now = tick / TICK_RATE;
    const ability = SERVER_ABILITIES[cast.ability];
    if (!ability) {
        sendResult({ ok: false, ability: cast.ability, reason: "unknown_ability" });
        return;
    }

    if ((player.cooldowns[ability.id] || 0) > now) {
        sendResult({ ok: false, ability: ability.id, reason: "cooldown" });
        return;
    }

    if (player.resource < ability.resourceCost) {
        sendResult({ ok: false, ability: ability.id, reason: "resource" });
        return;
    }

    if (ability.effect === "heal") {
        player.resource -= ability.resourceCost;
        player.cooldowns[ability.id] = now + ability.cooldownSeconds;
        const healed = Math.min(ability.magnitude, PLAYER_MAX_HEALTH - player.hp);
        player.hp += healed;
        sendResult({ ok: true, ability: ability.id, heal: healed });
        return;
    }

    // Schadens-Fähigkeit: Ziel- und Reichweitenprüfung.
    if (cast.target === undefined || cast.target === null) {
        sendResult({ ok: false, ability: ability.id, reason: "no_target" });
        return;
    }

    const enemy = state.enemies[cast.target];
    if (!enemy || enemy.health <= 0) {
        sendResult({ ok: false, ability: ability.id, reason: "invalid_target" });
        return;
    }

    if (ability.range > 0) {
        const distance = serverDistance(player.x, player.y, enemy.x, enemy.y);
        if (distance > ability.range + RANGE_TOLERANCE) {
            sendResult({ ok: false, ability: ability.id, reason: "out_of_range" });
            return;
        }
    }

    // Combo: Finisher verbraucht den Marker vor der Schadensrechnung (GAME_DESIGN §7).
    let damage = ability.magnitude;
    let combo = false;
    if (ability.consumesMarker.length > 0 && (enemy.markers[ability.consumesMarker] || 0) > now) {
        delete enemy.markers[ability.consumesMarker];
        damage *= ability.comboMultiplier;
        combo = true;
    }

    player.resource -= ability.resourceCost;
    player.cooldowns[ability.id] = now + ability.cooldownSeconds;
    enemy.health = Math.max(0, enemy.health - damage);

    let xpGained = 0;
    if (enemy.health <= 0) {
        const type = SERVER_ENEMY_TYPES[enemy.typeId];
        xpGained = type ? type.xpReward : 0;
        player.xp += xpGained;
        enemy.markers = {};
        enemy.respawnAtTick = tick + Math.round(ZONE_SPAWNS[cast.target].respawnSeconds * TICK_RATE);
    } else if (ability.appliesMarker.length > 0) {
        enemy.markers[ability.appliesMarker] = now + ability.markerDurationSeconds;
    }

    sendResult({
        ok: true,
        ability: ability.id,
        damage: damage,
        combo: combo,
        targetHealth: enemy.health,
        xp: xpGained,
    });
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
        if (message.opCode === OPCODE_CAST) {
            handleCastMessage(nk, logger, dispatcher, tick, state, message);
            continue;
        }

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

    // Ressourcen-Regeneration (autoritativ; Client zeigt nur an).
    for (const userId of Object.keys(state.players)) {
        const player = state.players[userId];
        player.resource = Math.min(
            PLAYER_MAX_RESOURCE,
            player.resource + (PLAYER_RESOURCE_REGEN_PER_SECOND / TICK_RATE));
    }

    // Fällige Gegner-Respawns.
    for (let i = 0; i < state.enemies.length; i++) {
        const enemy = state.enemies[i];
        if (enemy.respawnAtTick !== null && tick >= enemy.respawnAtTick) {
            const type = SERVER_ENEMY_TYPES[enemy.typeId];
            enemy.health = type ? type.maxHealth : 1;
            enemy.markers = {};
            enemy.respawnAtTick = null;
        }
    }

    // Snapshot an alle: autoritative Positionen, Kampfwerte und Gegnerzustand.
    const snapshot = {
        t: tick / TICK_RATE,
        players: Object.keys(state.players).map(function (userId) {
            const player = state.players[userId];
            return {
                id: userId,
                x: player.x,
                y: player.y,
                ack: player.ack,
                hp: player.hp,
                res: Math.round(player.resource),
                xp: player.xp,
            };
        }),
        enemies: state.enemies.map(function (enemy, index) {
            return { sid: index, x: enemy.x, y: enemy.y, hp: enemy.health };
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
