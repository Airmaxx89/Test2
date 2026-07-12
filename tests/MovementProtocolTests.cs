using System.Text.Json;
using Aethermoor.Networking.Protocol;
using Xunit;

namespace Aethermoor.Tests;

/// <summary>
/// Sichert die Protokollkompatibilität zum Match-Handler ab
/// (<c>server/modules/src/movement_match.ts</c>): Feldnamen und Formate müssen exakt
/// übereinstimmen, sonst verwirft der Server die Eingaben stillschweigend.
/// </summary>
public sealed class MovementProtocolTests
{
    [Fact]
    public void EncodeInput_UsesExactServerFieldNames()
    {
        string json = MovementProtocol.EncodeInput(new MovementInputPayload(7, 0.5f, -1f, 0.016f));

        using JsonDocument doc = JsonDocument.Parse(json);
        JsonElement root = doc.RootElement;

        Assert.Equal(7u, root.GetProperty("seq").GetUInt32());
        Assert.Equal(0.5f, root.GetProperty("dx").GetSingle(), precision: 5);
        Assert.Equal(-1f, root.GetProperty("dy").GetSingle(), precision: 5);
        Assert.Equal(0.016f, root.GetProperty("dt").GetSingle(), precision: 5);
    }

    [Fact]
    public void DecodeSnapshot_ParsesServerFormat()
    {
        // Exakt das Format, das der Match-Handler pro Tick broadcastet.
        const string json =
            "{\"t\":1.5,\"players\":[{\"id\":\"user-a\",\"x\":10.5,\"y\":-20,\"ack\":42}," +
            "{\"id\":\"user-b\",\"x\":0,\"y\":0,\"ack\":0}]}";

        MovementSnapshot? snapshot = MovementProtocol.DecodeSnapshot(json);

        Assert.NotNull(snapshot);
        Assert.Equal(1.5, snapshot!.Time, precision: 5);
        Assert.Equal(2, snapshot.Players.Count);
        Assert.Equal("user-a", snapshot.Players[0].Id);
        Assert.Equal(10.5f, snapshot.Players[0].X, precision: 4);
        Assert.Equal(-20f, snapshot.Players[0].Y, precision: 4);
        Assert.Equal(42u, snapshot.Players[0].Ack);
    }

    [Fact]
    public void DecodeSnapshot_EmptyPlayersList_IsValid()
    {
        MovementSnapshot? snapshot = MovementProtocol.DecodeSnapshot("{\"t\":0,\"players\":[]}");

        Assert.NotNull(snapshot);
        Assert.Empty(snapshot!.Players);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("nicht-json")]
    [InlineData("{\"t\":1.0}")] // players fehlt
    [InlineData("[1,2,3]")]
    public void DecodeSnapshot_InvalidPayloads_ReturnNull(string json)
    {
        Assert.Null(MovementProtocol.DecodeSnapshot(json));
    }

    [Fact]
    public void EncodeThenDecode_InputSurvivesJsonRoundtripViaServerFieldNames()
    {
        // Simuliert die Server-Sicht: Eingabe kodieren, als generisches JSON lesen.
        string json = MovementProtocol.EncodeInput(new MovementInputPayload(99, 1f, 0f, 0.05f));
        using JsonDocument doc = JsonDocument.Parse(json);

        // Der Match-Handler validiert genau diese vier Felder als Zahlen.
        Assert.Equal(JsonValueKind.Number, doc.RootElement.GetProperty("seq").ValueKind);
        Assert.Equal(JsonValueKind.Number, doc.RootElement.GetProperty("dx").ValueKind);
        Assert.Equal(JsonValueKind.Number, doc.RootElement.GetProperty("dy").ValueKind);
        Assert.Equal(JsonValueKind.Number, doc.RootElement.GetProperty("dt").ValueKind);
    }
}
