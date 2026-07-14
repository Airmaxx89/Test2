// Autoritative Kampf-Daten (ADR-0002: Balancing lebt serverseitig; die Client-.tres-Dateien
// sind nur die Vorschau fürs UI).
//
// BEKANNTE DUPLIZIERUNG: Diese Werte spiegeln client/assets/abilities/*.tres bzw.
// enemies/*.tres. Eine generierte gemeinsame Schema-Quelle ist als spätere Iteration
// vorgesehen (siehe modules/README) — bis dahin ist DIESE Datei die Wahrheit.

/** Wirkungsarten (entspricht AbilityEffectType im Client). */
type ServerAbilityEffect = "damage" | "heal";

interface ServerAbility {
    id: string;
    cooldownSeconds: number;
    resourceCost: number;
    /** Reichweite in px; <= 0 = ohne Zielprüfung (Selbstwirkung). */
    range: number;
    effect: ServerAbilityEffect;
    magnitude: number;
    /** Combo-Marker, den ein Treffer setzt (leer = keiner). */
    appliesMarker: string;
    markerDurationSeconds: number;
    /** Combo-Marker, den diese Fähigkeit als Finisher verbraucht (leer = keiner). */
    consumesMarker: string;
    comboMultiplier: number;
}

const SERVER_ABILITIES: { [id: string]: ServerAbility } = {
    "waechter.schildschlag": {
        id: "waechter.schildschlag", cooldownSeconds: 6, resourceCost: 20, range: 80,
        effect: "damage", magnitude: 35,
        appliesMarker: "", markerDurationSeconds: 0, consumesMarker: "", comboMultiplier: 1,
    },
    "waechter.wappenbruch": {
        id: "waechter.wappenbruch", cooldownSeconds: 10, resourceCost: 25, range: 80,
        effect: "damage", magnitude: 20,
        appliesMarker: "wappenbruch", markerDurationSeconds: 8, consumesMarker: "", comboMultiplier: 1,
    },
    "waechter.vergeltung": {
        id: "waechter.vergeltung", cooldownSeconds: 12, resourceCost: 30, range: 80,
        effect: "damage", magnitude: 50,
        appliesMarker: "", markerDurationSeconds: 0, consumesMarker: "wappenbruch", comboMultiplier: 1.6,
    },
    "waechter.schildwurf": {
        id: "waechter.schildwurf", cooldownSeconds: 8, resourceCost: 25, range: 400,
        effect: "damage", magnitude: 25,
        appliesMarker: "", markerDurationSeconds: 0, consumesMarker: "", comboMultiplier: 1,
    },
    "waechter.zweiter_wind": {
        id: "waechter.zweiter_wind", cooldownSeconds: 30, resourceCost: 40, range: 0,
        effect: "heal", magnitude: 120,
        appliesMarker: "", markerDurationSeconds: 0, consumesMarker: "", comboMultiplier: 1,
    },
};

// Gegner-KI-/Kampfwerte spiegeln EnemyDefinition/wegelagerer.tres. Die KI-Zustandsmaschine
// selbst (Patrouille -> Aggro -> Verfolgen/Angriff -> Heimkehr) ist die serverseitige
// Portierung des getesteten C#-EnemyBrain (client/src/Gameplay/Enemies/EnemyBrain.cs).
interface ServerEnemyType {
    id: string;
    maxHealth: number;
    xpReward: number;
    moveSpeed: number;
    aggroRadius: number;
    leashRadius: number;
    attackRange: number;
    attackDamage: number;
    attackIntervalSeconds: number;
}

const SERVER_ENEMY_TYPES: { [id: string]: ServerEnemyType } = {
    "silberwald.wegelagerer": {
        id: "silberwald.wegelagerer", maxHealth: 120, xpReward: 25,
        moveSpeed: 160, aggroRadius: 260, leashRadius: 600,
        attackRange: 70, attackDamage: 12, attackIntervalSeconds: 1.5,
    },
};

interface Point { x: number; y: number; }

/** Server-Spawnliste der Zone (spiegelt Morgenau.tscn; Positionen = Heimatpunkte). */
interface ZoneSpawn {
    typeId: string;
    x: number;
    y: number;
    respawnSeconds: number;
    /** Patrouillen-Wegpunkte relativ zum Heimatpunkt (leer = stehen). */
    patrol: Point[];
}

const ZONE_SPAWNS: ZoneSpawn[] = [
    {
        typeId: "silberwald.wegelagerer", x: 1100, y: 250, respawnSeconds: 20,
        patrol: [{ x: 0, y: 0 }, { x: 150, y: 0 }, { x: 150, y: 130 }, { x: 0, y: 130 }],
    },
    { typeId: "silberwald.wegelagerer", x: 1250, y: 600, respawnSeconds: 20, patrol: [] },
    {
        typeId: "silberwald.wegelagerer", x: 750, y: 900, respawnSeconds: 20,
        patrol: [{ x: 0, y: 0 }, { x: -170, y: 60 }],
    },
];

/** Distanz, ab der ein Weg-/Heimatpunkt als erreicht gilt (spiegelt EnemyBrain.ArrivalEpsilon). */
const ENEMY_ARRIVAL_EPSILON = 8;

/** Spieler-Kampfwerte (Platzhalter bis zum Attributsystem; müssen Client-Vorschau spiegeln). */
const PLAYER_MAX_HEALTH = 200;
const PLAYER_MAX_RESOURCE = 100;
const PLAYER_RESOURCE_REGEN_PER_SECOND = 5;

/** Toleranz auf Reichweitenprüfungen in px (Latenz zwischen Klick und Ankunft am Server). */
const RANGE_TOLERANCE = 24;
