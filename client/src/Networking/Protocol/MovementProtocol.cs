using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Aethermoor.Networking.Protocol;

/// <summary>
/// Bewegungs-Eingabe an den Server (OpCode 1). Feldnamen entsprechen exakt dem
/// Match-Handler (<c>server/modules/src/movement_match.ts</c>): <c>{seq, dx, dy, dt}</c>.
/// </summary>
public readonly record struct MovementInputPayload(
    [property: JsonPropertyName("seq")] uint Seq,
    [property: JsonPropertyName("dx")] float Dx,
    [property: JsonPropertyName("dy")] float Dy,
    [property: JsonPropertyName("dt")] float Dt);

/// <summary>Ein Spieler-Eintrag im Server-Snapshot (OpCode 2), inkl. autoritativer Kampfwerte.</summary>
public readonly record struct PlayerSnapshot(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("x")] float X,
    [property: JsonPropertyName("y")] float Y,
    [property: JsonPropertyName("ack")] uint Ack,
    [property: JsonPropertyName("hp")] float Hp = 0f,
    [property: JsonPropertyName("res")] float Resource = 0f,
    [property: JsonPropertyName("xp")] float Xp = 0f);

/// <summary>Ein Zonen-Gegner im Server-Snapshot (Spawn-ID = Index der Server-Spawnliste).</summary>
public readonly record struct EnemySnapshot(
    [property: JsonPropertyName("sid")] int Sid,
    [property: JsonPropertyName("x")] float X,
    [property: JsonPropertyName("y")] float Y,
    [property: JsonPropertyName("hp")] float Hp);

/// <summary>Autoritativer Tick-Snapshot des Servers (OpCode 2): <c>{t, players:[…], enemies:[…]}</c>.</summary>
public sealed record MovementSnapshot(
    [property: JsonPropertyName("t")] double Time,
    [property: JsonPropertyName("players")] IReadOnlyList<PlayerSnapshot> Players,
    [property: JsonPropertyName("enemies")] IReadOnlyList<EnemySnapshot>? Enemies = null);

/// <summary>
/// Wirkwunsch an den Server (OpCode 3). <see cref="Target"/> ist die Spawn-ID des Gegners
/// (Server-Spawnliste) oder <c>null</c> für ungezielte Fähigkeiten — das Feld wird dann
/// weggelassen, exakt wie der Match-Handler es erwartet.
/// </summary>
public readonly record struct CastRequestPayload(
    [property: JsonPropertyName("ability")] string Ability,
    [property: JsonPropertyName("target")]
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    int? Target);

/// <summary>Autoritatives Wirk-Ergebnis des Servers (OpCode 4, nur an den Wirkenden).</summary>
public sealed record CastResultPayload(
    [property: JsonPropertyName("ok")] bool Ok,
    [property: JsonPropertyName("ability")] string Ability,
    [property: JsonPropertyName("reason")] string? Reason = null,
    [property: JsonPropertyName("damage")] float? Damage = null,
    [property: JsonPropertyName("combo")] bool? Combo = null,
    [property: JsonPropertyName("targetHealth")] float? TargetHealth = null,
    [property: JsonPropertyName("xp")] float? Xp = null,
    [property: JsonPropertyName("heal")] float? Heal = null);

/// <summary>
/// Kodierung/Dekodierung des Bewegungsprotokolls (Client ↔ Match-Handler). Engine- und
/// SDK-frei, damit die Protokollkompatibilität in CI getestet werden kann — Feld- oder
/// Formatabweichungen zum Server fallen so im Test auf, nicht erst zur Laufzeit.
/// </summary>
public static class MovementProtocol
{
    /// <summary>OpCode für Client-Eingaben (muss OPCODE_INPUT im Match-Handler entsprechen).</summary>
    public const long OpCodeInput = 1;

    /// <summary>OpCode für Server-Snapshots (muss OPCODE_SNAPSHOT im Match-Handler entsprechen).</summary>
    public const long OpCodeSnapshot = 2;

    /// <summary>OpCode für Wirkwünsche des Clients (muss OPCODE_CAST im Match-Handler entsprechen).</summary>
    public const long OpCodeCast = 3;

    /// <summary>OpCode für Wirk-Ergebnisse des Servers (muss OPCODE_CAST_RESULT entsprechen).</summary>
    public const long OpCodeCastResult = 4;

    /// <summary>Serialisiert eine Eingabe als JSON für den Match-Versand.</summary>
    public static string EncodeInput(MovementInputPayload input)
        => JsonSerializer.Serialize(input);

    /// <summary>Serialisiert einen Wirkwunsch als JSON für den Match-Versand.</summary>
    public static string EncodeCast(CastRequestPayload cast)
        => JsonSerializer.Serialize(cast);

    /// <summary>Parst ein Wirk-Ergebnis; <c>null</c> bei unlesbarem JSON.</summary>
    public static CastResultPayload? DecodeCastResult(string json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            CastResultPayload? result = JsonSerializer.Deserialize<CastResultPayload>(json);
            return string.IsNullOrEmpty(result?.Ability) ? null : result;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    /// <summary>
    /// Parst einen Server-Snapshot. Liefert <c>null</c> bei unlesbarem oder unvollständigem
    /// JSON — der Aufrufer verwirft das Paket, statt mit Teilzustand weiterzurechnen.
    /// </summary>
    public static MovementSnapshot? DecodeSnapshot(string json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            MovementSnapshot? snapshot = JsonSerializer.Deserialize<MovementSnapshot>(json);
            return snapshot?.Players is null ? null : snapshot;
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
