using System.Collections.Generic;
using System.Threading.Tasks;
using Aethermoor.Core.Events;
using Aethermoor.Networking;
using Aethermoor.Networking.Connection;
using Aethermoor.Networking.Model;
using Aethermoor.Tests.TestDoubles;
using Xunit;

namespace Aethermoor.Tests;

public sealed class OfflineNetworkServiceTests
{
    private static readonly AuthCredentials Credentials = new("device-123", "Held");

    private static (OfflineNetworkService Service, EventBus Bus) Create()
    {
        var bus = new EventBus(new RecordingLogger());
        return (new OfflineNetworkService(bus, new RecordingLogger()), bus);
    }

    [Fact]
    public void New_IsDisconnected_WithoutSession()
    {
        (OfflineNetworkService service, _) = Create();

        Assert.Equal(ConnectionState.Disconnected, service.State);
        Assert.Null(service.Session);
    }

    [Fact]
    public async Task ConnectAsync_ReachesConnected_WithSession()
    {
        (OfflineNetworkService service, _) = Create();

        await service.ConnectAsync(Credentials);

        Assert.Equal(ConnectionState.Connected, service.State);
        Assert.NotNull(service.Session);
        Assert.Equal("Held", service.Session!.Username);
        Assert.Contains("device-123", service.Session.UserId);
    }

    [Fact]
    public async Task ConnectAsync_PublishesStateChanges_AndAuthentication()
    {
        (OfflineNetworkService service, EventBus bus) = Create();
        var states = new List<ConnectionState>();
        bool authenticated = false;
        bus.Subscribe<NetworkStateChangedEvent>(e => states.Add(e.Current));
        bus.Subscribe<NetworkAuthenticatedEvent>(_ => authenticated = true);

        await service.ConnectAsync(Credentials);

        Assert.Equal(new[] { ConnectionState.Connecting, ConnectionState.Connected }, states);
        Assert.True(authenticated);
    }

    [Fact]
    public async Task AuthenticatedEvent_DoesNotCarryToken()
    {
        (OfflineNetworkService service, EventBus bus) = Create();
        NetworkAuthenticatedEvent captured = default;
        bus.Subscribe<NetworkAuthenticatedEvent>(e => captured = e);

        await service.ConnectAsync(Credentials);

        // Das Ereignis trägt nur nicht-sensible Kennungen (UserId/Username), kein Token.
        Assert.Equal(service.Session!.UserId, captured.UserId);
        Assert.Equal(service.Session.Username, captured.Username);
    }

    [Fact]
    public async Task ConnectAsync_Twice_IsIdempotent()
    {
        (OfflineNetworkService service, EventBus bus) = Create();
        int stateChanges = 0;
        bus.Subscribe<NetworkStateChangedEvent>(_ => stateChanges++);

        await service.ConnectAsync(Credentials);
        await service.ConnectAsync(Credentials); // zweiter Aufruf wirkungslos

        Assert.Equal(ConnectionState.Connected, service.State);
        Assert.Equal(2, stateChanges); // nur Connecting + Connected vom ersten Aufruf
    }

    [Fact]
    public async Task DisconnectAsync_ReturnsToDisconnected_AndClearsSession()
    {
        (OfflineNetworkService service, _) = Create();
        await service.ConnectAsync(Credentials);

        await service.DisconnectAsync();

        Assert.Equal(ConnectionState.Disconnected, service.State);
        Assert.Null(service.Session);
    }

    [Fact]
    public async Task DisconnectAsync_WhenAlreadyDisconnected_DoesNothing()
    {
        (OfflineNetworkService service, _) = Create();

        await service.DisconnectAsync(); // kein Wurf, bleibt getrennt

        Assert.Equal(ConnectionState.Disconnected, service.State);
    }

    [Fact]
    public async Task DefaultUsername_UsedWhenNoneProvided()
    {
        (OfflineNetworkService service, _) = Create();

        await service.ConnectAsync(new AuthCredentials("device-xyz"));

        Assert.Equal("Offline-Spieler", service.Session!.Username);
    }
}
