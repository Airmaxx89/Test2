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

/// <summary>Ein Spieler-Eintrag im Server-Snapshot (OpCode 2).</summary>
public readonly record struct PlayerSnapshot(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("x")] float X,
    [property: JsonPropertyName("y")] float Y,
    [property: JsonPropertyName("ack")] uint Ack);

/// <summary>Autoritativer Tick-Snapshot des Servers (OpCode 2): <c>{t, players:[…]}</c>.</summary>
public sealed record MovementSnapshot(
    [property: JsonPropertyName("t")] double Time,
    [property: JsonPropertyName("players")] IReadOnlyList<PlayerSnapshot> Players);

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

    /// <summary>Serialisiert eine Eingabe als JSON für den Match-Versand.</summary>
    public static string EncodeInput(MovementInputPayload input)
        => JsonSerializer.Serialize(input);

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
