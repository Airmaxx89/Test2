using Aethermoor.Gameplay.Abilities;
using Xunit;

namespace Aethermoor.Tests;

/// <summary>
/// Sichert ab, dass die Rohtext-Ablehnungsgründe des Match-Handlers
/// (server/modules/src/movement_match.ts) auf die richtigen <see cref="CastFailureReason"/>
/// abbilden — eine serverseitige Umbenennung fällt hier auf.
/// </summary>
public sealed class CastFailureReasonMapperTests
{
    [Theory]
    [InlineData("unknown_ability", CastFailureReason.UnknownAbility)]
    [InlineData("cooldown", CastFailureReason.OnCooldown)]
    [InlineData("resource", CastFailureReason.InsufficientResource)]
    [InlineData("out_of_range", CastFailureReason.OutOfRange)]
    [InlineData("no_target", CastFailureReason.NoTarget)]
    [InlineData("invalid_target", CastFailureReason.NoTarget)]
    public void KnownReasons_MapToExpected(string reason, CastFailureReason expected)
    {
        Assert.Equal(expected, CastFailureReasonMapper.FromServerReason(reason));
    }

    [Theory]
    [InlineData("etwas_neues")]
    [InlineData("")]
    [InlineData(null)]
    public void UnknownReasons_MapToServerRejected(string? reason)
    {
        Assert.Equal(CastFailureReason.ServerRejected, CastFailureReasonMapper.FromServerReason(reason));
    }
}
